package com.shengyu.framework.websocket.core.netty.handler;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * 异常处理器
 * 统一处理 Pipeline 中的异常
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class ExceptionHandler extends ChannelInboundHandlerAdapter {

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        // 忽略客户端主动断开连接的异常
        if (cause instanceof IOException) {
            log.debug("[Exception] 连接异常: {}, message: {}", 
                ctx.channel().id().asShortText(), cause.getMessage());
        } else {
            log.error("[Exception] 未处理的异常: {}", ctx.channel().id().asShortText(), cause);
        }
        
        ctx.close();
    }
}
