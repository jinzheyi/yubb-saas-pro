package com.shengyu.framework.websocket.core.netty;

import com.shengyu.framework.websocket.config.NettyProperties;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.*;
import io.netty.channel.epoll.Epoll;
import io.netty.channel.epoll.EpollEventLoopGroup;
import io.netty.channel.epoll.EpollServerSocketChannel;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.logging.LogLevel;
import io.netty.handler.logging.LoggingHandler;
import io.netty.util.concurrent.DefaultThreadFactory;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;

import java.net.InetSocketAddress;
import java.util.concurrent.TimeUnit;

/**
 * Netty 服务器
 * 支持千万级并发连接的长连接网关
 *
 * @author 圣钰科技
 */
@Slf4j
@RequiredArgsConstructor
public class NettyServer implements ApplicationRunner, DisposableBean {

    private final NettyProperties nettyProperties;
    private final NettyChannelInitializer channelInitializer;

    private EventLoopGroup bossGroup;
    private EventLoopGroup workerGroup;
    private Channel serverChannel;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        start();
    }

    /**
     * 启动 Netty 服务器
     */
    public void start() throws InterruptedException {
        log.info("[Netty Server] 开始启动...");
        
        // 判断是否使用 Epoll（Linux 环境下性能更优）
        boolean useEpoll = nettyProperties.getUseEpoll() && Epoll.isAvailable();
        
        // 创建 Boss 和 Worker 线程组
        if (useEpoll) {
            log.info("[Netty Server] 使用 Epoll 模式");
            bossGroup = new EpollEventLoopGroup(
                nettyProperties.getBossThreads(),
                new DefaultThreadFactory("netty-boss")
            );
            workerGroup = new EpollEventLoopGroup(
                nettyProperties.getWorkerThreads(),
                new DefaultThreadFactory("netty-worker")
            );
        } else {
            log.info("[Netty Server] 使用 NIO 模式");
            bossGroup = new NioEventLoopGroup(
                nettyProperties.getBossThreads(),
                new DefaultThreadFactory("netty-boss")
            );
            workerGroup = new NioEventLoopGroup(
                nettyProperties.getWorkerThreads(),
                new DefaultThreadFactory("netty-worker")
            );
        }

        try {
            ServerBootstrap bootstrap = new ServerBootstrap();
            bootstrap.group(bossGroup, workerGroup)
                .channel(useEpoll ? EpollServerSocketChannel.class : NioServerSocketChannel.class)
                .handler(new LoggingHandler(LogLevel.DEBUG))
                .childHandler(channelInitializer)
                // TCP 参数优化
                .option(ChannelOption.SO_BACKLOG, nettyProperties.getSoBacklog())
                .option(ChannelOption.SO_REUSEADDR, true)
                .childOption(ChannelOption.TCP_NODELAY, true)
                .childOption(ChannelOption.SO_KEEPALIVE, true)
                .childOption(ChannelOption.SO_RCVBUF, nettyProperties.getSoRcvbuf())
                .childOption(ChannelOption.SO_SNDBUF, nettyProperties.getSoSndbuf())
                // 写缓冲区水位线设置（防止内存溢出）
                .childOption(ChannelOption.WRITE_BUFFER_WATER_MARK, 
                    new WriteBufferWaterMark(
                        nettyProperties.getWriteBufferLowWaterMark(),
                        nettyProperties.getWriteBufferHighWaterMark()
                    ));

            // 绑定端口并启动
            ChannelFuture future = bootstrap.bind(
                new InetSocketAddress(nettyProperties.getHost(), nettyProperties.getPort())
            ).sync();
            
            serverChannel = future.channel();
            
            log.info("[Netty Server] 启动成功，监听端口: {}:{}", 
                nettyProperties.getHost(), nettyProperties.getPort());
            
        } catch (Exception e) {
            log.error("[Netty Server] 启动失败", e);
            shutdown();
            throw e;
        }
    }

    /**
     * 关闭 Netty 服务器
     */
    public void shutdown() {
        log.info("[Netty Server] 开始关闭...");
        
        try {
            if (serverChannel != null) {
                serverChannel.close().sync();
            }
        } catch (InterruptedException e) {
            log.error("[Netty Server] 关闭 Channel 失败", e);
            Thread.currentThread().interrupt();
        } finally {
            // 优雅关闭，设置 30 秒超时，避免僵尸进程
            if (bossGroup != null) {
                bossGroup.shutdownGracefully(0, 30, TimeUnit.SECONDS);
            }
            if (workerGroup != null) {
                workerGroup.shutdownGracefully(0, 30, TimeUnit.SECONDS);
            }
            log.info("[Netty Server] 关闭完成");
        }
    }

    @Override
    public void destroy() {
        shutdown();
    }
}
