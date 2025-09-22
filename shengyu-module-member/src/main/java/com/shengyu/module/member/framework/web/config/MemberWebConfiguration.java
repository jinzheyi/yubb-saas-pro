package com.shengyu.module.member.framework.web.config;

import com.shengyu.framework.swagger.config.ShengyuSwaggerAutoConfiguration;
import org.springdoc.core.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * member 模块的 web 组件的 Configuration
 *
 * @author 芋道源码
 */
@Configuration(proxyBeanMethods = false)
public class MemberWebConfiguration {

    /**
     * member 模块的 API 分组
     */
    @Bean
    public GroupedOpenApi memberGroupedOpenApi() {
        return ShengyuSwaggerAutoConfiguration.buildSystemGroupedOpenApi("租户端-会员", "member");
    }

}
