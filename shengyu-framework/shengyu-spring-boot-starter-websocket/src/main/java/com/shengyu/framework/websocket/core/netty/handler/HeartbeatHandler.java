package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.timeout.IdleState;
import io.netty.handler.timeout.IdleStateEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 心跳处理器
 * 处理客户端心跳和服务端空闲检测
 *
 * 支持：
 * 1. JSON 格式心跳（WebSocket）
 * 2. Protobuf 格式心跳（TCP）
 * 3. 空闲检测
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ChannelHandler.Sharable  // 标记为可共享的Handler
public class HeartbeatHandler extends ChannelInboundHandlerAdapter {

    private final NettySessionManager sessionManager;

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        // 处理 JSON 格式心跳请求（WebSocket）
        if (msg instanceof String) {
            String text = (String) msg;
            try {
                JSONObject json = JSONUtil.parseObj(text);
                JSONObject header = json.getJSONObject("header");
                if (header != null && header.getInt("messageType") == MessageType.HEARTBEAT_REQ_VALUE) {
                    sendJsonHeartbeatResponse(ctx);
                    // 更新会话活跃时间
                    sessionManager.updateLastActiveTime(ctx.channel());
                    return; // 心跳消息不继续传递
                }
            } catch (Exception e) {
                // 不是心跳消息，继续传递
            }
        }
        // 处理 Protobuf 格式心跳请求（TCP）
        else if (msg instanceof ImMessage) {
            ImMessage imMessage = (ImMessage) msg;
            if (imMessage.getHeader().getMessageType() == MessageType.HEARTBEAT_REQ) {
                sendProtobufHeartbeatResponse(ctx);
                // 更新会话活跃时间
                sessionManager.updateLastActiveTime(ctx.channel());
                return; // 心跳消息不继续传递
            }
        }

        // 不是心跳消息，继续传递给下一个处理器
        super.channelRead(ctx, msg);
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent) {
            IdleStateEvent event = (IdleStateEvent) evt;
            
            // 读空闲：客户端长时间未发送数据
            if (event.state() == IdleState.READER_IDLE) {
                log.warn("[Heartbeat] 读空闲超时，关闭连接: {}", ctx.channel().id().asShortText());
                sessionManager.removeSession(ctx.channel());
                ctx.close();
            }
            // 写空闲：服务端长时间未发送数据，主动发送心跳
            else if (event.state() == IdleState.WRITER_IDLE) {
                // 服务端主动发送心跳（可选）
                log.debug("[Heartbeat] 写空闲，可主动发送心跳: {}", ctx.channel().id().asShortText());
            }
            // 读写空闲
            else if (event.state() == IdleState.ALL_IDLE) {
                log.warn("[Heartbeat] 读写空闲超时，关闭连接: {}", ctx.channel().id().asShortText());
                sessionManager.removeSession(ctx.channel());
                ctx.close();
            }
        } else {
            super.userEventTriggered(ctx, evt);
        }
    }

    /**
     * 发送 JSON 格式心跳响应
     */
    private void sendJsonHeartbeatResponse(ChannelHandlerContext ctx) {
        JSONObject response = JSONUtil.createObj()
            .set("header", JSONUtil.createObj()
                .set("messageId", System.currentTimeMillis())
                .set("messageType", MessageType.HEARTBEAT_RESP_VALUE)
                .set("timestamp", System.currentTimeMillis()));

        ctx.writeAndFlush(new TextWebSocketFrame(response.toString()));
        log.debug("[Heartbeat] 发送 JSON 心跳响应: {}", ctx.channel().id().asShortText());
    }

    /**
     * 发送 Protobuf 格式心跳响应
     */
    private void sendProtobufHeartbeatResponse(ChannelHandlerContext ctx) {
        ImMessage heartbeat = ImMessage.newBuilder()
            .setHeader(MessageHeader.newBuilder()
                .setMessageId(System.currentTimeMillis())
                .setMessageType(MessageType.HEARTBEAT_RESP)
                .setTimestamp(System.currentTimeMillis())
                .build())
            .build();
        
        ctx.writeAndFlush(heartbeat);
        log.debug("[Heartbeat] 发送 Protobuf 心跳响应: {}", ctx.channel().id().asShortText());
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[Heartbeat] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }
}
