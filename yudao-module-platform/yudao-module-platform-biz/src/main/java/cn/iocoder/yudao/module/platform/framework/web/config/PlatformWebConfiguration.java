package cn.iocoder.yudao.module.platform.framework.web.config;

import cn.iocoder.yudao.framework.swagger.config.YudaoSwaggerAutoConfiguration;
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
        return YudaoSwaggerAutoConfiguration.buildPlatformGroupedOpenApi("平台端");
    }

}
