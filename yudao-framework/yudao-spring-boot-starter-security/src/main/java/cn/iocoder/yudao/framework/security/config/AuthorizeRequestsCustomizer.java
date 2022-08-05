package cn.iocoder.yudao.framework.security.config;

import cn.iocoder.yudao.framework.web.config.WebProperties;
import org.springframework.core.Ordered;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.ExpressionUrlAuthorizationConfigurer;

import javax.annotation.Resource;

/**
 * 自定义的 URL 的安全配置
 * 目的：每个 Maven Module 可以自定义规则！
 *
 * @author 芋道源码
 */
public abstract class AuthorizeRequestsCustomizer
        implements Customizer<ExpressionUrlAuthorizationConfigurer<HttpSecurity>.ExpressionInterceptUrlRegistry>, Ordered {

    @Resource
    private WebProperties webProperties;

    /**
     * platform 模块
     * @param url
     * @return
     */
    protected String buildPlatformApi(String url) {
        return webProperties.getCenterApi().getPrefix() + url;
    }

    /**
     * system 模块
     * @param url
     * @return
     */
    protected String buildAdminApi(String url) {
        return webProperties.getAdminApi().getPrefix() + url;
    }

    /**
     * member 模块
     * @param url
     * @return
     */
    protected String buildAppApi(String url) {
        return webProperties.getAppApi().getPrefix() + url;
    }

    @Override
    public int getOrder() {
        return 0;
    }

}
