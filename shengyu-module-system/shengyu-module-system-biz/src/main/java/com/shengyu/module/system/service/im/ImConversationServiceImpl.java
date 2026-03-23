package com.shengyu.module.system.service.im;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import cn.hutool.core.util.IdUtil;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.websocket.core.protocol.ConversationBadge;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationSearchReqVO;
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
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.baomidou.dynamic.datasource.annotation.Master;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
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
    private ImBadgeService imBadgeService;

    @Resource
    private NettyMessageSender messageSender;

    @Override
    public List<AppImConversationRespVO> getConversationList(Long userId) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        return toConversationRespVOList(userId, chatUsers);
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

        Map<Long, ImChatDO> chatMap = new HashMap<>();
        Map<Long, ImGroupDO> groupMap = new HashMap<>();
        Map<Long, AdminUserDO> userMap = new HashMap<>();

        if (states != null && !states.isEmpty()) {
            List<Long> chatIds = states.stream()
                    .filter(s -> s != null && s.getChatId() != null)
                    .map(ImConversationUserStateDO::getChatId)
                    .distinct()
                    .collect(Collectors.toList());
            if (!chatIds.isEmpty()) {
                List<ImChatDO> chats = chatMapper.selectBatchIds(chatIds);
                if (chats != null) {
                    for (ImChatDO c : chats) {
                        if (c != null && c.getId() != null) {
                            chatMap.put(c.getId(), c);
                        }
                    }
                }

                Set<Long> groupIds = new HashSet<>();
                Set<Long> otherUserIds = new HashSet<>();
                for (ImChatDO c : chatMap.values()) {
                    if (c == null) {
                        continue;
                    }
                    if (ImConversationTypeEnum.isGroup(c.getChatType())) {
                        if (c.getGroupId() != null) {
                            groupIds.add(c.getGroupId());
                        }
                    } else {
                        Long otherUserId = Objects.equals(c.getSingleUser1(), userId) ? c.getSingleUser2() : c.getSingleUser1();
                        if (otherUserId != null) {
                            otherUserIds.add(otherUserId);
                        }
                    }
                }

                if (!groupIds.isEmpty()) {
                    List<ImGroupDO> groups = groupMapper.selectBatchIds(new ArrayList<>(groupIds));
                    if (groups != null) {
                        for (ImGroupDO g : groups) {
                            if (g != null && g.getId() != null) {
                                groupMap.put(g.getId(), g);
                            }
                        }
                    }
                }
                if (!otherUserIds.isEmpty()) {
                    List<AdminUserDO> users = userMapper.selectBatchIds(new ArrayList<>(otherUserIds));
                    if (users != null) {
                        for (AdminUserDO u : users) {
                            if (u != null && u.getId() != null) {
                                userMap.put(u.getId(), u);
                            }
                        }
                    }
                }
            }
        }

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
                item.setLastMessageHasAtMe(Boolean.TRUE.equals(state.getLastMessageHasAtMe()));
                item.setLastMessageTime(state.getLastMessageTime());
                item.setIsPinned(state.getIsPinned());
                item.setNoDisturb(state.getNoDisturb());
                item.setDraft(state.getDraft());
                item.setDeletedByUser(state.getDeletedByUser());

                ImChatDO chat = state.getChatId() != null ? chatMap.get(state.getChatId()) : null;
                if (chat != null) {
                    item.setConversationType(chat.getChatType());
                    if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
                        item.setTargetId(chat.getGroupId());
                        ImGroupDO group = chat.getGroupId() != null ? groupMap.get(chat.getGroupId()) : null;
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
                        AdminUserDO targetUser = otherUserId != null ? userMap.get(otherUserId) : null;
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
            return toConversationRespVOList(userId, chatUsers);
        }
        return toConversationRespVOList(userId, chatUsers).stream()
                .filter(vo -> conversationType.equals(vo.getConversationType()))
                .collect(Collectors.toList());
    }

    @Override
    public PageResult<AppImConversationRespVO> searchConversations(Long userId, AppImConversationSearchReqVO searchReqVO) {
        if (searchReqVO == null) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }

        String keyword = searchReqVO.getKeyword() != null ? searchReqVO.getKeyword().trim() : "";
        if (keyword.isEmpty()) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }

        Integer conversationType = searchReqVO.getConversationType();
        Integer pageNo = searchReqVO.getPageNo() != null ? searchReqVO.getPageNo() : 1;
        Integer pageSize = searchReqVO.getPageSize() != null ? searchReqVO.getPageSize() : 20;

        if (pageNo < 1) {
            pageNo = 1;
        }
        if (pageSize < 1) {
            pageSize = 1;
        }
        if (pageSize > 200) {
            pageSize = 200;
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        Long total = chatUserMapper.countChatIdsByUserForSearch(tenantId, userId, conversationType, keyword);
        if (total == null || total <= 0L) {
            return new PageResult<>(Collections.emptyList(), 0L);
        }

        long offset = (long) (pageNo - 1) * (long) pageSize;
        List<Long> chatIds = chatUserMapper.selectChatIdsByUserForSearch(tenantId, userId, conversationType, keyword, offset, (long) pageSize);
        if (chatIds == null || chatIds.isEmpty()) {
            return new PageResult<>(Collections.emptyList(), total);
        }

        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserIdAndChatIds(userId, chatIds);
        if (chatUsers == null || chatUsers.isEmpty()) {
            return new PageResult<>(Collections.emptyList(), total);
        }

        Map<Long, ImChatUserDO> map = new HashMap<>();
        for (ImChatUserDO cu : chatUsers) {
            if (cu != null && cu.getChatId() != null) {
                map.put(cu.getChatId(), cu);
            }
        }

        List<ImChatUserDO> orderedChatUsers = new ArrayList<>();
        for (Long chatId : chatIds) {
            ImChatUserDO cu = map.get(chatId);
            if (cu == null) {
                continue;
            }
            orderedChatUsers.add(cu);
        }
        List<AppImConversationRespVO> list = toConversationRespVOList(userId, orderedChatUsers);

        return new PageResult<>(list, total);
    }

    @Override
    @Master
    @Transactional(rollbackFor = Exception.class)
    public AppImConversationRespVO createOrGetConversation(Long userId, AppImConversationCreateReqVO createReqVO) {
        try {
            return doCreateOrGetConversation(userId, createReqVO);
        } catch (ServiceException ex) {
            if (Objects.equals(ex.getCode(), CONVERSATION_CREATE_FAILED.getCode())) {
                return doCreateOrGetConversation(userId, createReqVO);
            }
            throw ex;
        }
    }

    private AppImConversationRespVO doCreateOrGetConversation(Long userId, AppImConversationCreateReqVO createReqVO) {
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
        if (chat == null || chat.getId() == null) {
            log.warn("[ImConversationService] 创建或获取会话失败，chat为空, userId: {}, targetId: {}, type: {}",
                    userId, createReqVO.getTargetId(), createReqVO.getConversationType());
            throw exception(CONVERSATION_CREATE_FAILED);
        }
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
                    false,
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

        Long oldReadSeq = chatUser.getLastReadSequence() != null ? chatUser.getLastReadSequence() : 0L;
        boolean advanced = seq > oldReadSeq;
        chatUserMapper.markReadToSequence(userId, chatId, seq);

        // 幂等：未推进水位时不产生 cursorVersion 与跨端事件（避免乱序/重复上报导致无意义扩散）
        if (!advanced) {
            return;
        }

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

            // 多端已读一致：推送 cursorVersion 触发端侧增量 sync（对标企微/钉钉跨端清未读）
            try {
                TextMessage body = TextMessage.newBuilder().setContent("").build();
                messageSender.sendToUser(userId, MessageType.SYSTEM_NOTIFY, body,
                        0L, userId, 0L, tenantId,
                        null, null, chatId,
                        cursorVersion, null);
            } catch (Exception e) {
                log.warn("[ImConversationService] 推送已读水位变更事件失败, userId: {}, chatId: {}, error: {}",
                        userId, chatId, e.getMessage(), e);
            }

            // 角标即时刷新：跨端推进已读水位后，推送 BADGE_UPDATE 让其它端立刻清红点（最终态仍以 sync 为准）
            try {
                imBadgeService.pushBadgeUpdate(userId);
            } catch (Exception e) {
                log.warn("[ImConversationService] 推送角标更新失败, userId: {}, chatId: {}, error: {}",
                        userId, chatId, e.getMessage(), e);
            }
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
        ImChatDO chat = findChat(conversationType, userId, targetId);
        if (chat == null || chat.getId() == null) {
            return;
        }

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
        List<AppImConversationRespVO> list = toConversationRespVOList(userId, Arrays.asList(chatUser));
        if (list != null && !list.isEmpty()) {
            return list.get(0);
        }
        return toConversationRespVO(userId, chatUser);
    }

    private List<AppImConversationRespVO> toConversationRespVOList(Long userId, List<ImChatUserDO> chatUsers) {
        if (chatUsers == null || chatUsers.isEmpty()) {
            return Collections.emptyList();
        }

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }

        List<Long> chatIds = chatUsers.stream()
                .filter(cu -> cu != null && cu.getChatId() != null)
                .map(ImChatUserDO::getChatId)
                .distinct()
                .collect(Collectors.toList());
        if (chatIds.isEmpty()) {
            return Collections.emptyList();
        }

        Map<Long, ImChatDO> chatMap = new HashMap<>();
        List<ImChatDO> chats = chatMapper.selectBatchIds(chatIds);
        if (chats != null) {
            for (ImChatDO c : chats) {
                if (c != null && c.getId() != null) {
                    chatMap.put(c.getId(), c);
                }
            }
        }

        Map<Long, ImConversationUserStateDO> stateMap = new HashMap<>();
        try {
            List<ImConversationUserStateDO> states = conversationUserStateMapper.selectListByUserIdAndChatIds(tenantId, userId, chatIds);
            if (states != null) {
                for (ImConversationUserStateDO s : states) {
                    if (s != null && s.getChatId() != null) {
                        stateMap.put(s.getChatId(), s);
                    }
                }
            }
        } catch (Exception ignore) {
            // ignore
        }

        Set<Long> groupIds = new HashSet<>();
        Set<Long> otherUserIds = new HashSet<>();
        for (ImChatDO c : chatMap.values()) {
            if (c == null) {
                continue;
            }
            if (ImConversationTypeEnum.isGroup(c.getChatType())) {
                if (c.getGroupId() != null) {
                    groupIds.add(c.getGroupId());
                }
            } else {
                Long otherUserId = Objects.equals(c.getSingleUser1(), userId) ? c.getSingleUser2() : c.getSingleUser1();
                if (otherUserId != null) {
                    otherUserIds.add(otherUserId);
                }
            }
        }

        Map<Long, ImGroupDO> groupMap = new HashMap<>();
        if (!groupIds.isEmpty()) {
            List<ImGroupDO> groups = groupMapper.selectBatchIds(new ArrayList<>(groupIds));
            if (groups != null) {
                for (ImGroupDO g : groups) {
                    if (g != null && g.getId() != null) {
                        groupMap.put(g.getId(), g);
                    }
                }
            }
        }

        Map<Long, AdminUserDO> userMap = new HashMap<>();
        if (!otherUserIds.isEmpty()) {
            List<AdminUserDO> users = userMapper.selectBatchIds(new ArrayList<>(otherUserIds));
            if (users != null) {
                for (AdminUserDO u : users) {
                    if (u != null && u.getId() != null) {
                        userMap.put(u.getId(), u);
                    }
                }
            }
        }

        Map<Long, Integer> lastMessageTypeMap = new HashMap<>();
        List<Long> needLastMsgIds = chatUsers.stream()
                .filter(cu -> cu != null && cu.getLastMessageId() != null && cu.getLastMessageType() == null)
                .map(ImChatUserDO::getLastMessageId)
                .distinct()
                .collect(Collectors.toList());
        if (!needLastMsgIds.isEmpty()) {
            List<ImChatMessageDO> msgs = chatMessageMapper.selectBatchIds(needLastMsgIds);
            if (msgs != null) {
                for (ImChatMessageDO m : msgs) {
                    if (m != null && m.getId() != null) {
                        lastMessageTypeMap.put(m.getId(), m.getMessageType());
                    }
                }
            }
        }

        List<AppImConversationRespVO> list = new ArrayList<>();
        for (ImChatUserDO chatUser : chatUsers) {
            if (chatUser == null || chatUser.getChatId() == null) {
                continue;
            }
            ImChatDO chat = chatMap.get(chatUser.getChatId());
            if (chat == null) {
                throw exception(CONVERSATION_NOT_EXISTS);
            }

            AppImConversationRespVO respVO = new AppImConversationRespVO();
            respVO.setChatId(chatUser.getChatId());
            respVO.setConversationType(chat.getChatType());

            // cursorVersion/conversationVersion：用于 WS gap 检测 + 端侧幂等/乱序保护
            ImConversationUserStateDO state = stateMap.get(chatUser.getChatId());
            if (state != null) {
                respVO.setCursorVersion(state.getCursorVersion());
                respVO.setConversationVersion(state.getConversationVersion());
                respVO.setLastMessageHasAtMe(Boolean.TRUE.equals(state.getLastMessageHasAtMe()));
            } else {
                respVO.setLastMessageHasAtMe(false);
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
                Integer t = lastMessageTypeMap.get(chatUser.getLastMessageId());
                if (t != null) {
                    lastType = t;
                }
            }
            respVO.setLastMessageType(lastType);
            respVO.setLastMessageContent(buildPreviewByType(lastType, chatUser.getLastMessageContent()));
            // 无消息时：群聊会话时间取群创建时间；有消息时取最后一条消息时间
            respVO.setLastMessageTime(chatUser.getLastMessageTime());
            respVO.setIsPinned(chatUser.getIsPinned());
            respVO.setNoDisturb(chatUser.getNoDisturb());

            if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
                respVO.setTargetId(chat.getGroupId());
                ImGroupDO group = chat.getGroupId() != null ? groupMap.get(chat.getGroupId()) : null;
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
                AdminUserDO targetUser = otherUserId != null ? userMap.get(otherUserId) : null;
                if (targetUser != null) {
                    respVO.setTargetName(targetUser.getNickname());
                    respVO.setTargetAvatar(targetUser.getAvatar());
                }
            }
            list.add(respVO);
        }
        return list;
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
        // raw 里可能已经包含群聊发送者前缀（例如："张三: [图片]"）。
        // 为保证推送与刷新一致：raw 非空则优先使用 raw（并做截断），避免被类型默认文案覆盖。
        if (raw != null) {
            String trimmed = raw.trim();
            if (!trimmed.isEmpty()) {
                if (trimmed.length() > 100) {
                    return trimmed.substring(0, 100) + "...";
                }
                return trimmed;
            }
        }
        if (messageType == null) {
            return "";
        }
        switch (messageType) {
            case 1:
                return "";
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
         Long tenantId = TenantContextHolder.getTenantId();
         if (tenantId == null) {
             tenantId = 0L;
         }
         if (ImConversationTypeEnum.isGroup(conversationType)) {
             ImChatDO chat = chatMapper.selectGroupChat(targetId, conversationType);
             if (chat != null && chat.getId() != null) {
                 return chat;
             }
            chatMapper.insertGroupChatIfAbsent(tenantId, IdUtil.getSnowflakeNextId(), conversationType, targetId, 1);
             chat = chatMapper.selectGroupChat(targetId, conversationType);
             if (chat != null && chat.getId() != null) {
                 return chat;
             }
             ImChatDO newChat = new ImChatDO();
            newChat.setId(IdUtil.getSnowflakeNextId());
             newChat.setChatType(conversationType);
             newChat.setGroupId(targetId);
             newChat.setStatus(1);
             newChat.setLastSequence(0L);
             try {
                 chatMapper.insert(newChat);
                 return newChat;
             } catch (Exception e) {
                 log.warn("[ImConversationService] 兜底创建群聊会话失败, targetId: {}, tenantId: {}, error: {}",
                         targetId, tenantId, e.getMessage());
                 return chatMapper.selectGroupChat(targetId, conversationType);
             }
         }

         Long user1 = Math.min(userId, targetId);
         Long user2 = Math.max(userId, targetId);
         ImChatDO chat = chatMapper.selectSingleChat(user1, user2, conversationType);
         if (chat != null && chat.getId() != null) {
             return chat;
         }
        chatMapper.insertSingleChatIfAbsent(tenantId, IdUtil.getSnowflakeNextId(), conversationType, user1, user2, 1);
         chat = chatMapper.selectSingleChat(user1, user2, conversationType);
         if (chat != null && chat.getId() != null) {
             return chat;
         }
         ImChatDO newChat = new ImChatDO();
        newChat.setId(IdUtil.getSnowflakeNextId());
         newChat.setChatType(conversationType);
         newChat.setSingleUser1(user1);
         newChat.setSingleUser2(user2);
         newChat.setStatus(1);
         newChat.setLastSequence(0L);
         try {
             chatMapper.insert(newChat);
             return newChat;
         } catch (Exception e) {
             log.warn("[ImConversationService] 兜底创建单聊会话失败, user1: {}, user2: {}, tenantId: {}, error: {}",
                     user1, user2, tenantId, e.getMessage());
             return chatMapper.selectSingleChat(user1, user2, conversationType);
         }
     }

     private ImChatDO findChat(Integer conversationType, Long userId, Long targetId) {
         if (conversationType == null || userId == null || targetId == null) {
             return null;
         }
         if (ImConversationTypeEnum.isGroup(conversationType)) {
             return chatMapper.selectGroupChat(targetId, conversationType);
         }
         Long user1 = Math.min(userId, targetId);
         Long user2 = Math.max(userId, targetId);
         return chatMapper.selectSingleChat(user1, user2, conversationType);
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
        try {
            chatUserMapper.insert(chatUser);
        } catch (DuplicateKeyException e) {
            ImChatUserDO existing = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
            if (existing != null) {
                return existing;
            }
            throw e;
        }
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
