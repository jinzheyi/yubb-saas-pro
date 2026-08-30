package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.module.system.dal.dataobject.im.ImCallEventOutboxDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.mysql.im.ImCallEventOutboxMapper;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import com.shengyu.module.system.dal.mysql.im.ImCallRecordMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;

/**
 * 通话业务事件唯一出口：先落库，再向已在线设备投递 SYSTEM_NOTIFY。
 * LiveKit 音频、视频和协商数据绝不可经过该组件。
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class CallEventPublisher {
    private static final int MAX_RETRY_ATTEMPTS = 4;
    private static final long MAX_RETRY_DELAY_SECONDS = 8L;

    private final ImCallEventOutboxMapper outboxMapper;
    private final ImCallRecordMapper callRecordMapper;
    private final ImCallParticipantMapper callParticipantMapper;
    private final CallPushService callPushService;

    public void publish(Collection<Long> recipientIds, Long senderId, Long tenantId, JSONObject payload) {
        String callId = payload.getStr("callId", payload.getStr("callSessionId", "unknown"));
        Integer version = payload.getInt("eventVersion", 0);
        if (version == null || version <= 0) {
            version = callRecordMapper.allocateNextStateVersion(callId);
            payload.set("eventVersion", version);
        }
        payload.set("version", version);
        if (!payload.containsKey("occurredAt")) {
            payload.set("occurredAt", System.currentTimeMillis());
        }
        publish(recipientIds, senderId, tenantId, callId, version, payload);
    }

    public void publish(Collection<Long> recipientIds, Long senderId, Long tenantId,
                        String callId, int eventVersion, JSONObject payload) {
        if (recipientIds == null || recipientIds.isEmpty() || tenantId == null) return;
        for (Long recipientId : new LinkedHashSet<>(recipientIds)) {
            if (recipientId == null) continue;
            ImCallEventOutboxDO outbox = new ImCallEventOutboxDO();
            outbox.setTenantId(tenantId);
            outbox.setCallId(callId);
            outbox.setEventType(payload.getStr("type"));
            outbox.setEventVersion(eventVersion);
            outbox.setRecipientId(recipientId);
            outbox.setPayload(payload.toString());
            outbox.setStatus("PENDING");
            outbox.setRetryCount(0);
            outbox.setCreatedAt(LocalDateTime.now());
            try {
                outboxMapper.insert(outbox);
            } catch (DuplicateKeyException duplicate) {
                continue;
            }
            dispatchAfterCommit(outbox, senderId, payload);
        }
    }

    /**
     * 事务内只写 outbox；在线投递必须等提交成功后执行，避免回滚事务产生幽灵来电。
     * 无事务的重试/管理操作保持同步投递，失败仍保留 PENDING 供下一轮扫描。
     */
    private void dispatchAfterCommit(ImCallEventOutboxDO outbox, Long senderId, JSONObject payload) {
        Runnable dispatch = () -> dispatch(outbox, senderId, payload);
        if (TransactionSynchronizationManager.isSynchronizationActive()
                && TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    dispatch.run();
                }
            });
            return;
        }
        dispatch.run();
    }

    private void dispatch(ImCallEventOutboxDO outbox, Long senderId, JSONObject payload) {
        try {
            CallEventDeliveryResult result = callPushService.publishCallEvent(java.util.Collections.singleton(outbox.getRecipientId()),
                    senderId, outbox.getTenantId(), payload);
            markDeliveryResult(outbox.getId(), result);
        } catch (Exception e) {
            log.error("[CallEventPublisher] 投递失败，将由 outbox 重试，callId={}, recipientId={}",
                    outbox.getCallId(), outbox.getRecipientId(), e);
        }
    }

    /** 由生命周期任务调用；失败采用有上限的指数退避，不改变既有通话业务状态。 */
    public void retryPendingEvents() {
        List<ImCallEventOutboxDO> pending = outboxMapper.selectRetryable(100, LocalDateTime.now());
        for (ImCallEventOutboxDO event : pending) {
            try {
                JSONObject payload = JSONUtil.parseObj(event.getPayload());
                if (isExpiredInvite(event, payload)) {
                    outboxMapper.markSkipped(event.getId());
                    log.info("[CallEventPublisher] 来电已不在响铃态，跳过过期 outbox, id={}, callId={}",
                            event.getId(), event.getCallId());
                    continue;
                }
                Long senderId = payload.getLong("actorId", 0L);
                CallEventDeliveryResult result = callPushService.publishCallEvent(java.util.Collections.singleton(event.getRecipientId()),
                        senderId, event.getTenantId(), payload);
                markDeliveryResult(event.getId(), result);
            } catch (Exception e) {
                int retries = event.getRetryCount() + 1;
                if (retries >= MAX_RETRY_ATTEMPTS) {
                    outboxMapper.markFailed(event.getId(), retries);
                    log.error("[CallEventPublisher] outbox 达到最大重试次数，已标记 FAILED, id={}, callId={}",
                            event.getId(), event.getCallId(), e);
                    continue;
                }
                long delaySeconds = Math.min(MAX_RETRY_DELAY_SECONDS, 1L << Math.min(retries, 3));
                outboxMapper.scheduleRetry(event.getId(), retries, LocalDateTime.now().plusSeconds(delaySeconds));
                log.warn("[CallEventPublisher] outbox 重试失败, id={}, retry={}", event.getId(), retries, e);
            }
        }
    }

    private void markDeliveryResult(Long outboxId, CallEventDeliveryResult result) {
        if (result == CallEventDeliveryResult.SKIPPED) {
            outboxMapper.markSkipped(outboxId);
        } else {
            outboxMapper.markPublished(outboxId, LocalDateTime.now());
        }
    }

    private boolean isExpiredInvite(ImCallEventOutboxDO event, JSONObject payload) {
        String type = payload.getStr("type", "");
        if (!"call.invite".equals(type) && !"call.group_invite".equals(type)) {
            return false;
        }
        ImCallRecordDO call = callRecordMapper.selectByCallId(event.getCallId());
        if (call == null || "ENDED".equals(call.getState())) {
            return true;
        }
        if ("call.group_invite".equals(type)) {
            ImCallParticipantDO participant = callParticipantMapper.selectByCallIdAndUserId(
                    event.getCallId(), event.getRecipientId());
            return participant == null || !"PENDING".equals(participant.getInviteState());
        }
        return !"RINGING".equals(call.getState());
    }
}
