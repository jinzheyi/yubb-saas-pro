package com.shengyu.module.system.job.im;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.quartz.core.handler.JobHandler;
import com.shengyu.framework.tenant.core.aop.TenantIgnore;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import com.shengyu.module.system.dal.mysql.im.ImCallRecordMapper;
import com.shengyu.module.system.enums.im.ImCallStateEnum;
import com.shengyu.module.system.service.im.CallEventPublisher;
import com.shengyu.module.system.service.im.ImCallService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.scheduling.annotation.Scheduled;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collection;
import java.util.stream.Collectors;

/**
 * 服务端通话生命周期兜底任务。
 *
 * <p>这是全局 Job：与访问日志清理任务相同，入口忽略租户过滤并一次处理所有租户的通话。
 * 任务不依赖调度线程的租户上下文；需要传递租户信息时，使用通话记录自身的 tenantId。</p>
 */
@Component
@Slf4j
public class CallLifecycleJob implements JobHandler {

    @Resource
    private ImCallRecordMapper callRecordMapper;
    @Resource
    private ImCallParticipantMapper callParticipantMapper;
    @Resource
    private ImCallService callService;
    @Resource
    private CallEventPublisher callEventPublisher;
    @Value("${im.call.ring-timeout-seconds:30}")
    private long ringTimeoutSeconds;
    @Value("${im.call.max-duration-minutes:240}")
    private long maxDurationMinutes;

    @Override
    @TenantIgnore
    public String execute(String param) {
        callEventPublisher.retryPendingEvents();
        expirePendingCalls();
        expireConnectedCalls();
        return "通话生命周期巡检完成";
    }

    /**
     * 默认自驱动兜底，避免客户未在管理后台手工登记 Quartz 任务时产生永久忙线。
     * 数据库 CAS 使其与可选的人工 Quartz 触发并发执行时仍保持幂等。
     */
    @Scheduled(fixedDelayString = "${im.call.lifecycle-check-delay-ms:10000}")
    @TenantIgnore
    public void scheduledExecute() {
        execute("");
    }

    private void expirePendingCalls() {
        LocalDateTime deadline = LocalDateTime.now().minusSeconds(ringTimeoutSeconds);
        for (ImCallRecordDO call : callRecordMapper.selectByStateBefore(ImCallStateEnum.RINGING.getState(), deadline)) {
            finish(call, "TIMEOUT", "call.timeout", false);
        }
        // CONNECTING 同样属于尚未建立通话的中间态；协商异常时必须回收，避免用户永久忙线。
        for (ImCallRecordDO call : callRecordMapper.selectByStateBefore(ImCallStateEnum.CONNECTING.getState(), deadline)) {
            finish(call, "TIMEOUT", "call.timeout", false);
        }
    }

    private void expireConnectedCalls() {
        LocalDateTime deadline = LocalDateTime.now().minusMinutes(maxDurationMinutes);
        for (ImCallRecordDO call : callRecordMapper.selectByStateBefore(ImCallStateEnum.CONNECTED.getState(), deadline)) {
            finish(call, "MAX_DURATION", "call.ended", true);
        }
    }

    private void finish(ImCallRecordDO candidate, String reason, String eventType, boolean connected) {
        try {
            ImCallRecordDO before = callRecordMapper.selectByCallId(candidate.getCallId());
            if (before == null || ImCallStateEnum.ENDED.getState().equals(before.getState())) {
                return;
            }
            if (connected) {
                if (!ImCallStateEnum.CONNECTED.getState().equals(before.getState())) {
                    return;
                }
                callService.hangupCall(before.getCallId(), before.getCallerId(), reason);
            } else {
                if (!ImCallStateEnum.RINGING.getState().equals(before.getState())
                        && !ImCallStateEnum.CONNECTING.getState().equals(before.getState())) {
                    return;
                }
                // 超时不是主叫取消。必须保存为 MISSED，避免客户端把“对方无应答”
                // 错误显示为“已取消”。
                callService.timeoutCall(before.getCallId());
                // timeoutCall 已在同一业务事务中投递 call.timeout，不能重复发送。
                return;
            }
            ImCallRecordDO ended = callRecordMapper.selectByCallId(before.getCallId());
            if (ended != null && ImCallStateEnum.ENDED.getState().equals(ended.getState())
                    && reason.equals(ended.getEndReason())) {
                publish(ended, eventType, reason);
            }
        } catch (Exception e) {
            log.error("[CallLifecycleJob] 结束超时通话失败，callId={}, reason={}", candidate.getCallId(), reason, e);
        }
    }

    private void publish(ImCallRecordDO call, String type, String reason) {
        Collection<Long> recipients = call.getGroupId() == null
                ? Arrays.asList(call.getCallerId(), call.getCalleeId())
                : callParticipantMapper.selectByCallId(call.getCallId()).stream()
                .map(ImCallParticipantDO::getUserId).collect(Collectors.toList());
        JSONObject payload = JSONUtil.createObj()
                .set("type", type)
                .set("callSessionId", call.getCallId())
                .set("callId", call.getCallId())
                .set("actorId", String.valueOf(call.getCallerId()))
                .set("duration", call.getDuration())
                .set("reason", reason)
                .set("eventTime", System.currentTimeMillis());
        callEventPublisher.publish(recipients, call.getCallerId(), call.getTenantId(), payload);
    }
}
