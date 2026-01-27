package com.shengyu.framework.websocket.core.netty.handler;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.timeout.IdleState;
import io.netty.handler.timeout.IdleStateEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 心跳处理器
 * 处理客户端心跳和服务端空闲检测
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class HeartbeatHandler extends ChannelInboundHandlerAdapter {

    private final NettySessionManager sessionManager;

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
                sendHeartbeat(ctx);
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
     * 发送心跳响应
     */
    private void sendHeartbeat(ChannelHandlerContext ctx) {
        ImMessage heartbeat = ImMessage.newBuilder()
            .setHeader(MessageHeader.newBuilder()
                .setMessageId(System.currentTimeMillis())
                .setMessageType(MessageType.HEARTBEAT_RESP)
                .setTimestamp(System.currentTimeMillis())
                .build())
            .build();
        
        ctx.writeAndFlush(heartbeat);
        log.debug("[Heartbeat] 发送心跳响应: {}", ctx.channel().id().asShortText());
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[Heartbeat] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }
}
