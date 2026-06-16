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

    /**
     * Channel 属性 Key：记录连续读空闲次数
     */
    private static final io.netty.util.AttributeKey<Integer> NO_HEARTBEAT_COUNT_KEY =
        io.netty.util.AttributeKey.valueOf("noHeartbeatCount");

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        // 收到客户端任何消息时，重置读空闲计数器
        ctx.channel().attr(NO_HEARTBEAT_COUNT_KEY).set(0);

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
                    // presence：业务活跃
                    try {
                        JSONObject body = json.getJSONObject("body");
                        boolean presence = false;
                        if (body != null) {
                            // 新版：前端发送 body.presence=true
                            presence = Boolean.TRUE.equals(body.getBool("presence"));
                            // 兼容旧版：scene="presence"
                            if (!presence) {
                                presence = "presence".equalsIgnoreCase(body.getStr("scene"));
                            }
                        }
                        if (presence) {
                            sessionManager.updateLastBizActiveTime(ctx.channel());
                        }
                    } catch (Exception ignore) {
                    }
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
                // presence：业务活跃（使用 header.extra 透传 JSON）
                try {
                    String extra = imMessage.getHeader().getExtra();
                    if (extra != null && !extra.isEmpty()) {
                        JSONObject extraJson = JSONUtil.parseObj(extra);
                        boolean presence = Boolean.TRUE.equals(extraJson.getBool("presence"))
                            || "presence".equalsIgnoreCase(extraJson.getStr("scene"));
                        if (presence) {
                            sessionManager.updateLastBizActiveTime(ctx.channel());
                        }
                    }
                } catch (Exception ignore) {
                }
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
            
            // 读空闲：客户端长时间未发送数据，发心跳探测
            if (event.state() == IdleState.READER_IDLE) {
                // 尝试发心跳探测，连续 3 次无响应则关闭连接
                Integer noHeartbeatCount = ctx.channel().attr(NO_HEARTBEAT_COUNT_KEY).get();
                if (noHeartbeatCount == null) {
                    noHeartbeatCount = 0;
                }
                noHeartbeatCount++;
                ctx.channel().attr(NO_HEARTBEAT_COUNT_KEY).set(noHeartbeatCount);

                if (noHeartbeatCount >= 3) {
                    log.warn("[Heartbeat] 读空闲超时 3 次，关闭连接: {}", ctx.channel().id().asShortText());
                    sessionManager.removeSession(ctx.channel());
                    ctx.close();
                } else {
                    // 发心跳探测
                    log.debug("[Heartbeat] 读空闲，发送心跳探测: {}", ctx.channel().id().asShortText());
                    sendJsonHeartbeatResponse(ctx);
                }
            }
            // 写空闲：服务端长时间未发消息，主动发心跳保活（防止运营商 NAT 超时）
            else if (event.state() == IdleState.WRITER_IDLE) {
                log.debug("[Heartbeat] 写空闲，主动发送心跳保活: {}", ctx.channel().id().asShortText());
                sendJsonHeartbeatResponse(ctx);
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

        ctx.channel().writeAndFlush(heartbeat);
        log.debug("[Heartbeat] 发送 Protobuf 心跳响应: {}", ctx.channel().id().asShortText());
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[Heartbeat] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }
}
