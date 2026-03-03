package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.RecallMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.google.protobuf.InvalidProtocolBufferException;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 消息撤回处理器
 * 
 * 功能：
 * 1. 解析撤回消息
 * 2. 转发撤回通知到接收者
 * 3. 群聊时转发到所有群成员
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RecallMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;
    private final NettyMessageSender messageSender;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析撤回消息
            RecallMessage recallMessage = RecallMessage.parseFrom(message.getBody());
            
            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[RecallMessage] 发送者会话不存在");
                return;
            }

            log.info("[RecallMessage] 收到撤回消息, from: {}, to: {}, messageId: {}", 
                message.getHeader().getSenderId(),
                message.getHeader().getReceiverId(),
                recallMessage.getMessageId());

            // 转发撤回通知给接收者
            Long receiverId = message.getHeader().getReceiverId();
            Long groupId = message.getHeader().getGroupId();
            
            if (receiverId != null && receiverId > 0) {
                // 单聊：转发给接收者的所有在线设备（兼容 WebSocket JSON/TextFrame）
                MessageHeader header = message.getHeader();
                messageSender.sendToUser(
                        receiverId,
                        header.getMessageType(),
                        recallMessage,
                        header.getSenderId(),
                        receiverId,
                        groupId != null && groupId > 0 ? groupId : null,
                        header.getTenantId(),
                        header.getMessageId()
                );
            } else if (groupId != null && groupId > 0) {
                // 群聊：由消息总线处理转发到所有群成员
                log.debug("[RecallMessage] 群聊消息，groupId: {}, 由消息总线处理转发", groupId);
            }

        } catch (InvalidProtocolBufferException e) {
            log.error("[RecallMessage] 解析消息失败", e);
        }
    }
}
