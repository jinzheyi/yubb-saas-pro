package com.shengyu.framework.sms.config;

import com.shengyu.framework.sms.core.client.SmsClientFactory;
import com.shengyu.framework.sms.core.client.impl.SmsClientFactoryImpl;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;

/**
 * 短信配置类
 *
 * @author 圣钰科技
 */
@AutoConfiguration
public class ShengyuSmsAutoConfiguration {

    @Bean
    public SmsClientFactory smsClientFactory() {
        return new SmsClientFactoryImpl();
    }

}
