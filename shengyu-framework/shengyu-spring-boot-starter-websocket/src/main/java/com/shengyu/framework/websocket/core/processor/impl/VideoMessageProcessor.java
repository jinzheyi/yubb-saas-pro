package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.VideoMessage;
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
 * 视频消息处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class VideoMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;
    private final MessageStorageService messageStorageService;
    private final NettyMessageSender messageSender;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析视频消息
            VideoMessage videoMessage = VideoMessage.parseFrom(message.getBody());
            
            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[VideoMessage] 发送者会话不存在");
                return;
            }

            log.info("[VideoMessage] 收到视频消息, from: {}, to: {}, url: {}", 
                message.getHeader().getSenderId(),
                message.getHeader().getReceiverId(),
                videoMessage.getUrl());

            // 1. 存储消息到数据库
            MessageSaveResult saveResult = messageStorageService.saveMessageWithResult(message);
            if (saveResult == null || saveResult.getMessageId() == null || saveResult.getChatId() == null) {
                log.error("[VideoMessage] 消息未持久化，跳过回推与转发。messageId={}, saveResult={}",
                        message.getHeader().getMessageId(), saveResult);
                return;
            }

            // 1.1 回推给发送者（用于端侧把 SENDING -> SENT）
            MessageHeader ackHeader = message.getHeader();
            messageSender.sendToUser(
                    ackHeader.getSenderId(),
                    ackHeader.getMessageType(),
                    videoMessage,
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
                        videoMessage,
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
                log.debug("[VideoMessage] 群聊消息，groupId: {}, 由消息总线处理转发", groupId);
            }

        } catch (InvalidProtocolBufferException e) {
            log.error("[VideoMessage] 解析消息失败", e);
        }
    }
}
