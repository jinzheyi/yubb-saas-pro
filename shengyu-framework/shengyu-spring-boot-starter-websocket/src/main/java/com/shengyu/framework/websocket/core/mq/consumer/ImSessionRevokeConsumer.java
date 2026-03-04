package com.shengyu.framework.websocket.core.mq.consumer;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.mq.redis.core.pubsub.AbstractRedisChannelMessageListener;
import com.shengyu.framework.websocket.config.NettyProperties;
import com.shengyu.framework.websocket.core.mq.message.ImSessionRevokeMessage;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionAuthState;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.Channel;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.List;

/**
 * IM 会话撤销消费者（Redis Pub/Sub）
 */
@Slf4j
@Component
public class ImSessionRevokeConsumer extends AbstractRedisChannelMessageListener<ImSessionRevokeMessage> {

    @Resource
    private NettySessionManager sessionManager;

    @Resource
    private NettyProperties nettyProperties;

    @Override
    public void onMessage(ImSessionRevokeMessage message) {
        if (message == null) {
            return;
        }
        // 精确撤销优先级：accessToken -> (userId, deviceType, deviceId) -> userId
        // 只要有 accessToken 或 userId 任一维度，就可以处理（兼容批量撤销只带 userId 的场景）
        if (StrUtil.isBlank(message.getAccessToken()) && message.getUserId() == null) {
            return;
        }

        // clientId 过滤：避免非 IM OAuth2 client 的 revoke/refresh 影响 IM 连接
        // 约定：message.clientId 为空时，表示全量撤销（例如：管理员强退 / 互踢等）
        if (StrUtil.isNotBlank(message.getClientId())
            && nettyProperties != null
            && StrUtil.isNotBlank(nettyProperties.getImOAuth2ClientId())
            && !StrUtil.equals(message.getClientId(), nettyProperties.getImOAuth2ClientId())) {
            return;
        }

        String action = StrUtil.blankToDefault(message.getAction(), "REVOKED");
        String reason = StrUtil.blankToDefault(message.getReason(), "会话已失效");

        // 1) accessToken 精确撤销（O(1)）
        if (StrUtil.isNotBlank(message.getAccessToken())) {
            NettySession session = sessionManager.getSessionByAccessToken(message.getAccessToken());
            if (session == null || !session.isActive()) {
                return;
            }
            kickAndClose(session, action, reason);
            return;
        }

        // 2) 设备精确撤销（O(1)）
        if (message.getUserId() != null && message.getDeviceType() != null && StrUtil.isNotBlank(message.getDeviceId())) {
            NettySession session = sessionManager.getSessionByUserIdAndDevice(message.getUserId(), message.getDeviceType(), message.getDeviceId());
            if (session == null || !session.isActive()) {
                return;
            }
            kickAndClose(session, action, reason);
            return;
        }

        // 3) fallback：按 userId 批量撤销
        if (message.getUserId() == null) {
            return;
        }
        List<NettySession> sessions = sessionManager.getSessionsByUserId(message.getUserId());
        if (sessions.isEmpty()) {
            return;
        }

        log.info("[ImSessionRevokeConsumer] revoke userId={}, sessions={}, action={}, reason={}",
            message.getUserId(), sessions.size(), action, reason);

        for (NettySession session : sessions) {
            if (session == null || !session.isActive()) {
                continue;
            }
            kickAndClose(session, action, reason);
        }
    }

    private void kickAndClose(NettySession session, String action, String reason) {
        Channel ch = session.getChannel();
        if (ch == null) {
            return;
        }
        session.setAuthState(NettySessionAuthState.REVOKED);
        sendKicked(ch, 403, reason, action);
        sessionManager.removeSession(ch);
        ch.close();
    }

    private void sendKicked(Channel channel, int code, String message, String action) {
        if (isWebSocketChannel(channel)) {
            String payload = JSONUtil.createObj()
                .set("header", JSONUtil.createObj()
                    .set("messageId", System.currentTimeMillis())
                    .set("messageType", MessageType.CLOSE_VALUE)
                    .set("timestamp", System.currentTimeMillis()))
                .set("body", JSONUtil.createObj()
                    .set("action", action)
                    .set("code", code)
                    .set("message", message))
                .toString();
            channel.writeAndFlush(new TextWebSocketFrame(payload));
            return;
        }

        MessageHeader header = MessageHeader.newBuilder()
            .setMessageId(System.currentTimeMillis())
            .setMessageType(MessageType.CLOSE)
            .setTimestamp(System.currentTimeMillis())
            .setExtra(JSONUtil.createObj()
                .set("action", action)
                .set("code", code)
                .set("message", message)
                .toString())
            .build();
        channel.writeAndFlush(ImMessage.newBuilder().setHeader(header).build());
    }

    private boolean isWebSocketChannel(Channel channel) {
        try {
            return channel.pipeline().get(WebSocketServerProtocolHandler.class) != null;
        } catch (Exception ignore) {
            return false;
        }
    }
}
