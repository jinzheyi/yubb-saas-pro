package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImageMessage;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.service.dto.MessageSaveResult;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.google.protobuf.InvalidProtocolBufferException;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 图片消息处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImageMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;
    private final MessageStorageService messageStorageService;
    private final NettyMessageSender messageSender;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析图片消息
            ImageMessage imageMessage = ImageMessage.parseFrom(message.getBody());
            
            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[ImageMessage] 发送者会话不存在");
                return;
            }

            log.info("[ImageMessage] 收到图片消息, from: {}, to: {}, url: {}", 
                message.getHeader().getSenderId(),
                message.getHeader().getReceiverId(),
                imageMessage.getUrl());

            // 1. 存储消息到数据库
            MessageSaveResult saveResult = messageStorageService.saveMessageWithResult(message);

            // 1.1 回推给发送者（用于端侧把 SENDING -> SENT）
            MessageHeader ackHeader = message.getHeader();
            messageSender.sendToUser(
                    ackHeader.getSenderId(),
                    ackHeader.getMessageType(),
                    imageMessage,
                    ackHeader.getSenderId(),
                    ackHeader.getReceiverId(),
                    ackHeader.getGroupId() > 0 ? ackHeader.getGroupId() : null,
                    ackHeader.getTenantId(),
                    ackHeader.getMessageId(),
                    saveResult != null ? saveResult.getSequence() : null,
                    saveResult != null ? saveResult.getChatId() : null
            );

            // 2. 转发给接收者
            Long receiverId = message.getHeader().getReceiverId();
            if (receiverId != null && receiverId > 0) {
                MessageHeader header = message.getHeader();
                messageSender.sendToUser(
                        receiverId,
                        header.getMessageType(),
                        imageMessage,
                        header.getSenderId(),
                        receiverId,
                        header.getGroupId() > 0 ? header.getGroupId() : null,
                        header.getTenantId(),
                        header.getMessageId(),
                        saveResult != null ? saveResult.getSequence() : null,
                        saveResult != null ? saveResult.getChatId() : null
                );
            }

            // 3. 如果接收者离线，推送离线通知
            // TODO: 实现离线推送逻辑

        } catch (InvalidProtocolBufferException e) {
            log.error("[ImageMessage] 解析消息失败", e);
        }
    }
}
