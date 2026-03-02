package com.shengyu.module.system.service.im;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.websocket.core.protocol.ConversationBadge;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
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
    private ImGroupMapper groupMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Override
    public List<AppImConversationRespVO> getConversationList(Long userId) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        return chatUsers.stream().map(chatUser -> toConversationRespVO(userId, chatUser)).collect(Collectors.toList());
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
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteConversation(Long userId, Long conversationId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, conversationId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        chatUserMapper.softDelete(userId, conversationId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markConversationRead(Long userId, Long conversationId) {
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, conversationId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        chatUserMapper.markRead(userId, conversationId);
    }

    @Override
    public Integer getUnreadCount(Long userId) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        return chatUsers.stream().map(ImChatUserDO::getUnreadCount).filter(v -> v != null && v > 0).mapToInt(Integer::intValue).sum();
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
    @Transactional(rollbackFor = Exception.class)
    public void clearUnreadCount(Long conversationId) {
        // 由 markConversationRead 处理
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
    }

    @Override
    public Integer getTotalUnreadCount(Long userId) {
        return getUnreadCount(userId);
    }

    @Override
    public List<ConversationBadge> getConversationBadges(Long userId) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        return chatUsers.stream()
                .filter(cu -> cu.getUnreadCount() != null && cu.getUnreadCount() > 0)
                .map(cu -> ConversationBadge.newBuilder()
                        .setConversationId(cu.getChatId())
                        .setUnreadCount(cu.getUnreadCount())
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
         respVO.setUnreadCount(chatUser.getUnreadCount());
         respVO.setLastMessageContent(chatUser.getLastMessageContent());
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
