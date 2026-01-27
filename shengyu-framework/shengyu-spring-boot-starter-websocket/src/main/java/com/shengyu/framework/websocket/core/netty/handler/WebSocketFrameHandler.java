package com.shengyu.framework.websocket.core.netty.handler;

import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.codec.http.websocketx.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * WebSocket 帧处理器
 * 处理 WebSocket 协议的各种帧类型
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class WebSocketFrameHandler extends SimpleChannelInboundHandler<WebSocketFrame> {

    private final NettySessionManager sessionManager;

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
        
        // 将文本消息转发到业务处理器
        ctx.fireChannelRead(text);
    }

    /**
     * 处理二进制帧
     */
    private void handleBinaryFrame(ChannelHandlerContext ctx, BinaryWebSocketFrame frame) {
        log.debug("[WebSocket] 收到二进制消息, channel: {}", ctx.channel().id().asShortText());
        
        // 将二进制消息转发到 Protobuf 解码器
        ctx.fireChannelRead(frame.content().retain());
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        log.info("[WebSocket] 连接建立: {}", ctx.channel().id().asShortText());
        super.channelActive(ctx);
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        log.info("[WebSocket] 连接断开: {}", ctx.channel().id().asShortText());
        sessionManager.removeSession(ctx.channel());
        super.channelInactive(ctx);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[WebSocket] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }
}
