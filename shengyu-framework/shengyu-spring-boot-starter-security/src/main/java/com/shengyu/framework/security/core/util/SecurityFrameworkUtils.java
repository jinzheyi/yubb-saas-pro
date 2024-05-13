package com.shengyu.framework.security.core.util;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.PlatformLoginUser;
import com.shengyu.framework.web.core.util.WebFrameworkUtils;
import org.springframework.lang.Nullable;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.util.StringUtils;

import javax.servlet.http.HttpServletRequest;
import java.util.Collections;

/**
 * 安全服务工具类
 *
 * @author 圣钰科技
 */
public class SecurityFrameworkUtils {

    /**
     * HEADER 认证头 value 的前缀
     */
    public static final String AUTHORIZATION_BEARER = "Bearer";

    private SecurityFrameworkUtils() {}

    /**
     * 从请求中，获得认证 Token
     *
     * @param request 请求
     * @param headerName 认证 Token 对应的 Header 名字
     * @param parameterName 认证 Token 对应的 Parameter 名字
     * @return 认证 Token
     */
    public static String obtainAuthorization(HttpServletRequest request,
                                             String headerName, String parameterName) {
        // 1. 获得 Token。优先级：Header > Parameter
        String token = request.getHeader(headerName);
        if (StrUtil.isEmpty(token)) {
            token = request.getParameter(parameterName);
        }
        if (!StringUtils.hasText(token)) {
            return null;
        }
        // 2. 去除 Token 中带的 Bearer
        int index = token.indexOf(AUTHORIZATION_BEARER + " ");
        return index >= 0 ? token.substring(index + 7).trim() : token;
    }

    /**
     * 获得当前认证信息
     *
     * @return 认证信息
     */
    public static Authentication getAuthentication() {
        SecurityContext context = SecurityContextHolder.getContext();
        if (context == null) {
            return null;
        }
        return context.getAuthentication();
    }

    /**
     * 获取当前租户用户
     *
     * @return 当前租户用户
     */
    @Nullable
    public static LoginUser getLoginUser() {
        Authentication authentication = getAuthentication();
        if (authentication == null) {
            return null;
        }
        return authentication.getPrincipal() instanceof LoginUser ? (LoginUser) authentication.getPrincipal() : null;
    }

    /**
     * 获取当前平台用户
     *
     * @return 当前平台用户
     */
    @Nullable
    public static PlatformLoginUser getPlatformLoginUser() {
        Authentication authentication = getAuthentication();
        if (authentication == null) {
            return null;
        }
        return authentication.getPrincipal() instanceof PlatformLoginUser ? (PlatformLoginUser) authentication.getPrincipal() : null;
    }

    /**
     * 获得当前租户用户的编号，从上下文中
     *
     * @return 租户用户编号
     */
    @Nullable
    public static Long getLoginUserId() {
        Authentication authentication = getAuthentication();
        if (authentication == null) {
            return null;
        }
        LoginUser loginUser = authentication.getPrincipal() instanceof LoginUser ? (LoginUser) authentication.getPrincipal() : null;
        return loginUser != null ? loginUser.getId() : null;
    }

    /**
     * 获得当前平台用户的编号，从上下文中
     *
     * @return 平台用户编号
     */
    @Nullable
    public static Long getPlatformLoginUserId() {
        Authentication authentication = getAuthentication();
        if (authentication == null) {
            return null;
        }
        PlatformLoginUser platformLoginUser = authentication.getPrincipal() instanceof PlatformLoginUser ? (PlatformLoginUser) authentication.getPrincipal() : null;
        return platformLoginUser != null ? platformLoginUser.getId() : null;
    }

    /**
     * 设置当前用户
     *
     * @param loginBase 登录用户
     * @param request 请求
     */
    public static void setLoginUser(LoginBase loginBase, HttpServletRequest request) {
        // 创建 Authentication，并设置到上下文
        Authentication authentication = buildAuthentication(loginBase, request);
        SecurityContextHolder.getContext().setAuthentication(authentication);

        // 额外设置到 request 中，用于 ApiAccessLogFilter 可以获取到用户编号；
        // 原因是，Spring Security 的 Filter 在 ApiAccessLogFilter 后面，在它记录访问日志时，线上上下文已经没有用户编号等信息
        WebFrameworkUtils.setLoginUserId(request, loginBase.getId());
        WebFrameworkUtils.setLoginUserType(request, loginBase.getUserType());
    }

    private static Authentication buildAuthentication(LoginBase loginBase, HttpServletRequest request) {
        // 创建 UsernamePasswordAuthenticationToken 对象
        UsernamePasswordAuthenticationToken authenticationToken = new UsernamePasswordAuthenticationToken(
                loginBase, null, Collections.emptyList());
        authenticationToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
        return authenticationToken;
    }

}
