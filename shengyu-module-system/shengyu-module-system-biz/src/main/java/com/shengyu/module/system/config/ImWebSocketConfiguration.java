package com.shengyu.module.system.config;

import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.module.system.service.im.spi.SystemMessageStorageServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * IM WebSocket 配置类
 * 
 * 负责注册 WebSocket 中间件的 SPI 接口实现
 * 
 * 配置说明：
 * 1. 通过 @Primary 注解确保使用 System 模块的实现
 * 2. 支持多租户场景
 * 
 * 注意：
 * - AuthService 不在此配置，由 WebSocketAuthServiceImpl 自己注册
 * - 避免与 AdminAuthService 的 Bean 名称冲突
 *
 * @author 圣钰科技
 */
@Configuration
@Slf4j
public class ImWebSocketConfiguration {

    /**
     * 注册消息存储服务
     * 
     * 说明：
     * 1. 使用 @Primary 确保优先使用此实现
     * 2. 替换中间件的默认 NoOp 实现
     */
    @Bean
    @Primary
    public MessageStorageService messageStorageService(SystemMessageStorageServiceImpl impl) {
        log.info("[IM-WebSocket] 注册消息存储服务: SystemMessageStorageServiceImpl");
        return impl;
    }

}
