package com.shengyu.module.system.service.im.impl;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.netty.service.NettyService;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyAddReqVO;
import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyHandleReqVO;
import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyListRespVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatMessageRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImApplyDO;
import com.shengyu.module.system.dal.dataobject.im.ImFriendDO;
import com.shengyu.module.system.dal.mysql.im.ImApplyMapper;
import com.shengyu.module.system.dal.mysql.im.ImFriendMapper;
import com.shengyu.module.system.dal.redis.im.ImMessageRedisDAO;
import com.shengyu.module.system.service.user.AdminUserService;
import com.shengyu.module.system.service.im.ImApplyService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * 好友申请服务实现
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Service
public class ImApplyServiceImpl implements ImApplyService {

    @Autowired
    private ImApplyMapper imApplyMapper;

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
    public ImApplyDO addFriend(ImApplyAddReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long friendId = reqVO.getFriendId();

        // 不能添加自己
        if (currentUserId.equals(friendId)) {
            throw new ServiceException("不能添加自己");
        }

        // 对方是否存在
        UserRespVO friendUser = adminUserService.getUser(friendId);
        if (friendUser == null || friendUser.getStatus() != 1) {
            throw new ServiceException("该用户不存在或者已被禁用");
        }

        // 之前是否申请过了
        ImApplyDO existingApply = imApplyMapper.selectOne(
                new LambdaQueryWrapper<ImApplyDO>()
                        .eq(ImApplyDO::getUserId, currentUserId)
                        .eq(ImApplyDO::getFriendId, friendId)
                        .in(ImApplyDO::getStatus, "pending", "agree")
        );
        if (existingApply != null) {
            throw new ServiceException("你之前已经申请过了");
        }

        // 创建申请
        ImApplyDO apply = new ImApplyDO();
        apply.setUserId(currentUserId);
        apply.setFriendId(friendId);
        apply.setNickname(reqVO.getNickname());
        apply.setLookme(Integer.parseInt(reqVO.getLookme()));
        apply.setLookhim(Integer.parseInt(reqVO.getLookhim()));
        apply.setStatus("pending");

        if (imApplyMapper.insert(apply) == 0) {
            throw new ServiceException("申请失败");
        }

        // 消息推送
        sendApplyNotification(friendId);

        return apply;
    }

    @Override
    public List<ImApplyListRespVO> getApplyList(int page, int limit) {
        Long currentUserId = getCurrentUserId();
        int offset = (page - 1) * limit;

        // 查询申请列表
        List<ImApplyDO> applyList = imApplyMapper.selectList(
                new LambdaQueryWrapper<ImApplyDO>()
                        .eq(ImApplyDO::getFriendId, currentUserId)
                        .orderByDesc(ImApplyDO::getId)
                        .last("LIMIT " + offset + ", " + limit)
        );

        List<ImApplyListRespVO> resultList = new ArrayList<>();
        for (ImApplyDO apply : applyList) {
            ImApplyListRespVO respVO = new ImApplyListRespVO();
            BeanUtils.copyProperties(apply, respVO);
            respVO.setApplyNickname(apply.getNickname());

            // 获取申请人信息
            UserRespVO user = adminUserService.getUser(apply.getUserId());
            if (user != null) {
                respVO.setUsername(user.getUsername());
                respVO.setNickname(user.getNickname());
                respVO.setAvatar(user.getAvatar());
            }

            // 将LocalDateTime转换为时间戳（毫秒）
            respVO.setCreateTime(apply.getCreateTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli());
            resultList.add(respVO);
        }

        return resultList;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean handleApply(Long id, ImApplyHandleReqVO reqVO) {
        Long currentUserId = getCurrentUserId();

        // 查询该申请是否存在
        ImApplyDO apply = imApplyMapper.selectOne(
                new LambdaQueryWrapper<ImApplyDO>()
                        .eq(ImApplyDO::getId, id)
                        .eq(ImApplyDO::getFriendId, currentUserId)
                        .eq(ImApplyDO::getStatus, "pending")
        );

        if (apply == null) {
            throw new ServiceException("该记录不存在");
        }

        // 更新申请状态
        apply.setStatus(reqVO.getStatus());
        imApplyMapper.updateById(apply);

        // 如果是同意申请，添加好友关系
        if ("agree".equals(reqVO.getStatus())) {
            // 加入到对方好友列表
            ImFriendDO friend1 = new ImFriendDO();
            friend1.setUserId(apply.getUserId());
            friend1.setFriendId(currentUserId);
            friend1.setNickname(apply.getNickname());
            friend1.setLookme(apply.getLookme());
            friend1.setLookhim(apply.getLookhim());
            friend1.setStar(0);
            friend1.setIsblack(0);
            imFriendMapper.insert(friend1);

            // 将对方加入到我的好友列表
            ImFriendDO friend2 = new ImFriendDO();
            friend2.setUserId(currentUserId);
            friend2.setFriendId(apply.getUserId());
            friend2.setNickname(reqVO.getNickname());
            friend2.setLookme(Integer.parseInt(reqVO.getLookme()));
            friend2.setLookhim(Integer.parseInt(reqVO.getLookhim()));
            friend2.setStar(0);
            friend2.setIsblack(0);
            imFriendMapper.insert(friend2);

            // 发送系统消息给双方
            sendSystemMessage(apply, reqVO);
        }

        return true;
    }

    /**
     * 发送申请通知
     */
    private void sendApplyNotification(Long userId) {
        // 发送更新申请列表的通知
        String userIdStr = userId.toString();
        boolean isOnline = nettyService.isUserOnline(userIdStr);
        if (isOnline) {
            nettyService.sendToUser(userIdStr, new HashMap<String, Object>() {{
                put("type", "updateApplyList");
            }});
        }
    }

    /**
     * 发送系统消息
     */
    private void sendSystemMessage(ImApplyDO apply, ImApplyHandleReqVO reqVO) {
        Long currentUserId = getCurrentUserId();

        // 获取双方用户信息
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        UserRespVO applyUser = adminUserService.getUser(apply.getUserId());

        if (currentUser == null || applyUser == null) {
            return;
        }

        // 构建系统消息
        ImChatMessageRespVO message = new ImChatMessageRespVO();
        message.setId(System.currentTimeMillis());
        message.setType("system");
        message.setData("你们已经是好友，可以开始聊天啦");
        message.setOptions(new HashMap<>());
        message.setCreate_time(System.currentTimeMillis());
        message.setIsremove(0);

        // 发送给申请人
        message.setFrom_id(currentUserId);
        message.setFrom_avatar(currentUser.getAvatar());
        message.setFrom_name(StrUtil.isNotBlank(currentUser.getNickname()) ? currentUser.getNickname() : currentUser.getUsername());
        message.setTo_id(apply.getUserId());
        message.setTo_name(StrUtil.isNotBlank(applyUser.getNickname()) ? applyUser.getNickname() : applyUser.getUsername());
        message.setTo_avatar(applyUser.getAvatar());
        message.setChat_type("user");

        sendMessageToUser(apply.getUserId(), message);

        // 发送给当前用户
        message.setFrom_id(apply.getUserId());
        message.setFrom_avatar(applyUser.getAvatar());
        message.setFrom_name(StrUtil.isNotBlank(applyUser.getNickname()) ? applyUser.getNickname() : applyUser.getUsername());
        message.setTo_id(currentUserId);
        message.setTo_name(StrUtil.isNotBlank(currentUser.getNickname()) ? currentUser.getNickname() : currentUser.getUsername());
        message.setTo_avatar(currentUser.getAvatar());

        sendMessageToUser(currentUserId, message);
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
        } else {
            // 用户离线，存储到离线消息列表
            imMessageRedisDAO.addOfflineMessage(userId, message);
        }

        // 存储到聊天记录
        imMessageRedisDAO.addChatLog(userId, message.getChat_type(), message.getFrom_id(), message);
    }
}
