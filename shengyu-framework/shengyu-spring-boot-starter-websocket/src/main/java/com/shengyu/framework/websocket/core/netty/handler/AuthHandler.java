package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.google.protobuf.InvalidProtocolBufferException;
import com.shengyu.framework.security.core.util.LoginBase;
import com.shengyu.framework.websocket.config.NettyProperties;
import com.shengyu.framework.websocket.core.protocol.*;
import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionAuthState;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import io.netty.util.AttributeKey;
import lombok.extern.slf4j.Slf4j;

/**
 * 认证处理器
 * 处理客户端认证请求
 *
 * 支持：
 * 1. 租户端（system）认证
 * 2. 平台端（platform）认证
 * 3. Token 验证
 * 4. 多设备登录
 * 5. JSON 格式消息（WebSocket）
 * 6. Protobuf 格式消息（TCP）
 *
 * @author 圣钰科技
 */
@Slf4j
@ChannelHandler.Sharable  // 标记为可共享的Handler
public class AuthHandler extends ChannelInboundHandlerAdapter {

    private static final AttributeKey<Boolean> AUTH_KEY = AttributeKey.valueOf("AUTH");
    private static final AttributeKey<Long> USER_ID_KEY = AttributeKey.valueOf("USER_ID");
    private static final AttributeKey<Long> TENANT_ID_KEY = AttributeKey.valueOf("TENANT_ID");

    private final NettySessionManager sessionManager;
    private final AuthService authService;
    private final NettyProperties nettyProperties;

    public AuthHandler(NettySessionManager sessionManager, AuthService authService, NettyProperties nettyProperties) {
        this.sessionManager = sessionManager;
        this.authService = authService;
        this.nettyProperties = nettyProperties;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        // 0) 企业级协议控制：PROBE/ACK（JSON TextFrame）
        // PROBE 允许在未认证阶段执行，用于能力协商/打点；ACK 仅在已认证阶段接收
        if (msg instanceof String) {
            try {
                JSONObject json = JSONUtil.parseObj((String) msg);
                JSONObject header = json.getJSONObject("header");
                Integer mt = header != null ? header.getInt("messageType") : null;
                if (mt != null) {
                    // B2：未认证阶段允许 CLOSE（协议控制帧），直接关闭连接
                    if (mt == MessageType.CLOSE_VALUE) {
                        ctx.close();
                        return;
                    }
                    if (mt == 6) {
                        handleJsonProbe(ctx, json);
                        return;
                    }
                    if (mt == 8 && isAuthenticated(ctx)) {
                        handleJsonAck(ctx, json);
                        return;
                    }
                    // 严格模式：未完成 PROBE 不允许 AUTH_REQ
                    if (mt == MessageType.AUTH_REQ_VALUE && !isProbeDone(ctx)) {
                        sendJsonClose(ctx, "PROBE_REQUIRED", 426, "协议不兼容：请先发送 PROBE");
                        ctx.close();
                        return;
                    }
                }
            } catch (Exception ignore) {
            }
        }

        // B2：未认证阶段允许 Protobuf CLOSE（协议控制帧），直接关闭连接
        if (msg instanceof ImMessage) {
            try {
                ImMessage im = (ImMessage) msg;
                if (im.getHeader() != null && im.getHeader().getMessageType() == MessageType.CLOSE) {
                    ctx.close();
                    return;
                }
                // 严格模式：未完成 PROBE 不允许 AUTH_REQ（Protobuf）
                if (im.getHeader() != null && im.getHeader().getMessageType() == MessageType.AUTH_REQ && !isProbeDone(ctx)) {
                    sendProtobufClose(ctx, "PROBE_REQUIRED", 426, "协议不兼容：请先发送 PROBE");
                    ctx.close();
                    return;
                }
            } catch (Exception ignore) {
            }
        }

        // 1) 如果是认证请求（AUTH_REQ），即使已认证也允许走 renew
        if (isAuthRequestMessage(msg)) {
            if (msg instanceof String) {
                handleJsonAuthRequest(ctx, JSONUtil.parseObj((String) msg));
            } else {
                handleProtobufAuthRequest(ctx, (ImMessage) msg);
            }
            return;
        }

        // 2) 已认证连接：检查租约
        if (isAuthenticated(ctx)) {
            NettySession session = sessionManager.getSession(ctx.channel());
            if (session != null && session.isLeaseExpired()) {
                // TODO: 使用独立的 REAUTH_REQUIRED 协议消息替代 CLOSE reason
                sendReAuthRequired(ctx, 401, "登录已过期，请重新登录");
                sessionManager.removeSession(ctx.channel());
                ctx.close();
                return;
            }
            super.channelRead(ctx, msg);
            return;
        }

        // 未认证且不是认证消息，拒绝处理
        log.warn("[Auth] 未找到认证请求: {}, msgType: {}", ctx.channel().id().asShortText(), msg.getClass().getSimpleName());
        if (msg instanceof String) {
            sendJsonAuthResponse(ctx, false, 401, "未认证，请先发送认证请求", 0L, 0L);
        } else {
            sendProtobufAuthResponse(ctx, false, 401, "未认证，请先发送认证请求", 0L, 0L);
        }
        ctx.close();
    }

    private void handleJsonProbe(ChannelHandlerContext ctx, JSONObject json) {
        try {
            markProbeDone(ctx);
            JSONObject body = json.getJSONObject("body");
            String requestedCodec = body != null ? body.getStr("codec") : "";

            // B1：绑定 codec（严格模式下，codec 影响 Text/Binary 载体约束）
            try {
                String sp = ctx.channel().attr(WebSocketFrameHandler.NEGOTIATED_SUBPROTOCOL_KEY).get();
                // 若握手已选 subprotocol，则以 subprotocol 为准；否则以 PROBE.codec 为准
                if (sp == null || sp.isEmpty()) {
                    if (requestedCodec != null && !requestedCodec.isEmpty()) {
                        if ("pb".equalsIgnoreCase(requestedCodec)) {
                            ctx.channel().attr(WebSocketFrameHandler.CODEC_KEY).set("pb");
                        } else {
                            ctx.channel().attr(WebSocketFrameHandler.CODEC_KEY).set("json");
                        }
                    } else {
                        ctx.channel().attr(WebSocketFrameHandler.CODEC_KEY).set("json");
                    }
                    ctx.channel().attr(WebSocketFrameHandler.NEGOTIATION_MODE_KEY).set("probe");
                }
            } catch (Exception ignore) {
            }

            String negotiatedSubprotocol = "";
            String negotiatedCodec = "json";
            String negotiationMode = "";
            try {
                negotiatedSubprotocol = ctx.channel().attr(WebSocketFrameHandler.NEGOTIATED_SUBPROTOCOL_KEY).get();
                String c = ctx.channel().attr(WebSocketFrameHandler.CODEC_KEY).get();
                String m = ctx.channel().attr(WebSocketFrameHandler.NEGOTIATION_MODE_KEY).get();
                if (c != null && !c.isEmpty()) {
                    negotiatedCodec = c;
                }
                if (m != null) {
                    negotiationMode = m;
                }
                if (negotiatedSubprotocol == null) {
                    negotiatedSubprotocol = "";
                }
            } catch (Exception ignore) {
            }

            JSONObject features = body != null ? body.getJSONObject("features") : null;
            boolean ack = features != null && Boolean.TRUE.equals(features.getBool("ack"));

            JSONObject response = JSONUtil.createObj()
                .set("header", JSONUtil.createObj()
                    .set("messageId", System.currentTimeMillis())
                    .set("messageType", 7)
                    .set("timestamp", System.currentTimeMillis()))
                .set("body", JSONUtil.createObj()
                    .set("version", 1)
                    .set("codec", negotiatedCodec)
                    .set("negotiationMode", negotiationMode)
                    .set("subprotocol", negotiatedSubprotocol)
                    .set("features", JSONUtil.createObj().set("ack", ack))
                    .set("serverTime", System.currentTimeMillis()));

            if (log.isInfoEnabled()) {
                log.info("[PROBE] ok: channel={}, codec={}, mode={}, subprotocol={}, requestedCodec={}",
                    ctx.channel().id().asShortText(), negotiatedCodec, negotiationMode, negotiatedSubprotocol, requestedCodec);
            }

            ctx.writeAndFlush(new TextWebSocketFrame(response.toString()));
        } catch (Exception e) {
            log.warn("[Auth] handleJsonProbe failed: {}", ctx.channel().id().asShortText(), e);
        }
    }

    private boolean isProbeDone(ChannelHandlerContext ctx) {
        try {
            Boolean done = ctx.channel().attr(WebSocketFrameHandler.PROBE_DONE_KEY).get();
            return Boolean.TRUE.equals(done);
        } catch (Exception e) {
            return false;
        }
    }

    private void markProbeDone(ChannelHandlerContext ctx) {
        try {
            ctx.channel().attr(WebSocketFrameHandler.PROBE_DONE_KEY).set(true);
        } catch (Exception ignore) {
        }
    }

    private void sendJsonClose(ChannelHandlerContext ctx, String action, int code, String message) {
        try {
            JSONObject payload = JSONUtil.createObj()
                .set("header", JSONUtil.createObj()
                    .set("messageId", System.currentTimeMillis())
                    .set("messageType", MessageType.CLOSE_VALUE)
                    .set("timestamp", System.currentTimeMillis()))
                .set("body", JSONUtil.createObj()
                    .set("action", action)
                    .set("code", code)
                    .set("message", message));
            ctx.writeAndFlush(new TextWebSocketFrame(payload.toString()));
        } catch (Exception ignore) {
        }
    }

    private void sendProtobufClose(ChannelHandlerContext ctx, String action, int code, String message) {
        try {
            MessageHeader header = MessageHeader.newBuilder()
                .setMessageId(System.currentTimeMillis())
                .setMessageType(MessageType.CLOSE)
                .setTimestamp(System.currentTimeMillis())
                .setExtra(JSONUtil.createObj().set("action", action).set("code", code).set("message", message).toString())
                .build();
            ImMessage close = ImMessage.newBuilder().setHeader(header).build();
            ctx.channel().writeAndFlush(close);
        } catch (Exception ignore) {
        }
    }

    private void handleJsonAck(ChannelHandlerContext ctx, JSONObject json) {
        try {
            JSONObject body = json.getJSONObject("body");
            String messageId = body != null ? body.getStr("messageId") : "";
            String chatId = body != null ? body.getStr("chatId") : "";
            String sequence = body != null ? body.getStr("sequence") : "";
            String ackType = body != null ? body.getStr("ackType") : "";

            long clientReceivedAt = 0L;
            long originalTimestamp = 0L;
            long deliveryDelayMs = -1L;
            try {
                Object cr = body != null ? body.get("clientReceivedAt") : null;
                if (cr != null) {
                    clientReceivedAt = Long.parseLong(String.valueOf(cr));
                }
            } catch (Exception ignore) {
                clientReceivedAt = 0L;
            }
            try {
                Object ot = body != null ? body.get("originalTimestamp") : null;
                if (ot != null) {
                    originalTimestamp = Long.parseLong(String.valueOf(ot));
                }
            } catch (Exception ignore) {
                originalTimestamp = 0L;
            }
            if (clientReceivedAt > 0 && originalTimestamp > 0) {
                deliveryDelayMs = clientReceivedAt - originalTimestamp;
            }

            if (log.isInfoEnabled()) {
                log.info("[ACK] received: channel={}, userId={}, messageId={}, chatId={}, sequence={}, ackType={}, clientReceivedAt={}, originalTimestamp={}, deliveryDelayMs={}",
                    ctx.channel().id().asShortText(), ctx.channel().attr(USER_ID_KEY).get(), messageId, chatId, sequence, ackType,
                    clientReceivedAt, originalTimestamp, deliveryDelayMs);
            }

            JSONObject response = JSONUtil.createObj()
                .set("header", JSONUtil.createObj()
                    .set("messageId", System.currentTimeMillis())
                    .set("messageType", 9)
                    .set("timestamp", System.currentTimeMillis()))
                .set("body", JSONUtil.createObj()
                    .set("success", true)
                    .set("messageId", messageId)
                    .set("chatId", chatId)
                    .set("sequence", sequence));
            ctx.writeAndFlush(new TextWebSocketFrame(response.toString()));
        } catch (Exception e) {
            log.warn("[Auth] handleJsonAck failed: {}", ctx.channel().id().asShortText(), e);
        }
    }

    /**
     * 处理 JSON 格式认证请求
     */
    private void handleJsonAuthRequest(ChannelHandlerContext ctx, JSONObject json) {
        try {
            JSONObject body = json.getJSONObject("body");
            String accessToken = body.getStr("accessToken");
            Integer deviceType = body.getInt("deviceType", 0);
            String deviceId = body.getStr("deviceId", "");
            String deviceName = body.getStr("deviceName", "");
            String clientVersion = body.getStr("clientVersion", "");

            if (StrUtil.isBlank(accessToken)) {
                sendJsonAuthResponse(ctx, false, 400, "Token 不能为空", 0L, 0L);
                ctx.close();
                return;
            }

            // 验证 Token（集成项目鉴权）
            LoginBase loginUser = authService.validateToken(accessToken);
            if (loginUser == null) {
                sendJsonAuthResponse(ctx, false, 401, "Token 无效或已过期", 0L, 0L);
                ctx.close();
                return;
            }

            // 获取租户ID（如果是租户端用户）
            Long tenantId = authService.getTenantId(loginUser);

            // 认证成功，标记为已认证
            ctx.channel().attr(AUTH_KEY).set(true);
            ctx.channel().attr(USER_ID_KEY).set(loginUser.getId());
            if (tenantId != null) {
                ctx.channel().attr(TENANT_ID_KEY).set(tenantId);
            }

            // 创建会话
            long now = System.currentTimeMillis();
            long leaseExpireTime = now + Math.max(1L, nettyProperties.getAuthLeaseSeconds()) * 1000L;
            NettySession session = NettySession.builder()
                .channel(ctx.channel())
                .userId(loginUser.getId())
                .tenantId(tenantId)
                .userType(loginUser.getUserType())
                .nickname(loginUser.getNickname())
                .deviceType(deviceType)
                .deviceId(deviceId)
                .deviceName(deviceName)
                .clientVersion(clientVersion)
                .accessToken(accessToken)
                .connectTime(now)
                .lastActiveTime(now)
                .lastBizActiveTime(now)
                .leaseExpireTime(leaseExpireTime)
                .authState(NettySessionAuthState.ACTIVE)
                .build();

            sessionManager.addSession(session);

            // 发送认证成功响应
            sendJsonAuthResponse(ctx, true, 0, "认证成功", loginUser.getId(), tenantId);

            String codec = "";
            String sp = "";
            String mode = "";
            try {
                String c = ctx.channel().attr(WebSocketFrameHandler.CODEC_KEY).get();
                codec = c != null ? c : "";
            } catch (Exception ignore) {
            }
            try {
                String s = ctx.channel().attr(WebSocketFrameHandler.NEGOTIATED_SUBPROTOCOL_KEY).get();
                sp = s != null ? s : "";
            } catch (Exception ignore) {
            }
            try {
                String m = ctx.channel().attr(WebSocketFrameHandler.NEGOTIATION_MODE_KEY).get();
                mode = m != null ? m : "";
            } catch (Exception ignore) {
            }
            log.info("[Auth] JSON 认证成功, userId: {}, tenantId: {}, userType: {}, channel: {}, codec: {}, subprotocol: {}, negotiationMode: {}",
                loginUser.getId(), tenantId, loginUser.getUserType(), ctx.channel().id().asShortText(), codec, sp, mode);

        } catch (Exception e) {
            log.error("[Auth] JSON 认证处理异常", e);
            sendJsonAuthResponse(ctx, false, 500, "服务器内部错误", 0L, 0L);
            ctx.close();
        }
    }

    /**
     * 处理 Protobuf 格式认证请求
     */
    private void handleProtobufAuthRequest(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析认证请求
            AuthRequest authRequest = AuthRequest.parseFrom(message.getBody());
            String accessToken = authRequest.getAccessToken();

            if (StrUtil.isBlank(accessToken)) {
                sendProtobufAuthResponse(ctx, false, 400, "Token 不能为空", 0L, 0L);
                ctx.close();
                return;
            }

            // 验证 Token（集成项目鉴权）
            LoginBase loginUser = authService.validateToken(accessToken);
            if (loginUser == null) {
                sendProtobufAuthResponse(ctx, false, 401, "Token 无效或已过期", 0L, 0L);
                ctx.close();
                return;
            }

            // 获取租户ID（如果是租户端用户）
            Long tenantId = authService.getTenantId(loginUser);

            // 认证成功，标记为已认证
            ctx.channel().attr(AUTH_KEY).set(true);
            ctx.channel().attr(USER_ID_KEY).set(loginUser.getId());
            if (tenantId != null) {
                ctx.channel().attr(TENANT_ID_KEY).set(tenantId);
            }

            // 创建会话
            long now = System.currentTimeMillis();
            long leaseExpireTime = now + Math.max(1L, nettyProperties.getAuthLeaseSeconds()) * 1000L;
            NettySession session = NettySession.builder()
                .channel(ctx.channel())
                .userId(loginUser.getId())
                .tenantId(tenantId)
                .userType(loginUser.getUserType())
                .nickname(loginUser.getNickname())
                .deviceType(authRequest.getDeviceType())
                .deviceId(authRequest.getDeviceId())
                .clientVersion(authRequest.getClientVersion())
                .accessToken(accessToken)
                .connectTime(now)
                .lastActiveTime(now)
                .lastBizActiveTime(now)
                .leaseExpireTime(leaseExpireTime)
                .authState(NettySessionAuthState.ACTIVE)
                .build();

            sessionManager.addSession(session);

            // 发送认证成功响应
            sendProtobufAuthResponse(ctx, true, 0, "认证成功", loginUser.getId(), tenantId);

            String codec = "";
            String sp = "";
            String mode = "";
            try {
                String c = ctx.channel().attr(WebSocketFrameHandler.CODEC_KEY).get();
                codec = c != null ? c : "";
            } catch (Exception ignore) {
            }
            try {
                String s = ctx.channel().attr(WebSocketFrameHandler.NEGOTIATED_SUBPROTOCOL_KEY).get();
                sp = s != null ? s : "";
            } catch (Exception ignore) {
            }
            try {
                String m = ctx.channel().attr(WebSocketFrameHandler.NEGOTIATION_MODE_KEY).get();
                mode = m != null ? m : "";
            } catch (Exception ignore) {
            }
            log.info("[Auth] Protobuf 认证成功, userId: {}, tenantId: {}, userType: {}, channel: {}, codec: {}, subprotocol: {}, negotiationMode: {}",
                loginUser.getId(), tenantId, loginUser.getUserType(), ctx.channel().id().asShortText(), codec, sp, mode);

        } catch (InvalidProtocolBufferException e) {
            log.error("[Auth] 解析 Protobuf 认证请求失败", e);
            sendProtobufAuthResponse(ctx, false, 400, "请求格式错误", 0L, 0L);
            ctx.close();
        } catch (Exception e) {
            log.error("[Auth] Protobuf 认证处理异常", e);
            sendProtobufAuthResponse(ctx, false, 500, "服务器内部错误", 0L, 0L);
            ctx.close();
        }
    }

    /**
     * 发送 JSON 格式认证响应
     */
    private void sendJsonAuthResponse(ChannelHandlerContext ctx, boolean success, int code,
                                     String message, Long userId, Long tenantId) {
        JSONObject response = JSONUtil.createObj()
            .set("header", JSONUtil.createObj()
                .set("messageId", System.currentTimeMillis())
                .set("messageType", MessageType.AUTH_RESP_VALUE)
                .set("timestamp", System.currentTimeMillis()))
            .set("body", JSONUtil.createObj()
                .set("success", success)
                .set("code", code)
                .set("message", message)
                .set("userId", userId != null ? userId : 0L)
                .set("tenantId", tenantId != null ? tenantId : 0L));

        ctx.writeAndFlush(new TextWebSocketFrame(response.toString()));
    }

    /**
     * 发送 Protobuf 格式认证响应
     */
    private void sendProtobufAuthResponse(ChannelHandlerContext ctx, boolean success, int code,
                                         String message, Long userId, Long tenantId) {
        AuthResponse authResponse = AuthResponse.newBuilder()
            .setSuccess(success)
            .setCode(code)
            .setMessage(message)
            .setUserId(userId != null ? userId : 0L)
            .setTenantId(tenantId != null ? tenantId : 0L)
            .build();

        ImMessage imMessage = ImMessage.newBuilder()
            .setHeader(MessageHeader.newBuilder()
                .setMessageId(System.currentTimeMillis())
                .setMessageType(MessageType.AUTH_RESP)
                .setTimestamp(System.currentTimeMillis())
                .build())
            .setBody(authResponse.toByteString())
            .build();

        ctx.channel().writeAndFlush(imMessage);
    }

    private boolean isWebSocketChannel(ChannelHandlerContext ctx) {
        try {
            return ctx != null
                && ctx.channel() != null
                && ctx.channel().pipeline().get(WebSocketServerProtocolHandler.class) != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 判断是否已认证
     */
    private boolean isAuthenticated(ChannelHandlerContext ctx) {
        Boolean auth = ctx.channel().attr(AUTH_KEY).get();
        return auth != null && auth;
    }

    private boolean isAuthRequestMessage(Object msg) {
        try {
            if (msg instanceof ImMessage) {
                return ((ImMessage) msg).getHeader().getMessageType() == MessageType.AUTH_REQ;
            }
            if (msg instanceof String) {
                JSONObject json = JSONUtil.parseObj((String) msg);
                JSONObject header = json.getJSONObject("header");
                return header != null && header.getInt("messageType") == MessageType.AUTH_REQ_VALUE;
            }
        } catch (Exception ignore) {
        }
        return false;
    }

    private void sendReAuthRequired(ChannelHandlerContext ctx, int code, String message) {
        if (isWebSocketChannel(ctx)) {
            JSONObject response = JSONUtil.createObj()
                .set("header", JSONUtil.createObj()
                    .set("messageId", System.currentTimeMillis())
                    .set("messageType", MessageType.CLOSE_VALUE)
                    .set("timestamp", System.currentTimeMillis()))
                .set("body", JSONUtil.createObj()
                    .set("code", code)
                    .set("message", message)
                    .set("action", "REAUTH_REQUIRED"));
            ctx.writeAndFlush(new TextWebSocketFrame(response.toString()));
            return;
        }

        // Protobuf：使用 CLOSE + header.extra 携带原因（兼容现有协议）
        // TODO: 使用独立的 REAUTH_REQUIRED Protobuf message 替代 extra 透传
        MessageHeader header = MessageHeader.newBuilder()
            .setMessageId(System.currentTimeMillis())
            .setMessageType(MessageType.CLOSE)
            .setTimestamp(System.currentTimeMillis())
            .setExtra(JSONUtil.createObj().set("code", code).set("message", message).set("action", "REAUTH_REQUIRED").toString())
            .build();
        ImMessage close = ImMessage.newBuilder().setHeader(header).build();
        ctx.writeAndFlush(close);
    }

    /**
     * 获取用户ID
     */
    public static Long getUserId(ChannelHandlerContext ctx) {
        return ctx.channel().attr(USER_ID_KEY).get();
    }

    /**
     * 获取租户ID
     */
    public static Long getTenantId(ChannelHandlerContext ctx) {
        return ctx.channel().attr(TENANT_ID_KEY).get();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[Auth] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }
}
