package com.shengyu.framework.netty.service;

import com.shengyu.framework.netty.core.auth.AuthInfo;
import io.netty.channel.Channel;

/**
 * Netty认证服务接口
 * 支持多种认证方式
 *
 * @author zhusy
 * @since 2024/12/19
 */
public interface NettyAuthService {

    /**
     * 进行认证
     *
     * @param authInfo 认证信息
     * @param channel  通道对象
     * @return 是否认证成功
     */
    boolean authenticate(AuthInfo authInfo, Channel channel);

    /**
     * 从通道中获取认证信息
     *
     * @param channel 通道对象
     * @return 认证信息
     */
    AuthInfo getAuthInfo(Channel channel);

    /**
     * 保存认证信息到通道
     *
     * @param channel  通道对象
     * @param authInfo 认证信息
     */
    void saveAuthInfo(Channel channel, AuthInfo authInfo);

    /**
     * 清除通道中的认证信息
     *
     * @param channel 通道对象
     */
    void clearAuthInfo(Channel channel);

    /**
     * 检查通道是否已认证
     *
     * @param channel 通道对象
     * @return 是否已认证
     */
    boolean isAuthenticated(Channel channel);
}
