package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.netty.service.NettyService;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatMessageRespVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatRecallReqVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatSendReqVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImFriendDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupUserDO;
import com.shengyu.module.system.dal.mysql.im.ImFriendMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupMapper;
import com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper;
import com.shengyu.module.system.dal.redis.im.ImMessageRedisDAO;
import com.shengyu.module.system.service.user.AdminUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;

/**
 * 用户聊天 Service 接口实现类
 *
 * @author zhusy
 * @since 2022/11/23
 */
@Service
public class ImChatServiceImpl implements ImChatService {

    @Autowired
    private ImFriendMapper imFriendMapper;

    @Autowired
    private ImGroupMapper imGroupMapper;

    @Autowired
    private ImGroupUserMapper imGroupUserMapper;

    @Autowired
    private AdminUserService adminUserService;

    @Autowired
    private ImMessageRedisDAO imMessageRedisDAO;

    @Autowired
    private NettyService nettyService;

    /**
     * 获取当前登录用户ID
     */
    private Long getCurrentUserId() {
        return SecurityFrameworkUtils.getLoginUserId();
    }

    @Override
    public ImChatMessageRespVO sendMessage(ImChatSendReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        String chatType = reqVO.getChat_type();
        
        if ("user".equals(chatType)) {
            return sendUserMessage(currentUserId, reqVO);
        } else if ("group".equals(chatType)) {
            return sendGroupMessage(currentUserId, reqVO);
        } else {
            throw new ServiceException("聊天类型不支持");
        }
    }

    /**
     * 发送单聊消息
     */
    private ImChatMessageRespVO sendUserMessage(Long currentUserId, ImChatSendReqVO reqVO) {
        Long toId = reqVO.getTo_id();
        
        // 验证好友关系
        ImFriendDO friend = imFriendMapper.selectOne(
            new LambdaQueryWrapper<ImFriendDO>()
                .eq(ImFriendDO::getUserId, toId)
                .eq(ImFriendDO::getFriendId, currentUserId)
                .eq(ImFriendDO::getIsblack, 0)
        );
        
        if (friend == null) {
            throw new ServiceException("对方不存在或者已经把你拉黑");
        }
        
        // 获取发送者和接收者信息
        UserRespVO sender = adminUserService.getUser(currentUserId);
        UserRespVO receiver = adminUserService.getUser(toId);
        
        // 验证接收者是否被禁用
        if (receiver == null || receiver.getStatus() == 0) {
            throw new ServiceException("对方已被禁用");
        }
        
        // 构建消息
        ImChatMessageRespVO message = buildMessage(currentUserId, reqVO, sender, receiver);
        
        // 发送消息
        sendMessageToUser(toId, message, "ok");
        
        return message;
    }

    /**
     * 发送群聊消息
     */
    private ImChatMessageRespVO sendGroupMessage(Long currentUserId, ImChatSendReqVO reqVO) {
        Long groupId = reqVO.getTo_id();
        
        // 验证群聊是否存在且启用
        ImGroupDO group = imGroupMapper.selectById(groupId);
        if (group == null || group.getStatus() == 0) {
            throw new ServiceException("该群聊不存在或者已被封禁");
        }
        
        // 验证当前用户是否是群成员
        ImGroupUserDO groupUser = imGroupUserMapper.selectOne(
            new LambdaQueryWrapper<ImGroupUserDO>()
                .eq(ImGroupUserDO::getGroupId, groupId)
                .eq(ImGroupUserDO::getUserId, currentUserId)
        );
        
        if (groupUser == null) {
            throw new ServiceException("你不是该群的成员");
        }
        
        // 获取发送者信息
        UserRespVO sender = adminUserService.getUser(currentUserId);
        
        // 构建消息
        ImChatMessageRespVO message = buildMessage(currentUserId, reqVO, sender, null);
        message.setTo_name(group.getName());
        message.setTo_avatar(group.getAvatar());
        
        // 获取群成员列表
        List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
            new LambdaQueryWrapper<ImGroupUserDO>()
                .eq(ImGroupUserDO::getGroupId, groupId)
        );
        
        // 发送消息给所有群成员（除了发送者自己）
        for (ImGroupUserDO member : groupUsers) {
            if (!member.getUserId().equals(currentUserId)) {
                sendMessageToUser(member.getUserId(), message, "ok");
            }
        }
        
        return message;
    }

    /**
     * 构建消息
     */
    private ImChatMessageRespVO buildMessage(Long currentUserId, ImChatSendReqVO reqVO, UserRespVO sender, UserRespVO receiver) {
        ImChatMessageRespVO message = new ImChatMessageRespVO();
        
        // 设置基本信息
        message.setId(System.currentTimeMillis());
        message.setFrom_id(currentUserId);
        message.setFrom_avatar(sender.getAvatar());
        message.setFrom_name(StrUtil.isNotBlank(sender.getNickname()) ? sender.getNickname() : sender.getUsername());
        message.setTo_id(reqVO.getTo_id());
        message.setChat_type(reqVO.getChat_type());
        message.setType(reqVO.getType());
        message.setData(reqVO.getData());
        message.setOptions(new HashMap<>());
        message.setCreate_time(System.currentTimeMillis());
        message.setIsremove(0);
        
        // 设置接收者信息（单聊）
        if (receiver != null) {
            message.setTo_name(StrUtil.isNotBlank(receiver.getNickname()) ? receiver.getNickname() : receiver.getUsername());
            message.setTo_avatar(receiver.getAvatar());
        }
        
        // 处理特殊消息类型
        if ("video".equals(reqVO.getType())) {
            // 视频，添加封面
            message.getOptions().put("poster", reqVO.getData() + "?x-oss-process=video/snapshot,t_10,m_fast,w_300,f_png");
        } else if ("audio".equals(reqVO.getType())) {
            // 音频，添加时长
            message.getOptions().put("time", 1);
        } else if ("card".equals(reqVO.getType())) {
            // 名片，解析options
            message.setOptions(new HashMap<>());
        }
        
        return message;
    }

    /**
     * 发送消息给指定用户
     */
    private void sendMessageToUser(Long userId, ImChatMessageRespVO message, String msg) {
        Long currentUserId = getCurrentUserId();
        String chatType = message.getChat_type();
        String userIdStr = userId.toString();
        
        // 检查用户是否在线
        boolean isOnline = nettyService.isUserOnline(userIdStr);
        
        if (isOnline) {
            // 用户在线，直接发送消息
            nettyService.sendToUser(userIdStr, message);
            // 存储到聊天记录
            imMessageRedisDAO.addChatLog(userId, chatType, currentUserId, message);
        } else {
            // 用户离线，存储到离线消息列表
            imMessageRedisDAO.addOfflineMessage(userId, message);
        }
        
        // 存储到发送者的聊天记录
        imMessageRedisDAO.addChatLog(currentUserId, chatType, userId, message);
    }

    @Override
    public void getOfflineMessage() {
        Long currentUserId = getCurrentUserId();
        String currentUserIdStr = currentUserId.toString();
        
        // 获取离线消息列表
        List<String> offlineMessages = imMessageRedisDAO.getOfflineMessages(currentUserId);
        
        if (offlineMessages != null && !offlineMessages.isEmpty()) {
            // 批量处理离线消息
            for (String offlineMessageStr : offlineMessages) {
                try {
                    ImChatMessageRespVO message = JsonUtils.parseObject(offlineMessageStr, ImChatMessageRespVO.class);
                    if (message != null) {
                        // 直接发送离线消息
                        nettyService.sendToUser(currentUserIdStr, message);
                        
                        // 存储到聊天记录
                        String chatType = message.getChat_type();
                        Long fromId = message.getFrom_id();
                        if (chatType != null && fromId != null) {
                            imMessageRedisDAO.addChatLog(currentUserId, chatType, fromId, message);
                        }
                    }
                } catch (Exception e) {
                    // 忽略解析错误的消息
                }
            }
            
            // 清除离线消息
            imMessageRedisDAO.deleteOfflineMessages(currentUserId);
        }
    }

    @Override
    public ImChatMessageRespVO recallMessage(ImChatRecallReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        String chatType = reqVO.getChat_type();
        Long toId = reqVO.getTo_id();
        Long messageId = reqVO.getId();
        
        // 构建撤回消息
        ImChatMessageRespVO message = new ImChatMessageRespVO();
        message.setFrom_id(currentUserId);
        message.setTo_id(toId);
        message.setChat_type(chatType);
        message.setId(messageId);
        
        if ("user".equals(chatType)) {
            // 单聊撤回
            sendMessageToUser(toId, message, "recall");
        } else if ("group".equals(chatType)) {
            // 群聊撤回
            ImGroupDO group = imGroupMapper.selectById(toId);
            if (group != null) {
                // 获取群成员列表
                List<ImGroupUserDO> groupUsers = imGroupUserMapper.selectList(
                    new LambdaQueryWrapper<ImGroupUserDO>()
                        .eq(ImGroupUserDO::getGroupId, toId)
                );
                
                // 发送撤回消息给所有群成员（除了发送者自己）
                for (ImGroupUserDO member : groupUsers) {
                    if (!member.getUserId().equals(currentUserId)) {
                        sendMessageToUser(member.getUserId(), message, "recall");
                    }
                }
            }
        }
        
        return message;
    }
}
