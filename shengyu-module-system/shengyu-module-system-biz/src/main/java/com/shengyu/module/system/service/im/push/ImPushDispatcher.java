package com.shengyu.module.system.service.im.push;

import java.util.LinkedHashMap;
import java.util.Map;

/** Sends minimal, non-content-bearing IM events to every registered device. */
public interface ImPushDispatcher {
    FcmDispatchStatus dispatchMessage(Long tenantId, Long userId, String chatId, String messageId, long sentAt);
    FcmDispatchStatus dispatchCallInvite(Long tenantId, Long userId, String callId, String eventVersion, long sentAt);
}
