package com.shengyu.module.im.netty;

import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 用户连接管理器
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class ConnectionManager {

    /**
     * 用户ID -> Channel映射
     */
    private final Map<Long, Channel> userChannelMap = new ConcurrentHashMap<>();

    /**
     * Channel -> 用户ID映射
     */
    private final Map<Channel, Long> channelUserMap = new ConcurrentHashMap<>();

    /**
     * 添加用户连接
     *
     * @param userId 用户ID
     * @param ctx    通道上下文
     */
    public void addConnection(Long userId, ChannelHandlerContext ctx) {
        Channel channel = ctx.channel();
        // 移除旧连接
        removeConnectionByUserId(userId);
        // 移除旧的通道映射
        Long oldUserId = channelUserMap.get(channel);
        if (oldUserId != null) {
            userChannelMap.remove(oldUserId);
        }
        // 添加新映射
        userChannelMap.put(userId, channel);
        channelUserMap.put(channel, userId);
        log.info("用户连接添加成功: userId={}, channel={}", userId, channel.id());
    }

    /**
     * 移除用户连接
     *
     * @param ctx 通道上下文
     */
    public void removeConnection(ChannelHandlerContext ctx) {
        Channel channel = ctx.channel();
        Long userId = channelUserMap.remove(channel);
        if (userId != null) {
            userChannelMap.remove(userId);
            log.info("用户连接移除成功: userId={}, channel={}", userId, channel.id());
        }
    }

    /**
     * 根据用户ID移除连接
     *
     * @param userId 用户ID
     */
    public void removeConnectionByUserId(Long userId) {
        Channel channel = userChannelMap.remove(userId);
        if (channel != null) {
            channelUserMap.remove(channel);
            log.info("根据用户ID移除连接成功: userId={}, channel={}", userId, channel.id());
        }
    }

    /**
     * 根据用户ID获取通道
     *
     * @param userId 用户ID
     * @return 通道
     */
    public Channel getChannelByUserId(Long userId) {
        return userChannelMap.get(userId);
    }

    /**
     * 根据通道获取用户ID
     *
     * @param ctx 通道上下文
     * @return 用户ID
     */
    public Long getUserIdByChannel(ChannelHandlerContext ctx) {
        return channelUserMap.get(ctx.channel());
    }

    /**
     * 判断用户是否在线
     *
     * @param userId 用户ID
     * @return 是否在线
     */
    public boolean isOnline(Long userId) {
        return userChannelMap.containsKey(userId);
    }

    /**
     * 获取在线用户数量
     *
     * @return 在线用户数量
     */
    public int getOnlineUserCount() {
        return userChannelMap.size();
    }

    /**
     * 关闭所有连接
     */
    public void closeAllConnections() {
        userChannelMap.forEach((userId, channel) -> {
            if (channel.isActive()) {
                channel.close();
            }
        });
        userChannelMap.clear();
        channelUserMap.clear();
        log.info("所有用户连接已关闭");
    }

}
