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
     * 用户ID -> 租户ID映射
     */
    private final Map<Long, Long> userTenantMap = new ConcurrentHashMap<>();

    /**
     * 租户ID -> 用户ID列表映射
     */
    private final Map<Long, Map<Long, Channel>> tenantUserMap = new ConcurrentHashMap<>();

    /**
     * 添加用户连接
     *
     * @param userId   用户ID
     * @param tenantId 租户ID
     * @param ctx      通道上下文
     */
    public void addConnection(Long userId, Long tenantId, ChannelHandlerContext ctx) {
        Channel channel = ctx.channel();
        // 移除旧连接
        removeConnectionByUserId(userId);
        // 移除旧的通道映射
        Long oldUserId = channelUserMap.get(channel);
        if (oldUserId != null) {
            userChannelMap.remove(oldUserId);
            Long oldTenantId = userTenantMap.remove(oldUserId);
            if (oldTenantId != null) {
                Map<Long, Channel> tenantUsers = tenantUserMap.get(oldTenantId);
                if (tenantUsers != null) {
                    tenantUsers.remove(oldUserId);
                    if (tenantUsers.isEmpty()) {
                        tenantUserMap.remove(oldTenantId);
                    }
                }
            }
        }
        // 添加新映射
        userChannelMap.put(userId, channel);
        channelUserMap.put(channel, userId);
        userTenantMap.put(userId, tenantId);
        
        // 添加到租户用户映射
        tenantUserMap.computeIfAbsent(tenantId, k -> new ConcurrentHashMap<>()).put(userId, channel);
        
        log.info("用户连接添加成功: userId={}, tenantId={}, channel={}", userId, tenantId, channel.id());
    }
    
    /**
     * 添加用户连接（兼容旧版本）
     *
     * @param userId 用户ID
     * @param ctx    通道上下文
     */
    public void addConnection(Long userId, ChannelHandlerContext ctx) {
        addConnection(userId, 0L, ctx);
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
            Long tenantId = userTenantMap.remove(userId);
            if (tenantId != null) {
                Map<Long, Channel> tenantUsers = tenantUserMap.get(tenantId);
                if (tenantUsers != null) {
                    tenantUsers.remove(userId);
                    if (tenantUsers.isEmpty()) {
                        tenantUserMap.remove(tenantId);
                    }
                }
            }
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
            Long tenantId = userTenantMap.remove(userId);
            if (tenantId != null) {
                Map<Long, Channel> tenantUsers = tenantUserMap.get(tenantId);
                if (tenantUsers != null) {
                    tenantUsers.remove(userId);
                    if (tenantUsers.isEmpty()) {
                        tenantUserMap.remove(tenantId);
                    }
                }
            }
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
     * 获取用户的租户ID
     *
     * @param userId 用户ID
     * @return 租户ID
     */
    public Long getTenantIdByUserId(Long userId) {
        return userTenantMap.get(userId);
    }

    /**
     * 根据租户ID获取在线用户数量
     *
     * @param tenantId 租户ID
     * @return 在线用户数量
     */
    public int getOnlineUserCountByTenant(Long tenantId) {
        Map<Long, Channel> tenantUsers = tenantUserMap.get(tenantId);
        return tenantUsers != null ? tenantUsers.size() : 0;
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
     * 获取在线租户数量
     *
     * @return 在线租户数量
     */
    public int getOnlineTenantCount() {
        return tenantUserMap.size();
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
        userTenantMap.clear();
        tenantUserMap.clear();
        log.info("所有用户连接已关闭");
    }
    
    /**
     * 关闭指定租户的所有连接
     *
     * @param tenantId 租户ID
     */
    public void closeConnectionsByTenant(Long tenantId) {
        Map<Long, Channel> tenantUsers = tenantUserMap.remove(tenantId);
        if (tenantUsers != null) {
            tenantUsers.forEach((userId, channel) -> {
                if (channel.isActive()) {
                    channel.close();
                }
                userChannelMap.remove(userId);
                channelUserMap.remove(channel);
                userTenantMap.remove(userId);
            });
            log.info("租户所有连接已关闭: tenantId={}", tenantId);
        }
    }

}
