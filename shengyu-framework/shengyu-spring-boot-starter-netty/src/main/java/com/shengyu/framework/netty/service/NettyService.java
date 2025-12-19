package com.shengyu.framework.netty.service;

import io.netty.channel.Channel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Netty服务统一入口
 * 提供给业务模块使用的统一API接口
 *
 * @author zhusy
 * @since 2024/12/19
 */
@Service
public class NettyService {

    private final NettyMessageService nettyMessageService;
    private final NettyAuthService nettyAuthService;

    @Autowired
    public NettyService(NettyMessageService nettyMessageService,
                       NettyAuthService nettyAuthService) {
        this.nettyMessageService = nettyMessageService;
        this.nettyAuthService = nettyAuthService;
    }

    /**
     * 发送消息给指定用户
     *
     * @param userId   用户ID
     * @param message  消息内容
     * @return 是否发送成功
     */
    public boolean sendToUser(String userId, Object message) {
        return nettyMessageService.sendToUser(userId, message);
    }

    /**
     * 发送消息给多个用户
     *
     * @param userIds  用户ID列表
     * @param message  消息内容
     */
    public void sendToUsers(List<String> userIds, Object message) {
        nettyMessageService.sendToUsers(userIds, message);
    }

    /**
     * 发送消息给所有在线用户
     *
     * @param message  消息内容
     */
    public void sendToAll(Object message) {
        nettyMessageService.sendToAll(message);
    }

    /**
     * 关闭用户连接
     *
     * @param userId  用户ID
     */
    public void closeUserChannel(String userId) {
        nettyMessageService.closeUserChannel(userId);
    }

    /**
     * 获取用户通道
     *
     * @param userId  用户ID
     * @return 通道对象
     */
    public Channel getUserChannel(String userId) {
        return nettyMessageService.getUserChannel(userId);
    }

    /**
     * 获取在线用户数量
     *
     * @return 在线用户数量
     */
    public int getOnlineUserCount() {
        return nettyMessageService.getOnlineUserCount();
    }

    /**
     * 检查用户是否在线
     *
     * @param userId  用户ID
     * @return 是否在线
     */
    public boolean isUserOnline(String userId) {
        return nettyMessageService.isUserOnline(userId);
    }

    /**
     * 获取认证服务
     *
     * @return 认证服务实例
     */
    public NettyAuthService getNettyAuthService() {
        return nettyAuthService;
    }

    /**
     * 获取消息服务
     *
     * @return 消息服务实例
     */
    public NettyMessageService getNettyMessageService() {
        return nettyMessageService;
    }
}
