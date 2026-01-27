package com.shengyu.framework.websocket.core.service;

import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.PlatformLoginUser;
import com.shengyu.framework.security.core.util.LoginBase;

/**
 * 认证服务接口
 * 提供 Token 验证功能，支持租户端和平台端
 *
 * @author 圣钰科技
 */
public interface AuthService {

    /**
     * 验证 Token
     * 
     * @param accessToken 访问令牌
     * @return 登录用户信息，验证失败返回 null
     */
    LoginBase validateToken(String accessToken);

    /**
     * 获取租户ID
     * 
     * @param loginUser 登录用户
     * @return 租户ID，平台端用户返回 null
     */
    Long getTenantId(LoginBase loginUser);

    /**
     * 判断是否为租户端用户
     * 
     * @param loginUser 登录用户
     * @return true-租户端用户，false-平台端用户
     */
    default boolean isTenantUser(LoginBase loginUser) {
        return loginUser instanceof LoginUser;
    }

    /**
     * 判断是否为平台端用户
     * 
     * @param loginUser 登录用户
     * @return true-平台端用户，false-租户端用户
     */
    default boolean isPlatformUser(LoginBase loginUser) {
        return loginUser instanceof PlatformLoginUser;
    }
}
