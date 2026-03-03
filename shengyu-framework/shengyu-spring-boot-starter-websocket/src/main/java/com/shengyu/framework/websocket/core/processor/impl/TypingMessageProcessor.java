package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.TypingMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
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
    private final NettyMessageSender messageSender;

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
                typingMessage.getIsTyping());

            // 转发给接收者（不存储到数据库）
            Long receiverId = message.getHeader().getReceiverId();
            if (receiverId != null && receiverId > 0) {
                MessageHeader header = message.getHeader();
                messageSender.sendToUser(
                        receiverId,
                        header.getMessageType(),
                        typingMessage,
                        header.getSenderId(),
                        receiverId,
                        header.getGroupId() > 0 ? header.getGroupId() : null,
                        header.getTenantId(),
                        header.getMessageId()
                );
            }

        } catch (InvalidProtocolBufferException e) {
            log.error("[TypingMessage] 解析消息失败", e);
        }
    }
}
