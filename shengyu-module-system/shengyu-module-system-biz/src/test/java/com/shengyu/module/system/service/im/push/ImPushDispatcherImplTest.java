package com.shengyu.module.system.service.im.push;

import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ImPushDispatcherImplTest {

    @Test
    void removesInvalidDeviceAndReportsPermanentFailure() {
        RecordingRegistry registry = new RecordingRegistry();
        FcmV1Client client = new FcmV1Client(null, null) {
            @Override
            public FcmDispatchStatus send(String token, java.util.Map<String, Object> message) {
                return FcmDispatchStatus.PERMANENT_FAILURE;
            }
        };

        ImPushDispatcher dispatcher = new ImPushDispatcherImpl(registry, client);

        assertEquals(FcmDispatchStatus.PERMANENT_FAILURE,
                dispatcher.dispatchMessage(1L, 2L, "chat-1", "message-1", 3L));
        assertEquals(1, registry.removedCount);
    }

    private static final class RecordingRegistry implements ImPushDeviceRegistry {
        private int removedCount;

        @Override public void register(Long tenantId, Long userId, String provider, String deviceId, String platform,
                                       String token, String appVersion, String permissionState) { }
        @Override public void unregister(Long tenantId, Long userId, String provider, String deviceId) { }
        @Override public List<ImPushDevice> list(Long tenantId, Long userId, String provider) {
            ImPushDevice device = new ImPushDevice();
            device.setDeviceId("device-1");
            device.setToken("not-a-real-token");
            device.setPlatform("android");
            return Collections.singletonList(device);
        }
        @Override public void remove(Long tenantId, Long userId, String provider, String deviceId) { removedCount++; }
        @Override public void markDelivered(Long tenantId, Long userId, String provider, String deviceId) { }
    }
}
