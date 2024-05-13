package com.shengyu.module.platform.framework.web.config;

import com.shengyu.framework.swagger.config.ShengyuSwaggerAutoConfiguration;
import org.springdoc.core.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * platform 模块的 web 组件的 Configuration
 *
 * @author 圣钰科技
 */
@Configuration(proxyBeanMethods = false)
public class PlatformWebConfiguration {

    /**
     * system 模块的 API 分组
     */
    @Bean
    public GroupedOpenApi platformGroupedOpenApi() {
        return ShengyuSwaggerAutoConfiguration.buildPlatformGroupedOpenApi("平台端");
    }

}
