package cn.iocoder.yudao.framework.security.core.filter;

import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.exception.ServiceException;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.util.servlet.ServletUtils;
import cn.iocoder.yudao.framework.security.config.SecurityProperties;
import cn.iocoder.yudao.framework.security.core.PlatformLoginUser;
import cn.iocoder.yudao.framework.security.core.util.SecurityFrameworkUtils;
import cn.iocoder.yudao.framework.web.config.WebProperties;
import cn.iocoder.yudao.framework.web.core.filter.ApiPlatformRequestFilter;
import cn.iocoder.yudao.framework.web.core.handler.GlobalExceptionHandler;
import cn.iocoder.yudao.framework.web.core.util.WebFrameworkUtils;
import cn.iocoder.yudao.module.platform.api.oauth2.PlatformOAuth2TokenApi;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.OAuth2AccessTokenCheckRespDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * 平台系统端的Token 过滤器，验证 token 的有效性
 * 验证通过后，获得 {@link PlatformLoginUser} 信息，并加入到 Spring Security 上下文
 *
 * @author 芋道源码
 */
@Slf4j
public class TokenPlatformAuthenticationFilter extends ApiPlatformRequestFilter {

    private final SecurityProperties securityProperties;

    private final GlobalExceptionHandler globalExceptionHandler;

    private final PlatformOAuth2TokenApi oauth2TokenApiPlatform;

    public TokenPlatformAuthenticationFilter(WebProperties webProperties,
                                             SecurityProperties securityProperties,
                                             GlobalExceptionHandler globalExceptionHandler,
                                             PlatformOAuth2TokenApi oauth2TokenApiPlatform) {
        super(webProperties);
        this.securityProperties = securityProperties;
        this.globalExceptionHandler = globalExceptionHandler;
        this.oauth2TokenApiPlatform = oauth2TokenApiPlatform;
    }

    @Override
    @SuppressWarnings("NullableProblems")
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String token = SecurityFrameworkUtils.obtainAuthorization(request, securityProperties.getTokenHeader());
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
            OAuth2AccessTokenCheckRespDTO accessToken = oauth2TokenApiPlatform.checkAccessToken(token);
            if (accessToken == null) {
                return null;
            }
            // 用户类型不匹配，无权限
            if (ObjectUtil.notEqual(accessToken.getUserType(), userType)) {
                throw new AccessDeniedException("错误的用户类型");
            }
            // 构建登录用户
            return PlatformLoginUser.builder()
                    .id(accessToken.getUserId())
                    .userType(accessToken.getUserType())
                    .scopes(accessToken.getScopes()).build();
        } catch (ServiceException serviceException) {
            // 校验 Token 不通过时，考虑到一些接口是无需登录的，所以直接返回 null 即可
            return null;
        }
    }

}
