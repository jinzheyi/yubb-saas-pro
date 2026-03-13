package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.websocket.core.protocol.FileMessage;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.RecallMessage;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.protocol.ImageMessage;
import com.shengyu.framework.websocket.core.protocol.VideoMessage;
import com.shengyu.framework.websocket.core.protocol.VoiceMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePullReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSendReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImConversationUserStateMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.enums.im.ImMessageStatusEnum;
import com.shengyu.module.system.service.im.ImCursorVersionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.List;
import java.util.*;
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
        chatMessageMapper.insert(message);

        String preview = getMessagePreview(dbMessageType, sendReqVO.getContent());
        updateChatUsersAfterSend(chat, message.getId(), message.getSequence(), preview, message.getSendTime(), userId, sendReqVO);
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
        return list.stream().map(message -> {
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
        List<AppImMessageRespVO> respVOList = pageResult.getList().stream().map(message -> {
            AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
            respVO.setChatId(message.getChatId());
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
        AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
        respVO.setChatId(message.getChatId());
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

    private void updateChatUsersAfterSend(ImChatDO chat, Long lastMessageId, Long lastMessageSequence,
                                         String lastMessageContent, LocalDateTime lastMessageTime,
                                         Long senderId, AppImMessageSendReqVO sendReqVO) {
        Integer dbMessageType = normalizeDbMessageType(sendReqVO.getMessageType());
        if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
            List<Long> memberIds = imGroupService.getGroupMemberIds(chat.getGroupId());
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
                if (!isSender) {
                    imBadgeService.pushBadgeUpdate(memberId);
                    // 推送消息内容给接收者
                    pushMessageToUser(memberId, chat.getId(), lastMessageId, senderId, sendReqVO);
                }
            }
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

            Long receiverId = Objects.equals(chat.getSingleUser1(), senderId) ? chat.getSingleUser2() : chat.getSingleUser1();
            ImChatUserDO receiver = ensureChatUser(receiverId, chat.getId());
            chatUserMapper.updateLastMessageAndIncrementUnread(
                    receiver.getId(), lastMessageId, dbMessageType, lastMessageContent, lastMessageTime,
                    1,
                    Boolean.TRUE.equals(receiver.getNoDisturb()));
            imBadgeService.pushBadgeUpdate(receiverId);
            // 推送消息内容给接收者
            pushMessageToUser(receiverId, chat.getId(), lastMessageId, senderId, sendReqVO);
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

    private void pushMessageToUser(Long userId, Long chatId, Long messageId, Long senderId, AppImMessageSendReqVO sendReqVO) {
        try {
            Long tenantId = TenantContextHolder.getTenantId();

            // 根据消息类型构建不同的消息体
            MessageType messageType;
            com.google.protobuf.MessageLite messageBody;
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
            try {
                JSONObject obj = StrUtil.isNotBlank(headerExtra) ? JSONUtil.parseObj(headerExtra) : JSONUtil.createObj();
                obj.set("rev", 1);
                extraWithRev = obj.toString();
            } catch (Exception e) {
                try {
                    JSONObject obj = JSONUtil.createObj();
                    obj.set("rev", 1);
                    extraWithRev = obj.toString();
                } catch (Exception ignore) {
                    extraWithRev = null;
                }
            }

            // 群聊推送给成员时，前端会话路由依赖 groupId；单聊依赖 receiverId/senderId
            messageSender.sendToUserWithExtra(userId, messageType, messageBody,
                    senderId, receiverId, groupId, tenantId, messageId, null, chatId,
                    null, null, extraWithRev);
            log.debug("[ImMessageService] WebSocket 消息推送成功, userId: {}, messageId: {}", userId, messageId);
        } catch (Exception e) {
            log.error("[ImMessageService] WebSocket 消息推送失败, userId: {}, messageId: {}", userId, messageId, e);
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
        throw exception(MESSAGE_SEND_FAILED);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recallMessage(Long userId, Long messageId) {
        ImChatMessageDO message = chatMessageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }
        if (!Objects.equals(message.getSenderId(), userId)) {
            throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
        }
        long windowSec = recallWindowSeconds > 0 ? recallWindowSeconds : 120L;
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
                List<ImChatUserDO> chatUsers = chatUserMapper.selectList(new com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX<ImChatUserDO>()
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
        } catch (Exception e) {
            log.warn("[ImMessageService] 推送撤回事件失败, userId: {}, messageId: {}, error: {}",
                    userId, messageId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteMessage(Long userId, Long messageId) {
        // Route-A：暂不提供物理删除消息能力（通常是撤回/客户端侧隐藏）
        throw exception(MESSAGE_SEND_FAILED);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void clearConversationMessages(Long userId, Long chatId) {
        // Route-A：消息是全局单份存储，清空需要用户侧隐藏/删除标记表，暂不支持
        throw exception(MESSAGE_SEND_FAILED);
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
