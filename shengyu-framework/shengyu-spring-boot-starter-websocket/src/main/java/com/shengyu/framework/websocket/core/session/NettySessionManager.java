package com.shengyu.framework.websocket.core.session;

import io.netty.channel.Channel;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * Netty 会话管理器
 * 管理所有在线用户的连接会话
 * 
 * 优化点：
 * 1. 使用 ConcurrentHashMap 保证线程安全
 * 2. 支持单用户多设备登录
 * 3. 支持按租户、用户、设备等多维度查询
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class NettySessionManager {

    /**
     * Channel ID -> Session
     * 用于快速查找会话
     */
    private final Map<String, NettySession> channelSessionMap = new ConcurrentHashMap<>();

    /**
     * User ID -> Channel IDs
     * 用于查找用户的所有连接（支持多设备）
     */
    private final Map<Long, Set<String>> userChannelMap = new ConcurrentHashMap<>();

    /**
     * Tenant ID -> Channel IDs
     * 用于按租户查找所有连接
     */
    private final Map<Long, Set<String>> tenantChannelMap = new ConcurrentHashMap<>();

    /**
     * 添加会话
     */
    public void addSession(NettySession session) {
        if (session == null || session.getChannel() == null) {
            return;
        }

        String channelId = session.getChannelId();
        Long userId = session.getUserId();
        Long tenantId = session.getTenantId();

        // 添加到 Channel 映射
        channelSessionMap.put(channelId, session);

        // 添加到用户映射
        if (userId != null) {
            userChannelMap.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet())
                .add(channelId);
        }

        // 添加到租户映射
        if (tenantId != null) {
            tenantChannelMap.computeIfAbsent(tenantId, k -> ConcurrentHashMap.newKeySet())
                .add(channelId);
        }

        log.info("[SessionManager] 添加会话, userId: {}, tenantId: {}, channelId: {}, 当前在线: {}", 
            userId, tenantId, channelId, channelSessionMap.size());
    }

    /**
     * 移除会话
     */
    public void removeSession(Channel channel) {
        if (channel == null) {
            return;
        }

        String channelId = channel.id().asShortText();
        NettySession session = channelSessionMap.remove(channelId);
        
        if (session != null) {
            Long userId = session.getUserId();
            Long tenantId = session.getTenantId();

            // 从用户映射中移除
            if (userId != null) {
                Set<String> channels = userChannelMap.get(userId);
                if (channels != null) {
                    channels.remove(channelId);
                    if (channels.isEmpty()) {
                        userChannelMap.remove(userId);
                    }
                }
            }

            // 从租户映射中移除
            if (tenantId != null) {
                Set<String> channels = tenantChannelMap.get(tenantId);
                if (channels != null) {
                    channels.remove(channelId);
                    if (channels.isEmpty()) {
                        tenantChannelMap.remove(tenantId);
                    }
                }
            }

            log.info("[SessionManager] 移除会话, userId: {}, tenantId: {}, channelId: {}, 当前在线: {}", 
                userId, tenantId, channelId, channelSessionMap.size());
        }
    }

    /**
     * 根据 Channel ID 获取会话
     */
    public NettySession getSession(String channelId) {
        return channelSessionMap.get(channelId);
    }

    /**
     * 根据 Channel 获取会话
     */
    public NettySession getSession(Channel channel) {
        if (channel == null) {
            return null;
        }
        return getSession(channel.id().asShortText());
    }

    /**
     * 根据用户ID获取所有会话
     */
    public List<NettySession> getSessionsByUserId(Long userId) {
        if (userId == null) {
            return Collections.emptyList();
        }

        Set<String> channelIds = userChannelMap.get(userId);
        if (channelIds == null || channelIds.isEmpty()) {
            return Collections.emptyList();
        }

        return channelIds.stream()
            .map(channelSessionMap::get)
            .filter(Objects::nonNull)
            .filter(NettySession::isActive)
            .collect(Collectors.toList());
    }

    /**
     * 根据租户ID获取所有会话
     */
    public List<NettySession> getSessionsByTenantId(Long tenantId) {
        if (tenantId == null) {
            return Collections.emptyList();
        }

        Set<String> channelIds = tenantChannelMap.get(tenantId);
        if (channelIds == null || channelIds.isEmpty()) {
            return Collections.emptyList();
        }

        return channelIds.stream()
            .map(channelSessionMap::get)
            .filter(Objects::nonNull)
            .filter(NettySession::isActive)
            .collect(Collectors.toList());
    }

    /**
     * 获取所有会话
     */
    public List<NettySession> getAllSessions() {
        return new ArrayList<>(channelSessionMap.values());
    }

    /**
     * 获取在线用户数
     */
    public int getOnlineUserCount() {
        return userChannelMap.size();
    }

    /**
     * 获取在线连接数
     */
    public int getOnlineConnectionCount() {
        return channelSessionMap.size();
    }

    /**
     * 判断用户是否在线
     */
    public boolean isUserOnline(Long userId) {
        if (userId == null) {
            return false;
        }
        Set<String> channels = userChannelMap.get(userId);
        return channels != null && !channels.isEmpty();
    }

    /**
     * 清理所有会话
     */
    public void clear() {
        channelSessionMap.clear();
        userChannelMap.clear();
        tenantChannelMap.clear();
        log.info("[SessionManager] 清理所有会话");
    }
}
