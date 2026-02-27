package com.shengyu.module.system.service.im;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.group.*;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupInviteDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImGroupInviteMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImConversationTypeEnum;
import com.shengyu.module.system.enums.im.ImGroupInviteStatusEnum;
import com.shengyu.module.system.enums.im.ImGroupMemberRoleEnum;
import com.shengyu.module.system.enums.im.ImGroupStatusEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
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

    @Resource
    private ImGroupMapper groupMapper;

    @Resource
    private ImGroupUserMapper groupUserMapper;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private ImConversationService conversationService;

    @Resource
    private ImGroupInviteMapper groupInviteMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createGroup(Long userId, AppImGroupCreateReqVO createReqVO) {
        log.info("[ImGroupService] 开始创建群组, ownerId: {}, memberIds: {}", userId, createReqVO.getMemberIds());
        
        // 创建群组
        ImGroupDO group = new ImGroupDO();
        group.setOwnerId(userId);
        group.setName(createReqVO.getName());
        group.setAvatar(createReqVO.getAvatar());
        group.setGroupType(createReqVO.getGroupType());
        group.setIntroduction(createReqVO.getIntroduction());
        group.setStatus(ImGroupStatusEnum.NORMAL.getStatus());
        group.setAllowMemberInvite(true); // 默认允许成员邀请
        group.setNeedApproval(false); // 默认不需要审批
        group.setMuteAll(false); // 默认不禁言
        
        // 确保 memberIds 包含群主
        List<Long> memberIds = new ArrayList<>(createReqVO.getMemberIds());
        if (!memberIds.contains(userId)) {
            memberIds.add(userId);
            log.info("[ImGroupService] 群主不在成员列表中，自动添加: {}", userId);
        }
        
        group.setMemberCount(memberIds.size());
        group.setMaxMemberCount(500); // 默认最大500人
        groupMapper.insert(group);
        
        log.info("[ImGroupService] 群组创建成功, groupId: {}, 开始添加成员和创建会话", group.getId());

        // 添加群成员并创建会话
        for (Long memberId : memberIds) {
            // 添加群成员
            ImGroupUserDO groupUser = new ImGroupUserDO();
            groupUser.setGroupId(group.getId());
            groupUser.setUserId(memberId);
            groupUser.setJoinTime(LocalDateTime.now());
            // 群主角色
            if (memberId.equals(userId)) {
                groupUser.setRole(ImGroupMemberRoleEnum.OWNER.getRole());
            } else {
                groupUser.setRole(ImGroupMemberRoleEnum.MEMBER.getRole());
            }
            groupUserMapper.insert(groupUser);
            log.info("[ImGroupService] 添加群成员成功, groupId: {}, memberId: {}, role: {}", 
                    group.getId(), memberId, groupUser.getRole());
            
            // 为每个群成员创建会话
            try {
                AppImConversationCreateReqVO conversationReqVO = new AppImConversationCreateReqVO();
                conversationReqVO.setTargetId(group.getId());
                conversationReqVO.setConversationType(2); // 2-群聊
                conversationService.createOrGetConversation(memberId, conversationReqVO);
                log.info("[ImGroupService] 为成员创建会话成功, groupId: {}, memberId: {}", group.getId(), memberId);
            } catch (Exception e) {
                log.error("[ImGroupService] 为成员创建会话失败, groupId: {}, memberId: {}, error: {}", 
                        group.getId(), memberId, e.getMessage(), e);
            }
        }

        log.info("[ImGroupService] 创建群组完成, groupId: {}, ownerId: {}, memberCount: {}", 
                group.getId(), userId, memberIds.size());
        return group.getId();
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

        // 删除群组
        groupMapper.deleteById(groupId);

        // 删除所有群成员
        List<ImGroupUserDO> members = groupUserMapper.selectListByGroupId(groupId);
        for (ImGroupUserDO member : members) {
            groupUserMapper.deleteById(member.getId());
        }

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
        groupUserMapper.deleteById(groupUser.getId());

        // 更新群成员数量
        group.setMemberCount(group.getMemberCount() - 1);
        groupMapper.updateById(group);

        log.info("[ImGroupService] 退出群组成功, groupId: {}, userId: {}", groupId, userId);
    }

    @Override
    public AppImGroupRespVO getGroup(Long userId, Long groupId) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 检查是否是群成员
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 转换为VO
        AppImGroupRespVO respVO = BeanUtils.toBean(group, AppImGroupRespVO.class);
        
        // 不需要填充群主名称，前端可以通过 ownerId 查询
        
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

        List<AppImGroupRespVO> result = new ArrayList<>();
        for (Long groupId : groupIds) {
            ImGroupDO group = groupMapper.selectById(groupId);
            if (group != null) {
                AppImGroupRespVO respVO = BeanUtils.toBean(group, AppImGroupRespVO.class);
                
                // 不需要填充群主名称，前端可以通过 ownerId 查询
                
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

        // 检查权限(群主、管理员或允许成员邀请)
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(addReqVO.getGroupId(), userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        boolean isOwnerOrAdmin = ImGroupMemberRoleEnum.isOwner(groupUser.getRole()) || 
                                 ImGroupMemberRoleEnum.isAdmin(groupUser.getRole());
        if (!isOwnerOrAdmin && !group.getAllowMemberInvite()) {
            throw exception(GROUP_PERMISSION_DENIED);
        }

        // 添加群成员
        int addedCount = 0;
        for (Long memberId : addReqVO.getMemberIds()) {
            // 检查是否已经是群成员
            ImGroupUserDO existMember = groupUserMapper.selectByGroupIdAndUserId(addReqVO.getGroupId(), memberId);
            if (existMember != null) {
                continue;
            }

            // 添加成员
            ImGroupUserDO newMember = new ImGroupUserDO();
            newMember.setGroupId(addReqVO.getGroupId());
            newMember.setUserId(memberId);
            newMember.setRole(ImGroupMemberRoleEnum.MEMBER.getRole());
            newMember.setJoinTime(LocalDateTime.now());
            groupUserMapper.insert(newMember);
            addedCount++;
        }

        // 更新群成员数量
        if (addedCount > 0) {
            group.setMemberCount(group.getMemberCount() + addedCount);
            groupMapper.updateById(group);
        }

        log.info("[ImGroupService] 添加群成员成功, groupId: {}, addedCount: {}", addReqVO.getGroupId(), addedCount);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeGroupMember(Long userId, Long groupId, Long memberUserId) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

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
        groupUserMapper.deleteById(memberToRemove.getId());

        // 更新群成员数量
        group.setMemberCount(group.getMemberCount() - 1);
        groupMapper.updateById(group);

        // 删除该成员的会话记录
        try {
            conversationService.deleteConversationByTarget(memberUserId, groupId, ImConversationTypeEnum.GROUP.getType());
            log.info("[ImGroupService] 删除被移除成员的会话记录成功, userId: {}, groupId: {}", memberUserId, groupId);
        } catch (Exception e) {
            log.warn("[ImGroupService] 删除被移除成员的会话记录失败, userId: {}, groupId: {}, error: {}", 
                    memberUserId, groupId, e.getMessage());
            // 会话删除失败不影响成员移除操作
        }

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

        // 检查是否是群成员
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

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

        log.info("[ImGroupService] 设置群成员角色成功, groupId: {}, memberUserId: {}, role: {}", 
                groupId, memberUserId, role);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setGroupMemberMuted(Long userId, Long groupId, Long memberUserId, Boolean muted) {
        // 查询群组
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

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

        // 更新禁言状态
        // 如果禁言，设置禁言结束时间为24小时后；如果取消禁言，设置为null
        if (muted) {
            member.setMuteEndTime(LocalDateTime.now().plusHours(24));
        } else {
            member.setMuteEndTime(null);
        }
        groupUserMapper.updateById(member);

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

        log.info("[ImGroupService] 设置全员禁言成功, groupId: {}, muted: {}", groupId, muted);
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

        // 2. 验证用户是群成员
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 3. 查询是否已有有效邀请码
        ImGroupInviteDO existingInvite = groupInviteMapper.selectValidByGroupId(groupId);
        if (existingInvite != null) {
            // 返回现有邀请码
            return buildInviteRespVO(existingInvite, groupId);
        }

        // 4. 生成新邀请码
        String inviteCode = generateUniqueInviteCode();
        LocalDateTime expireTime = LocalDateTime.now().plusHours(reqVO.getExpireHours());

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

        return buildInviteRespVO(invite, groupId);
    }

    @Override
    public AppImGroupInviteVerifyRespVO verifyInviteCode(String inviteCode) {
        AppImGroupInviteVerifyRespVO respVO = new AppImGroupInviteVerifyRespVO();

        // 1. 查询邀请码
        ImGroupInviteDO invite = groupInviteMapper.selectByInviteCode(inviteCode);
        if (invite == null) {
            respVO.setValid(false);
            respVO.setErrorMessage("邀请码不存在");
            return respVO;
        }

        // 2. 验证状态
        if (!ImGroupInviteStatusEnum.isValid(invite.getStatus())) {
            respVO.setValid(false);
            respVO.setErrorMessage("邀请码已失效");
            return respVO;
        }

        // 3. 验证过期时间
        if (invite.getExpireTime().isBefore(LocalDateTime.now())) {
            respVO.setValid(false);
            respVO.setErrorMessage("邀请码已过期");
            return respVO;
        }

        // 4. 验证使用次数
        if (invite.getMaxUseCount() > 0 && invite.getUsedCount() >= invite.getMaxUseCount()) {
            respVO.setValid(false);
            respVO.setErrorMessage("邀请码使用次数已达上限");
            return respVO;
        }

        // 5. 查询群组信息
        ImGroupDO group = groupMapper.selectById(invite.getGroupId());
        if (group == null || !ImGroupStatusEnum.isNormal(group.getStatus())) {
            respVO.setValid(false);
            respVO.setErrorMessage("群组不存在或已解散");
            return respVO;
        }

        // 6. 返回验证成功信息
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
    public void joinGroupByInviteCode(Long userId, String inviteCode) {
        // 1. 验证邀请码
        AppImGroupInviteVerifyRespVO verifyResult = verifyInviteCode(inviteCode);
        if (!verifyResult.getValid()) {
            throw exception(GROUP_INVITE_CODE_INVALID, verifyResult.getErrorMessage());
        }

        Long groupId = verifyResult.getGroupId();

        // 2. 检查是否已是群成员
        ImGroupUserDO existingMember = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (existingMember != null) {
            throw exception(GROUP_MEMBER_ALREADY_EXISTS);
        }

        // 3. 检查群人数是否已满
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group.getMemberCount() >= group.getMaxMemberCount()) {
            throw exception(GROUP_MEMBER_FULL);
        }

        // 4. 如果需要审批，创建加群申请（暂不实现，直接加入）
        if (verifyResult.getNeedApproval()) {
            // TODO: 创建加群申请，等待审批
            throw exception(GROUP_JOIN_NEED_APPROVAL);
        }

        // 5. 添加群成员
        ImGroupUserDO groupUser = new ImGroupUserDO();
        groupUser.setGroupId(groupId);
        groupUser.setUserId(userId);
        groupUser.setRole(ImGroupMemberRoleEnum.MEMBER.getRole());
        groupUser.setJoinTime(LocalDateTime.now());
        groupUserMapper.insert(groupUser);

        // 6. 更新群成员数量
        group.setMemberCount(group.getMemberCount() + 1);
        groupMapper.updateById(group);

        // 7. 创建会话
        AppImConversationCreateReqVO conversationReqVO = new AppImConversationCreateReqVO();
        conversationReqVO.setTargetId(groupId);
        conversationReqVO.setConversationType(2); // 2-群聊
        conversationService.createOrGetConversation(userId, conversationReqVO);

        // 8. 更新邀请码使用次数
        ImGroupInviteDO invite = groupInviteMapper.selectByInviteCode(inviteCode);
        invite.setUsedCount(invite.getUsedCount() + 1);
        groupInviteMapper.updateById(invite);

        log.info("[ImGroupService] 通过邀请码加入群成功, userId: {}, groupId: {}, inviteCode: {}", 
                userId, groupId, inviteCode);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImGroupInviteRespVO getGroupInviteCode(Long userId, Long groupId) {
        // 1. 验证群组存在
        ImGroupDO group = groupMapper.selectById(groupId);
        if (group == null) {
            throw exception(GROUP_NOT_EXISTS);
        }

        // 2. 验证用户是群成员
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }

        // 3. 查询有效邀请码
        ImGroupInviteDO invite = groupInviteMapper.selectValidByGroupId(groupId);
        
        // 4. 如果没有有效邀请码，自动生成一个
        if (invite == null) {
            log.info("[ImGroupService] 群组没有有效邀请码，自动生成, groupId: {}", groupId);
            
            // 生成邀请码
            String inviteCode = generateUniqueInviteCode();
            LocalDateTime expireTime = LocalDateTime.now().plusHours(24); // 默认24小时
            
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
        
        // 6. 如果需要推送通知，发送系统消息给所有群成员
        if (Boolean.TRUE.equals(reqVO.getNotifyMembers()) && reqVO.getNotice() != null && !reqVO.getNotice().isEmpty()) {
            // 获取群成员ID列表
            List<Long> memberIds = getGroupMemberIds(reqVO.getGroupId());
            
            // 构建通知内容
            String noticePreview = reqVO.getNotice().length() > 30 
                    ? reqVO.getNotice().substring(0, 30) + "..." 
                    : reqVO.getNotice();
            String notificationContent = String.format("群主发布了新公告：%s", noticePreview);
            
            log.info("[ImGroupService] 准备推送群公告通知, groupId: {}, memberCount: {}", 
                    reqVO.getGroupId(), memberIds.size());
            
            // TODO: 调用消息服务发送系统通知
            // messageService.sendSystemNotification(memberIds, notificationContent, reqVO.getGroupId());
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
        
        // 2. 检查是否是群成员
        ImGroupUserDO groupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (groupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }
        
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
        
        // 2. 查询操作者在群中的角色
        ImGroupUserDO operatorGroupUser = groupUserMapper.selectByGroupIdAndUserId(groupId, userId);
        if (operatorGroupUser == null) {
            throw exception(GROUP_MEMBER_NOT_EXISTS);
        }
        
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

}
