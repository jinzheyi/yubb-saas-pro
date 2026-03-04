package com.shengyu.framework.websocket.core.session;

import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.config.NettyProperties;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import io.netty.channel.Channel;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import lombok.extern.slf4j.Slf4j;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * IM 鉴权租约扫描器
 *
 * 说明：
 * 1. 由于当前构建环境存在 protoc 依赖拉取失败问题，暂不新增 Protobuf 协议类型；
 *    租约提示与到期处理通过现有 MessageType（SYSTEM_NOTIFY/CLOSE）+ JSON extra/body 透传。
 * 2. 后续会补充独立的 RENEW_SUGGEST / REAUTH_REQUIRED / KICKED 协议消息。
 *
 * TODO: 将提示/关闭协议标准化为独立 Protobuf message，并为 WebSocket(JSON) 定义一致的 body schema。
 */
@Slf4j
public class NettyAuthLeaseMonitor {

    private final NettySessionManager sessionManager;
    private final NettyProperties nettyProperties;

    private ScheduledExecutorService executor;

    public NettyAuthLeaseMonitor(NettySessionManager sessionManager, NettyProperties nettyProperties) {
        this.sessionManager = sessionManager;
        this.nettyProperties = nettyProperties;
    }

    @PostConstruct
    public void start() {
        long intervalSeconds = Math.max(1L, nettyProperties.getAuthLeaseMonitorIntervalSeconds());
        this.executor = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "im-auth-lease-monitor");
            t.setDaemon(true);
            return t;
        });
        this.executor.scheduleAtFixedRate(this::scanOnce, intervalSeconds, intervalSeconds, TimeUnit.SECONDS);
        log.info("[LeaseMonitor] started, intervalSeconds={}", intervalSeconds);
    }

    @PreDestroy
    public void stop() {
        if (executor != null) {
            executor.shutdownNow();
        }
    }

    private void scanOnce() {
        try {
            List<NettySession> sessions = sessionManager.getAllSessions();
            if (sessions.isEmpty()) {
                return;
            }

            long now = System.currentTimeMillis();
            long suggestWindowMs = Math.max(1L, nettyProperties.getAuthRenewSuggestSeconds()) * 1000L;
            long activeWindowMs = Math.max(1L, nettyProperties.getBizActiveWindowSeconds()) * 1000L;

            for (NettySession session : sessions) {
                if (session == null || !session.isActive()) {
                    continue;
                }
                if (session.getLeaseExpireTime() == null || session.getLeaseExpireTime() <= 0) {
                    continue;
                }

                Channel ch = session.getChannel();
                if (ch == null) {
                    continue;
                }

                // 1) Lease 过期：强制重登
                if (session.isLeaseExpired()) {
                    sendReauthRequired(ch, 401, "登录已过期，请重新登录");
                    session.setAuthState(NettySessionAuthState.EXPIRED);
                    sessionManager.removeSession(ch);
                    ch.close();
                    continue;
                }

                // 2) 续期建议：仅在业务活跃窗口内提示
                long remainingMs = session.getLeaseExpireTime() - now;
                if (remainingMs <= suggestWindowMs) {
                    long lastBizActive = session.getLastBizActiveTime() != null ? session.getLastBizActiveTime() : 0L;
                    boolean active = (now - lastBizActive) <= activeWindowMs;
                    if (!active) {
                        continue;
                    }

                    Long lastSuggest = session.getLastRenewSuggestTime();
                    if (lastSuggest != null && (now - lastSuggest) <= Math.min(suggestWindowMs, 60_000L)) {
                        continue;
                    }

                    sendRenewSuggest(ch, (int) Math.max(0L, remainingMs / 1000L));
                    session.markRenewSuggested();
                }
            }
        } catch (Exception e) {
            log.warn("[LeaseMonitor] scan error: {}", e.getMessage());
        }
    }

    private void sendRenewSuggest(Channel channel, int remainingSeconds) {
        if (isWebSocketChannel(channel)) {
            String payload = JSONUtil.createObj()
                .set("header", JSONUtil.createObj()
                    .set("messageId", System.currentTimeMillis())
                    .set("messageType", MessageType.SYSTEM_NOTIFY_VALUE)
                    .set("timestamp", System.currentTimeMillis()))
                .set("body", JSONUtil.createObj()
                    .set("action", "RENEW_SUGGEST")
                    .set("remainingSeconds", remainingSeconds)
                    .set("message", "登录即将过期，建议刷新登录状态"))
                .toString();
            channel.writeAndFlush(new TextWebSocketFrame(payload));
            return;
        }

        // Protobuf：SYSTEM_NOTIFY + extra 透传
        MessageHeader header = MessageHeader.newBuilder()
            .setMessageId(System.currentTimeMillis())
            .setMessageType(MessageType.SYSTEM_NOTIFY)
            .setTimestamp(System.currentTimeMillis())
            .setExtra(JSONUtil.createObj()
                .set("action", "RENEW_SUGGEST")
                .set("remainingSeconds", remainingSeconds)
                .set("message", "登录即将过期，建议刷新登录状态")
                .toString())
            .build();
        channel.writeAndFlush(ImMessage.newBuilder().setHeader(header).build());
    }

    private void sendReauthRequired(Channel channel, int code, String message) {
        if (isWebSocketChannel(channel)) {
            String payload = JSONUtil.createObj()
                .set("header", JSONUtil.createObj()
                    .set("messageId", System.currentTimeMillis())
                    .set("messageType", MessageType.CLOSE_VALUE)
                    .set("timestamp", System.currentTimeMillis()))
                .set("body", JSONUtil.createObj()
                    .set("action", "REAUTH_REQUIRED")
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
                .set("action", "REAUTH_REQUIRED")
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
