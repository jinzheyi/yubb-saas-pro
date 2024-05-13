package com.shengyu.framework.pay.config;

import com.shengyu.framework.pay.core.client.PayClientFactory;
import com.shengyu.framework.pay.core.client.impl.PayClientFactoryImpl;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;

/**
 * 支付配置类
 *
 * @author 圣钰科技
 */
@AutoConfiguration
public class ShengyuPayAutoConfiguration {

    @Bean
    public PayClientFactory payClientFactory() {
        return new PayClientFactoryImpl();
    }

}
