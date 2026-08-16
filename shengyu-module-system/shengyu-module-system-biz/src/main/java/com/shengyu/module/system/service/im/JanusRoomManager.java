package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.common.util.http.HttpUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * Janus 房间管理器
 * 
 * 负责管理 Janus 多租户房间的创建、销毁和隔离
 * 
 * @author 圣钰科技
 */
@Service
@Slf4j
public class JanusRoomManager {

    @Value("${janus.tenant-isolation:true}")
    private boolean tenantIsolation;

    @Value("${janus.api-url:}")
    private String janusApiUrl;

    @Value("${janus.api-secret:}")
    private String janusApiSecret;

    /**
     * 房间信息缓存
     * key: roomId, value: RoomInfo
     */
    private final ConcurrentMap<String, RoomInfo> roomCache = new ConcurrentHashMap<>();

    /**
     * 房间信息
     */
    public static class RoomInfo {
        private final String roomId;
        private final Long tenantId;
        private final Long createdAt;
        private final String description;

        public RoomInfo(String roomId, Long tenantId, String description) {
            this.roomId = roomId;
            this.tenantId = tenantId;
            this.createdAt = System.currentTimeMillis();
            this.description = description;
        }

        public String getRoomId() {
            return roomId;
        }

        public Long getTenantId() {
            return tenantId;
        }

        public Long getCreatedAt() {
            return createdAt;
        }

        public String getDescription() {
            return description;
        }
    }

    /**
     * 生成房间 ID（多租户隔离）
     * 
     * @param tenantId 租户 ID
     * @return 房间 ID
     */
    public String generateRoomId(Long tenantId) {
        if (tenantIsolation) {
            // 格式：tenant_{tenantId}_room_{timestamp}_{random}
            String roomId = String.format("tenant_%d_room_%d_%s",
                tenantId,
                System.currentTimeMillis(),
                UUID.randomUUID().toString().substring(0, 8));
            log.info("[generateRoomId] 生成多租户隔离房间 ID: roomId={}, tenantId={}", roomId, tenantId);
            return roomId;
        } else {
            // 非隔离模式：room_{timestamp}_{random}
            String roomId = String.format("room_%d_%s",
                System.currentTimeMillis(),
                UUID.randomUUID().toString().substring(0, 8));
            log.info("[generateRoomId] 生成非隔离房间 ID: roomId={}", roomId);
            return roomId;
        }
    }

    /**
     * 创建房间
     * 
     * @param tenantId 租户 ID
     * @param description 房间描述
     * @return 房间信息
     */
    public RoomInfo createRoom(Long tenantId, String description) {
        if (tenantId == null) {
            throw new IllegalArgumentException("租户上下文不能为空");
        }
        if (StrUtil.isBlank(janusApiUrl)) {
            throw new IllegalStateException("RTC 服务未配置（需要 janus.api-url）");
        }
        String roomId = createVideoRoom(description);
        RoomInfo roomInfo = new RoomInfo(roomId, tenantId, description);
        roomCache.put(roomId, roomInfo);
        
        log.info("[createRoom] 创建房间成功: roomId={}, tenantId={}, description={}", 
            roomId, tenantId, description);
        
        return roomInfo;
    }

    /**
     * 通过 Janus REST API 创建 VideoRoom。不能只在 JVM 内生成房间名：客户端加入的是
     * Janus 的数值房间，内存字符串会被 Flutter 解析成 0，最终导致 room not found。
     */
    private String createVideoRoom(String description) {
        Long sessionId = null;
        try {
            JSONObject session = request(apiBaseUrl(), JSONUtil.createObj()
                    .set("janus", "create"));
            sessionId = session.getJSONObject("data").getLong("id");
            if (sessionId == null) {
                throw new IllegalStateException("Janus 未返回 sessionId");
            }

            JSONObject handle = request(apiBaseUrl() + "/" + sessionId, JSONUtil.createObj()
                    .set("janus", "attach")
                    .set("plugin", "janus.plugin.videoroom"));
            Long handleId = handle.getJSONObject("data").getLong("id");
            if (handleId == null) {
                throw new IllegalStateException("Janus 未返回 VideoRoom handleId");
            }

            JSONObject room = request(apiBaseUrl() + "/" + sessionId + "/" + handleId,
                    JSONUtil.createObj()
                            .set("janus", "message")
                            .set("body", JSONUtil.createObj()
                                    .set("request", "create")
                                    .set("description", description)
                                    .set("publishers", 2)
                                    .set("permanent", false)));
            JSONObject roomData = room.getJSONObject("plugindata") == null ? null
                    : room.getJSONObject("plugindata").getJSONObject("data");
            Long roomId = roomData == null ? null : roomData.getLong("room");
            if (roomId == null) {
                throw new IllegalStateException("Janus 未返回 VideoRoom 房间号: " + room);
            }
            return String.valueOf(roomId);
        } catch (Exception e) {
            throw new IllegalStateException("创建 Janus VideoRoom 失败: " + e.getMessage(), e);
        } finally {
            if (sessionId != null) {
                try {
                    request(apiBaseUrl() + "/" + sessionId, JSONUtil.createObj().set("janus", "destroy"));
                } catch (Exception e) {
                    log.warn("[createVideoRoom] 销毁 Janus 控制会话失败, sessionId={}", sessionId, e);
                }
            }
        }
    }

    private JSONObject request(String url, JSONObject payload) {
        payload.set("transaction", UUID.randomUUID().toString());
        if (StrUtil.isNotBlank(janusApiSecret)) {
            payload.set("apisecret", janusApiSecret);
        }
        JSONObject response = JSONUtil.parseObj(HttpUtils.post(url,
                java.util.Collections.singletonMap("Content-Type", "application/json"), payload.toString()));
        if (!"success".equals(response.getStr("janus"))) {
            throw new IllegalStateException("Janus API 返回异常: " + response);
        }
        return response;
    }

    private String apiBaseUrl() {
        return StrUtil.removeSuffix(janusApiUrl.trim(), "/");
    }

    /**
     * 获取房间信息
     * 
     * @param roomId 房间 ID
     * @return 房间信息，不存在则返回 null
     */
    public RoomInfo getRoom(String roomId) {
        return roomCache.get(roomId);
    }

    /**
     * 验证房间归属（多租户隔离检查）
     * 
     * @param roomId 房间 ID
     * @param tenantId 租户 ID
     * @return 是否属于该租户
     */
    public boolean validateRoomOwnership(String roomId, Long tenantId) {
        if (!tenantIsolation) {
            // 非隔离模式，不检查归属
            return true;
        }

        RoomInfo roomInfo = roomCache.get(roomId);
        if (roomInfo == null) {
            log.warn("[validateRoomOwnership] 房间不存在: roomId={}", roomId);
            return false;
        }

        boolean isOwner = roomInfo.getTenantId().equals(tenantId);
        if (!isOwner) {
            log.warn("[validateRoomOwnership] 房间归属验证失败: roomId={}, expectedTenantId={}, actualTenantId={}", 
                roomId, tenantId, roomInfo.getTenantId());
        }

        return isOwner;
    }

    /**
     * 销毁房间
     * 
     * @param roomId 房间 ID
     */
    public void destroyRoom(String roomId) {
        RoomInfo removed = roomCache.remove(roomId);
        if (removed != null) {
            log.info("[destroyRoom] 销毁房间成功: roomId={}, tenantId={}", 
                roomId, removed.getTenantId());
        } else {
            log.warn("[destroyRoom] 房间不存在: roomId={}", roomId);
        }
    }

    /**
     * 获取租户的所有房间
     * 
     * @param tenantId 租户 ID
     * @return 房间信息列表
     */
    public java.util.List<RoomInfo> getRoomsByTenant(Long tenantId) {
        java.util.List<RoomInfo> rooms = new java.util.ArrayList<>();
        for (RoomInfo roomInfo : roomCache.values()) {
            if (roomInfo.getTenantId().equals(tenantId)) {
                rooms.add(roomInfo);
            }
        }
        return rooms;
    }

    /**
     * 清理过期房间（超过指定时间未使用的房间）
     * 
     * @param maxAgeMillis 最大存活时间（毫秒）
     * @return 清理的房间数量
     */
    public int cleanupExpiredRooms(long maxAgeMillis) {
        long now = System.currentTimeMillis();
        int cleanedCount = 0;

        for (java.util.Iterator<java.util.Map.Entry<String, RoomInfo>> it = roomCache.entrySet().iterator(); it.hasNext(); ) {
            java.util.Map.Entry<String, RoomInfo> entry = it.next();
            RoomInfo roomInfo = entry.getValue();
            
            if (now - roomInfo.getCreatedAt() > maxAgeMillis) {
                it.remove();
                cleanedCount++;
                log.info("[cleanupExpiredRooms] 清理过期房间: roomId={}, tenantId={}, age={}ms", 
                    roomInfo.getRoomId(), roomInfo.getTenantId(), now - roomInfo.getCreatedAt());
            }
        }

        if (cleanedCount > 0) {
            log.info("[cleanupExpiredRooms] 清理过期房间完成: cleanedCount={}", cleanedCount);
        }

        return cleanedCount;
    }

    /**
     * 获取当前房间总数
     * 
     * @return 房间总数
     */
    public int getRoomCount() {
        return roomCache.size();
    }

    /**
     * 获取租户的房间数量
     * 
     * @param tenantId 租户 ID
     * @return 房间数量
     */
    public int getRoomCountByTenant(Long tenantId) {
        int count = 0;
        for (RoomInfo roomInfo : roomCache.values()) {
            if (roomInfo.getTenantId().equals(tenantId)) {
                count++;
            }
        }
        return count;
    }
}
