package com.shengyu.framework.websocket.core.netty.handler;

import com.google.protobuf.CodedOutputStream;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelOutboundHandlerAdapter;
import io.netty.channel.ChannelPromise;
import io.netty.handler.codec.http.websocketx.BinaryWebSocketFrame;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

@Slf4j
@Component
@ChannelHandler.Sharable
public class WebSocketProtobufOutboundHandler extends ChannelOutboundHandlerAdapter {

    @Override
    public void write(ChannelHandlerContext ctx, Object msg, ChannelPromise promise) throws Exception {
        if (msg instanceof ImMessage && isWebSocketChannel(ctx) && isPbCodec(ctx)) {
            try {
                ImMessage m = (ImMessage) msg;
                byte[] bytes = encodeLengthPrefixed(m);
                try {
                    if (m.getHeader() != null
                        && m.getHeader().getMessageType() == com.shengyu.framework.websocket.core.protocol.MessageType.AUTH_RESP) {
                        log.info("[WebSocketPbOut] AUTH_RESP wrapped: channel={}, messageId={}, bytes={}",
                            ctx.channel().id().asShortText(),
                            m.getHeader().getMessageId(),
                            bytes != null ? bytes.length : 0);
                    }
                } catch (Exception ignore) {
                }
                if (log.isDebugEnabled()) {
                    try {
                        log.debug("[WebSocketPbOut] wrap ImMessage -> BinaryFrame: channel={}, type={}, messageId={}",
                            ctx.channel().id().asShortText(),
                            m.getHeader() != null ? m.getHeader().getMessageType() : null,
                            m.getHeader() != null ? m.getHeader().getMessageId() : null);
                    } catch (Exception ignore) {
                    }
                }
                super.write(ctx, new BinaryWebSocketFrame(Unpooled.wrappedBuffer(bytes)), promise);
                return;
            } catch (Exception e) {
                log.warn("[WebSocketPbOut] encode failed: channel={}", ctx.channel().id().asShortText(), e);
            }
        }
        super.write(ctx, msg, promise);
    }

    private boolean isPbCodec(ChannelHandlerContext ctx) {
        try {
            String codec = ctx.channel().attr(WebSocketFrameHandler.CODEC_KEY).get();
            return "pb".equalsIgnoreCase(codec);
        } catch (Exception ignore) {
            return false;
        }
    }

    private boolean isWebSocketChannel(ChannelHandlerContext ctx) {
        try {
            return ctx != null
                && ctx.channel() != null
                && ctx.channel().pipeline().get(WebSocketServerProtocolHandler.class) != null;
        } catch (Exception ignore) {
            return false;
        }
    }

    private byte[] encodeLengthPrefixed(ImMessage message) {
        try {
            byte[] raw = message.toByteArray();
            ByteArrayOutputStream out = new ByteArrayOutputStream(raw.length + 8);
            CodedOutputStream cos = CodedOutputStream.newInstance(out);
            cos.writeUInt32NoTag(raw.length);
            cos.flush();
            out.write(raw);
            return out.toByteArray();
        } catch (IOException e) {
            return message.toByteArray();
        }
    }
}
