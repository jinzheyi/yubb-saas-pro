package com.shengyu.module.system.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;
import java.util.concurrent.ThreadPoolExecutor;

/**
 * 异步任务配置
 * 
 * 用于 IM 模块的异步处理，提升高并发性能
 * 
 * @author 圣钰科技
 */
@Slf4j
@Configuration
@EnableAsync
public class AsyncConfiguration {

    /**
     * IM 异步任务执行器
     * 
     * 用于处理 IM 消息存储、会话更新等异步任务
     * 避免阻塞 Netty IO 线程，提升系统吞吐量
     * 
     * 【线程池参数说明】
     * - 核心线程数：16（保持活跃，快速响应）
     * - 最大线程数：64（高峰期扩展）
     * - 队列容量：2000（缓冲任务）
     * - 拒绝策略：CallerRunsPolicy（降级到调用线程执行，避免任务丢失）
     * 
     * 【性能优化】
     * 1. 核心线程数设置为 CPU 核心数的 2 倍，适合 IO 密集型任务
     * 2. 队列容量设置为 2000，可以缓冲短时间的流量峰值
     * 3. 使用 CallerRunsPolicy 拒绝策略，保证任务不丢失
     * 4. 线程名称前缀便于问题排查
     */
    @Bean("imTaskExecutor")
    public Executor imTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        
        // 核心线程数
        executor.setCorePoolSize(16);
        
        // 最大线程数
        executor.setMaxPoolSize(64);
        
        // 队列容量
        executor.setQueueCapacity(2000);
        
        // 线程名称前缀
        executor.setThreadNamePrefix("im-async-");
        
        // 拒绝策略：由调用线程执行（降级策略）
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        
        // 线程空闲时间（秒）
        executor.setKeepAliveSeconds(60);
        
        // 允许核心线程超时
        executor.setAllowCoreThreadTimeOut(false);
        
        // 等待所有任务完成后再关闭线程池
        executor.setWaitForTasksToCompleteOnShutdown(true);
        
        // 等待时间（秒）
        executor.setAwaitTerminationSeconds(60);
        
        // 初始化
        executor.initialize();
        
        log.info("[AsyncConfig] IM 异步任务执行器初始化完成, corePoolSize: {}, maxPoolSize: {}, queueCapacity: {}", 
                executor.getCorePoolSize(), executor.getMaxPoolSize(), executor.getQueueCapacity());
        
        return executor;
    }
}
