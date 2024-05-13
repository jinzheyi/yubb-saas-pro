package com.shengyu.framework.file.config;

import com.shengyu.framework.file.core.client.FileClientFactory;
import com.shengyu.framework.file.core.client.FileClientFactoryImpl;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;

/**
 * 文件配置类
 *
 * @author 圣钰科技
 */
@AutoConfiguration
public class ShengyuFileAutoConfiguration {

    @Bean
    public FileClientFactory fileClientFactory() {
        return new FileClientFactoryImpl();
    }

}
