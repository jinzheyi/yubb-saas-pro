package com.shengyu.module.system.service.im.push;

import java.util.List;

/** Device-scoped push token registry. Tokens must never be written to logs. */
public interface ImPushDeviceRegistry {
    void register(Long tenantId, Long userId, String provider, String deviceId, String platform,
                  String token, String appVersion, String permissionState);

    void unregister(Long tenantId, Long userId, String provider, String deviceId);

    List<ImPushDevice> list(Long tenantId, Long userId, String provider);

    void remove(Long tenantId, Long userId, String provider, String deviceId);

    void markDelivered(Long tenantId, Long userId, String provider, String deviceId);
}
