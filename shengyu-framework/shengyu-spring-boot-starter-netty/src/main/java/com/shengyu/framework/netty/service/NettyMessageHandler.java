package com.shengyu.framework.netty.service;

import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;

/**
 * Netty WebSocket消息处理器
 * 由业务服务实现，用于处理具体的WebSocket消息
 *
 * @author zhusy
 * @since 2024/12/21
 */
public interface NettyMessageHandler {

    /**
     * 处理文本消息
     *
     * @param ctx       通道处理上下文
     * @param frame     文本消息帧
     * @param userId    用户ID
     * @param message   消息内容
     */
    void handleTextMessage(ChannelHandlerContext ctx, TextWebSocketFrame frame, String userId, String message);

    /**
     * 处理连接建立
     *
     * @param ctx       通道处理上下文
     * @param userId    用户ID
     */
    void handleConnectionEstablished(ChannelHandlerContext ctx, String userId);

    /**
     * 处理连接关闭
     *
     * @param ctx       通道处理上下文
     * @param userId    用户ID
     */
    void handleConnectionClosed(ChannelHandlerContext ctx, String userId);
}
