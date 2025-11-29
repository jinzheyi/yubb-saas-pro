package com.shengyu.module.im.netty;

import com.alibaba.fastjson.JSON;
import com.shengyu.framework.common.enums.im.ImMessageTypeEnum;
import com.shengyu.module.im.dto.ImMessage;
import com.shengyu.module.im.service.ImAuthService;
import com.shengyu.module.im.service.ImGroupService;
import com.shengyu.module.im.service.ImMessageService;
import com.shengyu.module.im.util.ImEncryptionUtil;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.timeout.IdleStateEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;

/**
 * IM消息处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class ImMessageHandler extends SimpleChannelInboundHandler<String> {

    @Autowired
    private ConnectionManager connectionManager;

    @Autowired
    private ImAuthService imAuthService;

    @Autowired
    private ImMessageService imMessageService;

    @Autowired
    private ImGroupService imGroupService;

    /**
     * 消息加密密钥（Base64编码）
     */
    @Value("${im.encryption.key:}")
    private String encryptionKey;

    /**
     * 是否启用消息加密
     */
    @Value("${im.encryption.enabled:false}")
    private boolean encryptionEnabled;

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, String msg) throws Exception {
        try {
            // 解密消息（如果启用了加密）
            String decryptedMsg = msg;
            if (encryptionEnabled && !msg.isEmpty()) {
                decryptedMsg = ImEncryptionUtil.decrypt(msg, encryptionKey);
            }
            
            // 解析消息
            ImMessage message = JSON.parseObject(decryptedMsg, ImMessage.class);
            log.debug("收到IM消息: {}", message);

            // 根据消息类型处理
            int type = message.getType();
            if (type == ImMessageTypeEnum.HEARTBEAT.getCode()) {
                handleHeartbeat(ctx, message);
            } else if (type == ImMessageTypeEnum.LOGIN_REQUEST.getCode()) {
                handleLogin(ctx, message);
            } else if (type == ImMessageTypeEnum.SINGLE_CHAT.getCode() ||
                    type == ImMessageTypeEnum.FILE_MESSAGE.getCode() ||
                    type == ImMessageTypeEnum.IMAGE_MESSAGE.getCode() ||
                    type == ImMessageTypeEnum.VOICE_MESSAGE.getCode() ||
                    type == ImMessageTypeEnum.VIDEO_MESSAGE.getCode()) {
                handleSingleChat(ctx, message);
            } else if (type == ImMessageTypeEnum.GROUP_CHAT.getCode()) {
                handleGroupChat(ctx, message);
            } else if (type == ImMessageTypeEnum.MESSAGE_ACK.getCode()) {
                handleMessageAck(ctx, message);
            } else {
                log.warn("未知消息类型: {}", message.getType());
            }
        } catch (Exception e) {
            log.error("处理IM消息失败: {}", msg, e);
            // 发送错误消息
            sendErrorMessage(ctx, "消息格式错误");
        }
    }

    /**
     * 处理心跳消息
     */
    private void handleHeartbeat(ChannelHandlerContext ctx, ImMessage message) {
        // 回复心跳
        ImMessage response = new ImMessage();
        response.setType(ImMessageTypeEnum.HEARTBEAT.getCode());
        // 将Date转换为LocalDateTime
        response.setTimestamp(LocalDateTime.now());
        sendMessage(ctx, response);
    }

    /**
     * 处理登录请求
     */
    private void handleLogin(ChannelHandlerContext ctx, ImMessage message) {
        imAuthService.authenticate(ctx, message);
    }

    /**
     * 处理单聊消息
     */
    private void handleSingleChat(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 1. 验证发送者权限
            Long senderId = connectionManager.getUserIdByChannel(ctx);
            if (senderId == null) {
                sendErrorMessage(ctx, "未登录或登录已过期");
                return;
            }

            // 2. 验证消息有效性
            if (message.getReceiverId() == null) {
                sendErrorMessage(ctx, "接收者ID不能为空");
                return;
            }

            // 3. 设置消息发送者ID
            message.setSenderId(senderId);

            // 4. 存储消息
            imMessageService.saveMessage(message);

            // 5. 转发消息给接收者
            Channel receiverChannel = connectionManager.getChannelByUserId(message.getReceiverId());
            if (receiverChannel != null && receiverChannel.isActive()) {
                sendMessage(receiverChannel, message);
            } else {
                // 接收者离线，消息已存储在数据库中，上线后会自动获取
                log.info("接收者离线，消息已存储: senderId={}, receiverId={}", senderId, message.getReceiverId());
            }

            // 6. 发送消息确认
            sendMessageAck(ctx, message.getMessageId(), true);
        } catch (Exception e) {
            log.error("处理单聊消息失败: {}", message, e);
            sendErrorMessage(ctx, "处理消息失败");
        }
    }

    /**
     * 处理群聊消息
     */
    private void handleGroupChat(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 1. 验证发送者权限
            Long senderId = connectionManager.getUserIdByChannel(ctx);
            if (senderId == null) {
                sendErrorMessage(ctx, "未登录或登录已过期");
                return;
            }

            // 2. 验证消息有效性
            if (message.getReceiverId() == null) {
                sendErrorMessage(ctx, "群组ID不能为空");
                return;
            }

            // 3. 设置消息发送者ID
            message.setSenderId(senderId);

            // 4. 存储消息
            imMessageService.saveMessage(message);

            // 5. 获取群成员列表
            List<Long> memberIds = imGroupService.getGroupMemberIds(message.getReceiverId());

            // 6. 转发消息给所有群成员
            for (Long memberId : memberIds) {
                if (memberId.equals(senderId)) {
                    continue; // 跳过发送者自己
                }
                Channel memberChannel = connectionManager.getChannelByUserId(memberId);
                if (memberChannel != null && memberChannel.isActive()) {
                    sendMessage(memberChannel, message);
                } else {
                    // 群成员离线，消息已存储在数据库中，上线后会自动获取
                    log.info("群成员离线，消息已存储: groupId={}, memberId={}", message.getReceiverId(), memberId);
                }
            }

            // 7. 发送消息确认
            sendMessageAck(ctx, message.getMessageId(), true);
        } catch (Exception e) {
            log.error("处理群聊消息失败: {}", message, e);
            sendErrorMessage(ctx, "处理消息失败");
        }
    }

    /**
     * 处理消息确认
     */
    private void handleMessageAck(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 1. 验证发送者权限
            Long senderId = connectionManager.getUserIdByChannel(ctx);
            if (senderId == null) {
                sendErrorMessage(ctx, "未登录或登录已过期");
                return;
            }

            // 2. 更新消息状态为已读
            imMessageService.updateMessageStatus(message.getMessageId(), 1);
            log.info("消息已确认: messageId={}, senderId={}", message.getMessageId(), senderId);
        } catch (Exception e) {
            log.error("处理消息确认失败: {}", message, e);
            sendErrorMessage(ctx, "处理消息确认失败");
        }
    }

    /**
     * 发送消息（自动处理加密）
     */
    private void sendMessage(ChannelHandlerContext ctx, ImMessage message) {
        try {
            String messageJson = JSON.toJSONString(message);
            
            // 加密消息（如果启用了加密）
            String finalMessage = messageJson;
            if (encryptionEnabled) {
                finalMessage = ImEncryptionUtil.encrypt(messageJson, encryptionKey);
            }
            
            ctx.writeAndFlush(finalMessage);
        } catch (Exception e) {
            log.error("发送消息失败: {}", message, e);
        }
    }

    /**
     * 发送消息（自动处理加密）
     */
    private void sendMessage(Channel channel, ImMessage message) {
        try {
            String messageJson = JSON.toJSONString(message);
            
            // 加密消息（如果启用了加密）
            String finalMessage = messageJson;
            if (encryptionEnabled) {
                finalMessage = ImEncryptionUtil.encrypt(messageJson, encryptionKey);
            }
            
            channel.writeAndFlush(finalMessage);
        } catch (Exception e) {
            log.error("发送消息失败: {}", message, e);
        }
    }

    /**
     * 发送消息确认
     */
    private void sendMessageAck(ChannelHandlerContext ctx, String messageId, boolean success) {
        ImMessage ackMessage = new ImMessage();
        ackMessage.setType(ImMessageTypeEnum.MESSAGE_ACK.getCode());
        ackMessage.setMessageId(messageId);
        ackMessage.setStatus(success ? 0 : 1);
        ackMessage.setTimestamp(LocalDateTime.now());
        sendMessage(ctx, ackMessage);
    }

    /**
     * 发送错误消息
     */
    private void sendErrorMessage(ChannelHandlerContext ctx, String errorMsg) {
        ImMessage errorMessage = new ImMessage();
        errorMessage.setType(ImMessageTypeEnum.ERROR.getCode());
        errorMessage.setContent(errorMsg);
        errorMessage.setTimestamp(LocalDateTime.now());
        sendMessage(ctx, errorMessage);
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent) {
            IdleStateEvent event = (IdleStateEvent) evt;
            switch (event.state()) {
                case READER_IDLE:
                    // 读空闲，关闭连接
                    log.info("客户端读空闲，关闭连接: {}", ctx.channel().remoteAddress());
                    ctx.close();
                    break;
                case WRITER_IDLE:
                    // 写空闲，发送心跳
                    ImMessage heartbeat = new ImMessage();
                    heartbeat.setType(ImMessageTypeEnum.HEARTBEAT.getCode());
                    heartbeat.setTimestamp(LocalDateTime.now());
                    ctx.writeAndFlush(JSON.toJSONString(heartbeat));
                    break;
                case ALL_IDLE:
                    // 读写都空闲
                    break;
                default:
                    break;
            }
        }
        super.userEventTriggered(ctx, evt);
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        log.info("客户端连接成功: {}", ctx.channel().remoteAddress());
        super.channelActive(ctx);
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        log.info("客户端断开连接: {}", ctx.channel().remoteAddress());
        // 获取断开连接的用户ID
        Long userId = connectionManager.getUserIdByChannel(ctx);
        // 移除用户连接
        connectionManager.removeConnection(ctx);
        // 如果用户ID不为空，调用logout方法更新用户状态
        if (userId != null) {
            imAuthService.logout(userId);
        }
        // TODO: 通知其他用户该用户下线
        super.channelInactive(ctx);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        log.error("客户端连接异常: {}", ctx.channel().remoteAddress(), cause);
        ctx.close();
    }
}
