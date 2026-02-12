package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.google.protobuf.InvalidProtocolBufferException;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 文本消息处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TextMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;
    private final MessageStorageService messageStorageService;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析文本消息
            TextMessage textMessage = TextMessage.parseFrom(message.getBody());
            
            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[TextMessage] 发送者会话不存在");
                return;
            }

            log.info("[TextMessage] 收到文本消息, from: {}, to: {}, group: {}, content: {}", 
                message.getHeader().getSenderId(),
                message.getHeader().getReceiverId(),
                message.getHeader().getGroupId(),
                textMessage.getContent());

            // 1. 存储消息到数据库
            messageStorageService.saveMessage(message);

            // 2. 转发消息
            Long receiverId = message.getHeader().getReceiverId();
            Long groupId = message.getHeader().getGroupId();
            
            if (receiverId != null && receiverId > 0) {
                // 单聊：转发给接收者的所有在线设备
                forwardToUser(receiverId, message);
            } else if (groupId != null && groupId > 0) {
                // 群聊：转发给群成员的所有在线设备（由中间件的消息总线处理）
                // 注意：这里只是示例，实际群聊需要查询群成员列表
                // 在分布式环境下，消息总线会自动转发到其他节点
                log.debug("[TextMessage] 群聊消息，groupId: {}, 由消息总线处理转发", groupId);
                // TODO: 查询群成员列表并转发（可选，也可以在 SystemMessageStorageServiceImpl 中处理）
            }

            // 3. 如果接收者离线，推送离线通知
            // TODO: 实现离线推送逻辑

        } catch (InvalidProtocolBufferException e) {
            log.error("[TextMessage] 解析消息失败", e);
        }
    }

    /**
     * 转发消息给指定用户的所有在线设备
     */
    private void forwardToUser(Long userId, ImMessage message) {
        sessionManager.getSessionsByUserId(userId).forEach(session -> {
            if (session.isActive()) {
                session.getChannel().writeAndFlush(message);
                session.updateLastActiveTime();
                log.debug("[TextMessage] 转发消息给用户: {}, 设备类型: {}", 
                    userId, session.getDeviceType());
            }
        });
    }
}
