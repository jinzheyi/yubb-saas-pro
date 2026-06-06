package com.shengyu.module.system.service.im;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.websocket.core.protocol.ConversationBadge;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
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
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImConversationUserStateMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.enums.im.ImMessageTypeEnum;
import com.shengyu.module.system.service.im.support.ImSystemMessageI18nSupport;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
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

    private boolean shouldKeepConversationItem(Integer conversationType, Long targetId, String targetName) {
        if (conversationType == null || targetId == null || targetId <= 0L) {
            return false;
        }
        if (ImConversationTypeEnum.isGroup(conversationType)) {
            return true;
        }
        return targetName != null && !targetName.trim().isEmpty();
    }

    private void logInvalidConversationItem(Long userId, String source, Long chatId,
                                            Integer conversationType, Long targetId, String targetName) {
        log.warn("[ImConversationService] skip invalid conversation, source: {}, userId: {}, chatId: {}, type: {}, targetId: {}, targetName: {}",
                source, userId, chatId, conversationType, targetId, targetName);
    }

    private void cleanupInvalidConversationState(Long tenantId, Long userId, Long chatId, String source) {
        if (userId == null || chatId == null || chatId <= 0L) {
            return;
        }
        try {
            chatUserMapper.softDelete(userId, chatId);
        } catch (Exception e) {
            log.warn("[ImConversationService] soft delete invalid chat_user failed, source: {}, userId: {}, chatId: {}, error: {}",
                    source, userId, chatId, e.getMessage());
        }
        try {
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterDelete(tenantId, chatId, userId, cursorVersion, true);
        } catch (Exception e) {
            log.warn("[ImConversationService] cleanup invalid conversation state failed, source: {}, userId: {}, chatId: {}, error: {}",
                    source, userId, chatId, e.getMessage());
        }
    }

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
    private ImGroupUserMapper groupUserMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private ImCursorVersionService cursorVersionService;

    @Resource
    private ImBadgeService imBadgeService;

    @Resource
    private NettyMessageSender messageSender;

    @Resource
    private NettySessionManager nettySessionManager;

    @Autowired(required = false)
    private ImPresenceService imPresenceService;

    @Resource
    private ImSystemMessageI18nSupport imSystemMessageI18nSupport;

    @Override
    public List<AppImConversationRespVO> getConversationList(Long userId) {
        List<ImChatUserDO> chatUsers = chatUserMapper.selectListByUserId(userId);
        return toConversationRespVOList(userId, chatUsers);
    }

    private void fillConversationPresence(AppImConversationRespVO respVO) {
        if (respVO == null || !ImConversationTypeEnum.isSingle(respVO.getConversationType())) {
            return;
        }
        Long targetUserId = respVO.getTargetId();
        if (targetUserId == null || targetUserId <= 0L) {
            respVO.setOnline(false);
            respVO.setOnlineDeviceTypes(Collections.emptyList());
            respVO.setLastActiveTime(null);
            return;
        }

        if (imPresenceService != null) {
            ImPresenceSnapshot snapshot = imPresenceService.getUserPresence(targetUserId);
            if (snapshot != null) {
                respVO.setOnline(Boolean.TRUE.equals(snapshot.getOnline()));
                respVO.setOnlineDeviceTypes(snapshot.getOnlineDeviceTypes() != null
                        ? snapshot.getOnlineDeviceTypes() : Collections.emptyList());
                respVO.setLastActiveTime(snapshot.getLastActiveTime());
                return;
            }
        }

        List<NettySession> sessions = nettySessionManager.getSessionsByUserId(targetUserId);
        if (sessions == null || sessions.isEmpty()) {
            respVO.setOnline(false);
            respVO.setOnlineDeviceTypes(Collections.emptyList());
            respVO.setLastActiveTime(null);
            return;
        }

        respVO.setOnline(true);
        respVO.setOnlineDeviceTypes(sessions.stream()
                .map(NettySession::getDeviceType)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList()));
        Long latestActiveTime = sessions.stream()
                .map(session -> session.getLastBizActiveTime() != null ? session.getLastBizActiveTime()
                        : (session.getLastActiveTime() != null ? session.getLastActiveTime() : session.getConnectTime()))
                .filter(Objects::nonNull)
                .max(Long::compareTo)
                .orElse(null);
        respVO.setLastActiveTime(latestActiveTime);
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
        Map<Long, ImChatMessageDO> lastMessageMap = new HashMap<>();

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
                List<Long> lastMessageIds = states.stream()
                        .filter(s -> s != null && s.getLastMessageId() != null
                                && (s.getLastMessageType() == null
                                || Objects.equals(s.getLastMessageType(), ImMessageTypeEnum.SYSTEM.getType())))
                        .map(ImConversationUserStateDO::getLastMessageId)
                        .distinct()
                        .collect(Collectors.toList());
                if (!lastMessageIds.isEmpty()) {
                    List<ImChatMessageDO> messages = chatMessageMapper.selectBatchIds(lastMessageIds);
                    if (messages != null) {
                        for (ImChatMessageDO message : messages) {
                            if (message != null && message.getId() != null) {
                                lastMessageMap.put(message.getId(), message);
                            }
                        }
                    }
                }

                // 获取群成员完整信息列表（最多4个，用于组合头像）
                Map<Long, List<AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem>> syncGroupMemberItemsMap = new HashMap<>();
                if (!groupIds.isEmpty()) {
                    for (Long groupId : groupIds) {
                        List<ImGroupUserDO> members = groupUserMapper.selectList(
                                new LambdaQueryWrapperX<ImGroupUserDO>()
                                        .eq(ImGroupUserDO::getGroupId, groupId)
                                        .orderByAsc(ImGroupUserDO::getJoinTime)
                                        .last("LIMIT 4"));
                        if (members != null && !members.isEmpty()) {
                            List<Long> memberUserIds = members.stream()
                                    .map(ImGroupUserDO::getUserId)
                                    .collect(Collectors.toList());
                            List<AdminUserDO> memberUsers = userMapper.selectBatchIds(memberUserIds);
                            if (memberUsers != null) {
                                List<AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem> syncItems = new ArrayList<>();
                                for (ImGroupUserDO member : members) {
                                    AdminUserDO user = memberUsers.stream()
                                            .filter(u -> u != null && u.getId().equals(member.getUserId()))
                                            .findFirst()
                                            .orElse(null);
                                    if (user != null) {
                                        AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem syncItem =
                                                new AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem();
                                        syncItem.setUserId(user.getId());
                                        syncItem.setName(user.getNickname());
                                        syncItem.setAvatar(user.getAvatar());
                                        syncItems.add(syncItem);
                                    }
                                }
                                if (!syncItems.isEmpty()) {
                                    syncGroupMemberItemsMap.put(groupId, syncItems);
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
                        Integer lastMessageType = state.getLastMessageType();
                        ImChatMessageDO lastMessage = state.getLastMessageId() != null ? lastMessageMap.get(state.getLastMessageId()) : null;
                        if (lastMessageType == null && lastMessage != null) {
                            lastMessageType = lastMessage.getMessageType();
                        }
                        item.setLastMessageType(lastMessageType);
                        item.setLastMessageContent(buildPreviewByType(lastMessageType, state.getLastMessageContent(),
                                lastMessage != null ? lastMessage.getExtra() : null));
                        item.setLastMessageSystemEventKey(extractSystemEventKey(lastMessage != null ? lastMessage.getExtra() : null));
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

                                // 判断用户是否已离群
                                boolean syncHasLeftGroup = state.getGroupMemberStatus() != null && state.getGroupMemberStatus() != 0;
                                if (syncHasLeftGroup) {
                                    String syncSnapshotData = state.getSnapshotData();
                                    if (syncSnapshotData != null && !syncSnapshotData.isEmpty()) {
                                        fillSyncItemFromSnapshot(item, syncSnapshotData, state);
                                    } else if (group != null) {
                                        fillSyncItemFromGroup(item, group, state, syncGroupMemberItemsMap);
                                    }
                                } else if (group != null) {
                                    fillSyncItemFromGroup(item, group, state, syncGroupMemberItemsMap);
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

                        if (!shouldKeepConversationItem(item.getConversationType(), item.getTargetId(), item.getTargetName())) {
                            logInvalidConversationItem(userId, "sync", item.getChatId(),
                                    item.getConversationType(), item.getTargetId(), item.getTargetName());
                            cleanupInvalidConversationState(tenantId, userId, item.getChatId(), "sync");
                            continue;
                        }

                        items.add(item);
                        if (item.getCursorVersion() != null && item.getCursorVersion() > next) {
                            next = item.getCursorVersion();
                        }
                    }
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
        if (pageSize > 50) {
            pageSize = 50;
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
        if (updateReqVO == null || updateReqVO.getChatId() == null) {
            return;
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, updateReqVO.getChatId());
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        Boolean newPinned = updateReqVO.getIsPinned() != null ? updateReqVO.getIsPinned() : chatUser.getIsPinned();
        Boolean newNoDisturb = updateReqVO.getNoDisturb() != null ? updateReqVO.getNoDisturb() : chatUser.getNoDisturb();
        if (Objects.equals(chatUser.getIsPinned(), newPinned)
                && Objects.equals(chatUser.getNoDisturb(), newNoDisturb)) {
            return;
        }
        chatUserMapper.updateSettings(userId, updateReqVO.getChatId(), updateReqVO.getIsPinned(), updateReqVO.getNoDisturb());

        // 同步写入会话-用户态 + 分配 cursorVersion（跨端设置一致）
        try {
            Long tenantId = resolveTenantId();
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
            pushConversationStateNotify(userId, tenantId, updateReqVO.getChatId(), cursorVersion,
                    "设置变更", "[ImConversationService] 推送会话设置变更事件失败");
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

        // 清理群组快照数据（被踢/退群/解散的快照信息），恢复为干净状态
        // 这样如果用户在群内，新消息到来时会重新创建干净的会话条目
        try {
            chatUserMapper.cleanGroupSnapshotAndStatus(userId, conversationId);
        } catch (Exception e) {
            log.warn("[ImConversationService] 清理群快照数据失败, userId: {}, chatId: {}, error: {}",
                    userId, conversationId, e.getMessage());
        }

        // 同步写入会话-用户态 + 分配 cursorVersion（跨端删除一致）
        try {
            Long tenantId = resolveTenantId();
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);

            // 同时清理 im_conversation_user_state 的快照数据
            try {
                conversationUserStateMapper.cleanGroupSnapshotAndStatus(tenantId, userId, conversationId);
            } catch (Exception e) {
                log.warn("[ImConversationService] 清理会话用户态快照数据失败, userId: {}, chatId: {}, error: {}",
                        userId, conversationId, e.getMessage());
            }

            conversationUserStateMapper.upsertAfterDelete(
                    tenantId,
                    conversationId,
                    userId,
                    cursorVersion,
                    true
            );
            pushConversationStateNotify(userId, tenantId, conversationId, cursorVersion,
                    "删除会话", "[ImConversationService] 推送会话删除事件失败");
            pushBadgeUpdateSafely(userId, conversationId, "删除会话");
        } catch (Exception e) {
            log.warn("[ImConversationService] 写入会话-用户态删除失败, userId: {}, chatId: {}, error: {}",
                    userId, conversationId, e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markConversationReadBySequence(Long userId, Long chatId, Long readSequence) {
        ImChatUserDO chatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, chatId);
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
            Long tenantId = resolveTenantId();
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
            pushConversationStateNotify(userId, tenantId, chatId, cursorVersion,
                    "已读水位变更", "[ImConversationService] 推送已读水位变更事件失败");
            pushBadgeUpdateSafely(userId, chatId, "已读水位变更");
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

        // 注意：此方法可能被群操作（退群/踢人/解散）的 DELETE 推送触发
        // 也可能被用户主动删除会话触发
        // 为保留快照查看能力，这里只做软删除，不清理快照数据
        // 快照数据的清理应由用户主动删除会话时执行（deleteConversation 方法）

        // 同步写入会话-用户态 + 分配 cursorVersion（跨端删除一致）
        try {
            Long tenantId = resolveTenantId();
            Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);
            conversationUserStateMapper.upsertAfterDelete(
                    tenantId,
                    chat.getId(),
                    userId,
                    cursorVersion,
                    true
            );
            pushConversationStateNotify(userId, tenantId, chat.getId(), cursorVersion,
                    "按 target 删除会话", "[ImConversationService] 推送按 target 删除会话事件失败");
            pushBadgeUpdateSafely(userId, chat.getId(), "按 target 删除会话");
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
        ImChatUserDO chatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, conversationId);
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

        // 获取群成员头像列表（最多4个）
        Map<Long, java.util.List<String>> groupMemberAvatarsMap = new HashMap<>();
        // 获取群成员完整信息列表（最多4个，用于组合头像）
        Map<Long, java.util.List<AppImConversationRespVO.GroupMemberItem>> groupMemberItemsMap = new HashMap<>();
        if (!groupIds.isEmpty()) {
            for (Long groupId : groupIds) {
                List<ImGroupUserDO> members = groupUserMapper.selectList(
                        new LambdaQueryWrapperX<ImGroupUserDO>()
                                .eq(ImGroupUserDO::getGroupId, groupId)
                                .orderByAsc(ImGroupUserDO::getJoinTime)
                                .last("LIMIT 4"));
                if (members != null && !members.isEmpty()) {
                    List<Long> memberUserIds = members.stream()
                            .map(ImGroupUserDO::getUserId)
                            .collect(Collectors.toList());
                    List<AdminUserDO> memberUsers = userMapper.selectBatchIds(memberUserIds);
                    if (memberUsers != null) {
                        // 按成员顺序映射用户信息
                        List<AppImConversationRespVO.GroupMemberItem> items = new ArrayList<>();
                        List<String> avatars = new ArrayList<>();
                        for (ImGroupUserDO member : members) {
                            AdminUserDO user = memberUsers.stream()
                                    .filter(u -> u != null && u.getId().equals(member.getUserId()))
                                    .findFirst()
                                    .orElse(null);
                            if (user != null) {
                                AppImConversationRespVO.GroupMemberItem item = new AppImConversationRespVO.GroupMemberItem();
                                item.setUserId(user.getId());
                                item.setName(user.getNickname());
                                item.setAvatar(user.getAvatar());
                                items.add(item);
                                if (user.getAvatar() != null && !user.getAvatar().isEmpty()) {
                                    avatars.add(user.getAvatar());
                                }
                            }
                        }
                        if (!avatars.isEmpty()) {
                            groupMemberAvatarsMap.put(groupId, avatars);
                        }
                        if (!items.isEmpty()) {
                            groupMemberItemsMap.put(groupId, items);
                        }
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

        Map<Long, ImChatMessageDO> lastMessageMap = new HashMap<>();
        List<Long> needLastMsgIds = chatUsers.stream()
                .filter(cu -> cu != null && cu.getLastMessageId() != null
                        && (cu.getLastMessageType() == null
                        || Objects.equals(cu.getLastMessageType(), ImMessageTypeEnum.SYSTEM.getType())))
                .map(ImChatUserDO::getLastMessageId)
                .distinct()
                .collect(Collectors.toList());
        if (!needLastMsgIds.isEmpty()) {
            List<ImChatMessageDO> msgs = chatMessageMapper.selectBatchIds(needLastMsgIds);
            if (msgs != null) {
                for (ImChatMessageDO m : msgs) {
                    if (m != null && m.getId() != null) {
                        lastMessageMap.put(m.getId(), m);
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
            ImChatMessageDO lastMessage = chatUser.getLastMessageId() != null
                    ? lastMessageMap.get(chatUser.getLastMessageId()) : null;
            if (lastType == null && lastMessage != null) {
                Integer t = lastMessage.getMessageType();
                if (t != null) {
                    lastType = t;
                }
            }
            respVO.setLastMessageType(lastType);
            respVO.setLastMessageContent(buildPreviewByType(lastType, chatUser.getLastMessageContent(),
                    lastMessage != null ? lastMessage.getExtra() : null));
            respVO.setLastMessageSystemEventKey(extractSystemEventKey(lastMessage != null ? lastMessage.getExtra() : null));
            // 无消息时：群聊会话时间取群创建时间；有消息时取最后一条消息时间
            respVO.setLastMessageTime(chatUser.getLastMessageTime());
            respVO.setIsPinned(chatUser.getIsPinned());
            respVO.setNoDisturb(chatUser.getNoDisturb());

            if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
                respVO.setTargetId(chat.getGroupId());
                ImGroupDO group = chat.getGroupId() != null ? groupMap.get(chat.getGroupId()) : null;

                // 判断用户是否已离群（被踢/退出/解散）
                boolean hasLeftGroup = chatUser.getGroupMemberStatus() != null && chatUser.getGroupMemberStatus() != 0;

                if (hasLeftGroup) {
                    // 已离群：优先使用快照数据（冻结的群名称、成员信息等）
                    String snapshotData = chatUser.getSnapshotData();
                    if (snapshotData != null && !snapshotData.isEmpty()) {
                        fillConversationFromSnapshot(respVO, snapshotData, chatUser);
                    } else if (group != null) {
                        // 快照不存在时降级使用实时数据
                        fillConversationFromGroup(respVO, group, chatUser, groupMemberAvatarsMap, groupMemberItemsMap);
                    }
                } else if (group != null) {
                    // 正常在群：使用实时数据
                    fillConversationFromGroup(respVO, group, chatUser, groupMemberAvatarsMap, groupMemberItemsMap);
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
            if (!shouldKeepConversationItem(respVO.getConversationType(), respVO.getTargetId(), respVO.getTargetName())) {
                logInvalidConversationItem(userId, "list", respVO.getChatId(),
                        respVO.getConversationType(), respVO.getTargetId(), respVO.getTargetName());
                cleanupInvalidConversationState(tenantId, userId, respVO.getChatId(), "list");
                continue;
            }
            fillConversationPresence(respVO);
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
        ImChatMessageDO lastMsg = null;
        if (chatUser.getLastMessageId() != null) {
            lastMsg = chatMessageMapper.selectById(chatUser.getLastMessageId());
            if (lastType == null && lastMsg != null) {
                lastType = lastMsg.getMessageType();
            }
        }
        respVO.setLastMessageType(lastType);
        respVO.setLastMessageContent(buildPreviewByType(lastType, chatUser.getLastMessageContent(),
                lastMsg != null ? lastMsg.getExtra() : null));
        respVO.setLastMessageSystemEventKey(extractSystemEventKey(lastMsg != null ? lastMsg.getExtra() : null));
        // 无消息时：群聊会话时间取群创建时间（体验对标企微/钉钉）；有消息时取最后一条消息时间
        respVO.setLastMessageTime(chatUser.getLastMessageTime());
        respVO.setIsPinned(chatUser.getIsPinned());
        respVO.setNoDisturb(chatUser.getNoDisturb());

         if (ImConversationTypeEnum.isGroup(chat.getChatType())) {
             respVO.setTargetId(chat.getGroupId());
             ImGroupDO group = groupMapper.selectById(chat.getGroupId());

             boolean hasLeftGroup = chatUser.getGroupMemberStatus() != null && chatUser.getGroupMemberStatus() != 0;
             if (hasLeftGroup) {
                 String snapshotData = chatUser.getSnapshotData();
                 if (snapshotData != null && !snapshotData.isEmpty()) {
                     fillConversationFromSnapshot(respVO, snapshotData, chatUser);
                 } else if (group != null) {
                     fillConversationFromGroupSingle(respVO, group, chatUser);
                 }
             } else if (group != null) {
                 fillConversationFromGroupSingle(respVO, group, chatUser);
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
         if (!shouldKeepConversationItem(respVO.getConversationType(), respVO.getTargetId(), respVO.getTargetName())) {
             logInvalidConversationItem(userId, "detail", respVO.getChatId(),
                     respVO.getConversationType(), respVO.getTargetId(), respVO.getTargetName());
             Long tenantId = TenantContextHolder.getTenantId();
             if (tenantId == null) {
                 tenantId = 0L;
             }
             cleanupInvalidConversationState(tenantId, userId, respVO.getChatId(), "detail");
             throw exception(CONVERSATION_NOT_EXISTS);
         }
         fillConversationPresence(respVO);
         return respVO;
    }

    /**
     * 从快照数据填充同步项VO（已离群用户使用）
     */
    private void fillSyncItemFromSnapshot(AppImConversationSyncItemRespVO item, String snapshotData, ImConversationUserStateDO state) {
        JSONObject snapshot = JSONUtil.parseObj(snapshotData);
        item.setTargetName(snapshot.getStr("groupName", ""));
        item.setGroupMemberCount(snapshot.getInt("memberCount", 0));
        item.setGroupMemberStatus(snapshot.getInt("groupMemberStatus", state.getGroupMemberStatus()));
        item.setLeftAt(state.getLeftAt());

        List<JSONObject> members = snapshot.getJSONArray("members").toList(JSONObject.class);
        if (members != null && !members.isEmpty()) {
            List<AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem> syncItems = new ArrayList<>();
            int limit = Math.min(members.size(), 4);
            for (int i = 0; i < limit; i++) {
                JSONObject member = members.get(i);
                String nickname = member.getStr("nickname", "");
                if (nickname.isEmpty()) {
                    nickname = member.getStr("userName", "");
                }
                String userIdStr = member.getStr("userId", "");
                AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem syncItem =
                        new AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem();
                if (!userIdStr.isEmpty()) {
                    syncItem.setUserId(Long.parseLong(userIdStr));
                }
                syncItem.setName(nickname);
                syncItem.setAvatar(member.getStr("avatarUrl", ""));
                syncItems.add(syncItem);
            }
            if (!syncItems.isEmpty()) {
                item.setGroupMemberItems(syncItems);
            }
        }
    }

    /**
     * 从实时群数据填充同步项VO（正常在群用户使用）
     */
    private void fillSyncItemFromGroup(AppImConversationSyncItemRespVO item, ImGroupDO group, ImConversationUserStateDO state,
                                       Map<Long, List<AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem>> syncGroupMemberItemsMap) {
        item.setTargetName(group.getName());
        item.setTargetAvatar(group.getAvatar());
        item.setGroupMemberCount(group.getMemberCount());
        if (group.getId() != null) {
            List<AppImConversationSyncItemRespVO.AppImConversationSyncGroupMemberItem> groupMemberItems =
                    syncGroupMemberItemsMap.get(group.getId());
            if (groupMemberItems != null && !groupMemberItems.isEmpty()) {
                item.setGroupMemberItems(groupMemberItems);
            }
        }
        item.setGroupMemberStatus(state.getGroupMemberStatus());
        item.setLeftAt(state.getLeftAt());
        if (item.getLastMessageTime() == null
                && state.getLastMessageId() == null
                && (state.getLastMessageSequence() == null || state.getLastMessageSequence() <= 0L)) {
            item.setLastMessageTime(group.getCreateTime());
        }
    }

    /**
     * 从实时群数据填充会话VO（正常在群用户使用 - 单个查询版本）
     */
    private void fillConversationFromGroupSingle(AppImConversationRespVO respVO, ImGroupDO group, ImChatUserDO chatUser) {
        respVO.setTargetName(group.getName());
        respVO.setTargetAvatar(group.getAvatar());
        respVO.setGroupMemberCount(group.getMemberCount());

        // 获取群成员头像列表（最多4个）
        List<ImGroupUserDO> members = groupUserMapper.selectList(
                new LambdaQueryWrapperX<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, group.getId())
                        .orderByAsc(ImGroupUserDO::getJoinTime)
                        .last("LIMIT 4"));
        if (members != null && !members.isEmpty()) {
            List<Long> memberUserIds = members.stream()
                    .map(ImGroupUserDO::getUserId)
                    .collect(Collectors.toList());
            List<AdminUserDO> memberUsers = userMapper.selectBatchIds(memberUserIds);
            if (memberUsers != null) {
                List<String> avatars = memberUsers.stream()
                        .map(u -> u != null ? u.getAvatar() : null)
                        .filter(a -> a != null && !a.isEmpty())
                        .collect(Collectors.toList());
                if (!avatars.isEmpty()) {
                    respVO.setGroupMemberAvatars(avatars);
                }

                List<AppImConversationRespVO.GroupMemberItem> items = new ArrayList<>();
                for (ImGroupUserDO member : members) {
                    AdminUserDO user = memberUsers.stream()
                            .filter(u -> u != null && u.getId().equals(member.getUserId()))
                            .findFirst()
                            .orElse(null);
                    if (user != null) {
                        AppImConversationRespVO.GroupMemberItem item = new AppImConversationRespVO.GroupMemberItem();
                        item.setUserId(user.getId());
                        item.setName(user.getNickname());
                        item.setAvatar(user.getAvatar());
                        items.add(item);
                    }
                }
                if (!items.isEmpty()) {
                    respVO.setGroupMemberItems(items);
                }
            }
        }

        respVO.setGroupMemberStatus(chatUser.getGroupMemberStatus());
        respVO.setLeftAt(chatUser.getLeftAt());

        // 群聊无消息：使用群创建时间作为会话时间
        if (respVO.getLastMessageTime() == null
                && chatUser.getLastMessageId() == null
                && (chatUser.getLastMessageSequence() == null || chatUser.getLastMessageSequence() <= 0L)) {
            respVO.setLastMessageTime(group.getCreateTime());
        }
    }

    /**
     * 从快照数据填充会话VO（已离群用户使用）
     */
    private void fillConversationFromSnapshot(AppImConversationRespVO respVO, String snapshotData, ImChatUserDO chatUser) {
        JSONObject snapshot = JSONUtil.parseObj(snapshotData);
        respVO.setTargetName(snapshot.getStr("groupName", ""));
        respVO.setGroupMemberCount(snapshot.getInt("memberCount", 0));
        respVO.setGroupMemberStatus(snapshot.getInt("groupMemberStatus", chatUser.getGroupMemberStatus()));
        respVO.setLeftAt(chatUser.getLeftAt());

        // 从快照中获取前4个成员用于头像展示
        List<JSONObject> members = snapshot.getJSONArray("members").toList(JSONObject.class);
        if (members != null && !members.isEmpty()) {
            List<String> avatars = new ArrayList<>();
            List<AppImConversationRespVO.GroupMemberItem> items = new ArrayList<>();
            int limit = Math.min(members.size(), 4);
            for (int i = 0; i < limit; i++) {
                JSONObject member = members.get(i);
                String avatar = member.getStr("avatarUrl", "");
                String nickname = member.getStr("nickname", "");
                if (nickname.isEmpty()) {
                    nickname = member.getStr("userName", "");
                }
                String userIdStr = member.getStr("userId", "");
                if (!avatar.isEmpty()) {
                    avatars.add(avatar);
                }
                AppImConversationRespVO.GroupMemberItem item = new AppImConversationRespVO.GroupMemberItem();
                if (!userIdStr.isEmpty()) {
                    item.setUserId(Long.parseLong(userIdStr));
                }
                item.setName(nickname);
                item.setAvatar(avatar);
                items.add(item);
            }
            if (!avatars.isEmpty()) {
                respVO.setGroupMemberAvatars(avatars);
            }
            if (!items.isEmpty()) {
                respVO.setGroupMemberItems(items);
            }
        }
    }

    /**
     * 从实时群数据填充会话VO（正常在群用户使用）
     */
    private void fillConversationFromGroup(AppImConversationRespVO respVO, ImGroupDO group, ImChatUserDO chatUser,
                                           Map<Long, List<String>> groupMemberAvatarsMap,
                                           Map<Long, List<AppImConversationRespVO.GroupMemberItem>> groupMemberItemsMap) {
        respVO.setTargetName(group.getName());
        respVO.setTargetAvatar(group.getAvatar());
        respVO.setGroupMemberCount(group.getMemberCount());
        respVO.setGroupMemberAvatars(groupMemberAvatarsMap.get(group.getId()));
        respVO.setGroupMemberItems(groupMemberItemsMap.get(group.getId()));
        respVO.setGroupMemberStatus(chatUser.getGroupMemberStatus());
        respVO.setLeftAt(chatUser.getLeftAt());

        // 群聊无消息：使用群创建时间作为会话时间
        if (respVO.getLastMessageTime() == null
                && chatUser.getLastMessageId() == null
                && (chatUser.getLastMessageSequence() == null || chatUser.getLastMessageSequence() <= 0L)) {
            respVO.setLastMessageTime(group.getCreateTime());
        }
    }

    private String buildPreviewByType(Integer messageType, String raw, String extra) {
        if (imSystemMessageI18nSupport.isRecallPreviewFallback(raw)) {
            return imSystemMessageI18nSupport.renderRecallPreview(raw);
        }
        if (Objects.equals(messageType, ImMessageTypeEnum.SYSTEM.getType())) {
            String localized = imSystemMessageI18nSupport.render(raw, extra);
            if (localized != null) {
                String trimmedLocalized = localized.trim();
                if (!trimmedLocalized.isEmpty()) {
                    if (trimmedLocalized.length() > 100) {
                        return trimmedLocalized.substring(0, 100) + "...";
                    }
                    return trimmedLocalized;
                }
            }
        }
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
                return "[动画表情]";
            case 10:
                return "[系统消息]";
            default:
                return "[消息]";
        }
    }

    /**
     * 从消息 extra JSON 中提取系统消息事件 Key（用于前端国际化渲染）
     */
    private String extractSystemEventKey(String extra) {
        if (extra == null || extra.isEmpty()) {
            return null;
        }
        try {
            JSONObject root = JSONUtil.parseObj(extra);
            if (root == null || root.isEmpty()) {
                return null;
            }
            JSONObject i18n = root.getJSONObject("i18n");
            if (i18n == null || i18n.isEmpty()) {
                return null;
            }
            String eventKey = i18n.getStr("eventKey");
            if (StrUtil.isBlank(eventKey)) {
                return null;
            }
            return eventKey;
        } catch (Exception e) {
            return null;
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
        ImChatUserDO deletedChatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, chatId);
        if (deletedChatUser != null) {
            if (Boolean.TRUE.equals(deletedChatUser.getDeletedByUser())) {
                chatUserMapper.reviveSoftDeleted(deletedChatUser.getId());
                deletedChatUser.setDeletedByUser(false);
            }
            return deletedChatUser;
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
            ImChatUserDO existing = chatUserMapper.selectAnyByUserIdAndChatId(userId, chatId);
            if (existing != null) {
                if (Boolean.TRUE.equals(existing.getDeletedByUser())) {
                    chatUserMapper.reviveSoftDeleted(existing.getId());
                    existing.setDeletedByUser(false);
                }
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
        AppImConversationUpdateReqVO reqVO = new AppImConversationUpdateReqVO();
        reqVO.setChatId(conversationId);
        reqVO.setIsPinned(isPinned);
        updateConversation(userId, reqVO);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setMute(Long userId, Long conversationId, Boolean noDisturb) {
        AppImConversationUpdateReqVO reqVO = new AppImConversationUpdateReqVO();
        reqVO.setChatId(conversationId);
        reqVO.setNoDisturb(noDisturb);
        updateConversation(userId, reqVO);
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
        ImChatUserDO chatUser = chatUserMapper.selectAnyByUserIdAndChatId(userId, conversationId);
        if (chatUser == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }
        return chatUser.getDraft();
    }

    private Long resolveTenantId() {
        Long tenantId = TenantContextHolder.getTenantId();
        return tenantId != null ? tenantId : 0L;
    }

    private void pushConversationStateNotify(Long userId, Long tenantId, Long chatId, Long cursorVersion,
                                             String scene, String logPrefix) {
        try {
            TextMessage body = TextMessage.newBuilder().setContent("").build();
            messageSender.sendToUser(userId, MessageType.SYSTEM_NOTIFY, body,
                    0L, userId, 0L, tenantId,
                    null, null, chatId,
                    cursorVersion, null);
        } catch (Exception e) {
            log.warn("{}, scene: {}, userId: {}, chatId: {}, error: {}",
                    logPrefix, scene, userId, chatId, e.getMessage(), e);
        }
    }

    private void pushBadgeUpdateSafely(Long userId, Long chatId, String scene) {
        try {
            imBadgeService.pushBadgeUpdate(userId);
        } catch (Exception e) {
            log.warn("[ImConversationService] 推送角标更新失败, scene: {}, userId: {}, chatId: {}, error: {}",
                    scene, userId, chatId, e.getMessage(), e);
        }
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
