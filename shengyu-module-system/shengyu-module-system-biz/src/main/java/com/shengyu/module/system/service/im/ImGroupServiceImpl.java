package com.shengyu.module.system.service.im;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.module.system.controller.app.im.vo.group.*;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupInviteDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupJoinRequestDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImConversationUserStateMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupInviteMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupJoinRequestMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.enums.im.ImGroupInviteStatusEnum;
import com.shengyu.module.system.enums.im.ImGroupJoinRequestStatusEnum;
import com.shengyu.module.system.enums.im.ImGroupMemberRoleEnum;
import com.shengyu.module.system.enums.im.ImGroupStatusEnum;
import com.shengyu.module.system.enums.im.ImMessageStatusEnum;
import com.shengyu.module.system.mq.message.im.ImGroupConversationRefreshMessage;
import com.shengyu.module.system.mq.producer.im.ImGroupConversationRefreshProducer;
import com.shengyu.module.system.service.im.support.ImSystemMessageI18nSupport;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import javax.annotation.Resource;
import java.time.format.DateTimeFormatter;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 群组 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImGroupServiceImpl implements ImGroupService {

    private static final DateTimeFormatter GROUP_MUTE_TIP_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private static final LocalDateTime PERMANENT_EXPIRE_TIME = LocalDateTime.of(9999, 12, 31, 23, 59, 59);

    /** 入群申请限流: 同一用户5分钟内最多3次 */
    private static final int JOIN_GROUP_RATE_LIMIT = 3;
    private static final long JOIN_GROUP_RATE_WINDOW_MS = 5 * 60 * 1000;
    /** 邀请码验证限流: 同一用户1分钟内最多10次 */
    private static final int VERIFY_INVITE_RATE_LIMIT = 10;
    private static final long VERIFY_INVITE_RATE_WINDOW_MS = 60 * 1000;

    /** 入群申请限流器: key=userId, value=请求时间戳列表 */
    private final java.util.concurrent.ConcurrentMap<String, java.util.List<Long>> joinGroupRateLimiter =
            new java.util.concurrent.ConcurrentHashMap<>();
    /** 邀请码验证限流器: key=userId, value=请求时间戳列表 */
    private final java.util.concurrent.ConcurrentMap<String, java.util.List<Long>> verifyInviteRateLimiter =
            new java.util.concurrent.ConcurrentHashMap<>();

    private boolean tryAcquireRateLimit(java.util.concurrent.ConcurrentMap<String, java.util.List<Long>> limiter,
                                        String key, int maxRequests, long windowMs) {
        long now = System.currentTimeMillis();
        java.util.List<Long> timestamps = limiter.computeIfAbsent(key, k ->
                java.util.Collections.synchronizedList(new java.util.ArrayList<>()));
        synchronized (timestamps) {
            timestamps.removeIf(ts -> now - ts > windowMs);
            if (timestamps.size() >= maxRequests) {
                return false;
            }
            timestamps.add(now);
            return true;
        }
    }

    @Resource
    private ImGroupMapper groupMapper;

    @Resource
    private ImGroupUserMapper groupUserMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private ImGroupConversationRefreshProducer groupConversationRefreshProducer;

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImGroupInviteMapper groupInviteMapper;

    @Resource
    private ImGroupJoinRequestMapper groupJoinRequestMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImConversationUserStateMapper conversationUserStateMapper;

    @Resource
    private ImCursorVersionService cursorVersionService;

    @Resource
    private ImBadgeService imBadgeService;

    @Resource
    private NettyMessageSender messageSender;

    @Resource
    private ImNotifyService imNotifyService;

    @Resource
    private ImSystemMessageI18nSupport imSystemMessageI18nSupport;

    @Resource
    private MessageSource messageSource;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createGroup(Long userId, AppImGroupCreateReqVO createReqVO) {
        log.info("[ImGroupService] 开始创建群组, ownerId: {}, memberIds: {}", userId, createReqVO.getMemberIds());
        
        // 创建群组
        ImGroupDO group = new ImGroupDO();
        group.setOwnerId(userId);
        group.setName(createReqVO.getName().trim());
        group.setAvatar(createReqVO.getAvatar());
        group.setGroupType(createReqVO.getGroupType());
        group.setIntroduction(createReqVO.getIntroduction());
        group.setStatus(ImGroupStatusEnum.NORMAL.getStatus());
        group.setAllowMemberInvite(true); // 默认允许成员邀请
        group.setNeedApproval(false); // 默认不需要审批
        group.setMuteAll(false); // 默认不禁言
        
        // 确保 memberIds 包含群主
        List<Long> memberIds = createReqVO.getMemberIds().stream()
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toCollection(ArrayList::new));
        if (!memberIds.contains(userId)) {
            memberIds.add(userId);
            log.info("[ImGroupService] 群主不在成员列表中，自动添加: {}", userId);
        }
        if (memberIds.size() > 500) {
            throw exception(GROUP_MEMBER_FULL);
        }
        
        group.setMemberCount(memberIds.size());
        group.setMaxMemberCount(500); // 默认最大500人
        groupMapper.insert(group);
        
        log.info("[ImGroupService] 群组创建成功, groupId: {}, 开始添加成员和创建会话", group.getId());

        // 添加群成员
        for (Long memberId : memberIds) {
            Integer role = memberId.equals(userId)
                    ? ImGroupMemberRoleEnum.OWNER.getRole()
                    : ImGroupMemberRoleEnum.MEMBER.getRole();
            upsertGroupMember(group.getId(), memberId, role);
            log.info("[ImGroupService] 添加群成员成功, groupId: {}, memberId: {}, role: {}", 
                    group.getId(), memberId, role);
        }

        ImGroupConversationRefreshMessage refreshMessage = new ImGroupConversationRefreshMessage();
        refreshMessage.setAction("UPSERT");
        refreshMessage.setOperatorUserId(userId);
        refreshMessage.setGroupId(group.getId());
        refreshMessage.setMemberIds(memberIds);
        refreshMessage.setConversationType(ImConversationTypeEnum.GROUP.getType());
        groupConversationRefreshProducer.sendAfterCommit(refreshMessage);

        log.info("[ImGroupService] 创建群组完成, groupId: {}, ownerId: {}, memberCount: {}", 
                group.getId(), userId, memberIds.size());
        return group.getId();
    }

    /**
     * 校验用户是否为群成员，非群成员抛出友好错误提示
     * 
     * @param userId 用户ID
     * @param groupId 群组ID
     * @throws com.shengyu.framework.common.exception.ServiceException 如果不是群成员
     */
    private void assertIsGroupMember(Long userId, Long groupId) {
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }
        
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser != null) {
            return;
        }
        
        // 用户不是群成员，检查历史记录判断是被踢还是退群
        ImGroupUserDO deletedMember = groupUserMapper.selectDeletedByGroupIdAndUserId(groupId, userId);
        if (deletedMember != null) {
            // 被踢出群
            throw exception(GROUP_MEMBER_KICKED_OUT);
        }
        
        // 从未加入过群（或硬删除）
        throw exception(GROUP_MEMBER_ALREADY_REMOVED);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateGroup(Long userId, AppImGroupUpdateReqVO updateReqVO) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(updateReqVO.getId());
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查权限(只有群主和管理员可以修改)
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(group.getId(), userId);
        if (groupUser == null || 
            (!ImGroupMemberRoleEnum.isOwner(groupUser.getRole()) && 
             !ImGroupMemberRoleEnum.isAdmin(groupUser.getRole()))) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 更新群组信息
        if (updateReqVO.getName() != null) {
            group.setName(updateReqVO.getName());
        }
        if (updateReqVO.getAvatar() != null) {
            group.setAvatar(updateReqVO.getAvatar());
        }
        if (updateReqVO.getNotice() != null) {
            group.setNotice(updateReqVO.getNotice());
        }
        if (updateReqVO.getIntroduction() != null) {
            group.setIntroduction(updateReqVO.getIntroduction());
        }
        if (updateReqVO.getNeedApproval() != null) {
            group.setNeedApproval(updateReqVO.getNeedApproval());
        }
        if (updateReqVO.getAllowMemberInvite() != null) {
            group.setAllowMemberInvite(updateReqVO.getAllowMemberInvite());
        }
        groupMapper.updateById(group);

        log.info("[ImGroupService] 更新群组成功, groupId: {}, userId: {}", group.getId(), userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void dissolveGroup(Long userId, Long groupId) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查权限(只有群主可以解散)
        if (!group.getOwnerId().equals(userId)) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 获取群成员（在删除前获取）
        List<ImGroupUserDO> members = groupUserMapper.selectListByGroupId(groupId);
        List<Long> memberIds = members.stream().map(ImGroupUserDO::getUserId).collect(Collectors.toList());

        // 获取群会话（在删除群前查询，确保 im_chat 记录仍在）
        ImChatDO groupChat = chatMapper.selectGroupChat(groupId, 2);
        Long chatId = groupChat != null ? groupChat.getId() : null;

        // 删除群组
        groupMapper.deleteById(groupId);

        // 删除所有群成员
        for (ImGroupUserDO member : members) {
            deleteGroupMemberRelation(groupId, member.getUserId(), member.getId());
        }

        // 批量更新所有群成员的群成员状态为3（群已解散）
        if (chatId != null) {
            chatUserMapper.batchUpdateGroupMemberStatusByChatId(chatId, 3);
        }

        ImGroupConversationRefreshMessage refreshMessage = new ImGroupConversationRefreshMessage();
        refreshMessage.setAction("DELETE");
        refreshMessage.setOperatorUserId(userId);
        refreshMessage.setGroupId(groupId);
        refreshMessage.setChatId(chatId);
        refreshMessage.setMemberIds(memberIds);
        refreshMessage.setConversationType(ImConversationTypeEnum.GROUP.getType());
        groupConversationRefreshProducer.sendAfterCommit(refreshMessage);

        // 推送群解散WebSocket通知给所有群成员
        String tipContent = "群「" + group.getName() + "」已被群主解散";
        String tipExtra = imSystemMessageI18nSupport.attachI18n(null,
                ImSystemMessageI18nSupport.EVENT_GROUP_DISBANDED, null);
        runAfterCommit(() -> {
            pushGroupDisbandedNotify(groupId, memberIds, userId, tipContent, tipExtra);
        });

        log.info("[ImGroupService] 解散群组成功, groupId: {}, ownerId: {}", groupId, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void quitGroup(Long userId, Long groupId) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 群主不能退出,必须先转让群主
        if (group.getOwnerId().equals(userId)) {
            throw exception(GROUP_OWNER_CANNOT_QUIT);
        }

        // 查询群成员
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 删除群成员
        deleteGroupMemberRelation(groupId, userId, groupUser.getId());

        // 更新群成员数量
        group.setMemberCount(group.getMemberCount() - 1);
        groupMapper.updateById(group);

        ImChatDO chat = chatMapper.selectGroupChat(groupId, 2);
        Long chatId = chat != null ? chat.getId() : null;
        ImGroupConversationRefreshMessage refreshMessage = new ImGroupConversationRefreshMessage();
        refreshMessage.setAction("DELETE");
        refreshMessage.setOperatorUserId(userId);
        refreshMessage.setGroupId(groupId);
        refreshMessage.setChatId(chatId);
        refreshMessage.setMemberIds(java.util.Collections.singletonList(userId));
        refreshMessage.setConversationType(ImConversationTypeEnum.GROUP.getType());
        groupConversationRefreshProducer.sendAfterCommit(refreshMessage);

        // 推送成员退出WebSocket通知给剩余群成员
        String tipContent = userId + " 已退出群聊";
        String tipExtra = imSystemMessageI18nSupport.attachI18n(null,
                ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_REMOVED, null);
        runAfterCommit(() -> {
            pushGroupQuitNotify(groupId, userId, tipContent, tipExtra);
        });

        log.info("[ImGroupService] 退出群组成功, groupId: {}, userId: {}", groupId, userId);
    }

    @Override
    public AppImGroupRespVO getGroup(Long userId, Long groupId) {
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        boolean inGroup = groupUser != null;

        AppImGroupRespVO respVO = BeanUtils.toBean(group, AppImGroupRespVO.class);
        respVO.setInGroup(inGroup);

        if (inGroup) {
            respVO.setMyRole(groupUser.getRole());
        } else {
            respVO.setMyRole(null);
        }

        return respVO;
    }

    @Override
    public List<AppImGroupRespVO> getGroupList(Long userId) {
        // 查询用户的所有群组
        List<ImGroupUserDO> groupUsers = groupUserMapper.selectListByUserId(userId);
        if (CollUtil.isEmpty(groupUsers)) {
            return new ArrayList<>();
        }

        // 查询群组详情
        List<Long> groupIds = groupUsers.stream()
                .map(ImGroupUserDO::getGroupId)
                .collect(Collectors.toList());

        // 获取群成员信息列表（最多4个，用于组合头像）
        Map<Long, java.util.List<AppImGroupRespVO.GroupMemberItem>> groupMemberItemsMap = new HashMap<>();
        if (!groupIds.isEmpty()) {
            for (Long groupId : groupIds) {
                List<ImGroupUserDO> members = groupUserMapper.selectList(
                        new com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX<ImGroupUserDO>()
                                .eq(ImGroupUserDO::getGroupId, groupId)
                                .orderByAsc(ImGroupUserDO::getJoinTime)
                                .last("LIMIT 4"));
                if (members != null && !members.isEmpty()) {
                    List<Long> memberUserIds = members.stream()
                            .map(ImGroupUserDO::getUserId)
                            .collect(Collectors.toList());
                    List<AdminUserDO> memberUsers = userMapper.selectBatchIds(memberUserIds);
                    if (memberUsers != null) {
                        List<AppImGroupRespVO.GroupMemberItem> items = new ArrayList<>();
                        for (ImGroupUserDO member : members) {
                            AdminUserDO user = memberUsers.stream()
                                    .filter(u -> u != null && u.getId().equals(member.getUserId()))
                                    .findFirst()
                                    .orElse(null);
                            if (user != null) {
                                AppImGroupRespVO.GroupMemberItem item = new AppImGroupRespVO.GroupMemberItem();
                                item.setUserId(user.getId());
                                item.setName(user.getNickname());
                                item.setAvatar(user.getAvatar());
                                items.add(item);
                            }
                        }
                        if (!items.isEmpty()) {
                            groupMemberItemsMap.put(groupId, items);
                        }
                    }
                }
            }
        }

        List<AppImGroupRespVO> result = new ArrayList<>();
        for (Long groupId : groupIds) {
            ImGroupDO group = groupMapper.selectById(groupId);
            if (group != null) {
                AppImGroupRespVO respVO = BeanUtils.toBean(group, AppImGroupRespVO.class);
                ImGroupUserDO currentMember = groupUsers.stream()
                        .filter(item -> Objects.equals(item.getGroupId(), groupId))
                        .findFirst()
                        .orElse(null);
                if (currentMember != null) {
                    respVO.setMyRole(currentMember.getRole());
                    if (ImGroupMemberRoleEnum.isOwner(currentMember.getRole()) || ImGroupMemberRoleEnum.isAdmin(currentMember.getRole())) {
                        respVO.setPendingJoinRequestCount(groupJoinRequestMapper.selectPendingCountByGroupId(groupId));
                    } else {
                        respVO.setPendingJoinRequestCount(0L);
                    }
                }
                respVO.setGroupMemberItems(groupMemberItemsMap.get(groupId));
                result.add(respVO);
            }
        }

        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void addGroupMembers(Long userId, AppImGroupMemberAddReqVO addReqVO) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(addReqVO.getGroupId());
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查操作者是群成员（操作类方法：严格校验）
        assertIsGroupMember(userId, addReqVO.getGroupId());
        
        // 检查权限(群主、管理员或允许成员邀请)
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(addReqVO.getGroupId(), userId);

        boolean isOwnerOrAdmin = ImGroupMemberRoleEnum.isOwner(groupUser.getRole()) || 
                                 ImGroupMemberRoleEnum.isAdmin(groupUser.getRole());
        if (!isOwnerOrAdmin && !group.getAllowMemberInvite()) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 添加群成员
        int addedCount = 0;
        List<Long> addedMemberIds = new ArrayList<>();
        for (Long memberId : addReqVO.getMemberIds()) {
            // 检查是否已经是群成员
            ImGroupUserDO existMember = groupUserMapper.selectByGroupIdAndUserId(addReqVO.getGroupId(), memberId);
            if (existMember != null) {
                continue;
            }

            // 添加成员
            upsertGroupMember(addReqVO.getGroupId(), memberId, ImGroupMemberRoleEnum.MEMBER.getRole());

            ImGroupJoinRequestDO pendingRequest = groupJoinRequestMapper.selectPendingByGroupIdAndApplicantUserId(addReqVO.getGroupId(), memberId);
            if (pendingRequest != null) {
                pendingRequest.setStatus(ImGroupJoinRequestStatusEnum.APPROVED.getStatus());
                pendingRequest.setHandledBy(userId);
                pendingRequest.setHandledTime(LocalDateTime.now());
                pendingRequest.setRejectReason(null);
                groupJoinRequestMapper.updateById(pendingRequest);
            }

            addedCount++;
            addedMemberIds.add(memberId);
        }

        // 更新群成员数量
        if (addedCount > 0) {
            group.setMemberCount(group.getMemberCount() + addedCount);
            groupMapper.updateById(group);

            ImGroupConversationRefreshMessage refreshMessage = new ImGroupConversationRefreshMessage();
            refreshMessage.setAction("UPSERT");
            refreshMessage.setOperatorUserId(userId);
            refreshMessage.setGroupId(addReqVO.getGroupId());
            refreshMessage.setMemberIds(addedMemberIds);
            refreshMessage.setConversationType(ImConversationTypeEnum.GROUP.getType());
            groupConversationRefreshProducer.sendAfterCommit(refreshMessage);

            final String tipContent = buildGroupMembersAddedTipContent(addedMemberIds);
            final String tipExtra = buildGroupMembersAddedTipExtra(addedMemberIds);
            runAfterCommit(() -> {
                persistGroupSystemTipConversationUpdate(addReqVO.getGroupId(), userId, tipContent, tipContent, tipExtra);
                pushGroupMemberAddedNotify(addReqVO.getGroupId(), addedMemberIds, userId, tipContent, tipExtra);
            });
        }

        log.info("[ImGroupService] 添加群成员成功, groupId: {}, addedCount: {}", addReqVO.getGroupId(), addedCount);
        log.info("[ImGroupService][批量拉人审计] 操作人: {}, 群ID: {}, 群名: {}, 拉入成员数: {}, 成员ID列表: {}, 操作时间: {}",
                userId, addReqVO.getGroupId(), group.getName(), addedCount, addedMemberIds, LocalDateTime.now());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeGroupMember(Long userId, Long groupId, Long memberUserId) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查操作者是群成员（操作类方法：严格校验）
        assertIsGroupMember(userId, groupId);
        
        // 检查权限(只有群主和管理员可以移除成员)
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null || 
            (!ImGroupMemberRoleEnum.isOwner(groupUser.getRole()) && 
             !ImGroupMemberRoleEnum.isAdmin(groupUser.getRole()))) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 不能移除群主
        if (group.getOwnerId().equals(memberUserId)) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 查询要移除的成员
        ImGroupUserDO memberToRemove = groupUserMapper.selectByGroupIdAndUserId(groupId, memberUserId);
        if (memberToRemove == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 删除群成员
        deleteGroupMemberRelation(groupId, memberUserId, memberToRemove.getId());

        // 更新群成员数量
        group.setMemberCount(group.getMemberCount() - 1);
        groupMapper.updateById(group);

        ImChatDO chat = chatMapper.selectGroupChat(groupId, 2);
        Long chatId = chat != null ? chat.getId() : null;
        ImGroupConversationRefreshMessage refreshMessage = new ImGroupConversationRefreshMessage();
        refreshMessage.setAction("DELETE");
        refreshMessage.setOperatorUserId(userId);
        refreshMessage.setGroupId(groupId);
        refreshMessage.setChatId(chatId);
        refreshMessage.setMemberIds(java.util.Collections.singletonList(memberUserId));
        refreshMessage.setConversationType(ImConversationTypeEnum.GROUP.getType());
        groupConversationRefreshProducer.sendAfterCommit(refreshMessage);

        final String tipContent = buildGroupMemberRemovedTipContent(memberToRemove, memberUserId);
        final String tipExtra = buildGroupMemberRemovedTipExtra(memberToRemove, memberUserId);
        runAfterCommit(() -> {
            persistGroupSystemTipConversationUpdate(groupId, userId, tipContent, tipContent, tipExtra);
            pushGroupMemberRemovedNotify(groupId, memberUserId, userId, tipContent, tipExtra);
        });

        log.info("[ImGroupService] 移除群成员成功, groupId: {}, memberUserId: {}, 剩余成员数: {}",
                groupId, memberUserId, group.getMemberCount());
    }

    @Override
    public List<AppImGroupMemberRespVO> getGroupMembers(Long userId, Long groupId) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 查看类方法：不强制要求当前用户是群成员，允许被踢/退群用户查看群成员列表（只读）
        // 查询所有群成员
        List<ImGroupUserDO> members = groupUserMapper.selectListByGroupId(groupId);
        
        // 转换为VO并填充用户信息
        return members.stream().map(member -> {
            AppImGroupMemberRespVO respVO = BeanUtils.toBean(member, AppImGroupMemberRespVO.class);
            
            // 填充用户信息
            AdminUserDO user = userMapper.selectById(member.getUserId());
            if (user != null) {
                respVO.setUserNickname(user.getNickname());
                respVO.setUserAvatar(user.getAvatar());
                // 填充部门名称
                if (user.getDeptId() != null) {
                    // TODO: 查询部门名称
                    respVO.setDeptName("");
                }
            }
            
            // 兼容历史前端：nickname 为空时回填 userNickname，避免展示“未知”
            if ((respVO.getNickname() == null || respVO.getNickname().trim().isEmpty())
                    && respVO.getUserNickname() != null && !respVO.getUserNickname().trim().isEmpty()) {
                respVO.setNickname(respVO.getUserNickname());
            }
            // 保证两个字段至少有一个可用
            if ((respVO.getUserNickname() == null || respVO.getUserNickname().trim().isEmpty())
                    && respVO.getNickname() != null && !respVO.getNickname().trim().isEmpty()) {
                respVO.setUserNickname(respVO.getNickname());
            }

            return respVO;
        }).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setGroupMemberRole(Long userId, Long groupId, Long memberUserId, Integer role) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查操作者是群成员（操作类方法：严格校验）
        assertIsGroupMember(userId, groupId);
        
        // 检查权限(只有群主可以设置角色)
        if (!group.getOwnerId().equals(userId)) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 查询要设置的成员
        ImGroupUserDO member = groupUserMapper.selectByGroupIdAndUserId(groupId, memberUserId);
        if (member == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 不能修改群主角色
        if (ImGroupMemberRoleEnum.isOwner(member.getRole())) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 更新角色
        member.setRole(role);
        groupUserMapper.updateById(member);

        // 发送角色变更通知（系统消息）
        notifyRoleChange(group, userId, memberUserId, role);

        log.info("[ImGroupService] 设置群成员角色成功, groupId: {}, memberUserId: {}, role: {}", 
                groupId, memberUserId, role);
    }

    /**
     * 发送角色变更通知
     */
    private void notifyRoleChange(ImGroupDO group, Long operatorId, Long targetUserId, Integer newRole) {
        try {
            // 获取操作者信息
            AdminUserDO operator = userMapper.selectById(operatorId);
            AdminUserDO targetUser = userMapper.selectById(targetUserId);
            if (operator == null || targetUser == null) {
                return;
            }
            
            // 获取群的会话
            ImChatDO chat = chatMapper.selectGroupChat(group.getId(), ImConversationTypeEnum.GROUP.getType());
            if (chat == null) {
                return;
            }
            
            // 构建系统消息内容
            String roleName = ImGroupMemberRoleEnum.isAdmin(newRole) ? "管理员" : "普通成员";
            String content = String.format("\"%s\" 将 \"%s\" 设置为 %s",
                    operator.getNickname(), targetUser.getNickname(), roleName);
            String eventKey = ImGroupMemberRoleEnum.isAdmin(newRole)
                    ? ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_ROLE_SET_ADMIN
                    : ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_ROLE_SET_MEMBER;
            Map<String, Object> params = new LinkedHashMap<>();
            params.put("operatorName", operator.getNickname());
            params.put("targetName", targetUser.getNickname());
            String extra = imSystemMessageI18nSupport.attachI18n(null, eventKey, params);
            
            LocalDateTime now = LocalDateTime.now();
            // 分配sequence
            Long sequence = chatMapper.nextSequence(chat.getId());
            ImChatMessageDO sysMessage = buildSystemTipMessage(chat.getId(), sequence, content, extra, now);
            chatMessageMapper.insert(sysMessage);
            
            log.info("[ImGroupService] 角色变更通知已发送, groupId: {}, targetUserId: {}, newRole: {}", 
                    group.getId(), targetUserId, newRole);
        } catch (Exception e) {
            log.warn("[ImGroupService] 发送角色变更通知失败, groupId: {}, targetUserId: {}, error: {}", 
                    group.getId(), targetUserId, e.getMessage());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setGroupMemberMuted(Long userId, Long groupId, Long memberUserId, Boolean muted) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查操作者是群成员（操作类方法：严格校验）
        assertIsGroupMember(userId, groupId);
        
        // 检查权限(只有群主和管理员可以禁言)
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null || 
            (!ImGroupMemberRoleEnum.isOwner(groupUser.getRole()) && 
             !ImGroupMemberRoleEnum.isAdmin(groupUser.getRole()))) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 查询要禁言的成员
        ImGroupUserDO member = groupUserMapper.selectByGroupIdAndUserId(groupId, memberUserId);
        if (member == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 不能禁言群主
        if (ImGroupMemberRoleEnum.isOwner(member.getRole())) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 显式更新 muteEndTime，避免 updateById 在空值场景下无法把禁言时间清空。
        LocalDateTime targetMuteEndTime = Boolean.TRUE.equals(muted) ? LocalDateTime.now().plusHours(24) : null;
        int updatedRows = groupUserMapper.update(null, new LambdaUpdateWrapper<ImGroupUserDO>()
                .eq(ImGroupUserDO::getId, member.getId())
                .eq(ImGroupUserDO::getGroupId, groupId)
                .eq(ImGroupUserDO::getUserId, memberUserId)
                .set(ImGroupUserDO::getMuteEndTime, targetMuteEndTime));
        if (updatedRows <= 0) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }
        member.setMuteEndTime(targetMuteEndTime);

        final LocalDateTime finalMuteEndTime = targetMuteEndTime;
        final String tipContent = buildGroupMemberMuteTipContent(member, memberUserId, muted, finalMuteEndTime);
        final String tipExtra = buildGroupMemberMuteTipExtra(member, memberUserId, muted, finalMuteEndTime);
        runAfterCommit(() -> {
            persistGroupSystemTipConversationUpdate(groupId, userId, tipContent, tipContent, tipExtra);
            pushGroupMemberMuteChangedNotify(groupId, memberUserId, muted, finalMuteEndTime, userId, tipContent, tipExtra);
        });

        log.info("[ImGroupService] 设置群成员禁言成功, groupId: {}, memberUserId: {}, muted: {}", 
                groupId, memberUserId, muted);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void muteAll(Long userId, Long groupId, Boolean muted) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查权限(只有群主和管理员可以全员禁言)
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null || 
            (!ImGroupMemberRoleEnum.isOwner(groupUser.getRole()) && 
             !ImGroupMemberRoleEnum.isAdmin(groupUser.getRole()))) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 更新群组全员禁言状态
        group.setMuteAll(muted);
        groupMapper.updateById(group);

        final String tipContent = Boolean.TRUE.equals(muted)
                ? "已开启全员禁言，只有群主和管理员可以发言"
                : "已解除全员禁言";
        final String tipExtra = imSystemMessageI18nSupport.attachI18n(null,
                Boolean.TRUE.equals(muted)
                        ? ImSystemMessageI18nSupport.EVENT_GROUP_MUTE_ALL_ENABLED
                        : ImSystemMessageI18nSupport.EVENT_GROUP_MUTE_ALL_DISABLED,
                Collections.emptyMap());
        runAfterCommit(() -> {
            persistGroupSystemTipConversationUpdate(groupId, userId, tipContent, tipContent, tipExtra);
            pushGroupMuteAllChangedNotify(groupId, muted, userId, tipContent, tipExtra);
        });

        log.info("[ImGroupService] 设置全员禁言成功, groupId: {}, muted: {}", groupId, muted);
    }

    private void pushGroupMemberMuteChangedNotify(Long groupId, Long memberUserId, Boolean muted,
                                                  LocalDateTime muteEndTime, Long operatorUserId,
                                                  String tipContent, String tipExtra) {
        List<Long> memberIds = getGroupMemberIds(groupId);
        if (CollUtil.isEmpty(memberIds)) {
            return;
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        String extra = JSONUtil.createObj()
                .set("action", "group_member_mute_changed")
                .set("groupId", String.valueOf(groupId))
                .set("memberUserId", String.valueOf(memberUserId))
                .set("muted", Boolean.TRUE.equals(muted))
                .set("muteEndTime", muteEndTime != null ? muteEndTime.toString() : "")
                .set("operatorUserId", operatorUserId != null ? String.valueOf(operatorUserId) : "")
                .set("tipContent", tipContent != null ? tipContent : "")
                .toString();
        extra = mergeSystemNotifyI18n(extra, tipExtra);
        TextMessage body = TextMessage.newBuilder().setContent("GROUP_MEMBER_MUTE_CHANGED").build();
        for (Long targetUserId : memberIds) {
            try {
                messageSender.sendToUserWithExtra(targetUserId, MessageType.SYSTEM_NOTIFY, body,
                        0L, targetUserId, groupId, tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送群成员禁言状态失败, groupId: {}, targetUserId: {}, error: {}",
                        groupId, targetUserId, e.getMessage(), e);
            }
        }
    }

    private void pushGroupMuteAllChangedNotify(Long groupId, Boolean muted, Long operatorUserId,
                                               String tipContent, String tipExtra) {
        List<Long> memberIds = getGroupMemberIds(groupId);
        if (CollUtil.isEmpty(memberIds)) {
            return;
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        String extra = JSONUtil.createObj()
                .set("action", "group_mute_all_changed")
                .set("groupId", String.valueOf(groupId))
                .set("muted", Boolean.TRUE.equals(muted))
                .set("operatorUserId", operatorUserId != null ? String.valueOf(operatorUserId) : "")
                .set("tipContent", tipContent != null ? tipContent : "")
                .toString();
        extra = mergeSystemNotifyI18n(extra, tipExtra);
        TextMessage body = TextMessage.newBuilder().setContent("GROUP_MUTE_ALL_CHANGED").build();
        for (Long targetUserId : memberIds) {
            try {
                messageSender.sendToUserWithExtra(targetUserId, MessageType.SYSTEM_NOTIFY, body,
                        0L, targetUserId, groupId, tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送全员禁言状态失败, groupId: {}, targetUserId: {}, error: {}",
                        groupId, targetUserId, e.getMessage(), e);
            }
        }
    }

    private void pushGroupMemberAddedNotify(Long groupId, List<Long> addedMemberIds, Long operatorUserId,
                                            String tipContent, String tipExtra) {
        List<Long> memberIds = getGroupMemberIds(groupId);
        if (CollUtil.isEmpty(memberIds)) {
            return;
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        String extra = JSONUtil.createObj()
                .set("action", "group_member_added")
                .set("groupId", String.valueOf(groupId))
                .set("memberUserIds", addedMemberIds != null ? addedMemberIds.stream().map(String::valueOf).collect(Collectors.toList()) : new ArrayList<>())
                .set("operatorUserId", operatorUserId != null ? String.valueOf(operatorUserId) : "")
                .set("tipContent", tipContent != null ? tipContent : "")
                .toString();
        extra = mergeSystemNotifyI18n(extra, tipExtra);
        TextMessage body = TextMessage.newBuilder().setContent("GROUP_MEMBER_ADDED").build();
        for (Long targetUserId : memberIds) {
            try {
                messageSender.sendToUserWithExtra(targetUserId, MessageType.SYSTEM_NOTIFY, body,
                        0L, targetUserId, groupId, tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送群成员新增状态失败, groupId: {}, targetUserId: {}, error: {}",
                        groupId, targetUserId, e.getMessage(), e);
            }
        }
    }

    private void pushGroupMemberRemovedNotify(Long groupId, Long memberUserId, Long operatorUserId,
                                              String tipContent, String tipExtra) {
        List<Long> memberIds = new ArrayList<>(getGroupMemberIds(groupId));
        if (memberUserId != null && !memberIds.contains(memberUserId)) {
            memberIds.add(memberUserId);
        }
        if (CollUtil.isEmpty(memberIds)) {
            return;
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        String extra = JSONUtil.createObj()
                .set("action", "group_member_removed")
                .set("groupId", String.valueOf(groupId))
                .set("memberUserId", memberUserId != null ? String.valueOf(memberUserId) : "")
                .set("operatorUserId", operatorUserId != null ? String.valueOf(operatorUserId) : "")
                .set("tipContent", tipContent != null ? tipContent : "")
                .toString();
        extra = mergeSystemNotifyI18n(extra, tipExtra);
        TextMessage body = TextMessage.newBuilder().setContent("GROUP_MEMBER_REMOVED").build();
        for (Long targetUserId : memberIds) {
            try {
                messageSender.sendToUserWithExtra(targetUserId, MessageType.SYSTEM_NOTIFY, body,
                        0L, targetUserId, groupId, tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送群成员移除状态失败, groupId: {}, targetUserId: {}, error: {}",
                        groupId, targetUserId, e.getMessage(), e);
            }
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void transferGroupOwner(Long userId, Long groupId, Long newOwnerId) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查权限(只有群主可以转让)
        if (!group.getOwnerId().equals(userId)) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 查询新群主
        ImGroupUserDO newOwner = groupUserMapper.selectByGroupIdAndUserId(groupId, newOwnerId);
        if (newOwner == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 查询原群主
        ImGroupUserDO oldOwner = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);

        // 更新群组群主
        group.setOwnerId(newOwnerId);
        groupMapper.updateById(group);

        // 更新新群主角色
        newOwner.setRole(ImGroupMemberRoleEnum.OWNER.getRole());
        groupUserMapper.updateById(newOwner);

        // 更新原群主角色为普通成员
        if (oldOwner != null) {
            oldOwner.setRole(ImGroupMemberRoleEnum.MEMBER.getRole());
            groupUserMapper.updateById(oldOwner);
        }

        String tipContent = buildGroupOwnerTransferredTipContent(newOwnerId, newOwner);
        String tipExtra = buildGroupOwnerTransferredTipExtra(newOwnerId, newOwner);
        persistGroupSystemTipConversationUpdate(groupId, userId, tipContent, tipContent, tipExtra);
        pushGroupOwnerTransferredNotify(groupId, userId, newOwnerId, tipContent, tipExtra);

        log.info("[ImGroupService] 转让群主成功, groupId: {}, oldOwnerId: {}, newOwnerId: {}", 
                groupId, userId, newOwnerId);
    }

    @Override
    public List<Long> getGroupMemberIds(Long groupId) {
        List<ImGroupUserDO> members = groupUserMapper.selectListByGroupId(groupId);
        return members.stream()
                .map(ImGroupUserDO::getUserId)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImGroupInviteRespVO generateInviteCode(Long userId, AppImGroupInviteGenerateReqVO reqVO) {
        Long groupId = reqVO.getGroupId();
        
        // 1. 验证群组存在
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 2. 验证用户是群成员（操作类方法：严格校验）
        assertIsGroupMember(userId, groupId);

        // 3. 查询是否已有有效邀请码
        ImGroupInviteDO existingInvite = groupInviteMapper.selectValidByGroupId(groupId);
        if (existingInvite != null) {
            // 返回现有邀请码
            return buildInviteRespVO(existingInvite, groupId);
        }

        // 4. 生成新邀请码
        String inviteCode = generateUniqueInviteCode();
        LocalDateTime expireTime = reqVO.getExpireHours() != null && reqVO.getExpireHours() > 0
                ? LocalDateTime.now().plusHours(reqVO.getExpireHours())
                : PERMANENT_EXPIRE_TIME;

        ImGroupInviteDO invite = ImGroupInviteDO.builder()
                .groupId(groupId)
                .inviteCode(inviteCode)
                .creatorId(userId)
                .expireTime(expireTime)
                .maxUseCount(reqVO.getMaxUseCount())
                .usedCount(0)
                .status(ImGroupInviteStatusEnum.VALID.getStatus())
                .build();

        groupInviteMapper.insert(invite);

        log.info("[ImGroupService] 生成群邀请码成功, groupId: {}, inviteCode: {}, expireTime: {}", 
                groupId, inviteCode, expireTime);
        log.info("[ImGroupService][邀请码生成审计] 操作人: {}, 群ID: {}, 群名: {}, 邀请码: {}, 过期时间: {}, 最大使用次数: {}, 生成时间: {}",
                userId, groupId, group.getName(), inviteCode, expireTime, reqVO.getMaxUseCount(), LocalDateTime.now());

        return buildInviteRespVO(invite, groupId);
    }

    @Override
    public AppImGroupInviteVerifyRespVO verifyInviteCode(String inviteCode) {
        Long userId = null;
        try {
            userId = com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId();
        } catch (Exception ignored) {
        }

        if (userId != null) {
            if (!tryAcquireRateLimit(verifyInviteRateLimiter, String.valueOf(userId), VERIFY_INVITE_RATE_LIMIT, VERIFY_INVITE_RATE_WINDOW_MS)) {
                log.warn("[ImGroupService] 邀请码验证触发限流, userId: {}, inviteCode: {}", userId, inviteCode);
                AppImGroupInviteVerifyRespVO respVO = new AppImGroupInviteVerifyRespVO();
                return buildInviteVerifyFailure(respVO, GROUP_INVITE_CODE_RATE_LIMIT_EXCEEDED);
            }
        }

        AppImGroupInviteVerifyRespVO respVO = new AppImGroupInviteVerifyRespVO();

        ImGroupInviteDO invite = groupInviteMapper.selectByInviteCode(inviteCode);
        if (invite == null) {
            return buildInviteVerifyFailure(respVO, GROUP_INVITE_CODE_NOT_EXISTS);
        }

        if (!ImGroupInviteStatusEnum.isValid(invite.getStatus())) {
            return buildInviteVerifyFailure(respVO, GROUP_INVITE_CODE_DISABLED);
        }

        if (!PERMANENT_EXPIRE_TIME.equals(invite.getExpireTime()) 
                && invite.getExpireTime().isBefore(LocalDateTime.now())) {
            return buildInviteVerifyFailure(respVO, GROUP_INVITE_CODE_EXPIRED);
        }

        if (invite.getMaxUseCount() > 0 && invite.getUsedCount() >= invite.getMaxUseCount()) {
            return buildInviteVerifyFailure(respVO, GROUP_INVITE_CODE_USAGE_LIMIT_REACHED);
        }

        ImGroupDO group = groupMapper.selectById(invite.getGroupId());
        if (group == null) {
            return buildInviteVerifyFailure(respVO, GROUP_NOT_EXISTS);
        }
        if (!ImGroupStatusEnum.isNormal(group.getStatus())) {
            return buildInviteVerifyFailure(respVO, GROUP_DISSOLVED);
        }

        Long currentTenantId = resolveTenantId();
        Long groupTenantId = group.getTenantId() != null ? group.getTenantId() : 0L;
        if (!Objects.equals(currentTenantId, groupTenantId)) {
            return buildInviteVerifyFailure(respVO, GROUP_INVITE_CODE_TENANT_MISMATCH);
        }

        respVO.setValid(true);
        respVO.setGroupId(group.getId());
        respVO.setGroupName(group.getName());
        respVO.setGroupAvatar(group.getAvatar());
        respVO.setMemberCount(group.getMemberCount());
        respVO.setNeedApproval(group.getNeedApproval());
        respVO.setExpireTime(invite.getExpireTime());

        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImGroupInviteJoinRespVO joinGroupByInviteCode(Long userId, String inviteCode) {
        if (!tryAcquireRateLimit(joinGroupRateLimiter, String.valueOf(userId), JOIN_GROUP_RATE_LIMIT, JOIN_GROUP_RATE_WINDOW_MS)) {
            log.warn("[ImGroupService] 入群申请触发限流, userId: {}, inviteCode: {}", userId, inviteCode);
            throw exception(GROUP_JOIN_REQUEST_RATE_LIMIT_EXCEEDED);
        }

        AppImGroupInviteVerifyRespVO verifyResult = verifyInviteCode(inviteCode);
        if (!verifyResult.getValid()) {
            throwInviteVerifyFailure(verifyResult);
        }

        Long groupId = verifyResult.getGroupId();

        Long currentTenantId = resolveTenantId();
        ImGroupDO groupForTenantCheck = groupMapper.selectById(groupId);
        if (groupForTenantCheck != null) {
            Long groupTenantId = groupForTenantCheck.getTenantId() != null ? groupForTenantCheck.getTenantId() : 0L;
            if (!Objects.equals(currentTenantId, groupTenantId)) {
                log.warn("[ImGroupService] 租户隔离校验失败, userId: {}, userTenantId: {}, groupId: {}, groupTenantId: {}",
                        userId, currentTenantId, groupId, groupTenantId);
                throw exception(GROUP_INVITE_CODE_TENANT_MISMATCH);
            }
        }

        ImGroupUserDO existingMember = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (existingMember != null) {
            throw exception(GROUP_MEMBER_ALREADY_EXISTS);
        }

        ImGroupDO group = groupMapper.selectById(groupId);
        if (group.getMemberCount() >= group.getMaxMemberCount()) {
            throw exception(GROUP_MEMBER_FULL);
        }

        AppImGroupInviteJoinRespVO respVO = new AppImGroupInviteJoinRespVO();
        respVO.setGroupId(groupId);

        if (verifyResult.getNeedApproval()) {
            ImGroupJoinRequestDO pendingRequest = groupJoinRequestMapper.selectPendingByGroupIdAndApplicantUserId(groupId, userId);
            if (pendingRequest == null) {
                pendingRequest = ImGroupJoinRequestDO.builder()
                        .groupId(groupId)
                        .applicantUserId(userId)
                        .inviteCode(inviteCode)
                        .status(ImGroupJoinRequestStatusEnum.PENDING.getStatus())
                        .build();
                groupJoinRequestMapper.insert(pendingRequest);
                ImGroupDO finalGroup = group;
                ImGroupJoinRequestDO finalPendingRequest = pendingRequest;
                runAfterCommit(() -> notifyJoinRequestCreated(finalGroup, finalPendingRequest));
            }
            respVO.setResultType(2);
            respVO.setMessage(getI18nMessage("im.group.invite.join.pending",
                    "已提交入群申请，请等待管理员审批"));
            respVO.setRequestId(pendingRequest.getId());
            return respVO;
        }

        addApprovedMemberToGroup(group, userId, userId);

        ImGroupInviteDO invite = groupInviteMapper.selectByInviteCode(inviteCode);
        invite.setUsedCount(invite.getUsedCount() + 1);
        groupInviteMapper.updateById(invite);

        log.info("[ImGroupService] 通过邀请码加入群成功, userId: {}, groupId: {}, inviteCode: {}", 
                userId, groupId, inviteCode);
        respVO.setResultType(1);
        respVO.setMessage(getI18nMessage("im.group.invite.join.success", "加入成功"));
        return respVO;
    }

    private AppImGroupInviteVerifyRespVO buildInviteVerifyFailure(AppImGroupInviteVerifyRespVO respVO,
                                                                  com.shengyu.framework.common.exception.ErrorCode errorCode) {
        respVO.setValid(false);
        respVO.setErrorCode(errorCode.getCode());
        respVO.setErrorMessage(exception(errorCode).getMessage());
        return respVO;
    }

    private void throwInviteVerifyFailure(AppImGroupInviteVerifyRespVO verifyResult) {
        Integer errorCode = verifyResult.getErrorCode();
        if (errorCode == null) {
            throw exception(GROUP_INVITE_CODE_INVALID);
        }
        if (Objects.equals(errorCode, GROUP_INVITE_CODE_NOT_EXISTS.getCode())) {
            throw exception(GROUP_INVITE_CODE_NOT_EXISTS);
        }
        if (Objects.equals(errorCode, GROUP_INVITE_CODE_DISABLED.getCode())) {
            throw exception(GROUP_INVITE_CODE_DISABLED);
        }
        if (Objects.equals(errorCode, GROUP_INVITE_CODE_EXPIRED.getCode())) {
            throw exception(GROUP_INVITE_CODE_EXPIRED);
        }
        if (Objects.equals(errorCode, GROUP_INVITE_CODE_USAGE_LIMIT_REACHED.getCode())) {
            throw exception(GROUP_INVITE_CODE_USAGE_LIMIT_REACHED);
        }
        if (Objects.equals(errorCode, GROUP_NOT_EXISTS.getCode())) {
            throw exception(GROUP_NOT_EXISTS);
        }
        if (Objects.equals(errorCode, GROUP_DISSOLVED.getCode())) {
            throw exception(GROUP_DISSOLVED);
        }
        if (Objects.equals(errorCode, GROUP_INVITE_CODE_TENANT_MISMATCH.getCode())) {
            throw exception(GROUP_INVITE_CODE_TENANT_MISMATCH);
        }
        throw exception(GROUP_INVITE_CODE_INVALID);
    }

    private String getI18nMessage(String key, String defaultMessage) {
        return messageSource.getMessage(key, null, defaultMessage, LocaleContextHolder.getLocale());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImGroupInviteRespVO getGroupInviteCode(Long userId, Long groupId) {
        // 1. 验证群组存在
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 2. 验证用户是群成员（操作类方法：严格校验）
        assertIsGroupMember(userId, groupId);

        // 3. 查询有效邀请码
        ImGroupInviteDO invite = groupInviteMapper.selectValidByGroupId(groupId);
        
        // 4. 如果没有有效邀请码，自动生成一个
        if (invite == null) {
            log.info("[ImGroupService] 群组没有有效邀请码，自动生成, groupId: {}", groupId);
            
            // 生成邀请码
            String inviteCode = generateUniqueInviteCode();
            LocalDateTime expireTime = PERMANENT_EXPIRE_TIME;
            
            invite = ImGroupInviteDO.builder()
                    .id(cn.hutool.core.util.IdUtil.getSnowflakeNextId())
                    .groupId(groupId)
                    .inviteCode(inviteCode)
                    .creatorId(userId)
                    .expireTime(expireTime)
                    .maxUseCount(0) // 不限制使用次数
                    .usedCount(0)
                    .status(ImGroupInviteStatusEnum.VALID.getStatus())
                    .build();
            
            groupInviteMapper.insert(invite);
            log.info("[ImGroupService] 自动生成邀请码成功, inviteCode: {}", inviteCode);
        }

        return buildInviteRespVO(invite, groupId);
    }

    /**
     * 生成唯一邀请码
     */
    private String generateUniqueInviteCode() {
        String inviteCode;
        int maxRetries = 10;
        int retries = 0;

        do {
            inviteCode = generateInviteCode();
            ImGroupInviteDO existing = groupInviteMapper.selectByInviteCode(inviteCode);
            if (existing == null) {
                return inviteCode;
            }
            retries++;
        } while (retries < maxRetries);

        throw new RuntimeException("生成邀请码失败，请重试");
    }

    /**
     * 生成邀请码
     * 格式: GRP + 时间戳(6位Base36) + 随机字符串(8位) + 校验码(2位)
     */
    private String generateInviteCode() {
        // 1. 前缀
        String prefix = "GRP";

        // 2. 时间戳（Base36编码，6位）
        long timestamp = System.currentTimeMillis() / 1000;
        String timeStr = Long.toString(timestamp, 36).toUpperCase();
        timeStr = timeStr.substring(Math.max(0, timeStr.length() - 6));

        // 3. 随机字符串（8位）
        String random = cn.hutool.core.util.RandomUtil.randomString(
                "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", 8);

        // 4. 校验码（2位）
        String data = prefix + timeStr + random;
        int crc = data.hashCode() & 0xFF;
        String checksum = String.format("%02X", crc);

        return data + checksum;
    }

    /**
     * 构建邀请码响应VO
     */
    private AppImGroupInviteRespVO buildInviteRespVO(ImGroupInviteDO invite, Long groupId) {
        AppImGroupInviteRespVO respVO = new AppImGroupInviteRespVO();
        respVO.setInviteCode(invite.getInviteCode());
        // 返回前端页面路径（uniapp 页面路径）
        respVO.setQrCodeUrl(String.format("/pages/message/join-group?code=%s&groupId=%d",
                invite.getInviteCode(), groupId));
        respVO.setExpireTime(invite.getExpireTime());
        respVO.setUsedCount(invite.getUsedCount());
        respVO.setMaxUseCount(invite.getMaxUseCount());
        ImGroupDO group = groupMapper.selectById(groupId);
        respVO.setNeedApproval(group != null && Boolean.TRUE.equals(group.getNeedApproval()));
        return respVO;
    }

    @Override
    public String getQRCodeContentByInviteCode(String inviteCode, Long groupId) {
        // 1. 查询邀请码信息
        ImGroupInviteDO invite = groupInviteMapper.selectByInviteCode(inviteCode);
        if (invite == null) {
            throw exception(GROUP_INVITE_CODE_NOT_EXISTS);
        }

        // 2. 使用邀请码对应的群组ID（如果参数没有传）
        if (groupId == null) {
            groupId = invite.getGroupId();
        }

        // 3. 返回前端页面路径（uniapp 页面路径）
        return String.format("/pages/message/join-group?code=%s&groupId=%d", inviteCode, groupId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateGroupNotice(Long userId, AppImGroupNoticeUpdateReqVO reqVO) {
        log.info("[ImGroupService] 开始更新群公告, userId: {}, groupId: {}", userId, reqVO.getGroupId());
        
        // 1. 查询群组
        ImGroupDO group = groupMapper.selectById(reqVO.getGroupId());
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }
        
        // 2. 检查群组状态
        if (ImGroupStatusEnum.DISSOLVED.getStatus().equals(group.getStatus())) {
            throw exception(GROUP_DISSOLVED);
        }
        
        // 3. 查询用户在群中的角色
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(reqVO.getGroupId(), userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }
        
        // 4. 检查权限：只有群主和管理员可以修改群公告
        if (!ImGroupMemberRoleEnum.OWNER.getRole().equals(groupUser.getRole()) 
                && !ImGroupMemberRoleEnum.ADMIN.getRole().equals(groupUser.getRole())) {
            throw exception(GROUP_PERMISSION_DENIED);
        }
        
        // 5. 更新群公告和置顶状态
        ImGroupDO updateGroup = new ImGroupDO();
        updateGroup.setId(reqVO.getGroupId());
        updateGroup.setNotice(reqVO.getNotice());
        updateGroup.setNoticePinned(reqVO.getPinNotice() != null ? reqVO.getPinNotice() : false);
        groupMapper.updateById(updateGroup);
        
        log.info("[ImGroupService] 群公告更新成功, groupId: {}, notice: {}, pinned: {}, notifyMembers: {}", 
                reqVO.getGroupId(), 
                reqVO.getNotice() != null && reqVO.getNotice().length() > 50 
                        ? reqVO.getNotice().substring(0, 50) + "..." 
                        : reqVO.getNotice(),
                reqVO.getPinNotice(),
                reqVO.getNotifyMembers());
        
        // 6. 如果需要推送通知：更新会话预览/未读，并推送角标与会话刷新
        if (Boolean.TRUE.equals(reqVO.getNotifyMembers()) && reqVO.getNotice() != null && !reqVO.getNotice().isEmpty()) {
            pushGroupNoticeConversationUpdate(userId, reqVO.getGroupId());
        }
    }

    private void pushGroupNoticeConversationUpdate(Long operatorUserId, Long groupId) {
        String preview = "[群公告有更新]";
        String tipContent = "群公告有更新";
        String tipExtra = imSystemMessageI18nSupport.attachI18n(null,
                ImSystemMessageI18nSupport.EVENT_GROUP_NOTICE_UPDATED,
                Collections.emptyMap());
        persistGroupSystemTipConversationUpdate(groupId, operatorUserId, preview, tipContent, tipExtra);
    }

    private void pushGroupConversationRefreshNotifyAfterCommit(Long groupId, Long tenantId, Long chatId,
                                                               Map<Long, Long> userCursorVersionMap, String logPrefix) {
        TextMessage body = TextMessage.newBuilder().setContent("").build();
        for (Map.Entry<Long, Long> entry : userCursorVersionMap.entrySet()) {
            Long targetUserId = entry.getKey();
            Long cursorVersion = entry.getValue();
            try {
                messageSender.sendToUser(targetUserId, MessageType.SYSTEM_NOTIFY, body,
                        0L, targetUserId, 0L, tenantId,
                        null, null, chatId,
                        cursorVersion, null);
                imBadgeService.pushBadgeUpdate(targetUserId);
            } catch (Exception e) {
                log.warn("[ImGroupService] {}提交后通知失败, groupId: {}, targetUserId: {}, error: {}",
                        logPrefix, groupId, targetUserId, e.getMessage(), e);
            }
        }
    }

    private void persistGroupSystemTipConversationUpdate(Long groupId, Long operatorUserId,
                                                         String preview, String tipContent, String tipExtra) {
        List<Long> memberIds = getGroupMemberIds(groupId);
        if (CollUtil.isEmpty(memberIds)) {
            return;
        }

        ImChatDO chat = chatMapper.selectGroupChat(groupId, ImConversationTypeEnum.GROUP.getType());
        if (chat == null) {
            log.warn("[ImGroupService] 群系统提示通知失败，群会话不存在, groupId: {}", groupId);
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        Long sequence = chatMapper.nextSequence(chat.getId());
        ImChatMessageDO tipMessage = buildSystemTipMessage(chat.getId(), sequence, tipContent, tipExtra, now);
        chatMessageMapper.insert(tipMessage);

        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        Map<Long, Long> userCursorVersionMap = new LinkedHashMap<>();
        for (Long targetUserId : memberIds) {
            try {
                int unreadDelta = Objects.equals(targetUserId, operatorUserId) ? 0 : 1;
                ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(targetUserId, chat.getId());
                if (chatUser != null) {
                    chatUserMapper.updateLastMessageAndIncrementUnread(
                            chatUser.getId(),
                            tipMessage.getId(),
                            sequence,
                            10,
                            preview,
                            now,
                            unreadDelta,
                            Boolean.TRUE.equals(chatUser.getNoDisturb())
                    );
                }

                Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, targetUserId);
                conversationUserStateMapper.upsertAfterMessage(
                        tenantId,
                        chat.getId(),
                        targetUserId,
                        cursorVersion,
                        unreadDelta,
                        null,
                        null,
                        tipMessage.getId(),
                        sequence,
                        10,
                        preview,
                        Boolean.FALSE,
                        now
                );
                // 操作者侧：推进已读水位，避免刷新后自己的操作出现未读角标
                if (Objects.equals(targetUserId, operatorUserId) && sequence != null) {
                    try {
                        chatUserMapper.markReadToSequence(targetUserId, chat.getId(), sequence);
                    } catch (Exception ignore) {
                        // ignore
                    }
                }

                userCursorVersionMap.put(targetUserId, cursorVersion);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送群系统提示会话更新失败, groupId: {}, targetUserId: {}, error: {}",
                        groupId, targetUserId, e.getMessage(), e);
            }
        }

        if (CollUtil.isNotEmpty(userCursorVersionMap)) {
            final Long tenantIdFinal = tenantId;
            final Long chatIdFinal = chat.getId();
            runAfterCommit(() -> pushGroupConversationRefreshNotifyAfterCommit(
                    groupId, tenantIdFinal, chatIdFinal, userCursorVersionMap, "群系统提示"));
        }
    }

    private String buildGroupMemberMuteTipContent(ImGroupUserDO member, Long memberUserId, Boolean muted, LocalDateTime muteEndTime) {
        String memberName = "";
        if (member != null && member.getNickname() != null) {
            memberName = member.getNickname().trim();
        }
        if (memberName.isEmpty() && memberUserId != null) {
            AdminUserDO targetUser = userMapper.selectById(memberUserId);
            if (targetUser != null && targetUser.getNickname() != null) {
                memberName = targetUser.getNickname().trim();
            }
        }
        if (memberName.isEmpty()) {
            memberName = "该成员";
        }
        if (Boolean.TRUE.equals(muted)) {
            if (muteEndTime != null) {
                return String.format("\"%s\" 已被禁言至 %s", memberName, muteEndTime.format(GROUP_MUTE_TIP_TIME_FORMATTER));
            }
            return String.format("\"%s\" 已被禁言", memberName);
        }
        return String.format("\"%s\" 已被解除禁言", memberName);
    }

    private String buildGroupMembersAddedTipContent(List<Long> addedMemberIds) {
        List<String> names = new ArrayList<>();
        if (CollUtil.isNotEmpty(addedMemberIds)) {
            for (Long memberUserId : addedMemberIds) {
                if (memberUserId == null) {
                    continue;
                }
                AdminUserDO user = userMapper.selectById(memberUserId);
                String nickname = user != null && user.getNickname() != null ? user.getNickname().trim() : "";
                if (!nickname.isEmpty()) {
                    names.add(nickname);
                }
            }
        }
        if (names.isEmpty()) {
            return "有新成员加入了群聊";
        }
        if (names.size() == 1) {
            return String.format("\"%s\" 加入了群聊", names.get(0));
        }
        if (names.size() == 2) {
            return String.format("\"%s\"、\"%s\" 加入了群聊", names.get(0), names.get(1));
        }
        return String.format("\"%s\"、\"%s\" 等%d人加入了群聊", names.get(0), names.get(1), names.size());
    }

    private String buildGroupMembersAddedTipExtra(List<Long> addedMemberIds) {
        List<String> names = new ArrayList<>();
        if (CollUtil.isNotEmpty(addedMemberIds)) {
            for (Long memberUserId : addedMemberIds) {
                if (memberUserId == null) {
                    continue;
                }
                AdminUserDO user = userMapper.selectById(memberUserId);
                String nickname = user != null && user.getNickname() != null ? user.getNickname().trim() : "";
                if (!nickname.isEmpty()) {
                    names.add(nickname);
                }
            }
        }
        Map<String, Object> params = new LinkedHashMap<>();
        String eventKey;
        if (names.isEmpty()) {
            params.put("firstName", "新成员");
            eventKey = ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_ADDED_ONE;
        } else if (names.size() == 1) {
            params.put("firstName", names.get(0));
            eventKey = ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_ADDED_ONE;
        } else if (names.size() == 2) {
            params.put("firstName", names.get(0));
            params.put("secondName", names.get(1));
            eventKey = ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_ADDED_TWO;
        } else {
            params.put("firstName", names.get(0));
            params.put("secondName", names.get(1));
            params.put("otherCount", String.valueOf(names.size() - 2));
            eventKey = ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_ADDED_MANY;
        }
        return imSystemMessageI18nSupport.attachI18n(null, eventKey, params);
    }

    private String buildGroupMemberRemovedTipContent(ImGroupUserDO member, Long memberUserId) {
        String memberName = "";
        if (member != null && member.getNickname() != null) {
            memberName = member.getNickname().trim();
        }
        if (memberName.isEmpty() && memberUserId != null) {
            AdminUserDO user = userMapper.selectById(memberUserId);
            if (user != null && user.getNickname() != null) {
                memberName = user.getNickname().trim();
            }
        }
        if (memberName.isEmpty()) {
            memberName = "该成员";
        }
        return String.format("\"%s\" 已被移出群聊", memberName);
    }

    private String buildGroupMemberRemovedTipExtra(ImGroupUserDO member, Long memberUserId) {
        String memberName = "";
        if (member != null && member.getNickname() != null) {
            memberName = member.getNickname().trim();
        }
        if (memberName.isEmpty() && memberUserId != null) {
            AdminUserDO user = userMapper.selectById(memberUserId);
            if (user != null && user.getNickname() != null) {
                memberName = user.getNickname().trim();
            }
        }
        if (memberName.isEmpty()) {
            memberName = "该成员";
        }
        Map<String, Object> params = new LinkedHashMap<>();
        params.put("memberName", memberName);
        return imSystemMessageI18nSupport.attachI18n(null,
                ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_REMOVED, params);
    }

    private String buildGroupOwnerTransferredTipContent(Long newOwnerId, ImGroupUserDO newOwner) {
        String memberName = "";
        if (newOwner != null && newOwner.getNickname() != null) {
            memberName = newOwner.getNickname().trim();
        }
        if (memberName.isEmpty() && newOwnerId != null) {
            AdminUserDO user = userMapper.selectById(newOwnerId);
            if (user != null && user.getNickname() != null) {
                memberName = user.getNickname().trim();
            }
        }
        if (memberName.isEmpty()) {
            memberName = "该成员";
        }
        return String.format("群主已转让给“%s”", memberName);
    }

    private String buildGroupOwnerTransferredTipExtra(Long newOwnerId, ImGroupUserDO newOwner) {
        String memberName = "";
        if (newOwner != null && newOwner.getNickname() != null) {
            memberName = newOwner.getNickname().trim();
        }
        if (memberName.isEmpty() && newOwnerId != null) {
            AdminUserDO user = userMapper.selectById(newOwnerId);
            if (user != null && user.getNickname() != null) {
                memberName = user.getNickname().trim();
            }
        }
        if (memberName.isEmpty()) {
            memberName = "该成员";
        }
        Map<String, Object> params = new LinkedHashMap<>();
        params.put("newOwnerName", memberName);
        params.put("newOwnerId", newOwnerId != null ? String.valueOf(newOwnerId) : "");
        return imSystemMessageI18nSupport.attachI18n(null,
                ImSystemMessageI18nSupport.EVENT_GROUP_OWNER_TRANSFERRED, params);
    }

    private String buildGroupMemberMuteTipExtra(ImGroupUserDO member, Long memberUserId,
                                                Boolean muted, LocalDateTime muteEndTime) {
        String memberName = "";
        if (member != null && member.getNickname() != null) {
            memberName = member.getNickname().trim();
        }
        if (memberName.isEmpty() && memberUserId != null) {
            AdminUserDO user = userMapper.selectById(memberUserId);
            if (user != null && user.getNickname() != null) {
                memberName = user.getNickname().trim();
            }
        }
        if (memberName.isEmpty()) {
            memberName = "该成员";
        }
        Map<String, Object> params = new LinkedHashMap<>();
        params.put("memberName", memberName);
        if (muteEndTime != null) {
            params.put("muteEndTime", muteEndTime.format(GROUP_MUTE_TIP_TIME_FORMATTER));
        }
        String eventKey;
        if (Boolean.TRUE.equals(muted)) {
            eventKey = muteEndTime != null
                    ? ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_MUTED_UNTIL
                    : ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_MUTED;
        } else {
            eventKey = ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_UNMUTED;
        }
        return imSystemMessageI18nSupport.attachI18n(null, eventKey, params);
    }

    private void pushGroupOwnerTransferredNotify(Long groupId, Long oldOwnerId, Long newOwnerId,
                                                 String tipContent, String tipExtra) {
        List<Long> memberIds = getGroupMemberIds(groupId);
        if (CollUtil.isEmpty(memberIds)) {
            return;
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        String extra = JSONUtil.createObj()
                .set("action", "group_owner_transferred")
                .set("groupId", String.valueOf(groupId))
                .set("oldOwnerId", oldOwnerId != null ? String.valueOf(oldOwnerId) : "")
                .set("newOwnerId", newOwnerId != null ? String.valueOf(newOwnerId) : "")
                .set("tipContent", tipContent != null ? tipContent : "")
                .toString();
        extra = mergeSystemNotifyI18n(extra, tipExtra);
        TextMessage body = TextMessage.newBuilder().setContent("GROUP_OWNER_TRANSFERRED").build();
        for (Long targetUserId : memberIds) {
            try {
                messageSender.sendToUserWithExtra(targetUserId, MessageType.SYSTEM_NOTIFY, body,
                        0L, targetUserId, groupId, tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送群主转让状态失败, groupId: {}, targetUserId: {}, error: {}",
                        groupId, targetUserId, e.getMessage(), e);
            }
        }
    }

    private void pushGroupDisbandedNotify(Long groupId, List<Long> memberIds, Long operatorUserId,
                                          String tipContent, String tipExtra) {
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        String extra = JSONUtil.createObj()
                .set("action", "group_disbanded")
                .set("groupId", String.valueOf(groupId))
                .set("operatorUserId", operatorUserId != null ? String.valueOf(operatorUserId) : "")
                .set("tipContent", tipContent != null ? tipContent : "")
                .toString();
        extra = mergeSystemNotifyI18n(extra, tipExtra);
        TextMessage body = TextMessage.newBuilder().setContent("GROUP_DISBANDED").build();
        for (Long targetUserId : memberIds) {
            if (operatorUserId != null && operatorUserId.equals(targetUserId)) {
                continue;
            }
            try {
                messageSender.sendToUserWithExtra(targetUserId, MessageType.SYSTEM_NOTIFY, body,
                        0L, targetUserId, groupId, tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送群解散状态失败, groupId: {}, targetUserId: {}, error: {}",
                        groupId, targetUserId, e.getMessage(), e);
            }
        }
    }

    private void pushGroupQuitNotify(Long groupId, Long quitUserId, String tipContent, String tipExtra) {
        List<Long> memberIds = new ArrayList<>(getGroupMemberIds(groupId));
        if (CollUtil.isEmpty(memberIds)) {
            return;
        }
        Long tenantId = TenantContextHolder.getTenantId();
        if (tenantId == null) {
            tenantId = 0L;
        }
        String extra = JSONUtil.createObj()
                .set("action", "group_member_removed")
                .set("groupId", String.valueOf(groupId))
                .set("userId", String.valueOf(quitUserId))
                .set("quitType", "self_quit")
                .set("tipContent", tipContent != null ? tipContent : "")
                .toString();
        extra = mergeSystemNotifyI18n(extra, tipExtra);
        TextMessage body = TextMessage.newBuilder().setContent("GROUP_MEMBER_REMOVED").build();
        for (Long targetUserId : memberIds) {
            try {
                messageSender.sendToUserWithExtra(targetUserId, MessageType.SYSTEM_NOTIFY, body,
                        0L, targetUserId, groupId, tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送成员退群状态失败, groupId: {}, targetUserId: {}, error: {}",
                        groupId, targetUserId, e.getMessage(), e);
            }
        }
    }

    private void runAfterCommit(Runnable task) {
        if (task == null) {
            return;
        }
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    task.run();
                }
            });
            return;
        }
        task.run();
    }

    /**
     * 统一构造群系统提示消息，避免字段漂移（仅使用 ImChatMessageDO 已定义字段）
     */
    private ImChatMessageDO buildSystemTipMessage(Long chatId, Long sequence, String content,
                                                  String extra, LocalDateTime sendTime) {
        ImChatMessageDO message = new ImChatMessageDO();
        message.setChatId(chatId);
        message.setSequence(sequence);
        message.setSenderId(0L);
        message.setMessageType(10);
        message.setContent(content);
        message.setExtra(extra);
        message.setSendTime(sendTime);
        message.setRev(1L);
        message.setStatus(ImMessageStatusEnum.SENT.getStatus());
        return message;
    }

    private String mergeSystemNotifyI18n(String notifyExtra, String tipExtra) {
        if (tipExtra == null || tipExtra.isEmpty()) {
            return notifyExtra;
        }
        try {
            JSONObject tipRoot = JSONUtil.parseObj(tipExtra);
            JSONObject tipI18n = tipRoot.getJSONObject("i18n");
            if (tipI18n == null) {
                return notifyExtra;
            }
            JSONObject notifyRoot = notifyExtra != null && !notifyExtra.isEmpty()
                    ? JSONUtil.parseObj(notifyExtra) : JSONUtil.createObj();
            notifyRoot.set("i18n", tipI18n);
            return notifyRoot.toString();
        } catch (Exception ignore) {
            return notifyExtra;
        }
    }

    @Override
    public String getAnnouncements(Long userId, Long groupId) {
        log.info("[ImGroupService] 查询群公告, userId: {}, groupId: {}", userId, groupId);
        
        // 1. 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }
        
        // 2. 查看类方法：不强制要求当前用户是群成员，允许被踢/退群用户查看群公告（只读）
        
        // 3. 返回群公告
        return group.getNotice();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setMemberNickname(Long userId, Long groupId, Long memberUserId, String nickname) {
        // 如果memberUserId为null，则设置自己的昵称
        Long targetUserId = memberUserId != null ? memberUserId : userId;
        
        log.info("[ImGroupService] 设置群成员昵称, userId: {}, groupId: {}, targetUserId: {}, nickname: {}", 
                userId, groupId, targetUserId, nickname);
        
        // 1. 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }
        
        // 2. 检查操作者是群成员（操作类方法：严格校验）
        assertIsGroupMember(userId, groupId);
        
        // 3. 查询操作者在群中的角色
        ImGroupUserDO operatorGroupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        
        // 3. 查询目标成员
        ImGroupUserDO targetGroupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, targetUserId);
        if (targetGroupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }
        
        // 4. 权限检查
        // 如果是设置自己的昵称，任何成员都可以
        // 如果是设置别人的昵称，只有群主可以
        if (!targetUserId.equals(userId)) {
            if (!ImGroupMemberRoleEnum.isOwner(operatorGroupUser.getRole())) {
                throw exception(GROUP_PERMISSION_DENIED);
            }
        }
        
        // 5. 更新昵称
        targetGroupUser.setNickname(nickname);
        groupUserMapper.updateById(targetGroupUser);
        
        log.info("[ImGroupService] 群成员昵称设置成功, groupId: {}, targetUserId: {}, nickname: {}", 
                groupId, targetUserId, nickname);
    }

    @Override
    public List<AppImGroupJoinRequestRespVO> getJoinRequests(Long userId, Long groupId, Integer status) {
        assertCanManageJoinRequests(userId, groupId);
        List<ImGroupJoinRequestDO> requests = groupJoinRequestMapper.selectListByGroupIdAndStatus(groupId, status);
        return requests.stream().map(this::buildJoinRequestRespVO).collect(Collectors.toList());
    }

    @Override
    public Long getPendingJoinRequestCount(Long userId, Long groupId) {
        assertCanManageJoinRequests(userId, groupId);
        return groupJoinRequestMapper.selectPendingCountByGroupId(groupId);
    }

    @Override
    public Long getManagedPendingJoinRequestCount(Long userId) {
        List<Long> managedGroupIds = getManagedGroupIds(userId);
        if (CollUtil.isEmpty(managedGroupIds)) {
            return 0L;
        }
        return groupJoinRequestMapper.selectPendingCountByGroupIds(managedGroupIds);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void approveJoinRequest(Long userId, Long requestId) {
        ImGroupJoinRequestDO request = groupJoinRequestMapper.selectById(requestId);
        if (request == null) {
            throw exception(GROUP_JOIN_REQUEST_NOT_EXISTS);
        }

        log.info("[ImGroupService][审批权限校验] 开始校验审批人权限, operatorUserId: {}, groupId: {}, requestId: {}",
                userId, request.getGroupId(), requestId);

        assertCanManageJoinRequests(userId, request.getGroupId());

        log.info("[ImGroupService][审批权限校验] 审批人权限校验通过, operatorUserId: {}, groupId: {}, applicantUserId: {}",
                userId, request.getGroupId(), request.getApplicantUserId());

        if (!ImGroupJoinRequestStatusEnum.isPending(request.getStatus())) {
            throw exception(GROUP_JOIN_REQUEST_STATUS_INVALID);
        }

        ImGroupDO group = groupMapper.selectById(request.getGroupId());
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        ImGroupUserDO existingMember = groupUserMapper.selectByGroupIdAndUserId(request.getGroupId(), request.getApplicantUserId());
        if (existingMember == null) {
            if (group.getMemberCount() >= group.getMaxMemberCount()) {
                throw exception(GROUP_MEMBER_FULL);
            }
            addApprovedMemberToGroup(group, request.getApplicantUserId(), userId);
        }

        LocalDateTime approveTime = LocalDateTime.now();
        request.setStatus(ImGroupJoinRequestStatusEnum.APPROVED.getStatus());
        request.setHandledBy(userId);
        request.setHandledTime(approveTime);
        request.setRejectReason(null);
        groupJoinRequestMapper.updateById(request);

        log.info("[ImGroupService][审批审计] 审批通过, operatorUserId: {}, operatorRole: {}, applicantUserId: {}, groupId: {}, approveTime: {}",
                userId, getMemberRoleName(request.getGroupId(), userId),
                request.getApplicantUserId(), request.getGroupId(), approveTime);

        ImGroupJoinRequestDO finalRequest = request;
        runAfterCommit(() -> {
            notifyJoinRequestProcessed(group, finalRequest, true);
            notifyJoinRequestAdminRefresh(group, finalRequest, "approved");
        });
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void rejectJoinRequest(Long userId, Long requestId, String rejectReason) {
        ImGroupJoinRequestDO request = groupJoinRequestMapper.selectById(requestId);
        if (request == null) {
            throw exception(GROUP_JOIN_REQUEST_NOT_EXISTS);
        }

        log.info("[ImGroupService][审批权限校验] 开始校验审批人权限, operatorUserId: {}, groupId: {}, requestId: {}",
                userId, request.getGroupId(), requestId);

        assertCanManageJoinRequests(userId, request.getGroupId());

        log.info("[ImGroupService][审批权限校验] 审批人权限校验通过, operatorUserId: {}, groupId: {}, applicantUserId: {}",
                userId, request.getGroupId(), request.getApplicantUserId());

        if (!ImGroupJoinRequestStatusEnum.isPending(request.getStatus())) {
            throw exception(GROUP_JOIN_REQUEST_STATUS_INVALID);
        }

        LocalDateTime rejectTime = LocalDateTime.now();
        String finalRejectReason = rejectReason != null && !rejectReason.trim().isEmpty() ? rejectReason.trim() : "管理员已拒绝";
        request.setStatus(ImGroupJoinRequestStatusEnum.REJECTED.getStatus());
        request.setHandledBy(userId);
        request.setHandledTime(rejectTime);
        request.setRejectReason(finalRejectReason);
        groupJoinRequestMapper.updateById(request);

        log.info("[ImGroupService][审批审计] 审批拒绝, operatorUserId: {}, operatorRole: {}, applicantUserId: {}, groupId: {}, rejectTime: {}, reason: {}",
                userId, getMemberRoleName(request.getGroupId(), userId),
                request.getApplicantUserId(), request.getGroupId(), rejectTime, finalRejectReason);

        ImGroupDO group = groupMapper.selectById(request.getGroupId());
        if (group != null) {
            ImGroupJoinRequestDO finalRequest = request;
            runAfterCommit(() -> {
                notifyJoinRequestProcessed(group, finalRequest, false);
                notifyJoinRequestAdminRefresh(group, finalRequest, "rejected");
            });
        }
    }

    private void assertCanManageJoinRequests(Long userId, Long groupId) {
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null ||
                (!ImGroupMemberRoleEnum.isOwner(groupUser.getRole()) &&
                        !ImGroupMemberRoleEnum.isAdmin(groupUser.getRole()))) {
            throw exception(GROUP_PERMISSION_DENIED);
        }
    }

    private AppImGroupJoinRequestRespVO buildJoinRequestRespVO(ImGroupJoinRequestDO request) {
        AppImGroupJoinRequestRespVO respVO = BeanUtils.toBean(request, AppImGroupJoinRequestRespVO.class);
        AdminUserDO applicant = userMapper.selectById(request.getApplicantUserId());
        if (applicant != null) {
            respVO.setApplicantNickname(applicant.getNickname());
            respVO.setApplicantAvatar(applicant.getAvatar());
        }
        if (request.getHandledBy() != null && request.getHandledBy() > 0) {
            AdminUserDO handler = userMapper.selectById(request.getHandledBy());
            if (handler != null) {
                respVO.setHandledByNickname(handler.getNickname());
            }
        }
        return respVO;
    }

    private void notifyJoinRequestCreated(ImGroupDO group, ImGroupJoinRequestDO request) {
        if (group == null || request == null) {
            return;
        }
        AdminUserDO applicant = userMapper.selectById(request.getApplicantUserId());
        String applicantName = applicant != null && applicant.getNickname() != null && !applicant.getNickname().trim().isEmpty()
                ? applicant.getNickname().trim() : "新申请人";
        List<Long> managerIds = getJoinRequestManagerIds(group.getId());
        if (CollUtil.isEmpty(managerIds)) {
            return;
        }

        String title = "新的入群申请";
        String content = applicantName + " 申请加入群聊「" + group.getName() + "」";
        String extra = buildJoinRequestNotifyExtra("group_join_request_created", group, request, "pending");
        Long tenantId = resolveTenantId();
        TextMessage body = TextMessage.newBuilder().setContent("").build();
        for (Long managerId : managerIds) {
            if (managerId == null) {
                continue;
            }
            try {
                imNotifyService.sendCustomNotify(managerId, title, content, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 保存入群申请管理员通知失败, groupId: {}, managerId: {}, error: {}",
                        group.getId(), managerId, e.getMessage(), e);
            }
            try {
                messageSender.sendToUserWithExtra(managerId, MessageType.SYSTEM_NOTIFY, body,
                        0L, managerId, group.getId(), tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送入群申请管理员实时通知失败, groupId: {}, managerId: {}, error: {}",
                        group.getId(), managerId, e.getMessage(), e);
            }
            try {
                imBadgeService.pushBadgeUpdate(managerId);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送入群申请管理员 badge 刷新失败, groupId: {}, managerId: {}, error: {}",
                        group.getId(), managerId, e.getMessage(), e);
            }
        }
    }

    private void notifyJoinRequestProcessed(ImGroupDO group, ImGroupJoinRequestDO request, boolean approved) {
        if (group == null || request == null || request.getApplicantUserId() == null) {
            return;
        }
        AdminUserDO handler = request.getHandledBy() != null ? userMapper.selectById(request.getHandledBy()) : null;
        String handlerName = handler != null && handler.getNickname() != null && !handler.getNickname().trim().isEmpty()
                ? handler.getNickname().trim() : "管理员";
        String title = approved ? "入群申请已通过" : "入群申请未通过";
        String content = approved
                ? handlerName + " 已通过你加入群聊「" + group.getName() + "」的申请"
                : handlerName + " 已拒绝你加入群聊「" + group.getName() + "」的申请";
        String status = approved ? "approved" : "rejected";
        String extra = buildJoinRequestNotifyExtra("group_join_request_processed", group, request, status);
        Long tenantId = resolveTenantId();
        TextMessage body = TextMessage.newBuilder().setContent("").build();
        try {
            imNotifyService.sendCustomNotify(request.getApplicantUserId(), title, content, null, extra);
        } catch (Exception e) {
            log.warn("[ImGroupService] 保存入群申请结果通知失败, groupId: {}, applicantUserId: {}, error: {}",
                    group.getId(), request.getApplicantUserId(), e.getMessage(), e);
        }
        try {
            messageSender.sendToUserWithExtra(request.getApplicantUserId(), MessageType.SYSTEM_NOTIFY, body,
                    0L, request.getApplicantUserId(), group.getId(), tenantId,
                    null, null, null,
                    null, null, extra);
        } catch (Exception e) {
            log.warn("[ImGroupService] 推送入群申请结果实时通知失败, groupId: {}, applicantUserId: {}, error: {}",
                    group.getId(), request.getApplicantUserId(), e.getMessage(), e);
        }
    }

    private void notifyJoinRequestAdminRefresh(ImGroupDO group, ImGroupJoinRequestDO request, String status) {
        if (group == null || request == null) {
            return;
        }
        List<Long> managerIds = getJoinRequestManagerIds(group.getId());
        if (CollUtil.isEmpty(managerIds)) {
            return;
        }
        String extra = buildJoinRequestNotifyExtra("group_join_request_admin_refresh", group, request, status);
        Long tenantId = resolveTenantId();
        TextMessage body = TextMessage.newBuilder().setContent("").build();
        for (Long managerId : managerIds) {
            if (managerId == null) {
                continue;
            }
            try {
                messageSender.sendToUserWithExtra(managerId, MessageType.SYSTEM_NOTIFY, body,
                        0L, managerId, group.getId(), tenantId,
                        null, null, null,
                        null, null, extra);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送管理员审批刷新通知失败, groupId: {}, managerId: {}, error: {}",
                        group.getId(), managerId, e.getMessage(), e);
            }
            try {
                imBadgeService.pushBadgeUpdate(managerId);
            } catch (Exception e) {
                log.warn("[ImGroupService] 推送管理员审批 badge 刷新失败, groupId: {}, managerId: {}, error: {}",
                        group.getId(), managerId, e.getMessage(), e);
            }
        }
    }

    private List<Long> getJoinRequestManagerIds(Long groupId) {
        List<ImGroupUserDO> groupUsers = groupUserMapper.selectListByGroupId(groupId);
        if (CollUtil.isEmpty(groupUsers)) {
            return new ArrayList<>();
        }
        return groupUsers.stream()
                .filter(groupUser -> groupUser != null && groupUser.getUserId() != null)
                .filter(groupUser -> ImGroupMemberRoleEnum.isOwner(groupUser.getRole())
                        || ImGroupMemberRoleEnum.isAdmin(groupUser.getRole()))
                .map(ImGroupUserDO::getUserId)
                .distinct()
                .collect(Collectors.toList());
    }

    private List<Long> getManagedGroupIds(Long userId) {
        List<ImGroupUserDO> groupUsers = groupUserMapper.selectListByUserId(userId);
        if (CollUtil.isEmpty(groupUsers)) {
            return new ArrayList<>();
        }
        return groupUsers.stream()
                .filter(groupUser -> groupUser != null && groupUser.getGroupId() != null)
                .filter(groupUser -> ImGroupMemberRoleEnum.isOwner(groupUser.getRole())
                        || ImGroupMemberRoleEnum.isAdmin(groupUser.getRole()))
                .map(ImGroupUserDO::getGroupId)
                .distinct()
                .collect(Collectors.toList());
    }

    private String buildJoinRequestNotifyExtra(String action, ImGroupDO group, ImGroupJoinRequestDO request, String status) {
        JSONObject extra = JSONUtil.createObj();
        extra.set("action", action);
        extra.set("requestId", request.getId());
        extra.set("groupId", request.getGroupId());
        extra.set("groupName", group != null && group.getName() != null ? group.getName() : "");
        extra.set("applicantUserId", request.getApplicantUserId());
        extra.set("status", status);
        if (request.getHandledBy() != null) {
            extra.set("handledBy", request.getHandledBy());
            AdminUserDO handler = userMapper.selectById(request.getHandledBy());
            if (handler != null && handler.getNickname() != null) {
                extra.set("handledByName", handler.getNickname());
            }
        }
        if (request.getRejectReason() != null) {
            extra.set("rejectReason", request.getRejectReason());
        }
        AdminUserDO applicant = request.getApplicantUserId() != null ? userMapper.selectById(request.getApplicantUserId()) : null;
        if (applicant != null) {
            extra.set("applicantNickname", applicant.getNickname());
        }
        return extra.toString();
    }

    private Long resolveTenantId() {
        Long tenantId = TenantContextHolder.getTenantId();
        return tenantId != null ? tenantId : 0L;
    }

    private String getMemberRoleName(Long groupId, Long userId) {
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null) {
            return "未知";
        }
        if (ImGroupMemberRoleEnum.isOwner(groupUser.getRole())) {
            return "群主";
        }
        if (ImGroupMemberRoleEnum.isAdmin(groupUser.getRole())) {
            return "管理员";
        }
        return "成员";
    }

    private void upsertGroupMember(Long groupId, Long memberUserId, Integer role) {
        ImGroupUserDO deletedMember = groupUserMapper.selectDeletedByGroupIdAndUserId(groupId, memberUserId);
        if (deletedMember != null) {
            groupUserMapper.reviveSoftDeleted(deletedMember.getId(), role, deletedMember.getNickname(), LocalDateTime.now(), null);
            return;
        }
        ImGroupUserDO groupUser = new ImGroupUserDO();
        groupUser.setGroupId(groupId);
        groupUser.setUserId(memberUserId);
        groupUser.setRole(role);
        groupUser.setJoinTime(LocalDateTime.now());
        groupUserMapper.insert(groupUser);
    }

    private void deleteGroupMemberRelation(Long groupId, Long memberUserId, Long relationId) {
        groupUserMapper.hardDeleteSoftDeletedByGroupIdAndUserId(groupId, memberUserId);
        groupUserMapper.deleteById(relationId);
    }

    private void addApprovedMemberToGroup(ImGroupDO group, Long memberUserId, Long operatorUserId) {
        upsertGroupMember(group.getId(), memberUserId, ImGroupMemberRoleEnum.MEMBER.getRole());

        group.setMemberCount(group.getMemberCount() + 1);
        groupMapper.updateById(group);

        ImGroupConversationRefreshMessage refreshMessage = new ImGroupConversationRefreshMessage();
        refreshMessage.setAction("UPSERT");
        refreshMessage.setOperatorUserId(operatorUserId);
        refreshMessage.setGroupId(group.getId());
        refreshMessage.setMemberIds(java.util.Collections.singletonList(memberUserId));
        refreshMessage.setConversationType(ImConversationTypeEnum.GROUP.getType());
        groupConversationRefreshProducer.sendAfterCommit(refreshMessage);

        // 推送新成员加入WebSocket通知给所有群成员
        String tipContent = "新成员已加入群聊「" + group.getName() + "」";
        String tipExtra = imSystemMessageI18nSupport.attachI18n(null,
                ImSystemMessageI18nSupport.EVENT_GROUP_MEMBER_ADDED_ONE, null);
        runAfterCommit(() -> {
            pushGroupMemberAddedNotify(group.getId(), java.util.Collections.singletonList(memberUserId), operatorUserId, tipContent, tipExtra);
        });
    }

    @Override
    public Integer getMemberRole(Long groupId, Long userId) {
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null) {
            return null;
        }
        return groupUser.getRole();
    }

    @Scheduled(cron = "0 */10 * * * ?")
    public void cleanExpiredRateLimitRecords() {
        try {
            joinGroupRateLimiter.values().forEach(list -> {
                long now = System.currentTimeMillis();
                list.removeIf(ts -> now - ts > JOIN_GROUP_RATE_WINDOW_MS);
            });
            joinGroupRateLimiter.entrySet().removeIf(entry -> entry.getValue().isEmpty());

            verifyInviteRateLimiter.values().forEach(list -> {
                long now = System.currentTimeMillis();
                list.removeIf(ts -> now - ts > VERIFY_INVITE_RATE_WINDOW_MS);
            });
            verifyInviteRateLimiter.entrySet().removeIf(entry -> entry.getValue().isEmpty());

            log.debug("[ImGroupService] 清理限流器过期数据完成");
        } catch (Exception e) {
            log.warn("[ImGroupService] 清理限流器过期数据失败, error: {}", e.getMessage());
        }
    }

}
