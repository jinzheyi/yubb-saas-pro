package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.google.protobuf.InvalidProtocolBufferException;
import com.shengyu.framework.security.core.util.LoginBase;
import com.shengyu.framework.websocket.core.protocol.*;
import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
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

    public AuthHandler(NettySessionManager sessionManager, AuthService authService) {
        this.sessionManager = sessionManager;
        this.authService = authService;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        // 如果已认证，直接放行
        if (isAuthenticated(ctx)) {
            super.channelRead(ctx, msg);
            return;
        }

        // 处理 JSON 格式认证消息（WebSocket）
        if (msg instanceof String) {
            String text = (String) msg;
            try {
                JSONObject json = JSONUtil.parseObj(text);
                JSONObject header = json.getJSONObject("header");
                if (header != null && header.getInt("messageType") == MessageType.AUTH_REQ_VALUE) {
                    handleJsonAuthRequest(ctx, json);
                    return;
                }
            } catch (Exception e) {
                log.error("[Auth] JSON 认证请求解析失败: {}", text, e);
                sendJsonAuthResponse(ctx, false, 400, "请求格式错误", 0L, 0L);
                ctx.close();
                return;
            }
        }
        // 处理 Protobuf 格式认证消息（TCP）
        else if (msg instanceof ImMessage) {
            ImMessage imMessage = (ImMessage) msg;
            if (imMessage.getHeader().getMessageType() == MessageType.AUTH_REQ) {
                handleProtobufAuthRequest(ctx, imMessage);
                return;
            }
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

    /**
     * 处理 JSON 格式认证请求
     */
    private void handleJsonAuthRequest(ChannelHandlerContext ctx, JSONObject json) {
        try {
            JSONObject body = json.getJSONObject("body");
            String accessToken = body.getStr("accessToken");
            Integer deviceType = body.getInt("deviceType", 0);
            String deviceId = body.getStr("deviceId", "");
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
            NettySession session = NettySession.builder()
                .channel(ctx.channel())
                .userId(loginUser.getId())
                .tenantId(tenantId)
                .userType(loginUser.getUserType())
                .nickname(loginUser.getNickname())
                .deviceType(deviceType)
                .deviceId(deviceId)
                .clientVersion(clientVersion)
                .connectTime(System.currentTimeMillis())
                .lastActiveTime(System.currentTimeMillis())
                .build();

            sessionManager.addSession(session);

            // 发送认证成功响应
            sendJsonAuthResponse(ctx, true, 0, "认证成功", loginUser.getId(), tenantId);

            log.info("[Auth] JSON 认证成功, userId: {}, tenantId: {}, userType: {}, channel: {}",
                loginUser.getId(), tenantId, loginUser.getUserType(), ctx.channel().id().asShortText());

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
            NettySession session = NettySession.builder()
                .channel(ctx.channel())
                .userId(loginUser.getId())
                .tenantId(tenantId)
                .userType(loginUser.getUserType())
                .nickname(loginUser.getNickname())
                .deviceType(authRequest.getDeviceType())
                .deviceId(authRequest.getDeviceId())
                .clientVersion(authRequest.getClientVersion())
                .connectTime(System.currentTimeMillis())
                .lastActiveTime(System.currentTimeMillis())
                .build();

            sessionManager.addSession(session);

            // 发送认证成功响应
            sendProtobufAuthResponse(ctx, true, 0, "认证成功", loginUser.getId(), tenantId);

            log.info("[Auth] Protobuf 认证成功, userId: {}, tenantId: {}, userType: {}, channel: {}",
                loginUser.getId(), tenantId, loginUser.getUserType(), ctx.channel().id().asShortText());

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

        ctx.writeAndFlush(imMessage);
    }

    /**
     * 判断是否已认证
     */
    private boolean isAuthenticated(ChannelHandlerContext ctx) {
        Boolean auth = ctx.channel().attr(AUTH_KEY).get();
        return auth != null && auth;
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
