package com.shengyu.framework.netty.core;

import com.alibaba.fastjson.JSON;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.netty.config.NettyProperties;
import com.shengyu.framework.netty.core.auth.AuthInfo;
import com.shengyu.framework.netty.service.NettyAuthService;
import com.shengyu.framework.netty.service.NettyMessageHandler;
import com.shengyu.framework.netty.service.NettyMessageService;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.*;
import io.netty.handler.codec.http.*;
import io.netty.handler.codec.http.websocketx.*;
import io.netty.util.CharsetUtil;
import lombok.extern.slf4j.Slf4j;
import cn.hutool.core.util.StrUtil;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * 通道入站处理
 *
 * @author zhusy
 * @since 2022/11/13
 */
@Slf4j
@ChannelHandler.Sharable
public class ShengyuChannelInboundHandler extends SimpleChannelInboundHandler<Object> {

    private static final String DEFAULT_TOKEN_HEADER = "token";
    private static final String DEFAULT_TOKEN_PARAM = "token";
    private static final String DEFAULT_USER_ID_PARAM = "userId";

    private final NettyProperties nettyProperties;
    private final NettyAuthService nettyAuthService;
    private final NettyMessageService nettyMessageService;
    private final NettyMessageHandler nettyMessageHandler;

    /**
     * 构造函数
     *
     * @param nettyProperties    配置属性
     * @param nettyAuthService   认证服务
     * @param nettyMessageService 消息服务
     * @param nettyMessageHandler 消息处理器
     */
    public ShengyuChannelInboundHandler(NettyProperties nettyProperties,
                                       NettyAuthService nettyAuthService,
                                       NettyMessageService nettyMessageService,
                                       NettyMessageHandler nettyMessageHandler) {
        this.nettyProperties = nettyProperties;
        this.nettyAuthService = nettyAuthService;
        this.nettyMessageService = nettyMessageService;
        this.nettyMessageHandler = nettyMessageHandler;
    }

    @Override
    protected void channelRead0(ChannelHandlerContext context, Object o) throws Exception {
        if (o instanceof FullHttpRequest) {
            handlerHttpRequest(context, (FullHttpRequest) o);
        } else if (o instanceof WebSocketFrame) {
            handlerWebSocketFrame(context, (WebSocketFrame) o);
        }
    }

    /**
     * 处理HTTP请求
     *
     * @param context  通道处理上下文
     * @param request  HTTP请求
     */
    private void handlerHttpRequest(ChannelHandlerContext context, FullHttpRequest request) {
        try {
            // 1. 检查是否为WebSocket握手请求
            if (!request.decoderResult().isSuccess() || !"websocket".equals(request.headers().get(HttpHeaderNames.UPGRADE))) {
                sendHttpResponse(context, request, new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.BAD_REQUEST));
                return;
            }

            // 2. 提取token和userId
            AuthInfo authInfo = extractTokenFromRequest(request);
            if (authInfo == null) {
                sendHttpResponse(context, request, new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.UNAUTHORIZED));
                return;
            }

            // 3. 调用业务服务的认证逻辑
            if (!nettyAuthService.authenticate(authInfo, context.channel())) {
                sendHttpResponse(context, request, new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.UNAUTHORIZED));
                return;
            }

            // 4. 执行WebSocket握手
            WebSocketServerHandshakerFactory factory = new WebSocketServerHandshakerFactory(
                    buildWebSocketUrl(request), nettyProperties.getImProtocol(), true, 65536);
            WebSocketServerHandshaker handshaker = factory.newHandshaker(request);
            if (handshaker == null) {
                WebSocketServerHandshakerFactory.sendUnsupportedVersionResponse(context.channel());
            } else {
                handshaker.handshake(context.channel(), request);
                // 5. 保存认证信息和用户通道
                nettyAuthService.saveAuthInfo(context.channel(), authInfo);
                if (authInfo.getUserId() != null) {
                    nettyMessageService.addUserChannel(authInfo.getUserId(), context.channel());
                    log.info("用户 {} 建立WebSocket连接，通道: {}", authInfo.getUserId(), context.channel().id());
                }
            }
        } catch (Exception e) {
            log.error("处理WebSocket握手请求异常: {}", e.getMessage(), e);
            sendHttpResponse(context, request, new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.INTERNAL_SERVER_ERROR));
        }
    }
    
    /**
     * 从请求中提取token和userId
     *
     * @param request HTTP请求
     * @return 认证信息
     */
    private AuthInfo extractTokenFromRequest(FullHttpRequest request) {
        AuthInfo authInfo = new AuthInfo();
        
        // 从请求头中获取token
        String token = request.headers().get(DEFAULT_TOKEN_HEADER);
        String refreshToken = null;
        String userId = null;
        String tenantId = null;
        
        // 从请求头中获取tenantId
        tenantId = request.headers().get("tenant-id");
        
        // 从URI参数中获取token和userId
        try {
            URI uri = new URI(request.uri());
            String query = uri.getQuery();
            if (query != null) {
                Map<String, String> params = parseQueryString(query);
                if (StrUtil.isBlank(token)) {
                    token = params.get(DEFAULT_TOKEN_PARAM);
                }
                refreshToken = params.get("refreshToken");
                userId = params.get(DEFAULT_USER_ID_PARAM);
                if (StrUtil.isBlank(tenantId)) {
                    tenantId = params.get("tenantId");
                }
            }
        } catch (Exception e) {
            log.error("解析URI失败: {}", e.getMessage());
        }
        
        // 只需要token，userId可以后续通过token解析获取
        if (StrUtil.isNotBlank(token)) {
            authInfo.setToken(token);
            authInfo.setRefreshToken(refreshToken);
            authInfo.setUserId(userId);
            authInfo.setTenantId(tenantId);
            return authInfo;
        }
        
        return null;
    }

    /**
     * 处理WebSocket帧
     *
     * @param context        通道处理上下文
     * @param webSocketFrame WebSocket帧
     */
    private void handlerWebSocketFrame(ChannelHandlerContext context, WebSocketFrame webSocketFrame) {
        try {
            // 1. 判断是否为关闭帧
            if (webSocketFrame instanceof CloseWebSocketFrame) {
                handleCloseFrame(context, (CloseWebSocketFrame) webSocketFrame);
                return;
            }

            // 2. 判断是否为心跳帧
            if (webSocketFrame instanceof PingWebSocketFrame) {
                handlePingFrame(context, (PingWebSocketFrame) webSocketFrame);
                return;
            }

            if (webSocketFrame instanceof PongWebSocketFrame) {
                // 处理pong帧，无需响应，仅记录日志
                log.debug("收到Pong帧，通道: {}", context.channel().id());
                return;
            }

            // 3. 判断是否为文本帧
            if (!(webSocketFrame instanceof TextWebSocketFrame)) {
                log.warn("不支持的帧类型: {}, 通道: {}", webSocketFrame.getClass().getName(), context.channel().id());
                return;
            }

            // 4. 处理文本消息
            handleTextFrame(context, (TextWebSocketFrame) webSocketFrame);
        } catch (Exception e) {
            log.error("处理WebSocket帧异常: {}", e.getMessage(), e);
            context.close();
        }
    }

    /**
     * 处理关闭帧
     *
     * @param context        通道处理上下文
     * @param closeFrame     关闭帧
     */
    private void handleCloseFrame(ChannelHandlerContext context, CloseWebSocketFrame closeFrame) {
        // 获取用户ID
        AuthInfo authInfo = nettyAuthService.getAuthInfo(context.channel());
        if (authInfo != null && authInfo.getUserId() != null) {
            // 移除用户通道
            nettyMessageService.removeUserChannel(authInfo.getUserId());
            log.info("用户 {} 关闭WebSocket连接，通道: {}", authInfo.getUserId(), context.channel().id());
        } else {
            log.info("未知用户关闭WebSocket连接，通道: {}", context.channel().id());
        }
        
        // 清理认证信息
        nettyAuthService.clearAuthInfo(context.channel());
        
        // 关闭通道
        context.channel().close();
    }

    /**
     * 处理Ping帧
     *
     * @param context    通道处理上下文
     * @param pingFrame  Ping帧
     */
    private void handlePingFrame(ChannelHandlerContext context, PingWebSocketFrame pingFrame) {
        context.writeAndFlush(new PongWebSocketFrame(pingFrame.content().retain()));
        log.debug("收到Ping帧，返回Pong帧，通道: {}", context.channel().id());
    }

    /**
     * 处理文本帧
     *
     * @param context        通道处理上下文
     * @param textFrame      文本帧
     */
    private void handleTextFrame(ChannelHandlerContext context, TextWebSocketFrame textFrame) {
        String message = textFrame.text();
        log.debug("收到消息: {}, 通道: {}", message, context.channel().id());
        
        // 从通道中获取认证信息
        AuthInfo authInfo = nettyAuthService.getAuthInfo(context.channel());
        if (authInfo != null && authInfo.getUserId() != null) {
            // 调用业务服务的消息处理逻辑
            nettyMessageHandler.handleTextMessage(context, textFrame, authInfo.getUserId(), message);
        } else {
            log.warn("处理消息失败：未认证的通道，通道ID={}", context.channel().id());
        }
    }

    /**
     * 发送HTTP响应
     *
     * @param context  通道处理上下文
     * @param request  HTTP请求
     * @param response HTTP响应
     */
    private void sendHttpResponse(ChannelHandlerContext context, FullHttpRequest request, FullHttpResponse response) {
        // 1. 处理响应状态
        if (response.status().code() != 200) {
            ByteBuf buf = Unpooled.copiedBuffer(response.status().toString(), CharsetUtil.UTF_8);
            response.content().writeBytes(buf);
            buf.release();
        }
        HttpUtil.setContentLength(response, response.content().readableBytes());

        // 2. 发送响应
        if (response.status().code() == HttpResponseStatus.UNAUTHORIZED.code() || HttpResponseStatus.INTERNAL_SERVER_ERROR.code() == response.status().code()) {
            Map<String, Object> message = new HashMap<>();
            message.put("msg", "redirectToLogin");
            message.put("data", "token刷新失败,跳转登录页");
            // 发送消息给客户端
            context.writeAndFlush(new TextWebSocketFrame(JSON.toJSONString(message)));
        } else {
            ChannelFuture future = context.writeAndFlush(response);
            // 3. 如果响应失败，关闭通道
            if (!HttpUtil.isKeepAlive(request) || response.status().code() != 200) {
                future.addListener(ChannelFutureListener.CLOSE);
            }
        }
    }

    /**
     * 构建WebSocket URL
     *
     * @param request HTTP请求
     * @return WebSocket URL
     */
    private String buildWebSocketUrl(FullHttpRequest request) {
        String host = request.headers().get(HttpHeaderNames.HOST);
        if (nettyProperties.getImSocketUrl() != null) {
            return nettyProperties.getImProtocol() + "://" + host + nettyProperties.getImSocketUrl();
        }
        return "ws://" + host + request.uri();
    }



    /**
     * 解析查询字符串
     *
     * @param query 查询字符串
     * @return 参数映射
     */
    private Map<String, String> parseQueryString(String query) {
        Map<String, String> params = new HashMap<>();
        if (StrUtil.isBlank(query)) {
            return params;
        }
        
        String[] pairs = query.split("&");
        for (String pair : pairs) {
            int equalsIndex = pair.indexOf("=");
            if (equalsIndex > 0 && equalsIndex < pair.length() - 1) {
                try {
                    String key = URLDecoder.decode(pair.substring(0, equalsIndex), StandardCharsets.UTF_8.name());
                    String value = URLDecoder.decode(pair.substring(equalsIndex + 1), StandardCharsets.UTF_8.name());
                    params.put(key, value);
                } catch (Exception e) {
                    log.warn("URL解码失败，参数对: {}", pair, e);
                }
            }
        }
        return params;
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        // 通道关闭时，清理资源
        AuthInfo authInfo = nettyAuthService.getAuthInfo(ctx.channel());
        if (authInfo != null && authInfo.getUserId() != null) {
            nettyMessageService.removeUserChannel(authInfo.getUserId());
            log.info("通道关闭，移除用户通道: {}, 用户ID: {}", ctx.channel().id(), authInfo.getUserId());
        }
        nettyAuthService.clearAuthInfo(ctx.channel());
        super.channelInactive(ctx);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        log.error("通道发生异常: {}, 通道: {}", cause.getMessage(), ctx.channel().id(), cause);
        // 异常处理时，清理资源
        AuthInfo authInfo = nettyAuthService.getAuthInfo(ctx.channel());
        if (authInfo != null && authInfo.getUserId() != null) {
            nettyMessageService.removeUserChannel(authInfo.getUserId());
        }
        nettyAuthService.clearAuthInfo(ctx.channel());
        ctx.close();
    }
}
