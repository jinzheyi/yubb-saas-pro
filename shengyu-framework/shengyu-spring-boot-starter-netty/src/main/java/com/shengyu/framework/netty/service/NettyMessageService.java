package com.shengyu.framework.netty.service;

import io.netty.channel.Channel;
import java.util.List;

/**
 * Netty消息发送服务接口
 * 提供底层的独立于业务之外的消息发送能力
 *
 * @author zhusy
 * @since 2024/12/19
 */
public interface NettyMessageService {

    /**
     * 发送消息给指定用户
     *
     * @param userId   用户ID
     * @param message  消息内容
     * @return 是否发送成功
     */
    boolean sendToUser(String userId, Object message);

    /**
     * 发送消息给多个用户
     *
     * @param userIds  用户ID列表
     * @param message  消息内容
     */
    void sendToUsers(List<String> userIds, Object message);

    /**
     * 发送消息给所有在线用户
     *
     * @param message  消息内容
     */
    void sendToAll(Object message);

    /**
     * 发送消息给指定通道
     *
     * @param channel  通道对象
     * @param message  消息内容
     */
    void sendToChannel(Channel channel, Object message);

    /**
     * 关闭用户连接
     *
     * @param userId  用户ID
     */
    void closeUserChannel(String userId);

    /**
     * 获取用户通道
     *
     * @param userId  用户ID
     * @return 通道对象
     */
    Channel getUserChannel(String userId);

    /**
     * 获取在线用户数量
     *
     * @return 在线用户数量
     */
    int getOnlineUserCount();

    /**
     * 检查用户是否在线
     *
     * @param userId  用户ID
     * @return 是否在线
     */
    boolean isUserOnline(String userId);
    
    /**
     * 添加用户通道
     *
     * @param userId  用户ID
     * @param channel 通道对象
     */
    void addUserChannel(String userId, Channel channel);
    
    /**
     * 移除用户通道
     *
     * @param userId  用户ID
     */
    void removeUserChannel(String userId);
}
