package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.google.protobuf.MessageLite;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.websocket.core.protocol.*;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.module.system.controller.app.im.vo.message.*;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.*;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.enums.im.ImGroupMemberRoleEnum;
import com.shengyu.module.system.enums.im.ImMessageForwardTypeEnum;
import com.shengyu.module.system.enums.im.ImMessageStatusEnum;
import com.shengyu.module.system.enums.im.ImMessageTypeEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 消息 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImMessageServiceImpl implements ImMessageService {

    @Value("${im.recall.window-seconds:120}")
    private long recallWindowSeconds;

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImChatMessageTombstoneMapper chatMessageTombstoneMapper;

    @Resource
    private ImChatClearWatermarkMapper chatClearWatermarkMapper;

    @Resource
    private ImConversationUserStateMapper conversationUserStateMapper;

    @Resource
    private ImGroupService imGroupService;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private ImBadgeService imBadgeService;

    @Resource
    private ImCursorVersionService cursorVersionService;

    @Resource
    private NettyMessageSender messageSender;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendMessage(Long userId, AppImMessageSendReqVO sendReqVO) {
        Long chatId = sendReqVO.getChatId();
        
        // 幂等检查：如果传入了 clientMessageId，检查是否已存在
        String clientMessageId = sendReqVO.getClientMessageId();
        if (StrUtil.isNotBlank(clientMessageId)) {
            ImChatMessageDO existingMessage = chatMessageMapper.selectByClientMessageId(clientMessageId);
            if (existingMessage != null) {
                // 幂等返回：同一 clientMessageId 返回已存在的消息ID
                log.info("[ImMessageService] 幂等重发命中, clientMessageId: {}, existingMessageId: {}", 
                        clientMessageId, existingMessage.getId());
                return existingMessage.getId();
            }
        }
        
        ImChatUserDO selfChatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (selfChatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        ImChatDO chat = chatMapper.selectById(chatId);
        if (chat == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        ImChatMessageDO message = new ImChatMessageDO();
        message.setChatId(chatId);
        message.setSenderId(userId);
        message.setClientMessageId(clientMessageId);
        Integer dbMessageType = normalizeDbMessageType(sendReqVO.getMessageType());
        message.setMessageType(dbMessageType);

        if (dbMessageType == 5) {
            if (StrUtil.isBlank(sendReqVO.getExtra())) {
                throw ServiceExceptionUtil.invalidParamException("FILE 消息缺少 extra：必须包含 url/fileName/size/fileType(mimeType)");
            }
            try {
                JSONObject obj = JSONUtil.parseObj(sendReqVO.getExtra());
                String fileName = obj.getStr("fileName", obj.getStr("name", ""));
                Long size = obj.getLong("size", null);
                String fileType = obj.getStr("fileType", obj.getStr("mimeType", ""));
                String url = obj.getStr("url", "");
                if (StrUtil.isBlank(fileName) || size == null || size <= 0 || StrUtil.isBlank(fileType) || StrUtil.isBlank(url)) {
                    throw ServiceExceptionUtil.invalidParamException("FILE 消息 extra 字段不完整：必须包含 url/fileName/size/fileType(mimeType)");
                }
            } catch (ServiceException ex) {
                throw ex;
            } catch (Exception ex) {
                throw ServiceExceptionUtil.invalidParamException("FILE 消息 extra 不是合法 JSON：{}", ex.getMessage());
            }
        }
        message.setContent(sendReqVO.getContent());
        message.setExtra(sendReqVO.getExtra());
        // 分配会话内 sequence（单调递增），用于会话水位与未读计算
        Long sequence = chatMapper.nextSequence(chatId);
        message.setSequence(sequence);
        message.setSendTime(LocalDateTime.now());
        message.setRev(1L);
        message.setStatus(ImMessageStatusEnum.SENT.getStatus());
        message.setQuoteMessageId(sendReqVO.getQuoteMessageId());
        message.setMentions(sendReqVO.getMentions());
        chatMessageMapper.insert(message);

        String preview = getMessagePreview(dbMessageType, sendReqVO.getContent());
        updateChatUsersAfterSend(chat, message.getId(), message.getSequence(), message.getRev(), preview, message.getSendTime(), userId, sendReqVO);
        return message.getId();
    }

    @Override
    public List<AppImMessageRespVO> pullMessages(Long userId, AppImMessagePullReqVO pullReqVO) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, pullReqVO.getChatId());
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        Long lastSequence = pullReqVO.getLastSequence() != null ? pullReqVO.getLastSequence() : 0L;
        Integer limit = pullReqVO.getLimit() != null ? pullReqVO.getLimit() : 200;
        if (limit <= 0) {
            limit = 200;
        }
        if (limit > 500) {
            limit = 500;
        }

        List<ImChatMessageDO> list = chatMessageMapper.selectListByChatIdAndSequenceGt(pullReqVO.getChatId(), lastSequence, limit);

        // enterprise: clear-history watermark filter (sequence <= clearSequence not visible)
        Long clearSeq = null;
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            clearSeq = chatClearWatermarkMapper.selectClearSequence(tenantId, userId, pullReqVO.getChatId());
        } catch (Exception ignore) {
            clearSeq = null;
        }
        final Long finalClearSeq = clearSeq;

        // enterprise: delete-for-me tombstone filter
        List<Long> messageIds = list.stream().filter(m -> m != null && m.getId() != null).map(ImChatMessageDO::getId).collect(Collectors.toList());
        List<Long> deletedIds = null;
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            if (!messageIds.isEmpty()) {
                deletedIds = chatMessageTombstoneMapper.selectDeletedMessageIds(tenantId, userId, pullReqVO.getChatId(), messageIds);
            }
        } catch (Exception ignore) {
            deletedIds = null;
        }
        final List<Long> finalDeletedIds = deletedIds;

        return list.stream()
                .filter(m -> m != null && m.getId() != null
                        && (finalClearSeq == null || finalClearSeq <= 0 || (m.getSequence() != null && m.getSequence() > finalClearSeq))
                        && (finalDeletedIds == null || !finalDeletedIds.contains(m.getId())))
                .map(message -> {
            AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
            respVO.setChatId(message.getChatId());
            respVO.setSequence(message.getSequence());
            // 兼容历史数据：如果 messageType 被存成了 Protobuf 的 100+，则转换回 REST/DB 的 1-10
            respVO.setMessageType(normalizeDbMessageType(respVO.getMessageType()));
            fillSenderInfo(respVO, message.getSenderId());
            respVO.setIsSelf(Objects.equals(message.getSenderId(), userId));
            fillChatTargetFields(respVO, userId);
            return respVO;
        }).collect(Collectors.toList());
    }

    @Override
    public PageResult<AppImMessageRespVO> getMessagePage(Long userId, AppImMessagePageReqVO pageReqVO) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, pageReqVO.getChatId());
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        PageResult<ImChatMessageDO> pageResult = chatMessageMapper.selectPageByChatId(pageReqVO.getChatId(), pageReqVO);

        // enterprise: clear-history watermark filter
        Long clearSeq = null;
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            clearSeq = chatClearWatermarkMapper.selectClearSequence(tenantId, userId, pageReqVO.getChatId());
        } catch (Exception ignore) {
            clearSeq = null;
        }
        final Long finalClearSeq = clearSeq;

        // enterprise: delete-for-me tombstone filter
        List<Long> pageIds = pageResult.getList().stream().filter(m -> m != null && m.getId() != null).map(ImChatMessageDO::getId).collect(Collectors.toList());
        List<Long> deletedIds = null;
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            if (!pageIds.isEmpty()) {
                deletedIds = chatMessageTombstoneMapper.selectDeletedMessageIds(tenantId, userId, pageReqVO.getChatId(), pageIds);
            }
        } catch (Exception ignore) {
            deletedIds = null;
        }
        final List<Long> finalDeletedIds = deletedIds;

        List<AppImMessageRespVO> respVOList = pageResult.getList().stream()
                .filter(m -> m != null && m.getId() != null
                        && (finalClearSeq == null || finalClearSeq <= 0 || (m.getSequence() != null && m.getSequence() > finalClearSeq))
                        && (finalDeletedIds == null || !finalDeletedIds.contains(m.getId())))
                .map(message -> {
            AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
            respVO.setChatId(message.getChatId());
            respVO.setSequence(message.getSequence());
            // 兼容历史数据：如果 messageType 被存成了 Protobuf 的 100+，则转换回 REST/DB 的 1-10
            respVO.setMessageType(normalizeDbMessageType(respVO.getMessageType()));
            fillSenderInfo(respVO, message.getSenderId());
            respVO.setIsSelf(Objects.equals(message.getSenderId(), userId));
            fillChatTargetFields(respVO, userId);
            return respVO;
        }).collect(Collectors.toList());
        return new PageResult<>(respVOList, pageResult.getTotal());
    }

    @Override
    public List<AppImMessageRespVO> getConversationMessages(Long userId, Long chatId, Long lastMessageId, Integer pageSize) {
        // 旧接口不再支持（线路 A 统一走分页接口）
        throw exception(MESSAGE_SEND_FAILED);
    }

    @Override
    public AppImMessageRespVO getMessageDetail(Long userId, Long messageId) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, message.getChatId());
        if (chatUser == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        // enterprise: visibility filter (clear-history watermark + delete-for-me tombstone)
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        boolean invisible = false;
        try {
            Long clearSeq = chatClearWatermarkMapper.selectClearSequence(tenantId, userId, message.getChatId());
            if (clearSeq != null && clearSeq > 0 && message.getSequence() != null && message.getSequence() <= clearSeq) {
                invisible = true;
            }
        } catch (Exception ignore) {
            // ignore
        }
        try {
            List<Long> deletedIds = chatMessageTombstoneMapper.selectDeletedMessageIds(tenantId, userId, message.getChatId(), Collections.singletonList(messageId));
            if (deletedIds != null && !deletedIds.isEmpty()) {
                invisible = true;
            }
        } catch (Exception ignore) {
            // ignore
        }
        if (invisible) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
        respVO.setChatId(message.getChatId());
        respVO.setSequence(message.getSequence());
        respVO.setMessageType(normalizeDbMessageType(respVO.getMessageType()));
        fillSenderInfo(respVO, message.getSenderId());
        respVO.setIsSelf(Objects.equals(message.getSenderId(), userId));
        fillChatTargetFields(respVO, userId);
        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateMessageStatus(Long userId, Long messageId, Integer status) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        // 仅允许发送者撤回
        if (!Objects.equals(message.getSenderId(), userId)) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        chatMessageMapper.update(null, new LambdaUpdateWrapper<ImChatMessageDO>()
                .eq(ImChatMessageDO::getId, messageId)
                .set(ImChatMessageDO::getStatus, status));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void batchUpdateMessageStatus(Long userId, List<Long> messageIds, Integer status) {
        if (messageIds == null || messageIds.isEmpty()) {
            return;
        }

        // 线路 A：按 messageId 批量更新
        int updatedCount = chatMessageMapper.updateStatusByIds(messageIds, status);
        log.debug("[ImMessageService] 批量更新消息状态成功, userId: {}, messageCount: {}, updated: {}, status: {}",
                userId, messageIds.size(), updatedCount, status);
    }

    private void updateChatUsersAfterSend(ImChatDO chat, Long lastMessageId, Long lastMessageSequence, Long messageRev,
                                         String lastMessageContent, LocalDateTime lastMessageTime,
                                         Long senderId, AppImMessageSendReqVO sendReqVO) {
        Integer dbMessageType = normalizeDbMessageType(sendReqVO.getMessageType());
        Long finalRev = messageRev != null && messageRev > 0 ? messageRev : 1L;
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
            List<Long> memberIds = imGroupService.getGroupMemberIds(chat.getGroupId());
            Map<Long, Long> cursorVerMap;
            try {
                cursorVerMap = cursorVersionService.allocateNextCursorVersions(tenantId, memberIds);
            } catch (Exception e) {
                cursorVerMap = Collections.emptyMap();
                log.warn("[ImMessageService] 批量分配 cursorVersion 失败(群消息), chatId: {}, groupId: {}, error: {}",
                        chat.getId(), chat.getGroupId(), e.getMessage());
            }

            for (Long memberId : memberIds) {
                ImChatUserDO chatUser = ensureChatUser(memberId, chat.getId());
                boolean isSender = Objects.equals(memberId, senderId);
                chatUserMapper.updateLastMessageAndIncrementUnread(
                        chatUser.getId(), lastMessageId, lastMessageSequence, dbMessageType, lastMessageContent, lastMessageTime,
                        isSender ? 0 : 1,
                        Boolean.TRUE.equals(chatUser.getNoDisturb()));

				// 发送者侧：持久化推进已读水位，避免重登后自己的消息出现未读角标
				if (isSender && lastMessageSequence != null) {
					try {
						chatUserMapper.markReadToSequence(senderId, chat.getId(), lastMessageSequence);
					} catch (Exception ignore) {
						// ignore
					}
				}

                // 同步写入 im_conversation_user_state，支持离线重连后 /sync 增量拉取
                try {
                    Long cursorVer = cursorVerMap.get(memberId);
                    if (cursorVer == null) {
                        cursorVer = cursorVersionService.allocateNextCursorVersion(tenantId, memberId);
                    }
                    int unreadDelta = isSender ? 0 : 1;
                    Long lastReadSeq = isSender ? lastMessageSequence : null;
                    LocalDateTime lastReadTime = isSender ? lastMessageTime : null;
                    conversationUserStateMapper.upsertAfterMessage(
                            tenantId, chat.getId(), memberId, cursorVer,
                            unreadDelta, lastReadSeq, lastReadTime,
                            lastMessageId, lastMessageSequence, dbMessageType, lastMessageContent, lastMessageTime);
                } catch (Exception e) {
                    log.warn("[ImMessageService] 写入会话-用户态失败(群消息), chatId: {}, memberId: {}, error: {}",
                            chat.getId(), memberId, e.getMessage());
                }

                if (!isSender) {
                    imBadgeService.pushBadgeUpdate(memberId);
                    // 推送消息内容给接收者
                    pushMessageToUser(memberId, chat.getId(), lastMessageId, lastMessageSequence, finalRev, senderId, sendReqVO);
                }
            }
            
            // 处理@提及强提醒：被@用户即使群免打扰也收到推送
            handleMentionNotifications(chat, lastMessageId, lastMessageSequence, finalRev, senderId, sendReqVO, memberIds);
        } else {
            ImChatUserDO sender = ensureChatUser(senderId, chat.getId());
            chatUserMapper.updateLastMessageAndIncrementUnread(
                    sender.getId(), lastMessageId, lastMessageSequence, dbMessageType, lastMessageContent, lastMessageTime,
                    0,
                    Boolean.TRUE.equals(sender.getNoDisturb()));

			// 发送者侧：持久化推进已读水位，避免重登后自己的消息出现未读角标
			if (lastMessageSequence != null) {
				try {
					chatUserMapper.markReadToSequence(senderId, chat.getId(), lastMessageSequence);
				} catch (Exception ignore) {
					// ignore
				}
			}

            // 发送者侧写入 im_conversation_user_state（lastRead=lastSeq，自己发的消息已读）
            Long receiverId = Objects.equals(chat.getSingleUser1(), senderId) ? chat.getSingleUser2() : chat.getSingleUser1();
            Map<Long, Long> cursorVerMap;
            try {
                cursorVerMap = cursorVersionService.allocateNextCursorVersions(tenantId, Arrays.asList(senderId, receiverId));
            } catch (Exception e) {
                cursorVerMap = Collections.emptyMap();
                log.warn("[ImMessageService] 批量分配 cursorVersion 失败(单聊消息), chatId: {}, senderId: {}, error: {}",
                        chat.getId(), senderId, e.getMessage());
            }
            try {
                Long senderCursorVer = cursorVerMap.get(senderId);
                if (senderCursorVer == null) {
                    senderCursorVer = cursorVersionService.allocateNextCursorVersion(tenantId, senderId);
                }
                conversationUserStateMapper.upsertAfterMessage(
                        tenantId, chat.getId(), senderId, senderCursorVer,
                        0, lastMessageSequence, lastMessageTime,
                        lastMessageId, lastMessageSequence, dbMessageType, lastMessageContent, lastMessageTime);
            } catch (Exception e) {
                log.warn("[ImMessageService] 写入会话-用户态失败(单聊发送者), chatId: {}, senderId: {}, error: {}",
                        chat.getId(), senderId, e.getMessage());
            }

            ImChatUserDO receiver = ensureChatUser(receiverId, chat.getId());
            chatUserMapper.updateLastMessageAndIncrementUnread(
                    receiver.getId(), lastMessageId, lastMessageSequence, dbMessageType, lastMessageContent, lastMessageTime,
                    1,
                    Boolean.TRUE.equals(receiver.getNoDisturb()));

            // 接收者侧写入 im_conversation_user_state（unreadDelta=1，支持离线 /sync 拉取未读）
            try {
                Long receiverCursorVer = cursorVerMap.get(receiverId);
                if (receiverCursorVer == null) {
                    receiverCursorVer = cursorVersionService.allocateNextCursorVersion(tenantId, receiverId);
                }
                conversationUserStateMapper.upsertAfterMessage(
                        tenantId, chat.getId(), receiverId, receiverCursorVer,
                        1, null, null,
                        lastMessageId, lastMessageSequence, dbMessageType, lastMessageContent, lastMessageTime);
            } catch (Exception e) {
                log.warn("[ImMessageService] 写入会话-用户态失败(单聊接收者), chatId: {}, receiverId: {}, error: {}",
                        chat.getId(), receiverId, e.getMessage());
            }

            imBadgeService.pushBadgeUpdate(receiverId);
            // 推送消息内容给接收者
            pushMessageToUser(receiverId, chat.getId(), lastMessageId, lastMessageSequence, finalRev, senderId, sendReqVO);
        }
    }

    /**
     * 统一 REST/DB 的 messageType（1-10）与 Protobuf/WebSocket 的 MessageType（100+）
     */
    private Integer normalizeDbMessageType(Integer messageType) {
        if (messageType == null) {
            return null;
        }
        // Protobuf/WebSocket 业务消息（100+）映射到 REST/DB（1-10）
        switch (messageType) {
            case 100:
                return 1;
            case 101:
                return 2;
            case 102:
                return 3;
            case 103:
                return 4;
            case 104:
                return 5;
            case 105:
                return 6;
            case 106:
                return 8;
            case 205:
                // 引用回复本质上仍然是文本（前端用 quote 渲染），DB 侧按文本存储
                return 1;
            default:
                return messageType;
        }
    }

    private void pushMessageToUser(Long userId, Long chatId, Long messageId, Long sequence, Long rev, Long senderId, AppImMessageSendReqVO sendReqVO) {
        try {
            Long tenantId = TenantContextHolder.getTenantId();

            // 根据消息类型构建不同的消息体
            MessageType messageType;
            MessageLite messageBody;
            String headerExtra = sendReqVO.getExtra();

            Integer dbMessageType = normalizeDbMessageType(sendReqVO.getMessageType());
            switch (dbMessageType) {
                case 1: // 文本消息
                    messageType = MessageType.TEXT;
                    messageBody = TextMessage.newBuilder()
                            .setContent(sendReqVO.getContent())
                            .build();
                    break;
                case 2: // 图片消息
                    messageType = MessageType.IMAGE;
                    messageBody = ImageMessage.newBuilder()
                            .setUrl(sendReqVO.getContent())
                            .build();
                    break;
                case 3: // 语音消息
                    messageType = MessageType.VOICE;
                    messageBody = VoiceMessage.newBuilder()
                            .setUrl(sendReqVO.getContent())
                            .build();
                    break;
                case 4: // 视频消息
                    messageType = MessageType.VIDEO;
                    messageBody = VideoMessage.newBuilder()
                            .setUrl(sendReqVO.getContent())
                            .build();
                    break;
                case 5: // 文件消息
                    messageType = MessageType.FILE;
                    // 优先从 extra JSON 中取元数据（fileName/size/fileType/url），确保端侧展示一致
                    String url = sendReqVO.getContent();
                    String fileName = "";
                    long size = 0L;
                    String fileType = "";
                    if (StrUtil.isNotBlank(sendReqVO.getExtra())) {
                        try {
                            JSONObject obj = JSONUtil.parseObj(sendReqVO.getExtra());
                            if (StrUtil.isBlank(url)) {
                                url = obj.getStr("url", "");
                            }
                            fileName = obj.getStr("fileName", obj.getStr("name", ""));
                            size = obj.getLong("size", 0L);
                            fileType = obj.getStr("fileType", obj.getStr("mimeType", ""));
                        } catch (Exception ignore) {
                            // ignore
                        }
                    }
                    if (StrUtil.isBlank(fileName) && StrUtil.isNotBlank(url)) {
                        int idx = url.lastIndexOf('/');
                        fileName = idx >= 0 ? url.substring(idx + 1) : url;
                    }
                    FileMessage.Builder fileBuilder = FileMessage.newBuilder()
                            .setUrl(url == null ? "" : url)
                            .setFileName(fileName == null ? "" : fileName)
                            .setSize(size)
                            .setFileType(fileType == null ? "" : fileType);
                    messageBody = fileBuilder.build();
                    // 同步补齐 header.extra，便于存储侧直接落库
                    if (StrUtil.isBlank(headerExtra)) {
                        JSONObject obj = JSONUtil.createObj();
                        obj.set("url", url);
                        obj.set("fileName", fileName);
                        obj.set("size", size);
                        obj.set("fileType", fileType);
                        headerExtra = obj.toString();
                    }
                    break;
                case 6: // 位置消息
                    messageType = MessageType.LOCATION;
                    messageBody = TextMessage.newBuilder()
                            .setContent(sendReqVO.getContent())
                            .build();
                    break;
                default:
                    // 默认使用系统通知类型
                    messageType = MessageType.SYSTEM_NOTIFY;
                    messageBody = TextMessage.newBuilder()
                            .setContent(sendReqVO.getContent())
                            .build();
                    break;
            }

            Long receiverId = sendReqVO.getReceiverId();
            Long groupId = sendReqVO.getGroupId();

            // enterprise: include rev for final-state merge; merge with existing header.extra (e.g. file metadata)
            String extraWithRev = null;
            Long finalRev = rev != null && rev > 0 ? rev : 1L;
            try {
                JSONObject obj = StrUtil.isNotBlank(headerExtra) ? JSONUtil.parseObj(headerExtra) : JSONUtil.createObj();
                obj.set("rev", finalRev);
                extraWithRev = obj.toString();
            } catch (Exception e) {
                try {
                    JSONObject obj = JSONUtil.createObj();
                    obj.set("rev", finalRev);
                    extraWithRev = obj.toString();
                } catch (Exception ignore) {
                    extraWithRev = null;
                }
            }

            // 群聊推送给成员时，前端会话路由依赖 groupId；单聊依赖 receiverId/senderId
            messageSender.sendToUserWithExtra(userId, messageType, messageBody,
                    senderId, receiverId, groupId, tenantId, messageId, sequence, chatId,
                    null, null, extraWithRev);
            log.debug("[ImMessageService] WebSocket 消息推送成功, userId: {}, messageId: {}", userId, messageId);
        } catch (Exception e) {
            log.error("[ImMessageService] WebSocket 消息推送失败, userId: {}, messageId: {}", userId, messageId, e);
        }
    }

    /**
     * 处理@提及强提醒
     * 被提及用户即使群免打扰也会收到推送
     * 
     * @param chat 会话
     * @param messageId 消息ID
     * @param sequence 序列号
     * @param rev 版本号
     * @param senderId 发送者ID
     * @param sendReqVO 发送请求
     * @param memberIds 群成员ID列表
     */
    private void handleMentionNotifications(ImChatDO chat, Long messageId, Long sequence, Long rev,
                                             Long senderId, AppImMessageSendReqVO sendReqVO, List<Long> memberIds) {
        String mentionsJson = sendReqVO.getMentions();
        if (StrUtil.isBlank(mentionsJson)) {
            return;
        }
        
        try {
            // 解析mentions字段
            List<JSONObject> mentions = JSONUtil.parseArray(mentionsJson).toList(JSONObject.class);
            if (mentions == null || mentions.isEmpty()) {
                return;
            }
            
            // 提取被@用户ID
            List<Long> mentionedUserIds = mentions.stream()
                    .map(m -> m.getLong("userId"))
                    .filter(id -> id != null)
                    .collect(Collectors.toList());
            
            if (mentionedUserIds.isEmpty()) {
                return;
            }
            
            log.info("[ImMessageService] 处理@提及强提醒, chatId: {}, mentionedUserIds: {}", 
                    chat.getId(), mentionedUserIds);
            
            // 对被@用户发送强提醒推送（即使群免打扰）
            for (Long mentionedUserId : mentionedUserIds) {
                if (Objects.equals(mentionedUserId, senderId)) {
                    continue; // 不给自己推送
                }
                
                // 检查是否是群成员
                if (memberIds != null && !memberIds.contains(mentionedUserId)) {
                    log.warn("[ImMessageService] 被@用户不在群成员列表中, userId: {}, chatId: {}", 
                            mentionedUserId, chat.getId());
                    continue;
                }
                
                // 强提醒推送：即使群免打扰也推送
                try {
                    // 构建强提醒消息
                    JSONObject extraData = new JSONObject();
                    extraData.set("mentionType", "SINGLE");
                    extraData.set("forceNotify", true);
                    
                    TextMessage notifyBody = TextMessage.newBuilder()
                            .setContent("[有人@我]")
                            .build();
                    
                    Long tenantId = TenantContextHolder.getTenantId();
                    messageSender.sendToUserWithExtra(mentionedUserId, MessageType.TEXT, notifyBody,
                            senderId, null, chat.getGroupId(), tenantId != null ? tenantId : 0L,
                            messageId, sequence, chat.getId(),
                            null, null, extraData.toString());
                    
                    log.debug("[ImMessageService] @提及强提醒推送成功, mentionedUserId: {}, messageId: {}", 
                            mentionedUserId, messageId);
                } catch (Exception e) {
                    log.warn("[ImMessageService] @提及强提醒推送失败, mentionedUserId: {}, messageId: {}, error: {}", 
                            mentionedUserId, messageId, e.getMessage());
                }
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 解析mentions字段失败, mentions: {}, error: {}", 
                    mentionsJson, e.getMessage());
        }
    }

    private ImChatUserDO ensureChatUser(Long userId, Long chatId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser != null) {
            return chatUser;
        }
        chatUser = new ImChatUserDO();
        chatUser.setUserId(userId);
        chatUser.setChatId(chatId);
        chatUser.setUnreadCount(0);
        chatUser.setIsPinned(false);
        chatUser.setNoDisturb(false);
        chatUser.setDeletedByUser(false);
        chatUserMapper.insert(chatUser);
        return chatUser;
    }

    private void fillSenderInfo(AppImMessageRespVO respVO, Long senderId) {
        if (senderId == null) {
            return;
        }
        AdminUserDO sender = userMapper.selectById(senderId);
        if (sender != null) {
            respVO.setSenderNickname(sender.getNickname());
            respVO.setSenderAvatar(sender.getAvatar());
        }
    }

    private void fillChatTargetFields(AppImMessageRespVO respVO, Long currentUserId) {
        if (respVO.getChatId() == null) {
            return;
        }
        ImChatDO chat = chatMapper.selectById(respVO.getChatId());
        if (chat == null) {
            return;
        }
        if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
            respVO.setGroupId(chat.getGroupId());
        } else {
            Long receiverId = Objects.equals(chat.getSingleUser1(), currentUserId) ? chat.getSingleUser2() : chat.getSingleUser1();
            respVO.setReceiverId(receiverId);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long forwardMessage(Long userId, Long messageId, Long targetChatId) {
        // 单条转发，复用批量转发逻辑
        AppImMessageForwardReqVO forwardReqVO = new AppImMessageForwardReqVO();
        forwardReqVO.setTargetChatId(targetChatId);
        forwardReqVO.setMessageIds(Collections.singletonList(messageId));
        forwardReqVO.setForwardType(ImMessageForwardTypeEnum.SINGLE.getType());
        List<Long> result = forwardMessages(userId, forwardReqVO);
        return result != null && !result.isEmpty() ? result.get(0) : null;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public List<Long> forwardMessages(Long userId, AppImMessageForwardReqVO forwardReqVO) {
        Long targetChatId = forwardReqVO.getTargetChatId();
        List<Long> messageIds = forwardReqVO.getMessageIds();
        Integer forwardType = forwardReqVO.getForwardType();

        // 1. 校验目标会话
        ImChatUserDO targetChatUser = chatUserMapper.selectByUserIdAndChatId(userId, targetChatId);
        if (targetChatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        ImChatDO targetChat = chatMapper.selectById(targetChatId);
        if (targetChat == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 2. 查询原消息并校验可见性
        List<ImChatMessageDO> originalMessages = chatMessageMapper.selectBatchIds(messageIds);
        if (originalMessages == null || originalMessages.isEmpty()) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        // 过滤不可转发的消息：已撤回、已删除(tombstone)
        List<ImChatMessageDO> forwardableMessages = new java.util.ArrayList<>();
        for (ImChatMessageDO msg : originalMessages) {
            if (msg == null) {
                continue;
            }
            // 已撤回消息不可转发
            if (Objects.equals(msg.getStatus(), ImMessageStatusEnum.RECALLED.getStatus())) {
                log.warn("[ImMessageService] 转发跳过已撤回消息, messageId: {}", msg.getId());
                continue;
            }
            // tombstone过滤：对我删除的消息不可转发
            boolean isDeleted = chatMessageTombstoneMapper.existsByUserIdAndMessageId(userId, msg.getId());
            if (isDeleted) {
                log.warn("[ImMessageService] 转发跳过已删除消息, userId: {}, messageId: {}", userId, msg.getId());
                continue;
            }
            forwardableMessages.add(msg);
        }

        if (forwardableMessages.isEmpty()) {
            throw exception(MESSAGE_SEND_FAILED, "无可转发的消息");
        }

        // 3. 获取原发送者信息用于隐私保护展示
        List<Long> senderIds = forwardableMessages.stream()
                .map(ImChatMessageDO::getSenderId)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, AdminUserDO> senderMap = new java.util.HashMap<>();
        if (!senderIds.isEmpty()) {
            List<AdminUserDO> senders = userMapper.selectBatchIds(senderIds);
            if (senders != null) {
                for (AdminUserDO sender : senders) {
                    senderMap.put(sender.getId(), sender);
                }
            }
        }

        List<Long> newMessageIds = new java.util.ArrayList<>();
        LocalDateTime forwardTime = LocalDateTime.now();

        // 4. 根据转发类型处理
        if (Objects.equals(forwardType, ImMessageForwardTypeEnum.COMBINE.getType())) {
            // 合并转发：生成一条 FORWARD_COMBINE 类型消息
            Long newMessageId = createCombineForwardMessage(userId, targetChat, forwardableMessages, 
                    senderMap, forwardReqVO.getComment(), forwardTime);
            newMessageIds.add(newMessageId);
        } else {
            // 逐条转发：每条消息生成新消息
            for (ImChatMessageDO originalMsg : forwardableMessages) {
                Long newMessageId = createSingleForwardMessage(userId, targetChat, originalMsg, 
                        senderMap.get(originalMsg.getSenderId()), forwardTime);
                newMessageIds.add(newMessageId);
            }
        }

        log.info("[ImMessageService] 转发消息成功, userId: {}, forwardType: {}, originalCount: {}, newMessageIds: {}",
                userId, forwardType, forwardableMessages.size(), newMessageIds);
        return newMessageIds;
    }

    /**
     * 创建单条转发消息
     */
    private Long createSingleForwardMessage(Long userId, ImChatDO targetChat, ImChatMessageDO originalMsg,
                                             AdminUserDO originalSender, LocalDateTime forwardTime) {
        ImChatMessageDO newMessage = new ImChatMessageDO();
        newMessage.setChatId(targetChat.getId());
        newMessage.setSenderId(userId);
        newMessage.setMessageType(originalMsg.getMessageType());
        newMessage.setContent(originalMsg.getContent());
        newMessage.setExtra(originalMsg.getExtra());

        Long sequence = chatMapper.nextSequence(targetChat.getId());
        newMessage.setSequence(sequence);
        newMessage.setSendTime(forwardTime);
        newMessage.setRev(1L);
        newMessage.setStatus(ImMessageStatusEnum.SENT.getStatus());

        // 构建转发来源信息
        JSONObject forwardedFrom = new JSONObject();
        forwardedFrom.set("originalMessageId", originalMsg.getId());
        forwardedFrom.set("originalChatId", originalMsg.getChatId());
        forwardedFrom.set("originalSenderId", originalMsg.getSenderId());
        forwardedFrom.set("originalSenderName", originalSender != null ? originalSender.getNickname() : "");
        forwardedFrom.set("forwardTime", forwardTime.toString());
        newMessage.setForwardedFrom(forwardedFrom.toString());

        chatMessageMapper.insert(newMessage);

        // 更新会话状态并推送
        String preview = getMessagePreview(originalMsg.getMessageType(), originalMsg.getContent());
        AppImMessageSendReqVO sendReqVO = new AppImMessageSendReqVO();
        sendReqVO.setMessageType(originalMsg.getMessageType());
        sendReqVO.setExtra(originalMsg.getExtra());
        updateChatUsersAfterSend(targetChat, newMessage.getId(), sequence, 1L, preview, forwardTime, userId, sendReqVO);

        return newMessage.getId();
    }

    /**
     * 创建合并转发消息
     */
    private Long createCombineForwardMessage(Long userId, ImChatDO targetChat, List<ImChatMessageDO> originalMessages,
                                              Map<Long, AdminUserDO> senderMap, String comment, LocalDateTime forwardTime) {
        ImChatMessageDO newMessage = new ImChatMessageDO();
        newMessage.setChatId(targetChat.getId());
        newMessage.setSenderId(userId);
        // 合并转发使用 CUSTOM 类型，前端按合并消息渲染
        newMessage.setMessageType(ImMessageTypeEnum.CUSTOM.getType());

        // 构建合并消息内容
        JSONObject body = new JSONObject();
        body.set("type", "FORWARD_COMBINE");
        
        // 构建消息列表
        List<JSONObject> messages = new java.util.ArrayList<>();
        for (ImChatMessageDO msg : originalMessages) {
            JSONObject msgObj = new JSONObject();
            msgObj.set("messageId", msg.getId());
            msgObj.set("messageType", msg.getMessageType());
            msgObj.set("content", msg.getContent());
            msgObj.set("extra", msg.getExtra());
            msgObj.set("senderId", msg.getSenderId());
            AdminUserDO sender = senderMap.get(msg.getSenderId());
            msgObj.set("senderName", sender != null ? sender.getNickname() : "");
            msgObj.set("sendTime", msg.getSendTime() != null ? msg.getSendTime().toString() : "");
            messages.add(msgObj);
        }
        body.set("messages", messages);
        body.set("count", messages.size());
        if (StrUtil.isNotBlank(comment)) {
            body.set("comment", comment);
        }

        newMessage.setContent(body.toString());

        Long sequence = chatMapper.nextSequence(targetChat.getId());
        newMessage.setSequence(sequence);
        newMessage.setSendTime(forwardTime);
        newMessage.setRev(1L);
        newMessage.setStatus(ImMessageStatusEnum.SENT.getStatus());

        // 构建转发来源信息（合并转发记录所有原消息）
        JSONObject forwardedFrom = new JSONObject();
        forwardedFrom.set("type", "COMBINE");
        forwardedFrom.set("messageIds", originalMessages.stream().map(ImChatMessageDO::getId).collect(Collectors.toList()));
        forwardedFrom.set("forwardTime", forwardTime.toString());
        newMessage.setForwardedFrom(forwardedFrom.toString());

        chatMessageMapper.insert(newMessage);

        // 更新会话状态并推送
        String preview = "[合并转发] " + originalMessages.size() + "条消息";
        AppImMessageSendReqVO sendReqVO = new AppImMessageSendReqVO();
        sendReqVO.setMessageType(ImMessageTypeEnum.CUSTOM.getType());
        updateChatUsersAfterSend(targetChat, newMessage.getId(), sequence, 1L, preview, forwardTime, userId, sendReqVO);

        return newMessage.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recallMessage(Long userId, Long messageId) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        
        ImChatDO chat = chatMapper.selectById(message.getChatId());
        if (chat == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        
        // 权限检查：判断是否可以撤回
        boolean isSelfMessage = Objects.equals(message.getSenderId(), userId);
        boolean isGroupChat = ImConversationTypeEnum.isGroup(chat.getChatType());
        Integer memberRole = null;
        
        if (isGroupChat && !isSelfMessage) {
            // 群聊中撤回他人消息：检查是否是群主或管理员
            memberRole = imGroupService.getMemberRole(chat.getGroupId(), userId);
            if (memberRole == null) {
                throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
            }
            // 只有群主(2)和管理员(1)可以撤回他人消息
            if (!ImGroupMemberRoleEnum.isOwner(memberRole) && !ImGroupMemberRoleEnum.isAdmin(memberRole)) {
                throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
            }
        } else if (!isSelfMessage) {
            // 单聊只能撤回自己的消息
            throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
        }
        
        // 时限检查
        long windowSec;
        if (isSelfMessage) {
            // 自己的消息：默认2分钟
            windowSec = recallWindowSeconds > 0 ? recallWindowSeconds : 120L;
        } else if (ImGroupMemberRoleEnum.isOwner(memberRole)) {
            // 群主撤回：不限时
            windowSec = Long.MAX_VALUE / 1000; // 实际不限
        } else {
            // 管理员撤回：默认24小时
            windowSec = 24 * 60 * 60L; // 可配置化扩展
        }
        
        LocalDateTime windowAgo = LocalDateTime.now().minusSeconds(windowSec);
        if (message.getSendTime().isBefore(windowAgo)) {
            throw exception(MESSAGE_RECALL_TIMEOUT);
        }
        
        LocalDateTime recallTime = LocalDateTime.now();
        Long oldRev = message.getRev() != null && message.getRev() > 0 ? message.getRev() : 1L;
        Long newRev = oldRev + 1L;
        chatMessageMapper.update(null, new LambdaUpdateWrapper<ImChatMessageDO>()
                .eq(ImChatMessageDO::getId, messageId)
                .set(ImChatMessageDO::getStatus, ImMessageStatusEnum.RECALLED.getStatus())
                .set(ImChatMessageDO::getRecallTime, recallTime)
                .set(ImChatMessageDO::getRecallBy, userId)
                .setSql("rev = IFNULL(rev, 1) + 1"));

        // 企微/钉钉口径：撤回影响会话列表预览的“最终态一致”，需持久化落库并通过 cursorVersion 增量同步到其它端
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            ImChatDO chat = chatMapper.selectById(message.getChatId());
            if (chat != null) {
                List<ImChatUserDO> chatUsers = chatUserMapper.selectList(new LambdaQueryWrapperX<ImChatUserDO>()
                        .eq(ImChatUserDO::getChatId, message.getChatId())
                        .eq(ImChatUserDO::getDeletedByUser, false)
                        .eq(ImChatUserDO::getDeleted, false));
                if (chatUsers != null) {
                    for (ImChatUserDO cu : chatUsers) {
                        if (cu == null) {
                            continue;
                        }
                        // 仅当撤回消息仍是该用户会话 lastMessage 时才更新预览（避免 lastMessage 已推进造成回写覆盖）
                        int updated = chatUserMapper.updateLastMessagePreviewIfMatch(
                                cu.getId(),
                                messageId,
                                10,
                                "[消息已撤回]"
                        );
                        if (updated <= 0) {
                            continue;
                        }

                        Long targetUserId = cu.getUserId();
                        Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, targetUserId);
                        // unreadCount/lastReadSeq 由 existing state/max 规则兜底，这里只用于推动“会话预览变更”跨端可见
                        conversationUserStateMapper.upsertAfterMessage(
                                tenantId,
                                message.getChatId(),
                                targetUserId,
                                cursorVersion,
                                0,
                                null,
                                null,
                                messageId,
                                message.getSequence() != null ? message.getSequence() : 0L,
                                10,
                                "[消息已撤回]",
                                message.getSendTime() != null ? message.getSendTime() : recallTime
                        );

                        // 主动推送“会话快照变更提示”，促使端侧增量 sync(cursor) 及时拉取预览变更（对标企微/钉钉多端一致）
                        try {
                            TextMessage notifyBody = TextMessage.newBuilder().setContent("").build();
                            messageSender.sendToUser(targetUserId, MessageType.SYSTEM_NOTIFY, notifyBody,
                                    0L, targetUserId, 0L, tenantId,
                                    null, null, message.getChatId(),
                                    cursorVersion, null);
                        } catch (Exception ignore) {
                            // ignore
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 撤回预览落库/增量同步失败, userId: {}, messageId: {}, error: {}",
                    userId, messageId, e.getMessage(), e);
        }

        // 企业级一致性：撤回必须通过 WS 实时广播到会话参与方（对端/群成员）以及操作者的其他设备
        try {
            ImChatDO chat = chatMapper.selectById(message.getChatId());
            if (chat == null) {
                return;
            }
            Long tenantId = TenantContextHolder.getTenantId();
            RecallMessage body = RecallMessage.newBuilder().setMessageId(messageId).build();

            // WS 元数据：rev/recallTime/recallBy，端侧用 rev 做最终态合并（对标企微/钉钉乱序与补偿）
            String extra = null;
            try {
                JSONObject obj = JSONUtil.createObj();
                obj.set("rev", newRev);
                obj.set("recallBy", userId);
                obj.set("recallTime", recallTime != null ? recallTime.toString() : "");
                extra = obj.toString();
            } catch (Exception ignore) {
                extra = null;
            }

            if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
                Long groupId = chat.getGroupId();
                List<Long> memberIds = imGroupService.getGroupMemberIds(groupId);
                if (memberIds != null) {
                    for (Long memberId : memberIds) {
                        if (memberId == null || memberId <= 0) {
                            continue;
                        }
                        messageSender.sendToUserWithExtra(memberId, MessageType.RECALL, body,
                                userId, 0L, groupId, tenantId,
                                messageId, message.getSequence(), message.getChatId(),
                                null, null, extra);
                    }
                }
                // 确保操作者本人多端可见（即便不在 memberIds 里）
                messageSender.sendToUserWithExtra(userId, MessageType.RECALL, body,
                        userId, 0L, groupId, tenantId,
                        messageId, message.getSequence(), message.getChatId(),
                        null, null, extra);
            } else {
                Long otherUserId = Objects.equals(chat.getSingleUser1(), userId) ? chat.getSingleUser2() : chat.getSingleUser1();
                // 对端
                messageSender.sendToUserWithExtra(otherUserId, MessageType.RECALL, body,
                        userId, otherUserId, 0L, tenantId,
                        messageId, message.getSequence(), message.getChatId(),
                        null, null, extra);
                // 自己多端
                messageSender.sendToUserWithExtra(userId, MessageType.RECALL, body,
                        userId, otherUserId, 0L, tenantId,
                        messageId, message.getSequence(), message.getChatId(),
                        null, null, extra);
            }

            // enterprise: re-edit-after-recall hint (ONLY to sender devices; never broadcast original content)
            try {
                boolean isText = Objects.equals(message.getMessageType(), ImMessageTypeEnum.TEXT.getType());
                if (isText) {
                    long reeditWindowSec = 300L;
                    long deadlineTs = recallTime != null ? recallTime.plusSeconds(reeditWindowSec).atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() : 0L;
                    String hintExtra = null;
                    try {
                        JSONObject obj = JSONUtil.createObj();
                        obj.set("action", "reedit_after_recall");
                        obj.set("chatId", message.getChatId());
                        obj.set("messageId", messageId);
                        obj.set("rev", newRev);
                        obj.set("recallBy", userId);
                        obj.set("recallTime", recallTime != null ? recallTime.toString() : "");
                        obj.set("deadlineTs", deadlineTs);
                        obj.set("originalContent", message.getContent() != null ? message.getContent() : "");
                        hintExtra = obj.toString();
                    } catch (Exception ignore) {
                        hintExtra = null;
                    }
                    TextMessage notifyBody = TextMessage.newBuilder().setContent("").build();
                    messageSender.sendToUserWithExtra(userId, MessageType.SYSTEM_NOTIFY, notifyBody,
                            0L, userId, 0L, tenantId,
                            null, null, message.getChatId(),
                            null, null, hintExtra);
                }
            } catch (Exception ignore) {
                // ignore
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 推送撤回事件失败, userId: {}, messageId: {}, error: {}",
                    userId, messageId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteMessage(Long userId, Long messageId) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, message.getChatId());
        if (chatUser == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        // idempotent tombstone insert
        chatMessageTombstoneMapper.insertIgnore(tenantId, message.getChatId(), userId, messageId);

        // push conversation state change via cursorVersion so other devices hide this message on refresh/sync
        try {
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterSettings(
                    tenantId,
                    message.getChatId(),
                    userId,
                    cursorVersion,
                    chatUser.getIsPinned(),
                    chatUser.getNoDisturb(),
                    chatUser.getDraft()
            );

            try {
                TextMessage body = TextMessage.newBuilder().setContent("").build();
                messageSender.sendToUser(userId, MessageType.SYSTEM_NOTIFY, body,
                        0L, userId, 0L, tenantId,
                        null, null, message.getChatId(),
                        cursorVersion, null);
            } catch (Exception e) {
                log.warn("[ImMessageService] 推送删除消息增量同步通知失败, userId: {}, messageId: {}, error: {}",
                        userId, messageId, e.getMessage(), e);
            }

            try {
                imBadgeService.pushBadgeUpdate(userId);
            } catch (Exception e) {
                log.warn("[ImMessageService] 推送删除消息角标更新失败, userId: {}, messageId: {}, error: {}",
                        userId, messageId, e.getMessage(), e);
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 删除消息写入会话用户态失败, userId: {}, messageId: {}, error: {}",
                    userId, messageId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void clearConversationMessages(Long userId, Long chatId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        // enterprise: clear to current chat last_sequence (monotonic)
        Long clearSeq = 0L;
        try {
            ImChatDO chat = chatMapper.selectById(chatId);
            if (chat != null && chat.getLastSequence() != null && chat.getLastSequence() > 0) {
                clearSeq = chat.getLastSequence();
            }
        } catch (Exception ignore) {
            clearSeq = 0L;
        }
        if (clearSeq == null) {
            clearSeq = 0L;
        }

        chatClearWatermarkMapper.upsertMax(tenantId, chatId, userId, clearSeq);

        // push cross-device conversation state change
        try {
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterSettings(
                    tenantId,
                    chatId,
                    userId,
                    cursorVersion,
                    chatUser.getIsPinned(),
                    chatUser.getNoDisturb(),
                    chatUser.getDraft()
            );

            try {
                TextMessage body = TextMessage.newBuilder().setContent("").build();
                messageSender.sendToUser(userId, MessageType.SYSTEM_NOTIFY, body,
                        0L, userId, 0L, tenantId,
                        null, null, chatId,
                        cursorVersion, null);
            } catch (Exception e) {
                log.warn("[ImMessageService] 推送清空聊天记录增量同步通知失败, userId: {}, chatId: {}, error: {}",
                        userId, chatId, e.getMessage(), e);
            }

            try {
                imBadgeService.pushBadgeUpdate(userId);
            } catch (Exception e) {
                log.warn("[ImMessageService] 推送清空聊天记录角标更新失败, userId: {}, chatId: {}, error: {}",
                        userId, chatId, e.getMessage(), e);
            }
        } catch (Exception e) {
            log.warn("[ImMessageService] 清空聊天记录写入会话用户态失败, userId: {}, chatId: {}, error: {}",
                    userId, chatId, e.getMessage(), e);
        }
    }

    @Override
    public PageResult<AppImMessageRespVO> searchMessages(Long userId, AppImMessageSearchReqVO searchReqVO) {
        // Route-A：搜索需要全文索引/ES，暂不支持
        throw exception(MESSAGE_SEND_FAILED);
    }

    /**
     * 获取消息预览文本
     */
    private String getMessagePreview(Integer messageType, String content) {
        switch (messageType) {
            case 1: // 文本
                return content.length() > 50 ? content.substring(0, 50) + "..." : content;
            case 2: // 图片
                return "[图片]";
            case 3: // 语音
                return "[语音]";
            case 4: // 视频
                return "[视频]";
            case 5: // 文件
                return "[文件]";
            case 6: // 位置
                return "[位置]";
            case 7: // 表情包
                return "[表情]";
            case 8: // 自定义贴纸
                return "[贴纸]";
            case 10: // 系统消息
                return "[系统消息]";
            default:
                return "[未知消息]";
        }
    }

}
