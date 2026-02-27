package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.TypingMessage;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.google.protobuf.InvalidProtocolBufferException;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 正在输入消息处理器
 * 
 * 功能：
 * 1. 解析正在输入消息
 * 2. 转发到目标用户
 * 3. 不存储到数据库（临时状态）
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TypingMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析正在输入消息
            TypingMessage typingMessage = TypingMessage.parseFrom(message.getBody());
            
            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[TypingMessage] 发送者会话不存在");
                return;
            }

            log.debug("[TypingMessage] 收到正在输入消息, from: {}, to: {}, typing: {}", 
                message.getHeader().getSenderId(),
                message.getHeader().getReceiverId(),
                typingMessage.getTyping());

            // 转发给接收者（不存储到数据库）
            Long receiverId = message.getHeader().getReceiverId();
            if (receiverId != null && receiverId > 0) {
                sessionManager.getSessionsByUserId(receiverId).forEach(session -> {
                    if (session.isActive()) {
                        session.getChannel().writeAndFlush(message);
                        log.debug("[TypingMessage] 转发正在输入状态给用户: {}", receiverId);
                    }
                });
            }

        } catch (InvalidProtocolBufferException e) {
            log.error("[TypingMessage] 解析消息失败", e);
        }
    }
}
