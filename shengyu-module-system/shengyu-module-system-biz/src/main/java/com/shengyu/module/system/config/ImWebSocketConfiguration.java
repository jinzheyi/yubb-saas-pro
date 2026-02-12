package com.shengyu.module.system.config;

import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.framework.websocket.core.service.MessageStorageService;
import com.shengyu.module.system.service.im.spi.SystemAuthServiceImpl;
import com.shengyu.module.system.service.im.spi.SystemMessageStorageServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
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
 * 2. 通过 @ConditionalOnProperty 控制是否启用 WebSocket
 * 3. 支持多租户场景
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

    /**
     * 注册认证服务
     * 
     * 说明：
     * 1. 使用 @Primary 确保优先使用此实现
     * 2. 替换中间件的默认实现
     * 3. 集成项目的 OAuth2 认证体系
     */
    @Bean
    @Primary
    public AuthService authService(SystemAuthServiceImpl impl) {
        log.info("[IM-WebSocket] 注册认证服务: SystemAuthServiceImpl");
        return impl;
    }

}
