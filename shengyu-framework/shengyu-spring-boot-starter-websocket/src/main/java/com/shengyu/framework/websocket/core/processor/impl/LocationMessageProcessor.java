package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.LocationMessage;
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
 * 位置消息处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LocationMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;
    private final MessageStorageService messageStorageService;
    private final NettyMessageSender messageSender;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析位置消息
            LocationMessage locationMessage = LocationMessage.parseFrom(message.getBody());
            
            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[LocationMessage] 发送者会话不存在");
                return;
            }

            log.info("[LocationMessage] 收到位置消息, from: {}, to: {}, address: {}", 
                message.getHeader().getSenderId(),
                message.getHeader().getReceiverId(),
                locationMessage.getAddress());

            // 1. 存储消息到数据库
            MessageSaveResult saveResult = messageStorageService.saveMessageWithResult(message);

            // 1.1 回推给发送者（用于端侧把 SENDING -> SENT）
            MessageHeader ackHeader = message.getHeader();
            messageSender.sendToUser(
                    ackHeader.getSenderId(),
                    ackHeader.getMessageType(),
                    locationMessage,
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
            Long groupId = message.getHeader().getGroupId();
            
            if (receiverId != null && receiverId > 0) {
                // 单聊：转发给接收者的所有在线设备
                MessageHeader header = message.getHeader();
                messageSender.sendToUser(
                        receiverId,
                        header.getMessageType(),
                        locationMessage,
                        header.getSenderId(),
                        receiverId,
                        groupId != null && groupId > 0 ? groupId : null,
                        header.getTenantId(),
                        header.getMessageId(),
                        saveResult != null ? saveResult.getSequence() : null,
                        saveResult != null ? saveResult.getChatId() : null
                );
            } else if (groupId != null && groupId > 0) {
                // 群聊：由消息总线处理转发
                log.debug("[LocationMessage] 群聊消息，groupId: {}, 由消息总线处理转发", groupId);
            }

        } catch (InvalidProtocolBufferException e) {
            log.error("[LocationMessage] 解析消息失败", e);
        }
    }
}
