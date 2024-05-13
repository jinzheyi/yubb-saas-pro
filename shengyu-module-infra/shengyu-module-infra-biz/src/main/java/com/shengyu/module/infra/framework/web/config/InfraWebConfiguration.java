package com.shengyu.module.infra.framework.web.config;

import com.shengyu.framework.swagger.config.ShengyuSwaggerAutoConfiguration;
import org.springdoc.core.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * infra 模块的 web 组件的 Configuration
 *
 * @author 圣钰科技
 */
@Configuration(proxyBeanMethods = false)
public class InfraWebConfiguration {

    /**
     * infra 模块的 API 分组
     */
    @Bean
    public GroupedOpenApi infraGroupedOpenApi() {
        return ShengyuSwaggerAutoConfiguration.buildSystemGroupedOpenApi("公共端", "infra");
    }

}
