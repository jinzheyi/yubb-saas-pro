package com.shengyu.module.im.service;

import com.shengyu.module.im.dto.ImMessage;
import io.netty.channel.ChannelHandlerContext;

/**
 * IM认证服务
 *
 * @author 圣钰科技
 */
public interface ImAuthService {

    /**
     * 验证用户登录
     *
     * @param ctx     通道上下文
     * @param message 登录消息
     * @return 是否认证成功
     */
    boolean authenticate(ChannelHandlerContext ctx, ImMessage message);

    /**
     * 处理用户登出
     *
     * @param userId 用户ID
     */
    void logout(Long userId);

}
