package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONObject;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.service.OfflineCallPushResult;
import com.shengyu.framework.websocket.core.service.OfflinePushService;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * SYSTEM_NOTIFY 通话事件的 WebSocket 传输适配器。
 *
 * <p>业务代码只能通过 {@link CallEventPublisher} 写入 outbox；本类不包含状态判断、
 * RTC 信息或旁路的来电/结束推送方法。</p>
 */
@Service
@Slf4j
public class CallPushService {

    @Resource
    private ObjectProvider<NettyMessageSender> nettyMessageSenderProvider;

    @Resource
    private NettySessionManager sessionManager;

    @Resource
    private OfflinePushService offlinePushService;

    /** 仅由 {@link CallEventPublisher} 在事务提交后或 outbox 重试时调用。 */
    public CallEventDeliveryResult publishCallEvent(Collection<Long> recipientIds, Long senderId,
                                                     Long tenantId, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            throw new IllegalStateException("NettyMessageSender 不可用");
        }
        if (recipientIds == null || recipientIds.isEmpty()) {
            return CallEventDeliveryResult.DELIVERED;
        }
        CallEventDeliveryResult deliveryResult = CallEventDeliveryResult.DELIVERED;
        TextMessage textMessage = TextMessage.newBuilder().setContent("").build();
        for (Long recipientId : new LinkedHashSet<>(recipientIds)) {
            if (recipientId == null) {
                continue;
            }
            int onlineSessionCount = sessionManager.getSessionsByUserId(recipientId).size();
            log.info("[CallPush] 下发通话事件, recipientId={}, tenantId={}, type={}, onlineSessions={}",
                    recipientId, tenantId, payload.getStr("type"), onlineSessionCount);
            messageSender.sendToUserWithExtra(recipientId, MessageType.SYSTEM_NOTIFY, textMessage,
                    senderId, recipientId, 0L, tenantId, null, null, null, null, null, payload.toString());
            if (onlineSessionCount == 0 && isInvite(payload)) {
                OfflineCallPushResult pushResult = offlinePushService.pushCallInvite(recipientId, pushData(payload, tenantId));
                if (pushResult == OfflineCallPushResult.RETRYABLE_FAILURE) {
                    throw new RetryableCallDeliveryException("离线来电推送发生可重试故障");
                }
                if (pushResult != OfflineCallPushResult.DELIVERED) {
                    deliveryResult = CallEventDeliveryResult.SKIPPED;
                    log.info("[CallPush] 离线来电未投递且不重试, recipientId={}, callId={}, result={}",
                            recipientId, payload.getStr("callId"), pushResult);
                }
            }
        }
        return deliveryResult;
    }

    private boolean isInvite(JSONObject payload) {
        String type = payload.getStr("type", "");
        return "call.invite".equals(type) || "call.group_invite".equals(type);
    }

    private Map<String, String> pushData(JSONObject payload, Long tenantId) {
        Map<String, String> data = new LinkedHashMap<>();
        data.put("v", "1");
        data.put("kind", "call_invite");
        copy(payload, data, "callId");
        copy(payload, data, "eventVersion");
        if (tenantId != null) data.put("tenantId", String.valueOf(tenantId));
        Object occurredAt = payload.get("occurredAt");
        if (occurredAt != null) data.put("sentAt", String.valueOf(occurredAt));
        String callId = data.get("callId");
        String version = data.getOrDefault("eventVersion", "0");
        if (callId != null) data.put("eventId", callId + ":" + version);
        return data;
    }

    private void copy(JSONObject source, Map<String, String> target, String key) {
        Object value = source.get(key);
        if (value != null) target.put(key, String.valueOf(value));
    }
}
