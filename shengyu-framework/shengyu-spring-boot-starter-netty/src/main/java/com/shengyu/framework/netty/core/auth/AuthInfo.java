package com.shengyu.framework.netty.core.auth;

import lombok.Data;

/**
 * 鉴权后返回的信息
 * @author zhusy
 * @since 2022/11/14
 */
@Data
public class AuthInfo {

    /**
     * 校验是否通过 true(通过) false(不通过)
     */
    private Boolean verify;

    /**
     * 用户ID
     */
    private String userId;
    
    /**
     * 租户ID
     */
    private String tenantId;
    
    /**
     * 访问令牌
     */
    private String token;
    
    /**
     * 刷新令牌
     */
    private String refreshToken;

}
