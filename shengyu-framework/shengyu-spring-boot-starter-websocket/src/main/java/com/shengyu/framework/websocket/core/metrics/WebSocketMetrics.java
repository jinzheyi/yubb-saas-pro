package com.shengyu.framework.websocket.core.metrics;

import com.shengyu.framework.websocket.core.session.NettySessionManager;
import io.micrometer.core.instrument.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;

/**
 * WebSocket 监控指标采集器
 * 基于 Micrometer，兼容 Prometheus、Grafana 等监控系统
 *
 * 当项目中未引入 MeterRegistry 时，所有记录方法会优雅降级（不报错）。
 *
 * @author 圣钰科技
 */
@Slf4j
public class WebSocketMetrics {

    private MeterRegistry meterRegistry;

    /**
     * 使用 @Autowired(required = false) 确保未引入 micrometer 时也不报错
     */
    @Autowired(required = false)
    public void setMeterRegistry(MeterRegistry meterRegistry, NettySessionManager sessionManager) {
        this.meterRegistry = meterRegistry;
        if (meterRegistry == null) {
            log.info("[WebSocketMetrics] MeterRegistry 未配置，监控指标采集已禁用");
            return;
        }
        registerMetrics(sessionManager);
    }

    private void registerMetrics(NettySessionManager sessionManager) {
        // 1. WebSocket 活跃连接数（Gauge）
        Gauge.builder("websocket.connections.active", sessionManager, s -> s.getActiveConnectionCount())
                .description("当前活跃的 WebSocket 连接数")
                .register(meterRegistry);

        // 2. 在线用户数（Gauge）
        Gauge.builder("websocket.users.online", sessionManager, s -> s.getOnlineUserCount())
                .description("当前在线用户数")
                .register(meterRegistry);

        // 3. 消息处理延迟（Timer）
        Timer.builder("websocket.message.process.duration")
                .description("消息处理耗时")
                .publishPercentiles(0.5, 0.95, 0.99)
                .register(meterRegistry);

        // 4. 消息发送失败数（Counter）
        Counter.builder("websocket.message.send.failure")
                .description("消息发送失败次数")
                .register(meterRegistry);

        // 5. 认证失败数（Counter）
        Counter.builder("websocket.auth.failure")
                .description("认证失败次数")
                .register(meterRegistry);

        // 6. 被踢下线次数（Counter）
        Counter.builder("websocket.session.kicked")
                .description("会话被踢下线次数")
                .register(meterRegistry);

        // 7. 租约过期数（Counter）
        Counter.builder("websocket.session.expired")
                .description("会话租约过期次数")
                .register(meterRegistry);
    }

    /**
     * 记录消息处理耗时
     */
    public void recordMessageProcessing(String messageType, Duration duration) {
        if (meterRegistry == null) return;
        Timer.builder("websocket.message.process.duration")
                .tag("type", messageType)
                .register(meterRegistry)
                .record(duration);
    }

    /**
     * 记录消息发送失败
     */
    public void recordMessageSendFailure(String reason) {
        if (meterRegistry == null) return;
        Counter.builder("websocket.message.send.failure")
                .tag("reason", reason)
                .register(meterRegistry)
                .increment();
    }

    /**
     * 记录认证失败
     */
    public void recordAuthFailure(String reason) {
        if (meterRegistry == null) return;
        Counter.builder("websocket.auth.failure")
                .tag("reason", reason)
                .register(meterRegistry)
                .increment();
    }

    /**
     * 记录被踢下线
     */
    public void recordSessionKicked() {
        if (meterRegistry == null) return;
        Counter.builder("websocket.session.kicked")
                .register(meterRegistry)
                .increment();
    }

    /**
     * 记录租约过期
     */
    public void recordSessionExpired() {
        if (meterRegistry == null) return;
        Counter.builder("websocket.session.expired")
                .register(meterRegistry)
                .increment();
    }
}
