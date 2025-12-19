package com.shengyu.framework.netty.service.impl;

import com.shengyu.framework.netty.core.Attributes;
import com.shengyu.framework.netty.core.auth.AuthInfo;
import com.shengyu.framework.netty.service.NettyAuthService;
import io.netty.channel.Channel;
import io.netty.handler.codec.http.FullHttpRequest;
import org.springframework.stereotype.Service;

/**
 * Netty认证服务实现类
 *
 * @author zhusy
 * @since 2024/12/19
 */
@Service
public class NettyAuthServiceImpl implements NettyAuthService {

    @Override
    public boolean authenticate(AuthInfo authInfo, Channel channel) {
        // 这里可以根据authInfo中的信息进行不同类型的认证
        // 例如：token认证、用户名密码认证、第三方认证等
        if (authInfo != null && authInfo.getUserId() != null) {
            saveAuthInfo(channel, authInfo);
            return true;
        }
        return false;
    }

    @Override
    public AuthInfo getAuthInfo(Channel channel) {
        return channel.attr(Attributes.AUTH_INFO).get();
    }

    @Override
    public void saveAuthInfo(Channel channel, AuthInfo authInfo) {
        channel.attr(Attributes.AUTH_INFO).set(authInfo);
    }

    @Override
    public void clearAuthInfo(Channel channel) {
        channel.attr(Attributes.AUTH_INFO).remove();
    }

    @Override
    public boolean isAuthenticated(Channel channel) {
        return getAuthInfo(channel) != null;
    }

    /**
     * 兼容原有接口的verifyToken方法
     *
     * @param fullHttpRequest 完整的http请求
     * @return 认证信息
     */
    public AuthInfo verifyToken(FullHttpRequest fullHttpRequest) {
        // 从请求中提取认证信息，例如从header或参数中获取token
        // 这里可以根据实际业务逻辑实现
        AuthInfo authInfo = new AuthInfo();
        // 示例：从header中获取token和userId
        String token = fullHttpRequest.headers().get("token");
        String userId = fullHttpRequest.headers().get("userId");
        
        if (token != null && userId != null) {
            authInfo.setToken(token);
            authInfo.setUserId(userId);
            return authInfo;
        }
        
        return null;
    }
}
