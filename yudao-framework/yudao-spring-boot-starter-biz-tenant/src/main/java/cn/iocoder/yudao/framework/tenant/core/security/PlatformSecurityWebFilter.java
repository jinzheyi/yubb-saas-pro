package cn.iocoder.yudao.framework.tenant.core.security;

import cn.iocoder.yudao.framework.tenant.core.context.TenantContextHolder;
import cn.iocoder.yudao.framework.web.config.WebProperties;
import cn.iocoder.yudao.framework.web.core.filter.ApiPlatformRequestFilter;
import lombok.extern.slf4j.Slf4j;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * 平台端请求对于租户ID的一些处理
 *
 * @author 芋道源码
 */
@Slf4j
public class PlatformSecurityWebFilter extends ApiPlatformRequestFilter {

    public PlatformSecurityWebFilter(WebProperties webProperties) {
        super(webProperties);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        //忽略租户ID的拼接
        TenantContextHolder.setIgnore(true);

        // 继续过滤
        chain.doFilter(request, response);
    }

}
