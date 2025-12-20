package com.shengyu.module.system.service.im.impl;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.netty.service.NettyService;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.group.*;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatMessageRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImFriendDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.mysql.im.ImFriendMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.redis.im.ImMessageRedisDAO;
import com.shengyu.module.system.service.im.ImGroupService;
import com.shengyu.module.system.service.user.AdminUserService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 群聊服务实现
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Service
public class ImGroupServiceImpl implements ImGroupService {

    @Autowired
    private ImGroupMapper imGroupMapper;

    @Autowired
    private ImGroupUserMapper imGroupUserMapper;

    @Autowired
    private ImFriendMapper imFriendMapper;

    @Autowired
    private AdminUserService adminUserService;

    @Autowired
    private NettyService nettyService;

    @Autowired
    private ImMessageRedisDAO imMessageRedisDAO;

    /**
     * 获取当前登录用户ID
     */
    private Long getCurrentUserId() {
        return SecurityFrameworkUtils.getLoginUserId();
    }

    @Override
    public List<ImGroupInfoRespVO> getGroupList(int page, int limit) {
        Long currentUserId = getCurrentUserId();

        // 查询当前用户加入的所有群聊，带分页
        List<ImGroupUserDO> groupUserList = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getUserId, currentUserId)
                        .last("LIMIT " + (page - 1) * limit + ", " + limit)
        );

        if (groupUserList.isEmpty()) {
            return new ArrayList<>();
        }

        // 提取群ID列表
        List<Long> groupIds = groupUserList.stream()
                .map(ImGroupUserDO::getGroupId)
                .collect(Collectors.toList());

        // 查询群信息
        List<ImGroupDO> groupList = imGroupMapper.selectList(
                new LambdaQueryWrapper<ImGroupDO>()
                        .in(ImGroupDO::getId, groupIds)
                        .eq(ImGroupDO::getStatus, 0)
        );

        // 转换为响应VO
        List<ImGroupInfoRespVO> resultList = new ArrayList<>();
        for (ImGroupDO group : groupList) {
            ImGroupInfoRespVO respVO = new ImGroupInfoRespVO();
            BeanUtils.copyProperties(group, respVO);
            respVO.setCreateTime(group.getCreateTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli());
            resultList.add(respVO);
        }

        return resultList;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ImGroupDO createGroup(ImGroupCreateReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        List<Long> memberIds = reqVO.getIds();

        // 验证是否是我的好友
        List<ImFriendDO> friends = imFriendMapper.selectList(
                new LambdaQueryWrapper<ImFriendDO>()
                        .eq(ImFriendDO::getUserId, currentUserId)
                        .in(ImFriendDO::getFriendId, memberIds)
        );

        if (friends.isEmpty()) {
            throw new ServiceException("请选择需要加入群聊的好友");
        }

        // 获取好友信息，用于生成群名称
        List<Long> friendIds = friends.stream()
                .map(ImFriendDO::getFriendId)
                .collect(Collectors.toList());

        List<UserRespVO> friendUsers = new ArrayList<>();
        for (Long friendId : friendIds) {
            UserRespVO user = adminUserService.getUser(friendId);
            if (user != null) {
                friendUsers.add(user);
            }
        }

        // 生成群名称
        List<String> userNames = friendUsers.stream()
                .map(user -> StrUtil.isNotBlank(user.getNickname()) ? user.getNickname() : user.getUsername())
                .collect(Collectors.toList());

        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        userNames.add(StrUtil.isNotBlank(currentUser.getNickname()) ? currentUser.getNickname() : currentUser.getUsername());

        String groupName = userNames.stream().collect(Collectors.joining(","));

        // 创建群聊
        ImGroupDO group = new ImGroupDO();
        group.setUserId(currentUserId);
        group.setName(groupName);
        group.setAvatar("");
        group.setStatus(0);
        group.setRemark("");
        group.setInviteConfirm(0);
        imGroupMapper.insert(group);

        // 创建群成员列表
        List<ImGroupUserDO> groupUsers = new ArrayList<>();

        // 添加好友到群成员列表
        for (Long friendId : friendIds) {
            ImGroupUserDO groupUser = new ImGroupUserDO();
            groupUser.setUserId(friendId);
            groupUser.setGroupId(group.getId());
            groupUsers.add(groupUser);
        }

        // 添加当前用户到群成员列表
        ImGroupUserDO currentUserGroup = new ImGroupUserDO();
        currentUserGroup.setUserId(currentUserId);
        currentUserGroup.setGroupId(group.getId());
        groupUsers.add(currentUserGroup);

        // 批量插入群成员
        imGroupUserMapper.insert(groupUsers);

        // 发送系统消息给所有群成员
        sendSystemMessageToGroup(group, currentUser, "创建群聊成功，可以开始聊天啦", groupUsers);

        return group;
    }

    @Override
    public ImGroupInfoRespVO getGroupInfo(Long id) {
        Long currentUserId = getCurrentUserId();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(id);
        if (group == null || group.getStatus() != 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, id)
        );

        // 检查当前用户是否是该群成员
        boolean isMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        if (!isMember) {
            throw new ServiceException("你不是该群成员，没有权限");
        }

        // 转换为响应VO
        ImGroupInfoRespVO respVO = new ImGroupInfoRespVO();
        BeanUtils.copyProperties(group, respVO);
        respVO.setCreateTime(group.getCreateTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli());

        // 转换群成员列表
        List<ImGroupInfoRespVO.GroupMemberRespVO> members = new ArrayList<>();
        for (ImGroupUserDO groupUser : groupUsers) {
            ImGroupInfoRespVO.GroupMemberRespVO memberRespVO = new ImGroupInfoRespVO.GroupMemberRespVO();
            memberRespVO.setUserId(groupUser.getUserId());
            memberRespVO.setNickname(groupUser.getNickname());

            // 获取用户信息
            UserRespVO user = adminUserService.getUser(groupUser.getUserId());
            memberRespVO.setUser(user);

            members.add(memberRespVO);
        }

        respVO.setMembers(members);
        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean renameGroup(ImGroupRenameReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long groupId = reqVO.getId();
        String name = reqVO.getName();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(groupId);
        if (group == null || group.getStatus() != 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        // 检查当前用户是否是该群成员
        boolean isMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        if (!isMember) {
            throw new ServiceException("你不是该群成员");
        }

        // 检查是否是群主
        if (!group.getUserId().equals(currentUserId)) {
            throw new ServiceException("你不是管理员，没有权限");
        }

        // 修改群名称
        group.setName(name);
        imGroupMapper.updateById(group);

        // 获取当前用户信息
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        String fromName = getMemberNickname(currentUserId, groupUsers, currentUser);

        // 发送系统消息给所有群成员
        String messageContent = StrUtil.format("{} 修改群名称为 {}", fromName, name);
        sendSystemMessageToGroup(group, currentUser, messageContent, groupUsers);

        return true;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateGroupRemark(ImGroupRemarkReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long groupId = reqVO.getId();
        String remark = reqVO.getRemark();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(groupId);
        if (group == null || group.getStatus() != 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        // 检查当前用户是否是该群成员
        boolean isMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        if (!isMember) {
            throw new ServiceException("你不是该群成员");
        }

        // 检查是否是群主
        if (!group.getUserId().equals(currentUserId)) {
            throw new ServiceException("你不是管理员，没有权限");
        }

        // 修改群公告
        group.setRemark(remark);
        imGroupMapper.updateById(group);

        // 获取当前用户信息
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        String fromName = getMemberNickname(currentUserId, groupUsers, currentUser);

        // 发送系统消息给所有群成员
        String messageContent = StrUtil.format("[新公告] {}", remark);
        sendSystemMessageToGroup(group, currentUser, messageContent, groupUsers);

        return true;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateGroupNickname(ImGroupNicknameReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long groupId = reqVO.getId();
        String nickname = reqVO.getNickname();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(groupId);
        if (group == null || group.getStatus() != 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        // 检查当前用户是否是该群成员
        boolean isMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        if (!isMember) {
            throw new ServiceException("你不是该群成员");
        }

        // 修改群昵称
        ImGroupUserDO groupUser = imGroupUserMapper.selectOne(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getUserId, currentUserId)
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        if (groupUser != null) {
            groupUser.setNickname(nickname);
            imGroupUserMapper.updateById(groupUser);
        }

        return true;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean quitGroup(ImGroupQuitReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long groupId = reqVO.getId();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(groupId);
        if (group == null) {
            throw new ServiceException("该群聊不存在");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        // 检查当前用户是否是该群成员
        boolean isMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        if (!isMember) {
            throw new ServiceException("你不是该群成员");
        }

        // 获取当前用户信息
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        String fromName = getMemberNickname(currentUserId, groupUsers, currentUser);

        // 构建系统消息
        ImChatMessageRespVO message = buildSystemMessage(group, currentUser, fromName, "");

        if (group.getUserId().equals(currentUserId)) {
            // 解散群聊
            imGroupMapper.deleteById(groupId);
            imGroupUserMapper.delete(
                    new LambdaQueryWrapper<ImGroupUserDO>()
                            .eq(ImGroupUserDO::getGroupId, groupId)
            );
            message.setData("该群已被解散");
        } else {
            // 退出群聊
            imGroupUserMapper.delete(
                    new LambdaQueryWrapper<ImGroupUserDO>()
                            .eq(ImGroupUserDO::getUserId, currentUserId)
                            .eq(ImGroupUserDO::getGroupId, groupId)
            );
            message.setData(StrUtil.format("{} 退出该群聊", fromName));
        }

        // 发送系统消息给所有群成员
        for (ImGroupUserDO groupUser : groupUsers) {
            sendMessageToUser(groupUser.getUserId(), message);
        }

        return true;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean kickoffGroupMember(ImGroupKickoffReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long groupId = reqVO.getId();
        Long userId = reqVO.getUserId();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(groupId);
        if (group == null || group.getStatus() != 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        // 检查当前用户是否是该群成员
        boolean isMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        if (!isMember) {
            throw new ServiceException("你不是该群成员");
        }

        // 检查是否是群主
        if (!group.getUserId().equals(currentUserId)) {
            throw new ServiceException("你不是管理员，没有权限");
        }

        // 不能踢自己
        if (userId.equals(currentUserId)) {
            throw new ServiceException("不能踢自己");
        }

        // 检查对方是否是该群成员
        boolean isKickMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(userId));

        if (!isKickMember) {
            throw new ServiceException("对方不是该群成员");
        }

        // 获取被踢成员昵称
        UserRespVO kickUser = adminUserService.getUser(userId);
        String kickName = getMemberNickname(userId, groupUsers, kickUser);

        // 踢出该群
        imGroupUserMapper.delete(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getUserId, userId)
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        // 获取当前用户信息
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        String fromName = getMemberNickname(currentUserId, groupUsers, currentUser);

        // 发送系统消息给所有群成员
        String messageContent = StrUtil.format("{} 将 {} 移出群聊", fromName, kickName);
        sendSystemMessageToGroup(group, currentUser, messageContent, groupUsers);

        return true;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean inviteToGroup(ImGroupInviteReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long groupId = reqVO.getId();
        Long userId = reqVO.getUserId();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(groupId);
        if (group == null || group.getStatus() != 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        // 检查当前用户是否是该群成员
        boolean isMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        if (!isMember) {
            throw new ServiceException("你不是该群成员");
        }

        // 检查对方是否已经是该群成员
        boolean isAlreadyMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(userId));

        if (isAlreadyMember) {
            throw new ServiceException("对方已经是该群成员");
        }

        // 检查对方是否存在
        UserRespVO user = adminUserService.getUser(userId);
        if (user == null || user.getStatus() != 1) {
            throw new ServiceException("对方不存在或者已被封禁");
        }

        String inviteName = StrUtil.isNotBlank(user.getNickname()) ? user.getNickname() : user.getUsername();

        // 加入该群
        ImGroupUserDO groupUser = new ImGroupUserDO();
        groupUser.setUserId(userId);
        groupUser.setGroupId(groupId);
        imGroupUserMapper.insert(groupUser);

        // 获取当前用户信息
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        String fromName = getMemberNickname(currentUserId, groupUsers, currentUser);

        // 发送系统消息给所有群成员
        String messageContent = StrUtil.format("{} 邀请 {} 加入群聊", fromName, inviteName);
        sendSystemMessageToGroup(group, currentUser, messageContent, groupUsers);
        
        // 将新成员添加到群成员列表，以便发送消息
        groupUsers.add(groupUser);
        
        // 发送系统消息给被邀请用户
        sendSystemMessageToUser(userId, group, currentUser, messageContent);

        return true;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean joinGroup(ImGroupJoinReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long groupId = reqVO.getId();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(groupId);
        if (group == null || group.getStatus() != 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, groupId)
        );

        // 检查当前用户是否已经是该群成员
        boolean isAlreadyMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        if (isAlreadyMember) {
            throw new ServiceException("你已经是该群成员");
        }

        // 加入该群
        ImGroupUserDO groupUser = new ImGroupUserDO();
        groupUser.setUserId(currentUserId);
        groupUser.setGroupId(groupId);
        imGroupUserMapper.insert(groupUser);

        // 获取当前用户信息
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        String fromName = StrUtil.isNotBlank(currentUser.getNickname()) ? currentUser.getNickname() : currentUser.getUsername();

        // 发送系统消息给所有群成员
        String messageContent = StrUtil.format("{} 加入群聊", fromName);
        sendSystemMessageToGroup(group, currentUser, messageContent, groupUsers);
        
        // 将当前用户添加到群成员列表
        groupUsers.add(groupUser);
        
        // 发送系统消息给当前用户
        sendSystemMessageToUser(currentUserId, group, currentUser, messageContent);

        return true;
    }

    @Override
    public GroupRelationRespVO checkGroupRelation(Long id) {
        Long currentUserId = getCurrentUserId();

        // 查询群聊信息
        ImGroupDO group = imGroupMapper.selectById(id);
        if (group == null || group.getStatus() != 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }

        // 查询群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, id)
        );

        // 检查当前用户是否是该群成员
        boolean isMember = groupUsers.stream()
                .anyMatch(user -> user.getUserId().equals(currentUserId));

        // 构建群聊信息响应
        GroupRelationRespVOImpl.GroupInfoRespImpl groupInfoResp = new GroupRelationRespVOImpl.GroupInfoRespImpl();
        groupInfoResp.setId(group.getId());
        groupInfoResp.setName(group.getName());
        groupInfoResp.setAvatar(group.getAvatar());
        groupInfoResp.setUsersCount(groupUsers.size());

        // 构建群聊关系响应
        GroupRelationRespVOImpl result = new GroupRelationRespVOImpl();
        result.setStatus(isMember);
        result.setGroup(groupInfoResp);

        return result;
    }

    /**
     * 获取成员昵称
     */
    private String getMemberNickname(Long userId, List<ImGroupUserDO> groupUsers, UserRespVO user) {
        // 查找群成员
        ImGroupUserDO member = groupUsers.stream()
                .filter(userDO -> userDO.getUserId().equals(userId))
                .findFirst()
                .orElse(null);

        if (member != null && StrUtil.isNotBlank(member.getNickname())) {
            return member.getNickname();
        }

        if (user != null) {
            return StrUtil.isNotBlank(user.getNickname()) ? user.getNickname() : user.getUsername();
        }

        return "";
    }

    /**
     * 构建系统消息
     */
    private ImChatMessageRespVO buildSystemMessage(ImGroupDO group, UserRespVO currentUser, String fromName, String data) {
        ImChatMessageRespVO message = new ImChatMessageRespVO();
        message.setId(System.currentTimeMillis());
        message.setFrom_avatar(currentUser.getAvatar());
        message.setFrom_name(fromName);
        message.setFrom_id(currentUser.getId());
        message.setTo_id(group.getId());
        message.setTo_name(group.getName());
        message.setTo_avatar(group.getAvatar());
        message.setChat_type("group");
        message.setType("system");
        message.setData(data);
        message.setOptions(new HashMap<>());
        message.setCreate_time(System.currentTimeMillis());
        message.setIsremove(0);
        return message;
    }

    /**
     * 发送系统消息给所有群成员
     */
    private void sendSystemMessageToGroup(ImGroupDO group, UserRespVO currentUser, String data, List<ImGroupUserDO> groupUsers) {
        String fromName = getMemberNickname(currentUser.getId(), groupUsers, currentUser);
        ImChatMessageRespVO message = buildSystemMessage(group, currentUser, fromName, data);

        for (ImGroupUserDO groupUser : groupUsers) {
            sendMessageToUser(groupUser.getUserId(), message);
        }
    }

    /**
     * 发送系统消息给指定用户
     */
    private void sendSystemMessageToUser(Long userId, ImGroupDO group, UserRespVO currentUser, String data) {
        String fromName = StrUtil.isNotBlank(currentUser.getNickname()) ? currentUser.getNickname() : currentUser.getUsername();
        ImChatMessageRespVO message = buildSystemMessage(group, currentUser, fromName, data);
        sendMessageToUser(userId, message);
    }

    /**
     * 发送消息给指定用户
     */
    private void sendMessageToUser(Long userId, ImChatMessageRespVO message) {
        String userIdStr = userId.toString();
        boolean isOnline = nettyService.isUserOnline(userIdStr);

        if (isOnline) {
            // 用户在线，直接发送消息
            nettyService.sendToUser(userIdStr, message);
            // 存到历史记录当中
            imMessageRedisDAO.addChatLog(userId, message.getChat_type(), message.getFrom_id(), message);
        } else {
            // 用户离线，存储到离线消息列表
            imMessageRedisDAO.addOfflineMessage(userId, message);
        }
    }
    
    @Override
    public byte[] generateGroupQrcode(Long id) {
        // 构建二维码内容
        String qrcodeContent = String.format("{\"id\":%d,\"type\":\"group\",\"event\":\"navigateTo\"}", id);
        
        // 使用Hutool的QrCodeUtil生成二维码
        return cn.hutool.extra.qrcode.QrCodeUtil.generatePng(qrcodeContent, 300, 300);
    }
}
