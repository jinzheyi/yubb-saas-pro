package com.shengyu.module.system.service.im.push;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Builds the only server-to-device contract used by IM push.  It deliberately
 * contains routing identifiers only: message body, user profile and RTC
 * credentials must be fetched after the client has authenticated.
 */
public class ImPushPayloadFactory {

    public Map<String, String> messageData(Long tenantId, Long userId, String chatId,
                                           String messageId, long sentAt) {
        Map<String, String> data = base("im_message", messageId, tenantId, sentAt);
        data.put("recipientUserId", String.valueOf(userId));
        data.put("chatId", chatId);
        data.put("messageId", messageId);
        return data;
    }

    public Map<String, String> callData(Long tenantId, String callId, String eventVersion, long sentAt) {
        Map<String, String> data = base("call_invite", callId + ':' + eventVersion, tenantId, sentAt);
        data.put("callId", callId);
        data.put("eventVersion", eventVersion);
        return data;
    }

    private Map<String, String> base(String kind, String eventId, Long tenantId, long sentAt) {
        if (tenantId == null || eventId == null || eventId.isEmpty()) {
            throw new IllegalArgumentException("push routing fields are required");
        }
        Map<String, String> data = new LinkedHashMap<>();
        data.put("v", "1");
        data.put("kind", kind);
        data.put("eventId", eventId);
        data.put("tenantId", String.valueOf(tenantId));
        data.put("sentAt", String.valueOf(sentAt));
        return data;
    }
}
