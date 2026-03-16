package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.json.JSONUtil;
import cn.hutool.json.JSONObject;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.framework.websocket.config.NettyProperties;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.codec.http.websocketx.*;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler.HandshakeComplete;
import io.netty.util.AttributeKey;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

/**
 * WebSocket 帧处理器
 * 处理 WebSocket 协议的各种帧类型
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@ChannelHandler.Sharable  // 标记为可共享的Handler
public class WebSocketFrameHandler extends SimpleChannelInboundHandler<WebSocketFrame> {

    private final NettySessionManager sessionManager;

    private final NettyProperties nettyProperties;

    public static final AttributeKey<Boolean> PROBE_DONE_KEY = AttributeKey.valueOf("PROBE_DONE");

    public static final AttributeKey<String> NEGOTIATED_SUBPROTOCOL_KEY = AttributeKey.valueOf("NEGOTIATED_SUBPROTOCOL");

    public static final AttributeKey<String> CODEC_KEY = AttributeKey.valueOf("CODEC");

    public static final AttributeKey<String> NEGOTIATION_MODE_KEY = AttributeKey.valueOf("NEGOTIATION_MODE");

    public WebSocketFrameHandler(NettySessionManager sessionManager, NettyProperties nettyProperties) {
        this.sessionManager = sessionManager;
        this.nettyProperties = nettyProperties;
    }

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, WebSocketFrame frame) {
        // 文本帧
        if (frame instanceof TextWebSocketFrame) {
            handleTextFrame(ctx, (TextWebSocketFrame) frame);
        }
        // 二进制帧
        else if (frame instanceof BinaryWebSocketFrame) {
            handleBinaryFrame(ctx, (BinaryWebSocketFrame) frame);
        }
        // Ping 帧
        else if (frame instanceof PingWebSocketFrame) {
            ctx.writeAndFlush(new PongWebSocketFrame(frame.content().retain()));
        }
        // Pong 帧
        else if (frame instanceof PongWebSocketFrame) {
            log.debug("[WebSocket] 收到 Pong 帧: {}", ctx.channel().id().asShortText());
        }
        // 关闭帧
        else if (frame instanceof CloseWebSocketFrame) {
            ctx.close();
        }
        // 其他类型帧
        else {
            log.warn("[WebSocket] 不支持的帧类型: {}", frame.getClass().getName());
        }
    }

    /**
     * 处理文本帧
     */
    private void handleTextFrame(ChannelHandlerContext ctx, TextWebSocketFrame frame) {
        String text = frame.text();
        log.debug("[WebSocket] 收到文本消息: {}, channel: {}", text, ctx.channel().id().asShortText());

        // B1：严格绑定载体与 codec；在 codec 尚未绑定前，仅允许 PROBE/CLOSE（TextFrame）
        // codec 绑定后：pb codec 仅允许 PROBE/PROBE_RESP/CLOSE 使用 TextFrame
        // 其余消息（包括 AUTH_REQ/HEARTBEAT/业务消息）必须走 BinaryFrame（Protobuf）
        String codec = null;
        try {
            codec = ctx.channel().attr(CODEC_KEY).get();
        } catch (Exception ignore) {
        }

        if (codec == null || codec.isEmpty()) {
            boolean allowed = false;
            try {
                JSONObject json = JSONUtil.parseObj(text);
                JSONObject header = json.getJSONObject("header");
                Integer mt = header != null ? header.getInt("messageType") : null;
                if (mt != null) {
                    allowed = (mt == 6 || mt == MessageType.CLOSE_VALUE);
                }
            } catch (Exception ignore) {
                allowed = false;
            }

            if (!allowed) {
                try {
                    String payload = JSONUtil.createObj()
                        .set("header", JSONUtil.createObj()
                            .set("messageId", System.currentTimeMillis())
                            .set("messageType", MessageType.CLOSE_VALUE)
                            .set("timestamp", System.currentTimeMillis()))
                        .set("body", JSONUtil.createObj()
                            .set("action", "CODEC_UNBOUND")
                            .set("code", 428)
                            .set("message", "当前连接尚未完成 codec 协商，请先发送 PROBE 或声明 SubProtocol"))
                        .toString();
                    ctx.writeAndFlush(new TextWebSocketFrame(payload));
                } catch (Exception ignore) {
                }
                ctx.close();
                return;
            }
        }

        if ("pb".equalsIgnoreCase(codec)) {
            boolean allowed = false;
            try {
                JSONObject json = JSONUtil.parseObj(text);
                JSONObject header = json.getJSONObject("header");
                Integer mt = header != null ? header.getInt("messageType") : null;
                if (mt != null) {
                    allowed = (mt == 6 || mt == 7 || mt == MessageType.CLOSE_VALUE);
                }
            } catch (Exception ignore) {
                allowed = false;
            }

            if (!allowed) {
                try {
                    String payload = JSONUtil.createObj()
                        .set("header", JSONUtil.createObj()
                            .set("messageId", System.currentTimeMillis())
                            .set("messageType", MessageType.CLOSE_VALUE)
                            .set("timestamp", System.currentTimeMillis()))
                        .set("body", JSONUtil.createObj()
                            .set("action", "CODEC_MISMATCH")
                            .set("code", 415)
                            .set("message", "当前连接已协商为 pb codec，TextFrame 仅允许 PROBE/PROBE_RESP/CLOSE，其余消息请使用 BinaryFrame"))
                        .toString();
                    ctx.writeAndFlush(new TextWebSocketFrame(payload));
                } catch (Exception ignore) {
                }
                ctx.close();
                return;
            }
        }
        
        // 将文本消息转发到业务处理器
        ctx.fireChannelRead(text);
    }

    /**
     * 处理二进制帧
     */
    private void handleBinaryFrame(ChannelHandlerContext ctx, BinaryWebSocketFrame frame) {
        log.debug("[WebSocket] 收到二进制消息, channel: {}", ctx.channel().id().asShortText());

        // B1：严格绑定载体与 codec；pb codec 才允许 BinaryFrame
        String codec = null;
        try {
            codec = ctx.channel().attr(CODEC_KEY).get();
        } catch (Exception ignore) {
        }
        if (codec == null || codec.isEmpty()) {
            try {
                String payload = JSONUtil.createObj()
                    .set("header", JSONUtil.createObj()
                        .set("messageId", System.currentTimeMillis())
                        .set("messageType", MessageType.CLOSE_VALUE)
                        .set("timestamp", System.currentTimeMillis()))
                    .set("body", JSONUtil.createObj()
                        .set("action", "CODEC_UNBOUND")
                        .set("code", 428)
                        .set("message", "当前连接尚未完成 codec 协商，不允许发送 BinaryFrame"))
                    .toString();
                ctx.writeAndFlush(new TextWebSocketFrame(payload));
            } catch (Exception ignore) {
            }
            ctx.close();
            return;
        }
        if (!"pb".equalsIgnoreCase(codec)) {
            try {
                String payload = JSONUtil.createObj()
                    .set("header", JSONUtil.createObj()
                        .set("messageId", System.currentTimeMillis())
                        .set("messageType", MessageType.CLOSE_VALUE)
                        .set("timestamp", System.currentTimeMillis()))
                    .set("body", JSONUtil.createObj()
                        .set("action", "CODEC_MISMATCH")
                        .set("code", 415)
                        .set("message", "当前连接未协商为 pb codec，不允许发送 BinaryFrame"))
                    .toString();
                ctx.writeAndFlush(new TextWebSocketFrame(payload));
            } catch (Exception ignore) {
            }
            ctx.close();
            return;
        }

        // 将二进制消息转发到 Protobuf 解码器（B3/B4 接通后生效）
        ctx.fireChannelRead(frame.content().retain());
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        log.info("[WebSocket] 连接建立: {}", ctx.channel().id().asShortText());

        // 严格模式：连接建立后必须在 probeTimeoutMs 内收到 PROBE
        try {
            ctx.channel().attr(PROBE_DONE_KEY).set(false);
            Long timeoutMs = nettyProperties != null ? nettyProperties.getProbeTimeoutMs() : 0L;
            if (timeoutMs == null) {
                timeoutMs = 0L;
            }
            final long finalTimeout = timeoutMs;
            if (finalTimeout > 0) {
                ctx.executor().schedule(() -> {
                    try {
                        Boolean done = ctx.channel().attr(PROBE_DONE_KEY).get();
                        if (Boolean.TRUE.equals(done)) {
                            return;
                        }
                        String channelId = ctx.channel().id().asShortText();
                        log.warn("[WebSocket] PROBE timeout, close channel: {}", channelId);
                        try {
                            String payload = JSONUtil.createObj()
                                .set("header", JSONUtil.createObj()
                                    .set("messageId", System.currentTimeMillis())
                                    .set("messageType", MessageType.CLOSE_VALUE)
                                    .set("timestamp", System.currentTimeMillis()))
                                .set("body", JSONUtil.createObj()
                                    .set("action", "PROBE_TIMEOUT")
                                    .set("code", 408)
                                    .set("message", "PROBE 超时，连接已关闭"))
                                .toString();
                            ctx.writeAndFlush(new TextWebSocketFrame(payload));
                        } catch (Exception ignore) {
                        }
                        sessionManager.removeSession(ctx.channel());
                        ctx.close();
                    } catch (Exception ignore) {
                    }
                }, finalTimeout, TimeUnit.MILLISECONDS);
            }
        } catch (Exception ignore) {
        }

        super.channelActive(ctx);
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        log.info("[WebSocket] 连接断开: {}", ctx.channel().id().asShortText());
        sessionManager.removeSession(ctx.channel());
        super.channelInactive(ctx);
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        // 绑定握手协商结果（selectedSubprotocol）到 channel attr
        if (evt instanceof HandshakeComplete) {
            try {
                HandshakeComplete e = (HandshakeComplete) evt;
                String sp = e.selectedSubprotocol();
                ctx.channel().attr(NEGOTIATED_SUBPROTOCOL_KEY).set(sp != null ? sp : "");

                // 企业级兼容策略：
                // - 优先使用 SubProtocol（Sec-WebSocket-Protocol）协商结果
                // - 严格模式：即使协商成功（pb/json 任一），仍要求客户端先发送 PROBE，再发送 AUTH_REQ
                // - SubProtocol 仅用于提前绑定 codec/negotiationMode，不能替代 PROBE（避免跳过能力/版本协商）
                if (sp != null && !sp.isEmpty()) {
                    ctx.channel().attr(NEGOTIATION_MODE_KEY).set("subprotocol");
                    try {
                        if ("im.pb.v1".equalsIgnoreCase(sp)) {
                            ctx.channel().attr(CODEC_KEY).set("pb");
                        } else {
                            ctx.channel().attr(CODEC_KEY).set("json");
                        }
                    } catch (Exception ignore) {
                    }
                }

                if (log.isInfoEnabled()) {
                    log.info("[WebSocket] handshake complete: channel={}, uri={}, subprotocol={}",
                        ctx.channel().id().asShortText(), e.requestUri(), sp);
                }
            } catch (Exception ex) {
                log.warn("[WebSocket] handshake complete event parse failed: {}", ctx.channel().id().asShortText(), ex);
            }
        }
        super.userEventTriggered(ctx, evt);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[WebSocket] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }
}
