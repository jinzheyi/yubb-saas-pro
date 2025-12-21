package com.shengyu.framework.netty.core;

import com.shengyu.framework.netty.config.NettyProperties;
import com.shengyu.framework.netty.service.NettyAuthService;
import com.shengyu.framework.netty.service.NettyMessageHandler;
import com.shengyu.framework.netty.service.NettyMessageService;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.InitializingBean;

/**
 * netty服务
 *
 * @author zhusy
 * @since 2022/11/13
 */
@Slf4j
public class NettyServer implements InitializingBean {

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
    public NettyServer(NettyProperties nettyProperties,
                      NettyAuthService nettyAuthService,
                      NettyMessageService nettyMessageService,
                      NettyMessageHandler nettyMessageHandler) {
        this.nettyProperties = nettyProperties;
        this.nettyAuthService = nettyAuthService;
        this.nettyMessageService = nettyMessageService;
        this.nettyMessageHandler = nettyMessageHandler;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        if (!nettyProperties.isEnable()) {
            log.info("Netty服务已禁用");
            return;
        }
        log.info("启动Netty服务...");
        
        //boss线程用于处理连接工作
        EventLoopGroup bossGroup = new NioEventLoopGroup(nettyProperties.getBossThread() > 0 ? nettyProperties.getBossThread() : Runtime.getRuntime().availableProcessors() * 2);
        //work线程用于数据处理
        EventLoopGroup workGroup = new NioEventLoopGroup(nettyProperties.getWorkerThread() > 0 ? nettyProperties.getWorkerThread() : Runtime.getRuntime().availableProcessors() * 2);
        
        try {
            ServerBootstrap serverBootstrap = new ServerBootstrap()
                    .group(bossGroup, workGroup)
                    //临时存放已经完成三次握手的请求的队列的最大长度，对应TCP/ip协议listen函数中backlog参数。
                    .option(ChannelOption.SO_BACKLOG, nettyProperties.getBackLog() > 0 ? nettyProperties.getBackLog() : 128)
                    //设置TCP长连接，一般如果两个小时内没有数据的通信时，TCP会自动发送一个活动探测数据报文
                    .childOption(ChannelOption.SO_KEEPALIVE, Boolean.TRUE)
                    //将小的数据包包装成更大的帧进行传送，提高网络的负载
                    .childOption(ChannelOption.TCP_NODELAY, Boolean.TRUE)
                    //设置nio模型，NioServerSocketChannel是对nio类型的链接的抽象
                    .channel(NioServerSocketChannel.class)
                    //工作线程处理业务工作类
                    .childHandler(new NettyWorkGroupPipelines(nettyProperties, nettyAuthService, nettyMessageService, nettyMessageHandler));
            
            bind(serverBootstrap, nettyProperties.getPort());
        } catch (Exception e) {
            log.error("Netty服务启动失败:", e);
            // 优雅关闭线程组
            bossGroup.shutdownGracefully();
            workGroup.shutdownGracefully();
            throw e;
        }
    }

    private void bind(final ServerBootstrap serverBootstrap, final int port) {
        serverBootstrap.bind(port).addListener(future -> {
            if (future.isSuccess()) {
                log.info("Netty服务绑定端口{}成功", port);
            } else {
                log.error("Netty服务绑定端口{}失败", port, future.cause());
                // 绑定失败，可以尝试其他端口或者关闭服务
            }
        });
    }
}
