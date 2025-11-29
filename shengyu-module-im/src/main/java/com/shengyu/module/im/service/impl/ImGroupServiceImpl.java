package com.shengyu.module.im.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.module.im.dal.dataobject.ImGroupDO;
import com.shengyu.module.im.dal.dataobject.ImGroupMemberDO;
import com.shengyu.module.im.dal.mapper.ImGroupMapper;
import com.shengyu.module.im.dal.mapper.ImGroupMemberMapper;
import com.shengyu.module.im.enums.ErrorCodeConstants;
import com.shengyu.module.im.service.ImGroupService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;

/**
 * IM群组服务实现类
 *
 * @author 圣钰科技
 */
@Slf4j
@Service
@Validated
public class ImGroupServiceImpl implements ImGroupService {

    @Autowired
    private ImGroupMapper imGroupMapper;

    @Autowired
    private ImGroupMemberMapper imGroupMemberMapper;

    @Override
    public Long createGroup(String name, String avatar, String description, Long ownerId) {
        // 创建群组
        ImGroupDO groupDO = new ImGroupDO();
        groupDO.setName(name);
        groupDO.setAvatar(avatar);
        groupDO.setDescription(description);
        groupDO.setOwnerId(ownerId);
        groupDO.setMemberCount(1); // 初始成员为群主
        groupDO.setStatus(0); // 0表示正常
        imGroupMapper.insert(groupDO);
        
        // 添加群主为群成员
        ImGroupMemberDO memberDO = new ImGroupMemberDO();
        memberDO.setGroupId(groupDO.getId());
        memberDO.setUserId(ownerId);
        memberDO.setRole(2); // 2表示群主
        memberDO.setJoinTime(new Date());
        memberDO.setStatus(0); // 0表示正常
        imGroupMemberMapper.insert(memberDO);
        
        return groupDO.getId();
    }

    @Override
    public boolean joinGroup(Long groupId, Long userId) {
        // 检查群组是否存在
        ImGroupDO groupDO = imGroupMapper.selectById(groupId);
        if (groupDO == null || groupDO.getStatus() != 0) {
            throw exception(ErrorCodeConstants.IM_GROUP_NOT_EXISTS);
        }
        
        // 检查用户是否已经是群成员
        ImGroupMemberDO existingMember = imGroupMemberMapper.getGroupMember(groupId, userId);
        if (existingMember != null && existingMember.getStatus() == 0) {
            throw exception(ErrorCodeConstants.IM_GROUP_ALREADY_JOINED);
        }
        
        // 添加或更新群成员
        ImGroupMemberDO memberDO = new ImGroupMemberDO();
        memberDO.setGroupId(groupId);
        memberDO.setUserId(userId);
        memberDO.setRole(0); // 0表示普通成员
        memberDO.setJoinTime(new Date());
        memberDO.setStatus(0); // 0表示正常
        if (existingMember != null) {
            memberDO.setId(existingMember.getId());
            imGroupMemberMapper.updateById(memberDO);
        } else {
            imGroupMemberMapper.insert(memberDO);
            // 增加群成员数量
            imGroupMapper.increaseMemberCount(groupId, 1);
        }
        
        return true;
    }

    @Override
    public boolean exitGroup(Long groupId, Long userId) {
        // 检查用户是否是群成员
        ImGroupMemberDO memberDO = imGroupMemberMapper.getGroupMember(groupId, userId);
        if (memberDO == null || memberDO.getStatus() != 0) {
            throw exception(ErrorCodeConstants.IM_GROUP_MEMBER_NOT_EXISTS);
        }
        
        // 群主不能退出群组，只能解散群组
        if (memberDO.getRole() == 2) {
            throw exception(ErrorCodeConstants.IM_GROUP_NOT_OWNER);
        }
        
        // 更新群成员状态为已退出
        memberDO.setStatus(1); // 1表示已退出
        imGroupMemberMapper.updateById(memberDO);
        
        // 减少群成员数量
        imGroupMapper.decreaseMemberCount(groupId, 1);
        
        return true;
    }

    @Override
    public ImGroupDO getGroupInfo(Long groupId) {
        return imGroupMapper.selectById(groupId);
    }

    @Override
    public List<ImGroupMemberDO> getGroupMembers(Long groupId) {
        return imGroupMemberMapper.getGroupMembers(groupId);
    }

    @Override
    public List<ImGroupDO> getUserGroups(Long userId) {
        // 获取用户加入的群组成员列表
        List<ImGroupMemberDO> memberList = imGroupMemberMapper.getUserGroups(userId);
        
        // 提取群组ID列表
        List<Long> groupIds = memberList.stream()
                .map(ImGroupMemberDO::getGroupId)
                .distinct()
                .collect(Collectors.toList());
        
        // 获取群组信息列表
        return imGroupMapper.selectBatchIds(groupIds);
    }

    @Override
    public List<Long> getGroupMemberIds(Long groupId) {
        // 获取群组成员列表
        List<ImGroupMemberDO> memberList = imGroupMemberMapper.getGroupMembers(groupId);
        
        // 提取用户ID列表
        return memberList.stream()
                .map(ImGroupMemberDO::getUserId)
                .collect(Collectors.toList());
    }

    @Override
    public boolean updateGroup(Long groupId, String name, String avatar, String description, Long ownerId) {
        // 检查群组是否存在
        ImGroupDO groupDO = imGroupMapper.selectById(groupId);
        if (groupDO == null) {
            throw exception(ErrorCodeConstants.IM_GROUP_NOT_EXISTS);
        }
        
        // 检查是否是群主
        if (!groupDO.getOwnerId().equals(ownerId)) {
            throw exception(ErrorCodeConstants.IM_GROUP_NOT_OWNER);
        }
        
        // 更新群组信息
        groupDO.setName(name);
        groupDO.setAvatar(avatar);
        groupDO.setDescription(description);
        
        int result = imGroupMapper.updateById(groupDO);
        return result > 0;
    }

    @Override
    public boolean dissolveGroup(Long groupId, Long ownerId) {
        // 检查群组是否存在
        ImGroupDO groupDO = imGroupMapper.selectById(groupId);
        if (groupDO == null) {
            throw exception(ErrorCodeConstants.IM_GROUP_NOT_EXISTS);
        }
        
        // 检查是否是群主
        if (!groupDO.getOwnerId().equals(ownerId)) {
            throw exception(ErrorCodeConstants.IM_GROUP_NOT_OWNER);
        }
        
        // 更新群组状态为解散
        groupDO.setStatus(1); // 1表示解散
        imGroupMapper.updateById(groupDO);
        
        // 更新所有群成员状态为已退出
        LambdaQueryWrapper<ImGroupMemberDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImGroupMemberDO::getGroupId, groupId);
        wrapper.eq(ImGroupMemberDO::getStatus, 0);
        
        List<ImGroupMemberDO> memberList = imGroupMemberMapper.selectList(wrapper);
        for (ImGroupMemberDO memberDO : memberList) {
            memberDO.setStatus(1); // 1表示已退出
            imGroupMemberMapper.updateById(memberDO);
        }
        
        return true;
    }

    @Override
    public boolean removeMember(Long groupId, Long userId, Long operator) {
        // 检查操作人是否是群主或管理员
        ImGroupMemberDO operatorMember = imGroupMemberMapper.getGroupMember(groupId, operator);
        if (operatorMember == null || (operatorMember.getRole() != 1 && operatorMember.getRole() != 2)) {
            return false; // 不是管理员或群主，没有权限
        }
        
        // 检查被移除用户是否是群成员
        ImGroupMemberDO memberDO = imGroupMemberMapper.getGroupMember(groupId, userId);
        if (memberDO == null || memberDO.getStatus() != 0) {
            return false;
        }
        
        // 群主不能被移除
        if (memberDO.getRole() == 2) {
            return false;
        }
        
        // 更新群成员状态为已退出
        memberDO.setStatus(1); // 1表示已退出
        imGroupMemberMapper.updateById(memberDO);
        
        // 减少群成员数量
        imGroupMapper.decreaseMemberCount(groupId, 1);
        
        return true;
    }

    @Override
    public boolean setMemberRole(Long groupId, Long userId, Integer role, Long operator) {
        // 检查操作人是否是群主
        ImGroupMemberDO operatorMember = imGroupMemberMapper.getGroupMember(groupId, operator);
        if (operatorMember == null || operatorMember.getRole() != 2) {
            return false; // 不是群主，没有权限
        }
        
        // 检查被设置用户是否是群成员
        ImGroupMemberDO memberDO = imGroupMemberMapper.getGroupMember(groupId, userId);
        if (memberDO == null || memberDO.getStatus() != 0) {
            return false;
        }
        
        // 更新群成员角色
        memberDO.setRole(role);

        int result = imGroupMemberMapper.updateById(memberDO);
        return result > 0;
    }
}
