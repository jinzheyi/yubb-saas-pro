package com.shengyu.framework.netty.core;

import com.shengyu.framework.netty.config.NettyProperties;
import com.shengyu.framework.netty.core.heart.HeartBeatHandler;
import com.shengyu.framework.netty.service.NettyAuthService;
import com.shengyu.framework.netty.service.NettyMessageHandler;
import com.shengyu.framework.netty.service.NettyMessageService;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.http.HttpContentCompressor;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpServerCodec;
import io.netty.handler.stream.ChunkedWriteHandler;

/**
 * 工作线程需要处理的职责，设置管道的职责链
 *
 * @author zhusy
 * @since 2022/11/13
 */
public class NettyWorkGroupPipelines extends ChannelInitializer<NioSocketChannel> {

    private final NettyProperties nettyProperties;
    private final NettyAuthService nettyAuthService;
    private final NettyMessageService nettyMessageService;
    private final NettyMessageHandler nettyMessageHandler;

    /**
     * 构造函数
     *
     * @param nettyProperties    配置属性
     * @param nettyAuthService   认证服务
     * @param nettyMessageService 消息服务
     * @param nettyMessageHandler 消息处理器
     */
    public NettyWorkGroupPipelines(NettyProperties nettyProperties,
                                   NettyAuthService nettyAuthService,
                                   NettyMessageService nettyMessageService,
                                   NettyMessageHandler nettyMessageHandler) {
        this.nettyProperties = nettyProperties;
        this.nettyAuthService = nettyAuthService;
        this.nettyMessageService = nettyMessageService;
        this.nettyMessageHandler = nettyMessageHandler;
    }

    @Override
    protected void initChannel(NioSocketChannel nioSocketChannel) throws Exception {
        //获取pipeline管道
        ChannelPipeline pipeline = nioSocketChannel.pipeline();
        //前端项目使用websocket协议，需要添加基于http的编解码器
        pipeline.addLast(new HttpServerCodec());
        //对httpMessage进行聚合，聚合成FullHttpRequest或FullHttpResponse
        pipeline.addLast(new HttpObjectAggregator(1024 * 64));
        //httpContent压缩
        pipeline.addLast(new HttpContentCompressor());
        //对写大数据流的支持
        pipeline.addLast(new ChunkedWriteHandler());
        //权限校验与业务转发
        pipeline.addLast(new ShengyuChannelInboundHandler(nettyProperties, nettyAuthService, nettyMessageService, nettyMessageHandler));
        //心跳检测
        pipeline.addLast(new HeartBeatHandler(nettyProperties));
    }

}
