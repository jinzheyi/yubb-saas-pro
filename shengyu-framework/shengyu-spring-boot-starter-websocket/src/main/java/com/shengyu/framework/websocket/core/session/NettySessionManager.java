package com.shengyu.framework.websocket.core.session;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.audit.AuditLogBuilder;
import com.shengyu.framework.websocket.core.audit.AuditLogEvent;
import com.shengyu.framework.websocket.core.metrics.WebSocketMetrics;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageHeader;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFutureListener;
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
import java.util.concurrent.TimeUnit;
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

    /**
     * Lease Expire Time -> Channel IDs (Sorted)
     * 用于租约扫描器高效扫描即将到期/已到期的连接（O(log N) 而非 O(N)）
     * key: leaseExpireTime (毫秒时间戳), value: Set<channelId>
     */
    private final TreeMap<Long, Set<String>> leaseExpireIndex = new TreeMap<>();

    private List<NettySessionLifecycleListener> lifecycleListeners = Collections.emptyList();

    private AuditLogPublisher auditLogPublisher;

    private WebSocketMetrics metrics;

    @Autowired(required = false)
    public void setMetrics(WebSocketMetrics metrics) {
        this.metrics = metrics;
    }

    @Autowired(required = false)
    public void setLifecycleListeners(List<NettySessionLifecycleListener> lifecycleListeners) {
        this.lifecycleListeners = lifecycleListeners != null ? lifecycleListeners : Collections.emptyList();
    }

    @Autowired(required = false)
    public void setAuditLogPublisher(AuditLogPublisher auditLogPublisher) {
        this.auditLogPublisher = auditLogPublisher;
    }

    private void notifySessionAdded(NettySession session) {
        for (NettySessionLifecycleListener listener : lifecycleListeners) {
            try {
                listener.onSessionAdded(session);
            } catch (Exception e) {
                log.warn("[SessionManager] lifecycle onSessionAdded failed, userId: {}, deviceType: {}",
                        session != null ? session.getUserId() : null,
                        session != null ? session.getDeviceType() : null,
                        e);
            }
        }
    }

    private void notifySessionRemoved(NettySession session) {
        for (NettySessionLifecycleListener listener : lifecycleListeners) {
            try {
                listener.onSessionRemoved(session);
            } catch (Exception e) {
                log.warn("[SessionManager] lifecycle onSessionRemoved failed, userId: {}, deviceType: {}",
                        session != null ? session.getUserId() : null,
                        session != null ? session.getDeviceType() : null,
                        e);
            }
        }
    }

    private void notifySessionBizActive(NettySession session) {
        for (NettySessionLifecycleListener listener : lifecycleListeners) {
            try {
                listener.onSessionBizActive(session);
            } catch (Exception e) {
                log.warn("[SessionManager] lifecycle onSessionBizActive failed, userId: {}, deviceType: {}",
                        session != null ? session.getUserId() : null,
                        session != null ? session.getDeviceType() : null,
                        e);
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

        // 2.3 添加租约到期索引（用于高效扫描）
        if (session.getLeaseExpireTime() != null && session.getLeaseExpireTime() > 0) {
            leaseExpireIndex.computeIfAbsent(session.getLeaseExpireTime(), k -> ConcurrentHashMap.newKeySet())
                .add(channelId);
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

        log.debug("[SessionManager] 添加会话, userId: {}, tenantId: {}, deviceType: {}, channelId: {}, 当前在线: {}", 
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
            // 【竞态修复】仅当 map 中的值等于被移除的 channelId 时才 remove，防止踢人时序误删新登录设备的映射
            if (userId != null && deviceType != null) {
                String userDeviceKey = buildUserDeviceKey(userId, deviceType);
                userDeviceChannelMap.compute(userDeviceKey, (key, current) ->
                    current != null && current.equals(channelId) ? null : current);
            }

            // 从租约到期索引中移除
            if (session.getLeaseExpireTime() != null && session.getLeaseExpireTime() > 0) {
                Set<String> expireChannels = leaseExpireIndex.get(session.getLeaseExpireTime());
                if (expireChannels != null) {
                    expireChannels.remove(channelId);
                    if (expireChannels.isEmpty()) {
                        leaseExpireIndex.remove(session.getLeaseExpireTime());
                    }
                }
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

            log.debug("[SessionManager] 移除会话, userId: {}, tenantId: {}, deviceType: {}, channelId: {}, 当前在线: {}", 
            userId, tenantId, deviceType, channelId, channelSessionMap.size());
            notifySessionRemoved(session);
        }
    }

    /**
     * 根据 accessToken 撤销连接（Token 撤销联动，实时失效）
     *
     * 用于：用户修改密码、管理员踢人、Token 过期等场景
     * 通过 O(1) 查找快速定位连接并关闭，避免权限残留窗口
     */
    public void revokeByAccessToken(String accessToken) {
        if (StrUtil.isBlank(accessToken)) {
            return;
        }
        String channelId = accessTokenChannelMap.get(accessToken);
        if (channelId == null) {
            log.debug("[SessionManager] Token 撤销但连接不存在, accessToken: {}", accessToken);
            return;
        }
        NettySession session = channelSessionMap.get(channelId);
        if (session == null || !session.isActive()) {
            // 连接已失效，清理残留索引
            if (session != null) {
                removeSession(session.getChannel());
            }
            return;
        }

        log.info("[SessionManager] Token 撤销联动, userId: {}, tenantId: {}, deviceType: {}",
                session.getUserId(), session.getTenantId(), session.getDeviceType());

        Channel ch = session.getChannel();
        removeSession(ch);

        // 发送关闭通知
        try {
            if (isWebSocketChannel(ch)) {
                String payload = JSONUtil.createObj()
                    .set("header", JSONUtil.createObj()
                        .set("messageId", System.currentTimeMillis())
                        .set("messageType", MessageType.CLOSE_VALUE)
                        .set("timestamp", System.currentTimeMillis()))
                    .set("body", JSONUtil.createObj()
                        .set("action", "TOKEN_REVOKED")
                        .set("code", 401)
                        .set("message", "认证已失效，请重新登录"))
                    .toString();
                ch.writeAndFlush(new TextWebSocketFrame(payload));
            } else {
                String extra = JSONUtil.createObj()
                    .set("action", "TOKEN_REVOKED")
                    .set("code", 401)
                    .set("message", "认证已失效，请重新登录")
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
            log.warn("[SessionManager] Token 撤销关闭连接失败", e);
        }
    }

    /**
     * 踢掉指定设备（公开方法，供业务层调用）
     *
     * @param userId     用户ID
     * @param deviceType 设备类型
     * @param reason     踢人原因
     * @return true-成功踢掉或设备已不存在, false-设备不存在或已离线
     */
    public boolean kickDevice(Long userId, Integer deviceType, String reason) {
        if (userId == null || deviceType == null) {
            return false;
        }
        NettySession session = getSessionByUserIdAndDeviceType(userId, deviceType);
        if (session == null || !session.isActive()) {
            return false;
        }

        // 记录审计日志：设备被踢出
        publishKickAuditLog(session, AuditLogEvent.DEVICE_KICK, reason, null);

        kickOffDeviceByReason(session, reason);
        return true;
    }

    /**
     * 踢掉设备（内部互踢调用）
     */
    private void kickOffDevice(NettySession kickedSession, NettySession bySession) {
        long kickedAt = System.currentTimeMillis();
        String byDevice = buildDeviceDisplay(bySession);
        String kickedAtText = KICK_TIME_FORMATTER.format(Instant.ofEpochMilli(kickedAt));
        String reason = "当前账号于" + kickedAtText + "在" + byDevice + "设备上登录。此客户端已退出登录。";

        // 记录审计日志：被踢下线
        publishKickAuditLog(kickedSession, AuditLogEvent.KICKED, reason, bySession);

        kickOffDeviceByReason(kickedSession, reason);
    }

    /**
     * 执行踢人操作（发送通知并关闭连接）
     */
    private void kickOffDeviceByReason(NettySession kickedSession, String reason) {
        long kickedAt = System.currentTimeMillis();
        String kickedAtText = KICK_TIME_FORMATTER.format(Instant.ofEpochMilli(kickedAt));
        String byDevice = buildDeviceDisplay(kickedSession);

        log.info("[SessionManager] 踢掉设备, userId: {}, deviceType: {}, reason: {}",
            kickedSession.getUserId(), kickedSession.getDeviceType(), reason);

        if (metrics != null) {
            metrics.recordSessionKicked();
        }

        try {
            Channel ch = kickedSession.getChannel();
            if (ch == null) {
                return;
            }

            // 先移除会话索引，避免关闭链路延迟导致旧索引残留
            removeSession(ch);

            Object notification;
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
                notification = new TextWebSocketFrame(payload);
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
                notification = ImMessage.newBuilder().setHeader(header).build();
            }

            // 【延迟关闭修复】等待 KICKED 消息发送完成后再关闭连接（500ms 延迟），确保客户端来得及处理通知
            ch.writeAndFlush(notification)
                .addListener((ChannelFutureListener) future ->
                    future.channel().eventLoop().schedule(
                        () -> future.channel().close(),
                        500, TimeUnit.MILLISECONDS
                    )
                );
        } catch (Exception e) {
            log.error("[SessionManager] 踢掉设备失败", e);
        }
    }

    /**
     * 发布踢人/设备下线审计日志
     */
    private void publishKickAuditLog(NettySession session, AuditLogEvent event, String reason, NettySession bySession) {
        if (auditLogPublisher == null || session == null) {
            return;
        }
        try {
            String details = JSONUtil.createObj()
                    .set("reason", reason)
                    .set("eventType", event.getType())
                    .set("byDevice", bySession != null ? buildDeviceDisplay(bySession) : null)
                    .set("byUserId", bySession != null ? bySession.getUserId() : null)
                    .toString();
            auditLogPublisher.publish(AuditLogBuilder.builder()
                    .eventType(event.getType())
                    .eventName(event.getName())
                    .userId(session.getUserId())
                    .tenantId(session.getTenantId())
                    .deviceId(session.getDeviceId())
                    .deviceType(session.getDeviceType())
                    .details(details)
                    .timestamp(System.currentTimeMillis())
                    .build());
        } catch (Exception e) {
            log.warn("[SessionManager] 发布审计日志失败, eventType: {}", event.getType(), e);
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
     * 获取活跃连接数（用于监控指标采集）
     */
    public int getActiveConnectionCount() {
        return (int) channelSessionMap.values().stream().filter(NettySession::isActive).count();
    }

    /**
     * 按租户统计活跃连接数（用于监控指标采集）
     */
    public Map<Long, Integer> getActiveConnectionCountByTenant() {
        return tenantChannelMap.entrySet().stream()
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        e -> (int) e.getValue().stream()
                                .map(channelSessionMap::get)
                                .filter(Objects::nonNull)
                                .filter(NettySession::isActive)
                                .count()
                ));
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
        leaseExpireIndex.clear();
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

    /**
     * 获取指定时间前到期的所有会话（高效范围查询）
     * @param expireTimeMs 到期时间戳（毫秒）
     * @return 到期会话列表
     */
    public List<NettySession> getSessionsExpiringBefore(long expireTimeMs) {
        Map<Long, Set<String>> headMap = leaseExpireIndex.headMap(expireTimeMs);
        List<NettySession> result = new ArrayList<>();
        for (Set<String> channelIds : headMap.values()) {
            for (String channelId : channelIds) {
                NettySession session = channelSessionMap.get(channelId);
                if (session != null && session.isActive()) {
                    result.add(session);
                }
            }
        }
        return result;
    }

    /**
     * 获取租约索引条目数（用于监控）
     */
    public int getLeaseExpireIndexEntryCount() {
        return leaseExpireIndex.size();
    }
}
