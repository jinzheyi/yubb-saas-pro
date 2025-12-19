package com.shengyu.framework.netty.config;

import com.shengyu.framework.netty.core.NettyServer;
import com.shengyu.framework.netty.service.NettyAuthService;
import com.shengyu.framework.netty.service.NettyMessageService;
import com.shengyu.framework.netty.service.NettyService;
import com.shengyu.framework.netty.service.impl.NettyAuthServiceImpl;
import com.shengyu.framework.netty.service.impl.NettyMessageServiceImpl;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

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
    public NettyAuthService nettyAuthService() {
        return new NettyAuthServiceImpl();
    }

    /**
     * 消息服务Bean
     *
     * @return 消息服务实例
     */
    @Bean
    public NettyMessageService nettyMessageService() {
        return new NettyMessageServiceImpl();
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
     * @return Netty服务器实例
     */
    @Bean
    public NettyServer nettyServer(NettyProperties nettyProperties,
                                  NettyAuthService nettyAuthService,
                                  NettyMessageService nettyMessageService) {
        return new NettyServer(nettyProperties, nettyAuthService, nettyMessageService);
    }

}
