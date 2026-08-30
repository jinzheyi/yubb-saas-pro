package com.shengyu.module.system.service.im.push;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class RedisImPushDeviceRegistry implements ImPushDeviceRegistry {
    private static final Duration TTL = Duration.ofDays(35);
    private static final Pattern DEVICE_ID = Pattern.compile("[A-Za-z0-9._:-]{1,128}");
    private final RedisTemplate<String, Object> redisTemplate;

    @Override
    public void register(Long tenantId, Long userId, String provider, String deviceId, String platform,
                         String token, String appVersion, String permissionState) {
        requireScope(tenantId, userId, provider, deviceId);
        if (token == null || token.trim().isEmpty() || token.length() > 4096) {
            throw new IllegalArgumentException("invalid push token");
        }
        ImPushDevice metadata = new ImPushDevice();
        metadata.setToken(token);
        metadata.setPlatform(platform);
        metadata.setAppVersion(appVersion);
        // Token registration is allowed even when OS permission is denied so
        // a later token refresh can recover without a server-side migration.
        metadata.setPermissionState(permissionState == null ? "unknown" : permissionState);
        metadata.setUpdatedAt(System.currentTimeMillis());
        redisTemplate.opsForValue().set(deviceKey(tenantId, userId, deviceId, provider), metadata, TTL);
        redisTemplate.opsForSet().add(indexKey(tenantId, userId), deviceId + ":" + provider);
        redisTemplate.expire(indexKey(tenantId, userId), TTL);
    }

    @Override
    public void unregister(Long tenantId, Long userId, String provider, String deviceId) {
        remove(tenantId, userId, provider, deviceId);
    }

    @Override
    public List<ImPushDevice> list(Long tenantId, Long userId, String provider) {
        Set<Object> members = redisTemplate.opsForSet().members(indexKey(tenantId, userId));
        List<ImPushDevice> result = new ArrayList<>();
        if (members == null) return result;
        for (Object member : members) {
            String value = String.valueOf(member);
            if (!value.endsWith(":" + provider)) continue;
            String deviceId = value.substring(0, value.length() - provider.length() - 1);
            Object metadata = redisTemplate.opsForValue().get(deviceKey(tenantId, userId, deviceId, provider));
            if (metadata instanceof ImPushDevice) {
                ImPushDevice device = (ImPushDevice) metadata;
                device.setDeviceId(deviceId);
                result.add(device);
            }
            else redisTemplate.opsForSet().remove(indexKey(tenantId, userId), value);
        }
        return result;
    }

    @Override
    public void remove(Long tenantId, Long userId, String provider, String deviceId) {
        requireScope(tenantId, userId, provider, deviceId);
        redisTemplate.delete(deviceKey(tenantId, userId, deviceId, provider));
        redisTemplate.opsForSet().remove(indexKey(tenantId, userId), deviceId + ":" + provider);
    }

    @Override
    public void markDelivered(Long tenantId, Long userId, String provider, String deviceId) {
        requireScope(tenantId, userId, provider, deviceId);
        String key = deviceKey(tenantId, userId, deviceId, provider);
        Object metadata = redisTemplate.opsForValue().get(key);
        if (!(metadata instanceof ImPushDevice)) return;
        ImPushDevice device = (ImPushDevice) metadata;
        device.setLastDeliveryAt(System.currentTimeMillis());
        redisTemplate.opsForValue().set(key, device, TTL);
    }

    private void requireScope(Long tenantId, Long userId, String provider, String deviceId) {
        if (tenantId == null || userId == null || !"fcm".equals(provider) || deviceId == null
                || !DEVICE_ID.matcher(deviceId).matches()) throw new IllegalArgumentException("invalid push device scope");
    }
    private String indexKey(Long tenantId, Long userId) { return "im:push:devices:" + tenantId + ':' + userId; }
    private String deviceKey(Long tenantId, Long userId, String deviceId, String provider) {
        return "im:push:device:" + tenantId + ':' + userId + ':' + deviceId + ':' + provider;
    }
}
