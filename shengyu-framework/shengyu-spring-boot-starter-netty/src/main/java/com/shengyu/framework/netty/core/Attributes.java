package com.shengyu.framework.netty.core;

import com.shengyu.framework.netty.core.auth.AuthInfo;
import io.netty.util.AttributeKey;

public interface Attributes {

    AttributeKey<String> userId = AttributeKey.newInstance("userId");
    
    /**
     * 认证信息
     */
    AttributeKey<AuthInfo> AUTH_INFO = AttributeKey.newInstance("authInfo");

}
