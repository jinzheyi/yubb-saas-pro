package com.shengyu.framework.netty.config;

import com.shengyu.framework.netty.core.NettyServer;
import com.shengyu.framework.netty.service.NettyAuthService;
import com.shengyu.framework.netty.service.NettyMessageHandler;
import com.shengyu.framework.netty.service.NettyMessageService;
import com.shengyu.framework.netty.service.NettyService;
import com.shengyu.framework.netty.service.impl.DefaultNettyMessageHandler;
import com.shengyu.framework.netty.service.impl.NettyAuthServiceImpl;
import com.shengyu.framework.netty.service.impl.NettyMessageServiceImpl;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * 网络通讯配置类
 * @author zhusy
 * @since 2022/11/12
 */
@Configuration
@EnableConfigurationProperties(NettyProperties.class)
public class ShengyuNettyAutoConfiguration {

    /**
     * 认证服务Bean
     *
     * @return 认证服务实例
     */
    @Bean
    @Primary
    @ConditionalOnMissingBean(NettyAuthService.class)
    public NettyAuthService nettyAuthService() {
        return new NettyAuthServiceImpl();
    }

    /**
     * 消息服务Bean
     *
     * @return 消息服务实例
     */
    @Bean
    @Primary
    @ConditionalOnMissingBean(NettyMessageService.class)
    public NettyMessageService nettyMessageService() {
        return new NettyMessageServiceImpl();
    }

    /**
     * 消息处理器Bean
     *
     * @return 消息处理器实例
     */
    @Bean
    @Primary
    @ConditionalOnMissingBean(NettyMessageHandler.class)
    public NettyMessageHandler nettyMessageHandler() {
        return new DefaultNettyMessageHandler();
    }

    /**
     * Netty服务统一入口Bean
     *
     * @param nettyMessageService 消息服务
     * @param nettyAuthService   认证服务
     * @return Netty服务统一入口实例
     */
    @Bean
    public NettyService nettyService(NettyMessageService nettyMessageService,
                                    NettyAuthService nettyAuthService) {
        return new NettyService(nettyMessageService, nettyAuthService);
    }

    /**
     * Netty服务器Bean
     *
     * @param nettyProperties    配置属性
     * @param nettyAuthService   认证服务
     * @param nettyMessageService 消息服务
     * @param nettyMessageHandler 消息处理器
     * @return Netty服务器实例
     */
    @Bean
    public NettyServer nettyServer(NettyProperties nettyProperties,
                                  NettyAuthService nettyAuthService,
                                  NettyMessageService nettyMessageService,
                                  NettyMessageHandler nettyMessageHandler) {
        return new NettyServer(nettyProperties, nettyAuthService, nettyMessageService, nettyMessageHandler);
    }

}
