package com.shengyu.module.system.service.im.push;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ImPushDispatcherImpl implements ImPushDispatcher {
    private final ImPushDeviceRegistry registry;
    private final FcmV1Client client;
    private final ImPushPayloadFactory payloadFactory = new ImPushPayloadFactory();
    @Override public FcmDispatchStatus dispatchMessage(Long tenantId, Long userId, String chatId, String messageId, long sentAt) {
        if (userId == null || chatId == null || chatId.isEmpty() || messageId == null || messageId.isEmpty()) return FcmDispatchStatus.PERMANENT_FAILURE;
        Map<String, String> data = payloadFactory.messageData(tenantId, userId, chatId, messageId, sentAt);
        return dispatch(tenantId, userId, data, false);
    }
    @Override public FcmDispatchStatus dispatchCallInvite(Long tenantId, Long userId, String callId, String eventVersion, long sentAt) {
        if (userId == null || callId == null || callId.isEmpty() || eventVersion == null || eventVersion.isEmpty()) return FcmDispatchStatus.PERMANENT_FAILURE;
        Map<String, String> data = payloadFactory.callData(tenantId, callId, eventVersion, sentAt);
        return dispatch(tenantId, userId, data, true);
    }
    private FcmDispatchStatus dispatch(Long tenantId, Long userId, Map<String, String> data, boolean call) {
        List<ImPushDevice> devices = registry.list(tenantId, userId, "fcm");
        if (devices.isEmpty()) return FcmDispatchStatus.NO_DEVICE;
        boolean delivered = false;
        boolean retryableFailure = false;
        for (ImPushDevice device : devices) {
            Map<String, Object> message = new LinkedHashMap<>(); message.put("token", device.getToken()); message.put("data", data);
            if (call) {
                message.put("notification", mapOf("title", "圣钰科技 IM", "body", "来电提醒"));
            } else {
                message.put("notification", mapOf("title", "圣钰科技 IM", "body", "你收到一条新消息"));
            }
            if ("android".equals(device.getPlatform())) {
                Map<String, Object> android = new LinkedHashMap<>();
                android.put("priority", call ? "high" : "normal");
                android.put("notification", mapOf("channel_id", "im_messages"));
                message.put("android", android);
            }
            if ("ios".equals(device.getPlatform())) {
                message.put("apns", mapOf("headers", mapOf("apns-priority", call ? "10" : "5")));
            }
            FcmDispatchStatus result = client.send(device.getToken(), message);
            if (result == FcmDispatchStatus.PERMANENT_FAILURE) {
                registry.remove(tenantId, userId, "fcm", device.getDeviceId());
            } else if (result == FcmDispatchStatus.DELIVERED) {
                delivered = true;
                registry.markDelivered(tenantId, userId, "fcm", device.getDeviceId());
            } else if (result == FcmDispatchStatus.RETRYABLE_FAILURE) {
                retryableFailure = true;
            }
        }
        if (delivered) return FcmDispatchStatus.DELIVERED;
        if (retryableFailure) return FcmDispatchStatus.RETRYABLE_FAILURE;
        return FcmDispatchStatus.PERMANENT_FAILURE;
    }
    private Map<String, Object> mapOf(Object... entries) {
        if (entries.length % 2 != 0) {
            throw new IllegalArgumentException("Map entries must be key-value pairs");
        }
        Map<String, Object> map = new LinkedHashMap<>();
        for (int index = 0; index < entries.length; index += 2) {
            map.put(String.valueOf(entries[index]), entries[index + 1]);
        }
        return map;
    }
}
