package com.shengyu.module.system.service.im;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.controller.app.im.vo.group.*;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImGroupMemberRoleEnum;
import com.shengyu.module.system.enums.im.ImGroupStatusEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
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

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createGroup(Long userId, AppImGroupCreateReqVO createReqVO) {
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
        group.setMemberCount(createReqVO.getMemberIds().size() + 1); // +1 包括群主
        group.setMaxMemberCount(500); // 默认最大500人
        groupMapper.insert(group);

        // 添加群成员(包括群主)
        List<Long> memberIds = createReqVO.getMemberIds();
        for (Long memberId : memberIds) {
            ImGroupUserDO groupUser = new ImGroupUserDO();
            groupUser.setGroupId(group.getId());
            groupUser.setUserId(memberId);
            // 群主角色
            if (memberId.equals(userId)) {
                groupUser.setRole(ImGroupMemberRoleEnum.OWNER.getRole());
            } else {
                groupUser.setRole(ImGroupMemberRoleEnum.MEMBER.getRole());
            }
            groupUserMapper.insert(groupUser);
        }

        log.info("[ImGroupService] 创建群组成功, groupId: {}, ownerId: {}, memberCount: {}", 
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

        log.info("[ImGroupService] 移除群成员成功, groupId: {}, memberUserId: {}", groupId, memberUserId);
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
        member.setMuted(muted);
        groupUserMapper.updateById(member);

        log.info("[ImGroupService] 设置群成员禁言成功, groupId: {}, memberUserId: {}, muted: {}", 
                groupId, memberUserId, muted);
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

}
