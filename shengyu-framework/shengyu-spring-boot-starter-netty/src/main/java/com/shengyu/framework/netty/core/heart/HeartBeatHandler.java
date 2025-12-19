package com.shengyu.framework.netty.core.heart;

import com.shengyu.framework.netty.config.NettyProperties;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.timeout.IdleState;
import io.netty.handler.timeout.IdleStateEvent;
import io.netty.handler.timeout.IdleStateHandler;
import lombok.extern.slf4j.Slf4j;

import java.util.concurrent.TimeUnit;

/**
 * 用于检测channel的心跳handler
 * @author zhusy
 * @since 2021/11/22
 */
@Slf4j
public class HeartBeatHandler extends IdleStateHandler {

    private NettyProperties nettyProperties;

    /**
     * 设置心跳检测时间
     */
    public HeartBeatHandler(NettyProperties nettyProperties) {
        super(nettyProperties.getReadHeartBeatTime(),
                nettyProperties.getWriterHeartBeatTime(),
                nettyProperties.getAllHeartBeatTime(), TimeUnit.SECONDS);
        this.nettyProperties = nettyProperties;
    }

    /**
     * 通道空闲心跳检测
     * @param context 通道上下文对象
     * @param idleStateEvent 事件
     * @throws Exception
     */
    @Override
    protected void channelIdle(ChannelHandlerContext context, IdleStateEvent idleStateEvent) throws Exception {
        if (idleStateEvent.state() == IdleState.READER_IDLE) {
            log.info("{}进入读空闲。。。。。。", context.channel());
        } else if (idleStateEvent.state() == IdleState.WRITER_IDLE) {
            log.info("{}进入写空闲。。。。。。", context.channel());
        } else if (idleStateEvent.state() == IdleState.ALL_IDLE) {
            log.info("{}进入读写空闲。。。。。", context.channel());
        }
        // 关闭空闲通道
        context.close();
    }

}
