package com.shengyu.framework.websocket.core.netty.handler;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.processor.MessageProcessorFactory;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Protobuf 消息处理器
 * 根据消息类型分发到不同的业务处理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ChannelHandler.Sharable  // 标记为可共享的Handler
public class ProtobufMessageHandler extends SimpleChannelInboundHandler<ImMessage> {

    private final MessageProcessorFactory processorFactory;

    private final NettySessionManager sessionManager;

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, ImMessage msg) {
        try {
            MessageType messageType = msg.getHeader().getMessageType();
            log.debug("[Protobuf] 收到消息, type: {}, messageId: {}, channel: {}", 
                messageType, msg.getHeader().getMessageId(), ctx.channel().id().asShortText());

            // 更新业务活跃时间：任何非系统消息都视为业务活跃
            if (messageType != null && messageType.getNumber() >= MessageType.TEXT_VALUE) {
                sessionManager.updateLastBizActiveTime(ctx.channel());
            }

            // 获取对应的消息处理器
            MessageProcessor processor = processorFactory.getProcessor(messageType);
            if (processor == null) {
                log.warn("[Protobuf] 未找到消息处理器, type: {}", messageType);
                return;
            }

            // 处理消息
            processor.process(ctx, msg);
            
        } catch (Exception e) {
            log.error("[Protobuf] 消息处理异常", e);
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.error("[Protobuf] 异常: {}", ctx.channel().id().asShortText(), cause);
        ctx.close();
    }
}
