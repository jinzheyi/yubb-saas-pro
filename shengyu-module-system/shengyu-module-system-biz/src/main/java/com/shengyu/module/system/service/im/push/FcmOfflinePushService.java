package com.shengyu.module.system.service.im.push;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.service.OfflineCallPushResult;
import com.shengyu.framework.websocket.core.service.OfflinePushService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.Map;

/** Backwards-compatible facade; all real delivery remains device-scoped. */
@Service
@RequiredArgsConstructor
public class FcmOfflinePushService implements OfflinePushService {
    private final ImPushDispatcher dispatcher;
    @Override public boolean pushOfflineMessage(Long userId, ImMessage message) {
        // The WebSocket protocol header contains participants, not a persisted
        // conversation id.  Message FCM dispatch therefore happens from the
        // after-commit event in ImNotificationEventPublisher, where the real
        // chatId and messageId are available.  Returning false here prevents a
        // malformed or duplicate notification if this legacy SPI is invoked.
        return false;
    }
    @Override public OfflineCallPushResult pushCallInvite(Long userId, Map<String, String> data) {
        Long tenantId = data == null ? null : parse(data.get("tenantId"));
        if (tenantId == null || userId == null || data == null) return OfflineCallPushResult.NOT_CONFIGURED;
        FcmDispatchStatus status = dispatcher.dispatchCallInvite(tenantId, userId, data.get("callId"), data.getOrDefault("eventVersion", "0"), parse(data.get("sentAt")) == null ? System.currentTimeMillis() : parse(data.get("sentAt")));
        return status == FcmDispatchStatus.DELIVERED ? OfflineCallPushResult.DELIVERED : status == FcmDispatchStatus.RETRYABLE_FAILURE ? OfflineCallPushResult.RETRYABLE_FAILURE : OfflineCallPushResult.NOT_CONFIGURED;
    }
    private Long parse(String value) { try { return value == null ? null : Long.valueOf(value); } catch (NumberFormatException e) { return null; } }
    @Override public boolean pushUnreadCount(Long userId, long count) { return false; }
    @Override public boolean pushSystemNotify(Long userId, String title, String content) { return false; }
    @Override public boolean isPushEnabled(Long userId) { return true; }
    @Override public void setPushEnabled(Long userId, boolean enabled) { }
    @Override public void bindPushToken(Long userId, String deviceType, String pushToken) { }
    @Override public void unbindPushToken(Long userId, String deviceType) { }
}
