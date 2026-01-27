package com.shengyu.framework.websocket.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import javax.validation.constraints.NotNull;

/**
 * Netty 配置属性
 *
 * @author 圣钰科技
 */
@Data
@Validated
@ConfigurationProperties(prefix = "shengyu.netty")
public class NettyProperties {

    /**
     * 是否启用 Netty 服务器
     */
    private Boolean enable = true;

    /**
     * 服务器主机地址
     */
    @NotNull(message = "Netty 服务器主机地址不能为空")
    private String host = "0.0.0.0";

    /**
     * 服务器端口
     */
    @NotNull(message = "Netty 服务器端口不能为空")
    private Integer port = 9000;

    /**
     * 是否使用 Epoll（Linux 环境下性能更优）
     */
    private Boolean useEpoll = true;

    /**
     * Boss 线程数（接收连接）
     */
    private Integer bossThreads = 1;

    /**
     * Worker 线程数（处理 IO）
     * 默认为 CPU 核心数 * 2
     */
    private Integer workerThreads = Runtime.getRuntime().availableProcessors() * 2;

    /**
     * TCP 连接队列大小
     */
    private Integer soBacklog = 1024;

    /**
     * TCP 接收缓冲区大小（字节）
     */
    private Integer soRcvbuf = 64 * 1024;

    /**
     * TCP 发送缓冲区大小（字节）
     */
    private Integer soSndbuf = 64 * 1024;

    /**
     * 写缓冲区低水位线（字节）
     */
    private Integer writeBufferLowWaterMark = 32 * 1024;

    /**
     * 写缓冲区高水位线（字节）
     */
    private Integer writeBufferHighWaterMark = 64 * 1024;

    /**
     * 读空闲时间（秒）
     * 超过此时间未收到客户端消息，触发读空闲事件
     */
    private Integer readerIdleTime = 60;

    /**
     * 写空闲时间（秒）
     * 超过此时间未向客户端发送消息，触发写空闲事件
     */
    private Integer writerIdleTime = 0;

    /**
     * 读写空闲时间（秒）
     * 超过此时间既未读也未写，触发读写空闲事件
     */
    private Integer allIdleTime = 0;

    /**
     * 是否启用 WebSocket 协议
     */
    private Boolean enableWebSocket = true;

    /**
     * WebSocket 路径
     */
    private String webSocketPath = "/ws";

    /**
     * HTTP 最大内容长度（字节）
     */
    private Integer maxContentLength = 64 * 1024;

    /**
     * 是否启用 Protobuf 协议
     */
    private Boolean enableProtobuf = true;
}
