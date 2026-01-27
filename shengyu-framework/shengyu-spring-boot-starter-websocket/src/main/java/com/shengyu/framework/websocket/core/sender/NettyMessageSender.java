package com.shengyu.framework.websocket.core.sender;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.google.protobuf.ByteString;
import com.google.protobuf.MessageLite;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Netty 消息发送器
 * 提供各种消息发送方法
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NettyMessageSender {

    private final NettySessionManager sessionManager;

    /**
     * 发送消息给指定用户
     *
     * @param userId      用户ID
     * @param messageType 消息类型
     * @param body        消息体
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body) {
        sendToUser(userId, messageType, body, null);
    }

    /**
     * 发送消息给指定用户
     *
     * @param userId      用户ID
     * @param messageType 消息类型
     * @param body        消息体
     * @param senderId    发送者ID
     */
    public void sendToUser(Long userId, MessageType messageType, MessageLite body, Long senderId) {
        List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
        if (sessions.isEmpty()) {
            log.debug("[MessageSender] 用户不在线: {}", userId);
            return;
        }

        ImMessage message = buildMessage(messageType, body, senderId, userId, null, null);
        
        int successCount = 0;
        for (NettySession session : sessions) {
            if (session.isActive()) {
                session.getChannel().writeAndFlush(message);
                successCount++;
            }
        }

        log.debug("[MessageSender] 发送消息给用户: {}, 设备数: {}, 成功: {}", 
            userId, sessions.size(), successCount);
    }

    /**
     * 发送消息给指定租户的所有用户
     *
     * @param tenantId    租户ID
     * @param messageType 消息类型
     * @param body        消息体
     */
    public void sendToTenant(Long tenantId, MessageType messageType, MessageLite body) {
        List<NettySession> sessions = sessionManager.getSessionsByTenantId(tenantId);
        if (sessions.isEmpty()) {
            log.debug("[MessageSender] 租户无在线用户: {}", tenantId);
            return;
        }

        ImMessage message = buildMessage(messageType, body, null, null, null, tenantId);
        
        int successCount = 0;
        for (NettySession session : sessions) {
            if (session.isActive()) {
                session.getChannel().writeAndFlush(message);
                successCount++;
            }
        }

        log.debug("[MessageSender] 发送消息给租户: {}, 用户数: {}, 成功: {}", 
            tenantId, sessions.size(), successCount);
    }

    /**
     * 广播消息给所有在线用户
     *
     * @param messageType 消息类型
     * @param body        消息体
     */
    public void broadcast(MessageType messageType, MessageLite body) {
        List<NettySession> sessions = sessionManager.getAllSessions();
        if (sessions.isEmpty()) {
            log.debug("[MessageSender] 无在线用户");
            return;
        }

        ImMessage message = buildMessage(messageType, body, null, null, null, null);
        
        int successCount = 0;
        for (NettySession session : sessions) {
            if (session.isActive()) {
                session.getChannel().writeAndFlush(message);
                successCount++;
            }
        }

        log.debug("[MessageSender] 广播消息, 总用户数: {}, 成功: {}", 
            sessions.size(), successCount);
    }

    /**
     * 发送消息给指定用户的指定设备
     *
     * @param userId      用户ID
     * @param deviceId    设备ID
     * @param messageType 消息类型
     * @param body        消息体
     */
    public void sendToDevice(Long userId, String deviceId, MessageType messageType, MessageLite body) {
        List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
        
        for (NettySession session : sessions) {
            if (deviceId.equals(session.getDeviceId()) && session.isActive()) {
                ImMessage message = buildMessage(messageType, body, null, userId, null, session.getTenantId());
                session.getChannel().writeAndFlush(message);
                log.debug("[MessageSender] 发送消息给设备: userId={}, deviceId={}", userId, deviceId);
                return;
            }
        }

        log.debug("[MessageSender] 设备不在线: userId={}, deviceId={}", userId, deviceId);
    }

    /**
     * 构建 IM 消息
     */
    private ImMessage buildMessage(MessageType messageType, MessageLite body, 
                                   Long senderId, Long receiverId, Long groupId, Long tenantId) {
        MessageHeader.Builder headerBuilder = MessageHeader.newBuilder()
            .setMessageId(generateMessageId())
            .setMessageType(messageType)
            .setTimestamp(System.currentTimeMillis());

        if (senderId != null) {
            headerBuilder.setSenderId(senderId);
        }
        if (receiverId != null) {
            headerBuilder.setReceiverId(receiverId);
        }
        if (groupId != null) {
            headerBuilder.setGroupId(groupId);
        }
        if (tenantId != null) {
            headerBuilder.setTenantId(tenantId);
        }

        ImMessage.Builder messageBuilder = ImMessage.newBuilder()
            .setHeader(headerBuilder.build());

        if (body != null) {
            messageBuilder.setBody(ByteString.copyFrom(body.toByteArray()));
        }

        return messageBuilder.build();
    }

    /**
     * 生成消息ID（雪花算法）
     * TODO: 集成实际的ID生成器
     */
    private long generateMessageId() {
        return System.currentTimeMillis();
    }
}
