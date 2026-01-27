package com.shengyu.framework.websocket.core.processor;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import io.netty.channel.ChannelHandlerContext;

/**
 * 消息处理器接口
 * 不同类型的消息由不同的处理器处理
 *
 * @author 圣钰科技
 */
public interface MessageProcessor {

    /**
     * 处理消息
     *
     * @param ctx     Channel 上下文
     * @param message IM 消息
     */
    void process(ChannelHandlerContext ctx, ImMessage message);
}
