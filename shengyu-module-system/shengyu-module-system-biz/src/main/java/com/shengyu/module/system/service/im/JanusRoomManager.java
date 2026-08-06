package com.shengyu.module.system.service.im;

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
        String roomId = generateRoomId(tenantId);
        RoomInfo roomInfo = new RoomInfo(roomId, tenantId, description);
        roomCache.put(roomId, roomInfo);
        
        log.info("[createRoom] 创建房间成功: roomId={}, tenantId={}, description={}", 
            roomId, tenantId, description);
        
        return roomInfo;
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
