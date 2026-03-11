package com.shengyu.module.system.service.im;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.websocket.core.protocol.ConversationBadge;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationSyncItemRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationSyncRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImConversationUserStateDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImConversationUserStateMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.im.ImUserCursorMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 会话 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImConversationServiceImpl implements ImConversationService {

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImConversationUserStateMapper conversationUserStateMapper;

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImGroupMapper groupMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private ImCursorVersionService cursorVersionService;

    @Resource
    private ImUserCursorMapper userCursorMapper;

    @Transactional(rollbackFor = Exception.class)
    public Long allocateNextCursorVersion(Long userId) {
        if (userId == null || userId <= 0) {
            return 0L;
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        userCursorMapper.insertIgnore(tenantId, userId);
        com.shengyu.module.system.dal.dataobject.im.ImUserCursorDO cursor = userCursorMapper.selectForUpdate(tenantId, userId);
        long next = 1L;
        if (cursor != null && cursor.getNextCursorVersion() != null) {
            next = cursor.getNextCursorVersion() + 1L;
        }
        userCursorMapper.updateNext(tenantId, userId, next);
        return next;
    }

    @Override
    public List<AppImConversationRespVO> getConversationList(Long userId) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        return chatUsers.stream().map(chatUser -> toConversationRespVO(userId, chatUser)).collect(Collectors.toList());
    }

    @Override
    public AppImConversationSyncRespVO syncConversations(Long userId, Long cursorVersion, Integer limit) {
        long cursor = cursorVersion != null && cursorVersion > 0 ? cursorVersion : 0L;
        int pageSize = limit != null && limit > 0 ? Math.min(limit, 200) : 100;
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        List<ImConversationUserStateDO> states = conversationUserStateMapper.selectSyncList(tenantId, userId, cursor, pageSize);
        List<AppImConversationSyncItemRespVO> items = new ArrayList<>();
        long next = cursor;

        if (states != null) {
            for (ImConversationUserStateDO state : states) {
                if (state == null) {
                    continue;
                }
                AppImConversationSyncItemRespVO item = new AppImConversationSyncItemRespVO();
                item.setChatId(state.getChatId());
                item.setCursorVersion(state.getCursorVersion() != null ? state.getCursorVersion() : 0L);
                item.setConversationVersion(state.getConversationVersion() != null ? state.getConversationVersion() : 0L);
                item.setUnreadCount(state.getUnreadCount() != null ? Math.max(state.getUnreadCount(), 0) : 0);
                item.setLastMessageSequence(state.getLastMessageSequence() != null ? state.getLastMessageSequence() : 0L);
                item.setLastReadSequence(state.getLastReadSequence() != null ? state.getLastReadSequence() : 0L);
                item.setLastMessageType(state.getLastMessageType());
                item.setLastMessageContent(buildPreviewByType(state.getLastMessageType(), state.getLastMessageContent()));
                item.setLastMessageTime(state.getLastMessageTime());
                item.setIsPinned(state.getIsPinned());
                item.setNoDisturb(state.getNoDisturb());
                item.setDraft(state.getDraft());
                item.setDeletedByUser(state.getDeletedByUser());

                ImChatDO chat = chatMapper.selectById(state.getChatId());
                if (chat != null) {
                    item.setConversationType(chat.getChatType());
                    if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
                        item.setTargetId(chat.getGroupId());
                        ImGroupDO group = groupMapper.selectById(chat.getGroupId());
                        if (group != null) {
                            item.setTargetName(group.getName());
                            item.setTargetAvatar(group.getAvatar());
                            item.setGroupMemberCount(group.getMemberCount());
                            if (item.getLastMessageTime() == null
                                    && state.getLastMessageId() == null
                                    && (state.getLastMessageSequence() == null || state.getLastMessageSequence() <= 0L)) {
                                item.setLastMessageTime(group.getCreateTime());
                            }
                        }
                    } else {
                        Long otherUserId = Objects.equals(chat.getSingleUser1(), userId) ? chat.getSingleUser2() : chat.getSingleUser1();
                        item.setTargetId(otherUserId);
                        AdminUserDO targetUser = userMapper.selectById(otherUserId);
                        if (targetUser != null) {
                            item.setTargetName(targetUser.getNickname());
                            item.setTargetAvatar(targetUser.getAvatar());
                        }
                    }
                }

                items.add(item);
                if (item.getCursorVersion() != null && item.getCursorVersion() > next) {
                    next = item.getCursorVersion();
                }
            }
        }

        AppImConversationSyncRespVO respVO = new AppImConversationSyncRespVO();
        respVO.setNextCursorVersion(next);
        respVO.setHasMore(states != null && states.size() >= pageSize);
        respVO.setItems(items);
        return respVO;
    }

    @Override
    public List<AppImConversationRespVO> getConversationListByType(Long userId, Integer conversationType) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        if (conversationType == null) {
            return chatUsers.stream().map(chatUser -> toConversationRespVO(userId, chatUser)).collect(Collectors.toList());
        }
        return chatUsers.stream()
                .map(chatUser -> toConversationRespVO(userId, chatUser))
                .filter(vo -> conversationType.equals(vo.getConversationType()))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImConversationRespVO createOrGetConversation(Long userId, AppImConversationCreateReqVO createReqVO) {
        log.info("[ImConversationService] 创建或获取会话, userId: {}, targetId: {}, type: {}", 
                userId, createReqVO.getTargetId(), createReqVO.getConversationType());

        // 参数校验（避免脏数据写入）
        if (createReqVO.getTargetId() == null || createReqVO.getConversationType() == null) {
            log.warn("[ImConversationService] 创建会话参数非法, userId: {}, targetId: {}, type: {}",
                    userId, createReqVO.getTargetId(), createReqVO.getConversationType());
            throw exception(CONVERSATION_CREATE_FAILED);
        }
        if (!ImConversationTypeEnum.SINGLE.getType().equals(createReqVO.getConversationType())
                && !ImConversationTypeEnum.GROUP.getType().equals(createReqVO.getConversationType())) {
            log.warn("[ImConversationService] 创建会话类型非法, userId: {}, targetId: {}, type: {}",
                    userId, createReqVO.getTargetId(), createReqVO.getConversationType());
            throw exception(CONVERSATION_CREATE_FAILED);
        }
        if (ImConversationTypeEnum.GROUP.getType().equals(createReqVO.getConversationType())) {
            ImGroupDO group = groupMapper.selectById(createReqVO.getTargetId());
            if (group == null) {
                log.warn("[ImConversationService] 创建群聊会话失败，群组不存在, userId: {}, groupId: {}",
                        userId, createReqVO.getTargetId());
                throw exception(GROUP_NOT_EXISTS);
            }
        } else {
            // 单聊：targetId 必须是对方用户 ID
            if (createReqVO.getTargetId().equals(userId)) {
                log.warn("[ImConversationService] 创建单聊会话失败，不能与自己创建会话, userId: {}", userId);
                throw exception(CONVERSATION_CREATE_FAILED);
            }
            AdminUserDO targetUser = userMapper.selectById(createReqVO.getTargetId());
            if (targetUser == null) {
                log.warn("[ImConversationService] 创建单聊会话失败，用户不存在, userId: {}, targetUserId: {}",
                        userId, createReqVO.getTargetId());
                throw exception(USER_NOT_EXISTS);
            }
        }
        ImChatDO chat = getOrCreateChat(createReqVO.getConversationType(), userId, createReqVO.getTargetId());
        ImChatUserDO chatUser = ensureChatUser(userId, chat.getId());

        // 初始化会话-用户态（无消息也要可 sync 出现，对标企微/钉钉）
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);

            Integer unreadCount = chatUser.getUnreadCount() != null ? Math.max(chatUser.getUnreadCount(), 0) : 0;
            Long lastReadSeq = chatUser.getLastReadSequence() != null ? chatUser.getLastReadSequence() : 0L;
            Long lastMsgId = chatUser.getLastMessageId();
            Long lastMsgSeq = chatUser.getLastMessageSequence() != null ? chatUser.getLastMessageSequence() : 0L;
            Integer lastMsgType = chatUser.getLastMessageType();
            String lastMsgContent = chatUser.getLastMessageContent();
            java.time.LocalDateTime lastMsgTime = chatUser.getLastMessageTime();

            // 群聊无消息：使用群创建时间作为会话时间
            if (ImConversationTypeEnum.isGroup(chat.getChatType())
                    && lastMsgTime == null
                    && lastMsgId == null
                    && (lastMsgSeq == null || lastMsgSeq <= 0L)) {
                ImGroupDO group = groupMapper.selectById(chat.getGroupId());
                if (group != null) {
                    lastMsgTime = group.getCreateTime();
                }
            }

            conversationUserStateMapper.upsertInitConversation(
                    tenantId,
                    chat.getId(),
                    userId,
                    cursorVersion,
                    unreadCount,
                    lastReadSeq,
                    null,
                    lastMsgId,
                    lastMsgSeq,
                    lastMsgType,
                    lastMsgContent,
                    lastMsgTime,
                    chatUser.getIsPinned(),
                    chatUser.getNoDisturb(),
                    chatUser.getDraft()
            );
        } catch (Exception e) {
            log.warn("[ImConversationService] 初始化会话-用户态失败, userId: {}, chatId: {}, error: {}",
                    userId, chat.getId(), e.getMessage(), e);
        }
        return toConversationRespVO(userId, chatUser);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateConversation(Long userId, AppImConversationUpdateReqVO updateReqVO) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, updateReqVO.getChatId());
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        chatUserMapper.updateSettings(userId, updateReqVO.getChatId(), updateReqVO.getIsPinned(), updateReqVO.getNoDisturb());

        // 同步写入会话-用户态 + 分配 cursorVersion（跨端设置一致）
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            Boolean newPinned = updateReqVO.getIsPinned() != null ? updateReqVO.getIsPinned() : chatUser.getIsPinned();
            Boolean newNoDisturb = updateReqVO.getNoDisturb() != null ? updateReqVO.getNoDisturb() : chatUser.getNoDisturb();
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterSettings(
                    tenantId,
                    updateReqVO.getChatId(),
                    userId,
                    cursorVersion,
                    newPinned,
                    newNoDisturb,
                    chatUser.getDraft()
            );
        } catch (Exception e) {
            log.warn("[ImConversationService] 写入会话-用户态设置变更失败, userId: {}, chatId: {}, error: {}",
                    userId, updateReqVO.getChatId(), e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteConversation(Long userId, Long conversationId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, conversationId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        chatUserMapper.softDelete(userId, conversationId);

        // 同步写入会话-用户态 + 分配 cursorVersion（跨端删除一致）
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterDelete(
                    tenantId,
                    conversationId,
                    userId,
                    cursorVersion,
                    true
            );
        } catch (Exception e) {
            log.warn("[ImConversationService] 写入会话-用户态删除失败, userId: {}, chatId: {}, error: {}",
                    userId, conversationId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markConversationReadBySequence(Long userId, Long chatId, Long readSequence) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        Long seq = readSequence != null ? readSequence : 0L;
        if (seq < 0) {
            seq = 0L;
        }
        chatUserMapper.markReadToSequence(userId, chatId, seq);

        // 同步写入会话-用户态 + 分配 cursorVersion（跨端已读一致）
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterRead(
                    tenantId,
                    chatId,
                    userId,
                    cursorVersion,
                    seq,
                    java.time.LocalDateTime.now(),
                    chatUser.getLastMessageId(),
                    chatUser.getLastMessageSequence() != null ? chatUser.getLastMessageSequence() : 0L,
                    chatUser.getLastMessageType(),
                    chatUser.getLastMessageContent(),
                    chatUser.getLastMessageTime(),
                    chatUser.getIsPinned(),
                    chatUser.getNoDisturb(),
                    chatUser.getDraft()
            );
        } catch (Exception e) {
            log.warn("[ImConversationService] 写入会话-用户态已读水位失败, userId: {}, chatId: {}, error: {}",
                    userId, chatId, e.getMessage(), e);
        }
    }

    @Override
    public Integer getUnreadCount(Long userId) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        return chatUsers.stream().mapToInt(cu -> {
            Long lastMsgSeq = cu.getLastMessageSequence() != null ? cu.getLastMessageSequence() : 0L;
            Long lastReadSeq = cu.getLastReadSequence() != null ? cu.getLastReadSequence() : 0L;
            try {
                return (int) Math.max(lastMsgSeq - lastReadSeq, 0L);
            } catch (Exception ignore) {
                return cu.getUnreadCount() != null ? Math.max(cu.getUnreadCount(), 0) : 0;
            }
        }).sum();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateLastMessage(Long conversationId, Long messageId, String messageContent) {
        // 由 SystemMessageStorageServiceImpl 写入 im_chat_user.last_message_*，这里不再处理
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void incrementUnreadCount(Long conversationId) {
        incrementUnreadCount(conversationId, 1);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void incrementUnreadCount(Long conversationId, Integer delta) {
        // 未读数由 SystemMessageStorageServiceImpl 写入 im_chat_user.unread_count，HTTP 不再直接递增
    }

    @Override
    public Object getConversation(Long conversationId) {
        return null;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteConversationByTarget(Long userId, Long targetId, Integer conversationType) {
        ImChatDO chat = getOrCreateChat(conversationType, userId, targetId);
        chatUserMapper.softDelete(userId, chat.getId());

        // 同步写入会话-用户态 + 分配 cursorVersion（跨端删除一致）
        try {
            Long tenantId = TenantContextHolder.getTenantId();
            if (tenantId == null) {
                tenantId = 0L;
            }
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterDelete(
                    tenantId,
                    chat.getId(),
                    userId,
                    cursorVersion,
                    true
            );
        } catch (Exception e) {
            log.warn("[ImConversationService] 写入会话-用户态按 target 删除失败, userId: {}, chatId: {}, error: {}",
                    userId, chat.getId(), e.getMessage(), e);
        }
    }

    @Override
    public Integer getTotalUnreadCount(Long userId) {
        return getUnreadCount(userId);
    }

    @Override
    public List<ConversationBadge> getConversationBadges(Long userId) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        return chatUsers.stream()
                .map(cu -> {
                    Long lastMsgSeq = cu.getLastMessageSequence() != null ? cu.getLastMessageSequence() : 0L;
                    Long lastReadSeq = cu.getLastReadSequence() != null ? cu.getLastReadSequence() : 0L;
                    int unread = 0;
                    try {
                        unread = (int) Math.max(lastMsgSeq - lastReadSeq, 0L);
                    } catch (Exception ignore) {
                        unread = cu.getUnreadCount() != null ? Math.max(cu.getUnreadCount(), 0) : 0;
                    }
                    return new Object[]{cu.getChatId(), unread};
                })
                .filter(arr -> (int) arr[1] > 0)
                .map(cu -> ConversationBadge.newBuilder()
                        .setConversationId((Long) cu[0])
                        .setUnreadCount((Integer) cu[1])
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public AppImConversationRespVO getConversationDetail(Long userId, Long conversationId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, conversationId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        return toConversationRespVO(userId, chatUser);
    }

     private AppImConversationRespVO toConversationRespVO(Long userId, ImChatUserDO chatUser) {
         ImChatDO chat = chatMapper.selectById(chatUser.getChatId());
         if (chat == null) {
             throw exception(CONVERSATION_NOT_EXISTS);
         }
         AppImConversationRespVO respVO = new AppImConversationRespVO();
        respVO.setChatId(chatUser.getChatId());
        respVO.setConversationType(chat.getChatType());

		// cursorVersion/conversationVersion：用于 WS gap 检测 + 端侧幂等/乱序保护
		try {
			Long tenantId = TenantContextHolder.getTenantId();
			if (tenantId == null) {
				tenantId = 0L;
			}
			ImConversationUserStateDO state = conversationUserStateMapper.selectOne(new com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX<ImConversationUserStateDO>()
					.eq(ImConversationUserStateDO::getTenantId, tenantId)
					.eq(ImConversationUserStateDO::getUserId, userId)
					.eq(ImConversationUserStateDO::getChatId, chatUser.getChatId())
					.eq(ImConversationUserStateDO::getDeleted, false));
			if (state != null) {
				respVO.setCursorVersion(state.getCursorVersion());
				respVO.setConversationVersion(state.getConversationVersion());
			}
		} catch (Exception ignore) {
			// ignore
		}
        Long lastMsgSeq = chatUser.getLastMessageSequence() != null ? chatUser.getLastMessageSequence() : 0L;
        Long lastReadSeq = chatUser.getLastReadSequence() != null ? chatUser.getLastReadSequence() : 0L;
        respVO.setLastMessageSequence(lastMsgSeq);
        respVO.setLastReadSequence(lastReadSeq);
        int unread = 0;
        try {
            unread = (int) Math.max(lastMsgSeq - lastReadSeq, 0L);
        } catch (Exception ignore) {
            unread = chatUser.getUnreadCount() != null ? chatUser.getUnreadCount() : 0;
        }
        respVO.setUnreadCount(unread);

        Integer lastType = chatUser.getLastMessageType();
        if (lastType == null && chatUser.getLastMessageId() != null) {
            ImChatMessageDO lastMsg = chatMessageMapper.selectById(chatUser.getLastMessageId());
            if (lastMsg != null) {
                lastType = lastMsg.getMessageType();
            }
        }
        respVO.setLastMessageType(lastType);
        respVO.setLastMessageContent(buildPreviewByType(lastType, chatUser.getLastMessageContent()));
        // 无消息时：群聊会话时间取群创建时间（体验对标企微/钉钉）；有消息时取最后一条消息时间
        respVO.setLastMessageTime(chatUser.getLastMessageTime());
        respVO.setIsPinned(chatUser.getIsPinned());
        respVO.setNoDisturb(chatUser.getNoDisturb());

         if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
             respVO.setTargetId(chat.getGroupId());
             ImGroupDO group = groupMapper.selectById(chat.getGroupId());
             if (group != null) {
                 respVO.setTargetName(group.getName());
                 respVO.setTargetAvatar(group.getAvatar());
                 respVO.setGroupMemberCount(group.getMemberCount());

				// 群聊无消息：使用群创建时间作为会话时间
				if (respVO.getLastMessageTime() == null
						&& chatUser.getLastMessageId() == null
						&& (chatUser.getLastMessageSequence() == null || chatUser.getLastMessageSequence() <= 0L)) {
					respVO.setLastMessageTime(group.getCreateTime());
				}
             }
         } else {
             Long otherUserId = Objects.equals(chat.getSingleUser1(), userId) ? chat.getSingleUser2() : chat.getSingleUser1();
             respVO.setTargetId(otherUserId);
             AdminUserDO targetUser = userMapper.selectById(otherUserId);
             if (targetUser != null) {
                 respVO.setTargetName(targetUser.getNickname());
                 respVO.setTargetAvatar(targetUser.getAvatar());
             }
         }
         return respVO;
    }

    private String buildPreviewByType(Integer messageType, String raw) {
        if (messageType == null) {
            return raw != null ? raw : "";
        }
        switch (messageType) {
            case 1:
                if (raw == null) {
                    return "";
                }
                String trimmed = raw.trim();
                if (trimmed.length() > 100) {
                    return trimmed.substring(0, 100) + "...";
                }
                return trimmed;
            case 2:
                return "[图片]";
            case 3:
                return "[语音]";
            case 4:
                return "[视频]";
            case 5:
                return "[文件]";
            case 6:
                return "[位置]";
            case 7:
                return "[表情]";
            case 8:
                return "[贴纸]";
            case 10:
                return "[系统消息]";
            default:
                return "[消息]";
        }
    }

     private ImChatDO getOrCreateChat(Integer conversationType, Long userId, Long targetId) {
         if (ImConversationTypeEnum.isGroup(conversationType)) {
             ImChatDO chat = chatMapper.selectGroupChat(targetId, conversationType);
             if (chat != null) {
                 return chat;
             }
             chat = new ImChatDO();
             chat.setChatType(conversationType);
             chat.setGroupId(targetId);
             chat.setStatus(1);
             chatMapper.insert(chat);
             return chat;
         }

         Long user1 = Math.min(userId, targetId);
         Long user2 = Math.max(userId, targetId);
         ImChatDO chat = chatMapper.selectSingleChat(user1, user2, conversationType);
         if (chat != null) {
             return chat;
         }
         chat = new ImChatDO();
         chat.setChatType(conversationType);
         chat.setSingleUser1(user1);
         chat.setSingleUser2(user2);
         chat.setStatus(1);
         chatMapper.insert(chat);
         return chat;
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

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImConversationRespVO getOrCreateSingleConversation(Long userId, Long targetUserId) {
        AppImConversationCreateReqVO reqVO = new AppImConversationCreateReqVO();
        reqVO.setTargetId(targetUserId);
        reqVO.setConversationType(ImConversationTypeEnum.SINGLE.getType());
        return createOrGetConversation(userId, reqVO);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImConversationRespVO getOrCreateGroupConversation(Long userId, Long groupId) {
        AppImConversationCreateReqVO reqVO = new AppImConversationCreateReqVO();
        reqVO.setTargetId(groupId);
        reqVO.setConversationType(ImConversationTypeEnum.GROUP.getType());
        return createOrGetConversation(userId, reqVO);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void pinConversation(Long userId, Long conversationId, Boolean isPinned) {
        chatUserMapper.updateSettings(userId, conversationId, isPinned, null);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setMute(Long userId, Long conversationId, Boolean noDisturb) {
        chatUserMapper.updateSettings(userId, conversationId, null, noDisturb);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveDraft(Long userId, Long conversationId, String draft) {
        chatUserMapper.update(null, new LambdaUpdateWrapper<ImChatUserDO>()
                .eq(ImChatUserDO::getUserId, userId)
                .eq(ImChatUserDO::getChatId, conversationId)
                .set(ImChatUserDO::getDraft, draft));
    }

    @Override
    public String getDraft(Long userId, Long conversationId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, conversationId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        return chatUser.getDraft();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void addTag(Long userId, Long conversationId, String tag) {
        // Route-A：标签能力未落表，暂不支持
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeTag(Long userId, Long conversationId, String tag) {
        // Route-A：标签能力未落表，暂不支持
    }

    @Override
    public List<String> getTags(Long userId, Long conversationId) {
        return new java.util.ArrayList<>();
    }

    @Override
    public List<AppImConversationRespVO> getConversationsByTag(Long userId, String tag) {
        return new java.util.ArrayList<>();
    }

}
