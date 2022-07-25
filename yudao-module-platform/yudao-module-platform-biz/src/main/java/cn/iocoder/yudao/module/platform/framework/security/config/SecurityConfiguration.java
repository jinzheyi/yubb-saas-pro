package cn.iocoder.yudao.module.platform.framework.security.config;

import cn.iocoder.yudao.framework.security.config.AuthorizeRequestsCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.ExpressionUrlAuthorizationConfigurer;

/**
 * platform 模块的 Security 配置
 *
 * @author zhusy
 * @since 2022/7/24
 */
@Configuration("platformSecurityConfiguration")
public class SecurityConfiguration {

    @Bean("platformAuthorizeRequestsCustomizer")
    public AuthorizeRequestsCustomizer authorizeRequestsCustomizer() {
        return new AuthorizeRequestsCustomizer() {
            @Override
            public void customize(ExpressionUrlAuthorizationConfigurer<HttpSecurity>.ExpressionInterceptUrlRegistry registry) {
                //登录的接口
                registry.antMatchers(buildPlatformApi("/platform/auth/login")).permitAll();
                registry.antMatchers(buildPlatformApi("/platform/auth/logout")).permitAll();
                registry.antMatchers(buildPlatformApi("/platform/auth/refresh-token")).permitAll();
                // 验证码的接口
                registry.antMatchers(buildPlatformApi("/platform/captcha/**")).permitAll();
            }
        };
    }

}
