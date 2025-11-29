package com.shengyu.module.im.netty;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.LengthFieldBasedFrameDecoder;
import io.netty.handler.codec.LengthFieldPrepender;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;
import io.netty.handler.logging.LogLevel;
import io.netty.handler.logging.LoggingHandler;
import io.netty.handler.timeout.IdleStateHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.util.concurrent.TimeUnit;

/**
 * IM Netty服务器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class ImNettyServer {

    @Autowired
    private ImMessageHandler imMessageHandler;

    @Value("${im.netty.port:8888}")
    private int port;

    @Value("${im.netty.bossGroupThreads:1}")
    private int bossGroupThreads;

    @Value("${im.netty.workerGroupThreads:8}")
    private int workerGroupThreads;

    @Value("${im.netty.readIdleTime:60}")
    private int readIdleTime;

    @Value("${im.netty.writeIdleTime:0}")
    private int writeIdleTime;

    @Value("${im.netty.allIdleTime:0}")
    private int allIdleTime;

    private EventLoopGroup bossGroup;
    private EventLoopGroup workerGroup;
    private ChannelFuture channelFuture;

    /**
     * 启动Netty服务器
     */
    @PostConstruct
    public void start() {
        log.info("开始启动IM Netty服务器...");
        log.info("配置参数: port={}, bossGroupThreads={}, workerGroupThreads={}", port, bossGroupThreads, workerGroupThreads);
        log.info("空闲检测配置: readIdleTime={}s, writeIdleTime={}s, allIdleTime={}s", readIdleTime, writeIdleTime, allIdleTime);
        
        // 初始化EventLoopGroup
        log.info("初始化BossGroup，线程数: {}", bossGroupThreads);
        bossGroup = new NioEventLoopGroup(bossGroupThreads);
        log.info("初始化WorkerGroup，线程数: {}", workerGroupThreads);
        workerGroup = new NioEventLoopGroup(workerGroupThreads);

        try {
            // 创建ServerBootstrap
            log.info("创建ServerBootstrap实例");
            ServerBootstrap bootstrap = new ServerBootstrap();
            
            // 配置ServerBootstrap
            log.info("配置ServerBootstrap参数");
            bootstrap.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 1024)
                    .option(ChannelOption.SO_REUSEADDR, true)
                    .childOption(ChannelOption.SO_KEEPALIVE, true)
                    .childOption(ChannelOption.TCP_NODELAY, true)
                    .handler(new LoggingHandler(LogLevel.INFO))
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) {
                            log.debug("初始化ChannelPipeline，客户端: {}", ch.remoteAddress());
                            ch.pipeline()
                                    // 空闲检测
                                    .addLast(new IdleStateHandler(readIdleTime, writeIdleTime, allIdleTime, TimeUnit.SECONDS))
                                    // 基于长度的帧解码器
                                    .addLast(new LengthFieldBasedFrameDecoder(1024 * 1024, 0, 4, 0, 4))
                                    // 长度字段预处理器
                                    .addLast(new LengthFieldPrepender(4))
                                    // 字符串编解码器
                                    .addLast(new StringDecoder())
                                    .addLast(new StringEncoder())
                                    // 业务处理器
                                    .addLast(imMessageHandler);
                            log.debug("ChannelPipeline初始化完成，客户端: {}", ch.remoteAddress());
                        }
                    });

            // 绑定端口并启动服务器
            log.info("开始绑定端口: {}", port);
            channelFuture = bootstrap.bind(port).sync();
            log.info("IM Netty服务器启动成功！监听端口: {}", port);
            log.info("服务器状态: 运行中");
            log.info("EventLoopGroup状态: BossGroup={}, WorkerGroup={}", bossGroup.isShutdown(), workerGroup.isShutdown());

            // 等待服务器关闭
            channelFuture.channel().closeFuture().addListener(future -> {
                log.info("IM Netty服务器关闭");
            });
        } catch (InterruptedException e) {
            log.error("IM Netty服务器启动失败", e);
            Thread.currentThread().interrupt();
        } catch (Exception e) {
            log.error("IM Netty服务器启动过程中发生异常", e);
        }
    }

    /**
     * 关闭Netty服务器
     */
    @PreDestroy
    public void stop() {
        if (channelFuture != null) {
            channelFuture.channel().close();
        }
        if (bossGroup != null) {
            bossGroup.shutdownGracefully();
        }
        if (workerGroup != null) {
            workerGroup.shutdownGracefully();
        }
        log.info("IM Netty服务器已关闭");
    }

}
