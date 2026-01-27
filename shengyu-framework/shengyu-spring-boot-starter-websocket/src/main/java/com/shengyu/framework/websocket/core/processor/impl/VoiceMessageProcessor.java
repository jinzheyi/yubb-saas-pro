package com.shengyu.framework.websocket.core.processor.impl;

import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.VoiceMessage;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.google.protobuf.InvalidProtocolBufferException;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 语音消息处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class VoiceMessageProcessor implements MessageProcessor {

    private final NettySessionManager sessionManager;
    private final MessageStorageService messageStorageService;

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析语音消息
            VoiceMessage voiceMessage = VoiceMessage.parseFrom(message.getBody());
            
            // 获取发送者会话
            NettySession senderSession = sessionManager.getSession(ctx.channel());
            if (senderSession == null) {
                log.warn("[VoiceMessage] 发送者会话不存在");
                return;
            }

            log.info("[VoiceMessage] 收到语音消息, from: {}, to: {}, duration: {}s", 
                message.getHeader().getSenderId(),
                message.getHeader().getReceiverId(),
                voiceMessage.getDuration());

            // 1. 存储消息到数据库
            messageStorageService.saveMessage(message);

            // 2. 转发给接收者
            Long receiverId = message.getHeader().getReceiverId();
            if (receiverId != null && receiverId > 0) {
                sessionManager.getSessionsByUserId(receiverId).forEach(session -> {
                    if (session.isActive()) {
                        session.getChannel().writeAndFlush(message);
                        session.updateLastActiveTime();
                        log.debug("[VoiceMessage] 转发语音消息给用户: {}", receiverId);
                    }
                });
            }

            // 3. 如果接收者离线，推送离线通知
            // TODO: 实现离线推送逻辑

        } catch (InvalidProtocolBufferException e) {
            log.error("[VoiceMessage] 解析消息失败", e);
        }
    }
}
