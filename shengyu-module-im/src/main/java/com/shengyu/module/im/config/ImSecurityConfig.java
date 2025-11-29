package com.shengyu.module.im.config;

import com.shengyu.framework.security.config.SecurityProperties;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;

import javax.servlet.http.HttpServletRequest;

/**
 * IM安全配置类
 * 暂时注释掉@Configuration注解，避免Spring自动扫描
 *
 * @author 圣钰科技
 */
@Configuration
public class ImSecurityConfig {

    @Autowired
    private SecurityProperties securityProperties;

    /**
     * 从请求中获取令牌
     *
     * @param request HTTP请求对象
     * @return 纯净的令牌
     */
    public String extractToken(HttpServletRequest request) {
        // 使用工具类从请求中提取令牌
        return SecurityFrameworkUtils.obtainAuthorization(request,
                securityProperties.getTokenHeader(), securityProperties.getTokenParameter());
    }

    /**
     * 验证令牌格式
     *
     * @param token 令牌字符串
     * @return 是否有效
     */
    public boolean validateTokenFormat(String token) {
        if (token == null || token.isEmpty()) {
            return false;
        }
        // 检查令牌是否包含Bearer前缀
        if (token.startsWith(securityProperties.getTokenHeader())) {
            return true;
        }
        // 检查令牌是否是纯净的UUID格式
        return token.matches("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");
    }

}
