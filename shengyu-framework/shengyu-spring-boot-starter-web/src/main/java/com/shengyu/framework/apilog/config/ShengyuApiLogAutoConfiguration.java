package com.shengyu.framework.apilog.config;

import com.shengyu.framework.apilog.core.filter.ApiAccessLogFilter;
import com.shengyu.framework.apilog.core.service.ApiAccessLogFrameworkService;
import com.shengyu.framework.apilog.core.service.ApiAccessLogFrameworkServiceImpl;
import com.shengyu.framework.apilog.core.service.ApiErrorLogFrameworkService;
import com.shengyu.framework.apilog.core.service.ApiErrorLogFrameworkServiceImpl;
import com.shengyu.framework.common.enums.WebFilterOrderEnum;
import com.shengyu.framework.web.config.WebProperties;
import com.shengyu.framework.web.config.ShengyuWebAutoConfiguration;
import com.shengyu.module.infra.api.logger.ApiAccessLogApi;
import com.shengyu.module.infra.api.logger.ApiErrorLogApi;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;

import javax.servlet.Filter;

@AutoConfiguration(after = ShengyuWebAutoConfiguration.class)
public class ShengyuApiLogAutoConfiguration {

    @Bean
    @ConditionalOnBean(ApiAccessLogApi.class)
    public ApiAccessLogFrameworkService apiAccessLogFrameworkService(ApiAccessLogApi apiAccessLogApi) {
        return new ApiAccessLogFrameworkServiceImpl(apiAccessLogApi);
    }

    @Bean
    @ConditionalOnBean(ApiErrorLogApi.class)
    public ApiErrorLogFrameworkService apiErrorLogFrameworkService(ApiErrorLogApi apiErrorLogApi) {
        return new ApiErrorLogFrameworkServiceImpl(apiErrorLogApi);
    }

    /**
     * 创建 ApiAccessLogFilter Bean，记录 API 请求日志
     */
    @Bean
    @ConditionalOnProperty(prefix = "shengyu.access-log", value = "enable", matchIfMissing = true) // 允许使用 shengyu.access-log.enable=false 禁用访问日志
    public FilterRegistrationBean<ApiAccessLogFilter> apiAccessLogFilter(WebProperties webProperties,
                                                                         @Value("${spring.application.name}") String applicationName,
                                                                         ApiAccessLogFrameworkService apiAccessLogFrameworkService) {
        ApiAccessLogFilter filter = new ApiAccessLogFilter(webProperties, applicationName, apiAccessLogFrameworkService);
        return createFilterBean(filter, WebFilterOrderEnum.API_ACCESS_LOG_FILTER);
    }

    private static <T extends Filter> FilterRegistrationBean<T> createFilterBean(T filter, Integer order) {
        FilterRegistrationBean<T> bean = new FilterRegistrationBean<>(filter);
        bean.setOrder(order);
        return bean;
    }

}
