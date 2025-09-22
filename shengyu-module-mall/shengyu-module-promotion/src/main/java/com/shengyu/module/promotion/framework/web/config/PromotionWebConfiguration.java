package com.shengyu.module.promotion.framework.web.config;

import com.shengyu.framework.swagger.config.ShengyuSwaggerAutoConfiguration;
import org.springdoc.core.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * promotion 模块的 web 组件的 Configuration
 *
 * @author 芋道源码
 */
@Configuration(proxyBeanMethods = false)
public class PromotionWebConfiguration {

    /**
     * promotion 模块的 API 分组
     */
    @Bean
    public GroupedOpenApi promotionGroupedOpenApi() {
        return ShengyuSwaggerAutoConfiguration.buildSystemGroupedOpenApi("租户端-营销", "promotion");
    }

}
