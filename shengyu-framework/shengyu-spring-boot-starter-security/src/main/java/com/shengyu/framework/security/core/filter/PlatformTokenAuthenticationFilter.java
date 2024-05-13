package com.shengyu.framework.security.core.filter;

import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.servlet.ServletUtils;
import com.shengyu.framework.security.config.SecurityProperties;
import com.shengyu.framework.security.core.PlatformLoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.framework.web.config.WebProperties;
import com.shengyu.framework.web.core.filter.PlatformApiRequestFilter;
import com.shengyu.framework.web.core.handler.GlobalExceptionHandler;
import com.shengyu.framework.web.core.util.WebFrameworkUtils;
import com.shengyu.module.platform.api.oauth2.PlatformOAuth2TokenApi;
import com.shengyu.module.platform.api.oauth2.dto.OAuth2AccessTokenCheckRespDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Token 过滤器，验证 token 的有效性
 * 验证通过后，获得 {@link PlatformLoginUser} 信息，并加入到 Spring Security 上下文
 *
 * @author 圣钰科技
 */
@Slf4j
public class PlatformTokenAuthenticationFilter extends PlatformApiRequestFilter {

    private final SecurityProperties securityProperties;

    private final GlobalExceptionHandler globalExceptionHandler;

    private final PlatformOAuth2TokenApi oauth2TokenApi;

    public PlatformTokenAuthenticationFilter(WebProperties webProperties,
                                             SecurityProperties securityProperties,
                                             GlobalExceptionHandler globalExceptionHandler,
                                             PlatformOAuth2TokenApi oauth2TokenApi) {
        super(webProperties);
        this.securityProperties = securityProperties;
        this.globalExceptionHandler = globalExceptionHandler;
        this.oauth2TokenApi = oauth2TokenApi;
    }

    @Override
    @SuppressWarnings("NullableProblems")
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String token = SecurityFrameworkUtils.obtainAuthorization(request,
            securityProperties.getTokenHeader(), securityProperties.getTokenParameter());
        if (StrUtil.isNotEmpty(token)) {
            Integer userType = WebFrameworkUtils.getLoginUserType(request);
            try {
                // 1.1 基于 token 构建登录用户
                PlatformLoginUser loginUser = buildLoginUserByToken(token, userType);
                // 2. 设置当前用户
                if (loginUser != null) {
                    SecurityFrameworkUtils.setLoginUser(loginUser, request);
                }
            } catch (Throwable ex) {
                CommonResult<?> result = globalExceptionHandler.allExceptionHandler(request, ex);
                ServletUtils.writeJSON(response, result);
                return;
            }
        }

        // 继续过滤链
        chain.doFilter(request, response);
    }

    private PlatformLoginUser buildLoginUserByToken(String token, Integer userType) {
        try {
            OAuth2AccessTokenCheckRespDTO accessToken = oauth2TokenApi.checkAccessToken(token);
            if (accessToken == null) {
                return null;
            }
            // 用户类型不匹配，无权限
            if (ObjectUtil.notEqual(accessToken.getUserType(), userType)) {
                throw new AccessDeniedException("错误的用户类型");
            }
            // 构建登录用户
            return PlatformLoginUser.builder().id(accessToken.getUserId()).userType(accessToken.getUserType())
                    .scopes(accessToken.getScopes()).build();
        } catch (ServiceException serviceException) {
            // 校验 Token 不通过时，考虑到一些接口是无需登录的，所以直接返回 null 即可
            return null;
        }
    }

}
