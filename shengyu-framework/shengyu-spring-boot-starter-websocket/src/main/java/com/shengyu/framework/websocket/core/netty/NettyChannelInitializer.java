package com.shengyu.framework.websocket.core.netty;

import com.shengyu.framework.websocket.config.NettyProperties;
import com.shengyu.framework.websocket.core.netty.handler.*;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.socket.SocketChannel;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpServerCodec;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import io.netty.handler.codec.protobuf.ProtobufDecoder;
import io.netty.handler.codec.protobuf.ProtobufEncoder;
import io.netty.handler.codec.protobuf.ProtobufVarint32FrameDecoder;
import io.netty.handler.codec.protobuf.ProtobufVarint32LengthFieldPrepender;
import io.netty.handler.stream.ChunkedWriteHandler;
import io.netty.handler.timeout.IdleStateHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.concurrent.TimeUnit;

/**
 * Netty Channel 初始化器
 * 配置 Pipeline 处理链
 *
 * @author 圣钰科技
 */
@Slf4j
@RequiredArgsConstructor
public class NettyChannelInitializer extends ChannelInitializer<SocketChannel> {

    private final NettyProperties nettyProperties;
    private final WebSocketFrameHandler webSocketFrameHandler;
    private final ProtobufMessageHandler protobufMessageHandler;
    private final HeartbeatHandler heartbeatHandler;
    private final AuthHandler authHandler;

    @Override
    protected void initChannel(SocketChannel ch) {
        ChannelPipeline pipeline = ch.pipeline();

        // ========== WebSocket 协议支持（对外） ==========
        if (nettyProperties.getEnableWebSocket()) {
            // HTTP 编解码器
            pipeline.addLast("http-codec", new HttpServerCodec());
            // HTTP 消息聚合器（将多个 HTTP 消息聚合成一个完整的 FullHttpRequest 或 FullHttpResponse）
            pipeline.addLast("http-aggregator", new HttpObjectAggregator(nettyProperties.getMaxContentLength()));
            // 支持大文件传输
            pipeline.addLast("http-chunked", new ChunkedWriteHandler());
            // WebSocket 协议处理器
            pipeline.addLast("websocket-protocol", 
                new WebSocketServerProtocolHandler(nettyProperties.getWebSocketPath(), null, true));
            // WebSocket 帧处理器
            pipeline.addLast("websocket-frame-handler", webSocketFrameHandler);
        } 
        // ========== Protobuf 协议支持（内部 TCP 直连） ==========
        // 注意：WebSocket 和 Protobuf 不能同时启用，WebSocket 使用 JSON 格式
        else if (nettyProperties.getEnableProtobuf()) {
            // Protobuf 解码器（处理粘包拆包）
            pipeline.addLast("protobuf-frame-decoder", new ProtobufVarint32FrameDecoder());
            pipeline.addLast("protobuf-decoder", 
                new ProtobufDecoder(com.shengyu.framework.websocket.core.protocol.ImMessage.getDefaultInstance()));
            
            // Protobuf 编码器
            pipeline.addLast("protobuf-frame-encoder", new ProtobufVarint32LengthFieldPrepender());
            pipeline.addLast("protobuf-encoder", new ProtobufEncoder());
            
            // Protobuf 消息处理器
            pipeline.addLast("protobuf-message-handler", protobufMessageHandler);
        }

        // ========== 业务处理器 ==========
        // 空闲检测处理器（心跳机制）
        pipeline.addLast("idle-state-handler", new IdleStateHandler(
            nettyProperties.getReaderIdleTime(),
            nettyProperties.getWriterIdleTime(),
            nettyProperties.getAllIdleTime(),
            TimeUnit.SECONDS
        ));
        
        // 心跳处理器
        pipeline.addLast("heartbeat-handler", heartbeatHandler);
        
        // 认证处理器
        pipeline.addLast("auth-handler", authHandler);
        
        // 异常处理器
        pipeline.addLast("exception-handler", new ExceptionHandler());
        
        log.debug("[Netty] Channel 初始化完成: {}", ch.id().asShortText());
    }
}
