package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.module.system.dal.redis.RedisKeyConstants;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * IM 在线状态服务
 *
 * 设计目标：
 * 1. 以 Redis 作为 presence 聚合源，兼容多实例部署
 * 2. 以设备类型为维度保留多端在线态
 * 3. 离线后保留最近活跃时间，供聊天头部/联系人详情复用
 */
@Service
@Slf4j
public class ImPresenceServiceImpl implements ImPresenceService {

    private static final Duration PRESENCE_CACHE_TTL = Duration.ofDays(30);

    /**
     * 客户端心跳 30s，服务端读空闲 60s。
     * 这里按 90s 视为在线态失效，避免短抖动误判，同时能自动兜底节点异常未清理场景。
     */
    private static final long ONLINE_STALE_MS = 90_000L;

    @Resource
    private StringRedisTemplate stringRedisTemplate;

    @Override
    public ImPresenceSnapshot getUserPresence(Long userId) {
        if (userId == null || userId <= 0L) {
            return ImPresenceSnapshot.builder()
                    .online(false)
                    .onlineDeviceTypes(Collections.emptyList())
                    .lastActiveTime(null)
                    .build();
        }
        try {
            Map<Object, Object> entries = stringRedisTemplate.opsForHash().entries(buildPresenceKey(userId));
            if (entries == null || entries.isEmpty()) {
                return ImPresenceSnapshot.builder()
                        .online(false)
                        .onlineDeviceTypes(Collections.emptyList())
                        .lastActiveTime(null)
                        .build();
            }

            long now = System.currentTimeMillis();
            List<Integer> onlineDeviceTypes = new ArrayList<>();
            long lastActiveTime = 0L;
            for (Map.Entry<Object, Object> entry : entries.entrySet()) {
                DevicePresenceState state = parseState(entry.getValue());
                if (state == null) {
                    continue;
                }
                long latest = maxPositive(state.getLastBizActiveTime(), state.getLastActiveTime(), state.getUpdatedAt());
                if (latest > lastActiveTime) {
                    lastActiveTime = latest;
                }
                if (Boolean.TRUE.equals(state.getOnline())
                        && state.getDeviceType() != null
                        && state.getUpdatedAt() != null
                        && now - state.getUpdatedAt() <= ONLINE_STALE_MS
                        && !onlineDeviceTypes.contains(state.getDeviceType())) {
                    onlineDeviceTypes.add(state.getDeviceType());
                }
            }

            onlineDeviceTypes.sort(Comparator.naturalOrder());
            return ImPresenceSnapshot.builder()
                    .online(!onlineDeviceTypes.isEmpty())
                    .onlineDeviceTypes(onlineDeviceTypes)
                    .lastActiveTime(lastActiveTime > 0 ? lastActiveTime : null)
                    .build();
        } catch (Exception e) {
            log.warn("[ImPresence] getUserPresence failed, userId: {}, error: {}", userId, e.getMessage());
            return ImPresenceSnapshot.builder()
                    .online(false)
                    .onlineDeviceTypes(Collections.emptyList())
                    .lastActiveTime(null)
                    .build();
        }
    }

    @Override
    public void markSessionOnline(NettySession session) {
        syncState(session, true, false);
    }

    @Override
    public void markSessionOffline(NettySession session) {
        syncState(session, false, false);
    }

    @Override
    public void refreshSessionBizActive(NettySession session) {
        syncState(session, true, true);
    }

    private void syncState(NettySession session, boolean online, boolean forceBizActive) {
        if (session == null || session.getUserId() == null || session.getUserId() <= 0L || session.getDeviceType() == null) {
            return;
        }
        try {
            String key = buildPresenceKey(session.getUserId());
            String field = buildPresenceField(session.getDeviceType());
            DevicePresenceState previous = parseState(stringRedisTemplate.opsForHash().get(key, field));
            long now = System.currentTimeMillis();
            long sessionLastActive = maxPositive(session.getLastActiveTime(), session.getConnectTime(), now);
            long sessionLastBizActive = forceBizActive
                    ? maxPositive(session.getLastBizActiveTime(), sessionLastActive, now)
                    : maxPositive(session.getLastBizActiveTime(), sessionLastActive);

            DevicePresenceState next = DevicePresenceState.builder()
                    .deviceType(session.getDeviceType())
                    .deviceId(session.getDeviceId())
                    .online(online)
                    .lastActiveTime(maxPositive(previous != null ? previous.getLastActiveTime() : null, sessionLastActive))
                    .lastBizActiveTime(maxPositive(previous != null ? previous.getLastBizActiveTime() : null, sessionLastBizActive))
                    .updatedAt(now)
                    .build();
            stringRedisTemplate.opsForHash().put(key, field, JSONUtil.toJsonStr(next));
            stringRedisTemplate.expire(key, PRESENCE_CACHE_TTL);
        } catch (Exception e) {
            log.warn("[ImPresence] syncState failed, userId: {}, deviceType: {}, online: {}, error: {}",
                    session.getUserId(), session.getDeviceType(), online, e.getMessage());
        }
    }

    private String buildPresenceKey(Long userId) {
        return String.format(RedisKeyConstants.IM_PRESENCE_USER, userId);
    }

    private String buildPresenceField(Integer deviceType) {
        return StrUtil.toString(deviceType);
    }

    private DevicePresenceState parseState(Object raw) {
        if (raw == null) {
            return null;
        }
        try {
            String text = String.valueOf(raw);
            if (StrUtil.isBlank(text)) {
                return null;
            }
            return JSONUtil.toBean(text, DevicePresenceState.class);
        } catch (Exception e) {
            return null;
        }
    }

    private long maxPositive(Long... values) {
        long max = 0L;
        if (values == null) {
            return max;
        }
        for (Long value : values) {
            if (value != null && value > max) {
                max = value;
            }
        }
        return max;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DevicePresenceState {

        private Integer deviceType;

        private String deviceId;

        private Boolean online;

        private Long lastActiveTime;

        private Long lastBizActiveTime;

        private Long updatedAt;
    }
}
