package com.shengyu.framework.websocket.core.session;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import io.netty.channel.Channel;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * Netty 会话管理器
 * 管理所有在线用户的连接会话
 * 
 * 【多端登录支持】
 * 1. 同一设备类型只允许一个设备在线（互踢策略）
 * 2. 不同设备类型可以同时在线
 * 3. 支持按租户、用户、设备等多维度查询
 * 
 * 【线程安全】
 * 使用 ConcurrentHashMap 保证线程安全
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
public class NettySessionManager {

    private static final DateTimeFormatter KICK_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
        .withZone(ZoneId.systemDefault());

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
     * User ID + Device Type -> Channel ID
     * 用于实现多端登录互踢策略（每个设备类型只保留一个连接）
     */
    private final Map<String, String> userDeviceChannelMap = new ConcurrentHashMap<>();

    /**
     * AccessToken -> Channel ID
     * 用于按 accessToken 精确撤销（O(1) 定位连接）
     */
    private final Map<String, String> accessTokenChannelMap = new ConcurrentHashMap<>();

    /**
     * User ID + Device Type + Device ID -> Channel ID
     * 用于按设备精确撤销（O(1) 定位连接）
     */
    private final Map<String, String> userDeviceIdChannelMap = new ConcurrentHashMap<>();

    /**
     * Tenant ID -> Channel IDs
     * 用于按租户查找所有连接
     */
    private final Map<Long, Set<String>> tenantChannelMap = new ConcurrentHashMap<>();

    private List<NettySessionLifecycleListener> lifecycleListeners = Collections.emptyList();

    @Autowired(required = false)
    public void setLifecycleListeners(List<NettySessionLifecycleListener> lifecycleListeners) {
        this.lifecycleListeners = lifecycleListeners != null ? lifecycleListeners : Collections.emptyList();
    }

    private void notifySessionAdded(NettySession session) {
        for (NettySessionLifecycleListener listener : lifecycleListeners) {
            try {
                listener.onSessionAdded(session);
            } catch (Exception e) {
                log.warn("[SessionManager] lifecycle onSessionAdded failed, userId: {}, deviceType: {}, error: {}",
                        session != null ? session.getUserId() : null,
                        session != null ? session.getDeviceType() : null,
                        e.getMessage());
            }
        }
    }

    private void notifySessionRemoved(NettySession session) {
        for (NettySessionLifecycleListener listener : lifecycleListeners) {
            try {
                listener.onSessionRemoved(session);
            } catch (Exception e) {
                log.warn("[SessionManager] lifecycle onSessionRemoved failed, userId: {}, deviceType: {}, error: {}",
                        session != null ? session.getUserId() : null,
                        session != null ? session.getDeviceType() : null,
                        e.getMessage());
            }
        }
    }

    private void notifySessionBizActive(NettySession session) {
        for (NettySessionLifecycleListener listener : lifecycleListeners) {
            try {
                listener.onSessionBizActive(session);
            } catch (Exception e) {
                log.warn("[SessionManager] lifecycle onSessionBizActive failed, userId: {}, deviceType: {}, error: {}",
                        session != null ? session.getUserId() : null,
                        session != null ? session.getDeviceType() : null,
                        e.getMessage());
            }
        }
    }

    /**
     * 添加会话（支持多端登录互踢策略）
     */
    public void addSession(NettySession session) {
        if (session == null || session.getChannel() == null) {
            return;
        }

        String channelId = session.getChannelId();

        // 同一条连接重复认证（续期/换 token）：先清理旧 session 的索引，避免 accessToken 等索引残留
        if (channelId != null && channelSessionMap.containsKey(channelId)) {
            removeSession(session.getChannel());
        }
        Long userId = session.getUserId();
        Integer deviceType = session.getDeviceType();
        Long tenantId = session.getTenantId();

        // 1. 检查是否有同类型设备在线（互踢策略）
        if (userId != null && deviceType != null) {
            String userDeviceKey = buildUserDeviceKey(userId, deviceType);
            String oldChannelId = userDeviceChannelMap.get(userDeviceKey);
            
            if (oldChannelId != null && !oldChannelId.equals(channelId)) {
                // 踢掉旧设备
                NettySession oldSession = channelSessionMap.get(oldChannelId);
                if (oldSession != null && oldSession.isActive()) {
                    kickOffDevice(oldSession, session);
                }
            }
            
            // 保存新设备的映射
            userDeviceChannelMap.put(userDeviceKey, channelId);
        }

        // 2. 添加到 Channel 映射
        channelSessionMap.put(channelId, session);

        // 2.1 添加到 accessToken 映射（用于精确撤销）
        if (StrUtil.isNotBlank(session.getAccessToken())) {
            accessTokenChannelMap.put(session.getAccessToken(), channelId);
        }

        // 2.2 添加到 userId + deviceType + deviceId 映射（用于设备精确撤销）
        if (userId != null && deviceType != null && StrUtil.isNotBlank(session.getDeviceId())) {
            userDeviceIdChannelMap.put(buildUserDeviceIdKey(userId, deviceType, session.getDeviceId()), channelId);
        }

        // 3. 添加到用户映射
        if (userId != null) {
            userChannelMap.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet())
                .add(channelId);
        }

        // 4. 添加到租户映射
        if (tenantId != null) {
            tenantChannelMap.computeIfAbsent(tenantId, k -> ConcurrentHashMap.newKeySet())
                .add(channelId);
        }

        log.info("[SessionManager] 添加会话, userId: {}, tenantId: {}, deviceType: {}, channelId: {}, 当前在线: {}", 
            userId, tenantId, deviceType, channelId, channelSessionMap.size());
        notifySessionAdded(session);
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
            Integer deviceType = session.getDeviceType();
            Long tenantId = session.getTenantId();

            // 从 accessToken 映射中移除
            if (StrUtil.isNotBlank(session.getAccessToken())) {
                accessTokenChannelMap.remove(session.getAccessToken());
            }

            // 从 userId + deviceType + deviceId 映射中移除
            if (userId != null && deviceType != null && StrUtil.isNotBlank(session.getDeviceId())) {
                userDeviceIdChannelMap.remove(buildUserDeviceIdKey(userId, deviceType, session.getDeviceId()));
            }

            // 从用户设备映射中移除
            if (userId != null && deviceType != null) {
                String userDeviceKey = buildUserDeviceKey(userId, deviceType);
                userDeviceChannelMap.remove(userDeviceKey);
            }

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

            log.info("[SessionManager] 移除会话, userId: {}, tenantId: {}, deviceType: {}, channelId: {}, 当前在线: {}", 
                userId, tenantId, deviceType, channelId, channelSessionMap.size());
            notifySessionRemoved(session);
        }
    }

    /**
     * 踢掉设备
     */
    private void kickOffDevice(NettySession kickedSession, NettySession bySession) {
        long kickedAt = System.currentTimeMillis();
        String byDevice = buildDeviceDisplay(bySession);
        String kickedAtText = KICK_TIME_FORMATTER.format(Instant.ofEpochMilli(kickedAt));
        String reason = "当前账号于" + kickedAtText + "在" + byDevice + "设备上登录。此客户端已退出登录。";

        log.info("[SessionManager] 踢掉设备, userId: {}, deviceType: {}, byDeviceType: {}, byDeviceId: {}",
            kickedSession.getUserId(), kickedSession.getDeviceType(),
            bySession != null ? bySession.getDeviceType() : null, bySession != null ? bySession.getDeviceId() : null);

        try {
            Channel ch = kickedSession.getChannel();
            if (ch == null) {
                return;
            }

            // 先移除会话索引，避免关闭链路延迟导致旧索引残留
            removeSession(ch);

            if (isWebSocketChannel(ch)) {
                String payload = JSONUtil.createObj()
                    .set("header", JSONUtil.createObj()
                        .set("messageId", System.currentTimeMillis())
                        .set("messageType", MessageType.CLOSE_VALUE)
                        .set("timestamp", System.currentTimeMillis()))
                    .set("body", JSONUtil.createObj()
                        .set("action", "KICKED")
                        .set("code", 403)
                        .set("message", reason)
                        .set("kickedAt", kickedAt)
                        .set("byDevice", byDevice))
                    .toString();
                ch.writeAndFlush(new TextWebSocketFrame(payload));
            } else {
                String extra = JSONUtil.createObj()
                    .set("action", "KICKED")
                    .set("code", 403)
                    .set("message", reason)
                    .set("kickedAt", kickedAt)
                    .set("byDevice", byDevice)
                    .toString();
                MessageHeader header = MessageHeader.newBuilder()
                    .setMessageId(System.currentTimeMillis())
                    .setMessageType(MessageType.CLOSE)
                    .setTimestamp(System.currentTimeMillis())
                    .setExtra(extra)
                    .build();
                ch.writeAndFlush(ImMessage.newBuilder().setHeader(header).build());
            }

            ch.close();
        } catch (Exception e) {
            log.error("[SessionManager] 踢掉设备失败", e);
        }
    }

    private String buildDeviceDisplay(NettySession session) {
        if (session == null) {
            return "未知";
        }

        if (StrUtil.isNotBlank(session.getDeviceName())) {
            return session.getDeviceName();
        }
        String deviceName;
        Integer dt = session.getDeviceType();
        if (dt == null) {
            deviceName = "未知";
        } else if (dt == 1) {
            deviceName = "Web";
        } else if (dt == 2) {
            deviceName = "iOS";
        } else if (dt == 3) {
            deviceName = "Android";
        } else if (dt == 4) {
            deviceName = "小程序";
        } else {
            deviceName = "设备" + dt;
        }
        return deviceName;
    }

    private boolean isWebSocketChannel(Channel channel) {
        try {
            return channel.pipeline().get(WebSocketServerProtocolHandler.class) != null;
        } catch (Exception ignore) {
            return false;
        }
    }

    /**
     * 构建用户设备键
     */
    private String buildUserDeviceKey(Long userId, Integer deviceType) {
        return userId + ":" + deviceType;
    }

    private String buildUserDeviceIdKey(Long userId, Integer deviceType, String deviceId) {
        return userId + ":" + deviceType + ":" + deviceId;
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
     * 根据用户ID获取所有会话（所有设备）
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
     * 根据用户ID和设备类型获取会话
     */
    public NettySession getSessionByUserIdAndDeviceType(Long userId, Integer deviceType) {
        if (userId == null || deviceType == null) {
            return null;
        }
        
        String userDeviceKey = buildUserDeviceKey(userId, deviceType);
        String channelId = userDeviceChannelMap.get(userDeviceKey);
        return channelId != null ? channelSessionMap.get(channelId) : null;
    }

    public NettySession getSessionByAccessToken(String accessToken) {
        if (StrUtil.isBlank(accessToken)) {
            return null;
        }
        String channelId = accessTokenChannelMap.get(accessToken);
        return channelId != null ? channelSessionMap.get(channelId) : null;
    }

    public NettySession getSessionByUserIdAndDevice(Long userId, Integer deviceType, String deviceId) {
        if (userId == null || deviceType == null || StrUtil.isBlank(deviceId)) {
            return null;
        }
        String channelId = userDeviceIdChannelMap.get(buildUserDeviceIdKey(userId, deviceType, deviceId));
        return channelId != null ? channelSessionMap.get(channelId) : null;
    }

    /**
     * 获取用户在线的所有设备类型
     */
    public List<Integer> getOnlineDeviceTypes(Long userId) {
        List<NettySession> sessions = getSessionsByUserId(userId);
        return sessions.stream()
            .map(NettySession::getDeviceType)
            .filter(Objects::nonNull)
            .distinct()
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
        userDeviceChannelMap.clear();
        accessTokenChannelMap.clear();
        userDeviceIdChannelMap.clear();
        tenantChannelMap.clear();
        log.info("[SessionManager] 清理所有会话");
    }

    /**
     * 更新会话最后活跃时间
     */
    public void updateLastActiveTime(Channel channel) {
        if (channel == null) {
            return;
        }
        NettySession session = getSession(channel);
        if (session != null) {
            session.updateLastActiveTime();
        }
    }

    public void updateLastBizActiveTime(Channel channel) {
        if (channel == null) {
            return;
        }
        NettySession session = getSession(channel);
        if (session != null) {
            session.updateLastBizActiveTime();
            notifySessionBizActive(session);
        }
    }
}
