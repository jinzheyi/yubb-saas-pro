package com.shengyu.framework.netty.service.impl;

import com.shengyu.framework.netty.service.NettyMessageHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Service;

/**
 * 默认的Netty WebSocket消息处理器
 * 当业务服务没有自定义实现时，使用此默认实现
 *
 * @author zhusy
 * @since 2024/12/21
 */
@Slf4j
@Service
@ConditionalOnMissingBean(NettyMessageHandler.class)
public class DefaultNettyMessageHandler implements NettyMessageHandler {

    @Override
    public void handleTextMessage(ChannelHandlerContext ctx, TextWebSocketFrame frame, String userId, String message) {
        log.debug("收到消息：用户ID={}, 消息内容={}", userId, message);
        // 默认实现：直接返回收到的消息
        ctx.channel().writeAndFlush(new TextWebSocketFrame("收到消息: " + message));
    }

    @Override
    public void handleConnectionEstablished(ChannelHandlerContext ctx, String userId) {
        log.info("用户连接建立：用户ID={}, 通道ID={}", userId, ctx.channel().id());
    }

    @Override
    public void handleConnectionClosed(ChannelHandlerContext ctx, String userId) {
        log.info("用户连接关闭：用户ID={}, 通道ID={}", userId, ctx.channel().id());
    }
}
