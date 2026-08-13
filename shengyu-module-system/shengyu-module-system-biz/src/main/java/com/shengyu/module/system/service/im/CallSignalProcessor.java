package com.shengyu.module.system.service.im;

import cn.hutool.core.util.IdUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.google.protobuf.InvalidProtocolBufferException;
import com.shengyu.framework.websocket.core.processor.MessageProcessor;
import com.shengyu.framework.websocket.core.protocol.CallSignalMessage;
import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.module.system.dal.dataobject.im.ImCallEventDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.enums.im.ImCallStateEnum;
import com.shengyu.module.system.enums.im.ImCallStatusEnum;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 通话信令处理器
 * 
 * 处理 CALL_SIGNAL (206) 的媒体控制信令（仅 signalType=6）。
 * 通话生命周期必须通过 REST + 数据库 CAS 处理，避免产生第二条状态迁移路径。
 * 
 * 处理流程：
 * 1. 解析 CallSignalMessage
 * 2. 验证当前通话参与者
 * 3. 转发媒体控制状态
 *
 * @author 圣钰科技
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class CallSignalProcessor implements MessageProcessor {

    private final ImCallService callService;
    private final NettyMessageSender messageSender;
    private final NettySessionManager sessionManager;
    private final com.shengyu.framework.websocket.core.processor.MessageProcessorFactory processorFactory;
    private final CallPushService callPushService;
    private final CallSecurityService callSecurityService;

    @javax.annotation.PostConstruct
    public void init() {
        // 注册到处理器工厂
        processorFactory.registerProcessor(MessageType.CALL_SIGNAL, this);
        log.info("[CallSignal] 注册通话信令处理器, messageType=CALL_SIGNAL(206)");
    }

    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析通话信令消息
            CallSignalMessage signal = CallSignalMessage.parseFrom(message.getBody());
            
            // 获取当前用户会话
            NettySession session = sessionManager.getSession(ctx.channel());
            if (session == null) {
                log.warn("[CallSignal] 用户会话不存在");
                return;
            }

            Long userId = session.getUserId();
            Long tenantId = session.getTenantId();
            String deviceId = session.getDeviceId();
            String callId = signal.getCallId();
            Integer signalType = signal.getSignalType();
            
            log.info("[CallSignal] 收到通话信令, userId={}, callId={}, signalType={}, deviceId={}", 
                userId, callId, signalType, deviceId);

            // 安全审计：记录信令接收
            callSecurityService.logSecurityAudit(userId, callId, "RECEIVE_SIGNAL", "SIGNAL_TYPE_" + signalType);

            // 安全检查 1: 信令数据合法性校验
            if (!callSecurityService.validateSignalData(callId, signalType)) {
                log.warn("[CallSignal] 信令数据非法, userId={}, callId={}, signalType={}", userId, callId, signalType);
                callSecurityService.logSecurityAudit(userId, callId, "VALIDATE_SIGNAL_DATA", "FAILED");
                return;
            }

            // CALL_SIGNAL is deliberately not a call-lifecycle API. Lifecycle
            // changes use REST + database CAS so all clients follow one state
            // machine.  This channel only transports in-call media controls.
            if (signalType != 6) {
                log.warn("[CallSignal] 拒绝生命周期信令, userId={}, callId={}, signalType={}；请使用 REST 通话接口",
                        userId, callId, signalType);
                callSecurityService.logSecurityAudit(userId, callId, "LIFECYCLE_SIGNAL_REJECTED", "FAILED");
                return;
            }

            // 媒体控制必须来自当前通话参与者。
            if (!callId.isEmpty()) {
                if (!callSecurityService.isCallParticipant(callId, userId)) {
                    log.warn("[CallSignal] 用户不是通话参与者, userId={}, callId={}", userId, callId);
                    callSecurityService.logSecurityAudit(userId, callId, "PARTICIPANT_CHECK", "FAILED");
                    return;
                }
            }

            // 记录安全检查通过
            callSecurityService.logSecurityAudit(userId, callId, "SECURITY_CHECK", "PASSED");

            handleMediaControl(userId, tenantId, signal);
        } catch (InvalidProtocolBufferException e) {
            log.error("[CallSignal] 解析通话信令消息失败", e);
        } catch (Exception e) {
            log.error("[CallSignal] 处理通话信令失败", e);
        }
    }

    /**
     * 处理发起呼叫
     */
    private void handleCallInitiate(Long callerId, Long tenantId, String deviceId, CallSignalMessage signal) {
        Long calleeId = signal.getCalleeId();
        Integer callType = signal.getCallType();
        
        log.info("[CallSignal] 发起呼叫, callerId={}, calleeId={}, callType={}", callerId, calleeId, callType);
        
        // 1. 检查被叫是否忙线
        if (callService.isUserBusy(calleeId)) {
            log.info("[CallSignal] 被叫忙线, calleeId={}", calleeId);
            // 向主叫发送忙线通知
            sendCallBusy(callerId, calleeId, signal.getCallId(), tenantId);
            return;
        }
        
        // 2. 创建通话记录
        String callId = callService.initiateCall(callerId, calleeId, callType, deviceId);
        
        // 3. 记录通话事件
        recordCallEvent(callId, 1, callerId, deviceId, null);
        
        // 4. 更新状态为 RINGING
        callService.updateCallState(callId, ImCallStateEnum.RINGING.getState(), ImCallStateEnum.INIT.getState());
        
        // 5. 向被叫发送来电通知（call.invite）
        sendCallInvite(calleeId, callerId, callId, callType, tenantId, deviceId);
        
        log.info("[CallSignal] 发起呼叫成功, callId={}", callId);
    }

    /**
     * 处理接听
     */
    private void handleCallAccept(Long userId, Long tenantId, String deviceId, CallSignalMessage signal) {
        String callId = signal.getCallId();
        
        log.info("[CallSignal] 接听通话, userId={}, callId={}, deviceId={}", userId, callId, deviceId);
        
        // 1. 接听通话
        callService.acceptCall(callId, userId, deviceId);
        
        // 2. 记录通话事件
        recordCallEvent(callId, 2, userId, deviceId, null);
        
        // 3. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallSignal] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 4. 向主叫和被叫的所有设备发送接听通知（call.accepted），包含接听设备信息
        sendCallAccepted(callRecord.getCallerId(), userId, callId, deviceId, tenantId);
        
        log.info("[CallSignal] 接听通话成功, callId={}", callId);
    }

    /**
     * 处理拒绝
     */
    private void handleCallReject(Long userId, Long tenantId, String deviceId, CallSignalMessage signal) {
        String callId = signal.getCallId();
        String reason = signal.getRejectReason();
        
        log.info("[CallSignal] 拒绝通话, userId={}, callId={}, reason={}", userId, callId, reason);
        
        // 1. 拒绝通话
        callService.rejectCall(callId, userId, reason);
        
        // 2. 记录通话事件
        recordCallEvent(callId, 3, userId, deviceId, reason);
        
        // 3. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallSignal] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 4. 向主叫发送拒绝通知（call.rejected）
        sendCallRejected(callRecord.getCallerId(), userId, callId, reason, tenantId);
        
        // 5. 向主叫推送未接来电通知
        callPushService.pushMissedCallNotification(callRecord);
        
        log.info("[CallSignal] 拒绝通话成功, callId={}", callId);
    }

    /**
     * 处理挂断
     */
    private void handleCallHangup(Long userId, Long tenantId, String deviceId, CallSignalMessage signal) {
        String callId = signal.getCallId();
        String reason = "HANGUP";
        
        log.info("[CallSignal] 挂断通话, userId={}, callId={}", userId, callId);
        
        // 1. 挂断通话
        callService.hangupCall(callId, userId, reason);
        
        // 2. 记录通话事件
        recordCallEvent(callId, 4, userId, deviceId, reason);
        
        // 3. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallSignal] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 4. 向对方发送挂断通知（call.ended）
        Long targetUserId = callRecord.getCallerId().equals(userId) ? callRecord.getCalleeId() : callRecord.getCallerId();
        sendCallEnded(targetUserId, userId, callId, callRecord.getDuration(), tenantId);
        
        // 5. 发送通话记录消息（CALL_RECORD=209）
        sendCallRecordMessage(callRecord, tenantId);
        
        log.info("[CallSignal] 挂断通话成功, callId={}, duration={}", callId, callRecord.getDuration());
    }

    /**
     * 处理忙线
     */
    private void handleCallBusy(Long userId, Long tenantId, String deviceId, CallSignalMessage signal) {
        String callId = signal.getCallId();
        
        log.info("[CallSignal] 用户忙线, userId={}, callId={}", userId, callId);
        
        // 1. 更新通话状态为忙线
        callService.updateCallStatus(callId, ImCallStatusEnum.BUSY.getStatus());
        
        // 2. 记录通话事件
        recordCallEvent(callId, 5, userId, deviceId, "BUSY");
        
        // 3. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallSignal] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 4. 向主叫发送忙线通知（call.busy）
        sendCallBusy(callRecord.getCallerId(), userId, callId, tenantId);
        
        log.info("[CallSignal] 用户忙线处理完成, callId={}", callId);
    }

    /**
     * 处理媒体控制（静音、摄像头切换等）
     */
    private void handleMediaControl(Long userId, Long tenantId, CallSignalMessage signal) {
        String callId = signal.getCallId();
        String extraData = signal.getExtraData();
        
        log.info("[CallSignal] 媒体控制, userId={}, callId={}, extraData={}", userId, callId, extraData);
        
        // 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[CallSignal] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 向对方转发媒体控制信令
        Long targetUserId = callRecord.getCallerId().equals(userId) ? callRecord.getCalleeId() : callRecord.getCallerId();
        sendMediaControl(targetUserId, userId, callId, extraData, tenantId);
        
        log.info("[CallSignal] 媒体控制转发完成, callId={}", callId);
    }

    // ===== 发送 SYSTEM_NOTIFY 消息（action=call.*）=====

    /**
     * 发送来电通知（call.invite）
     * 多设备来电处理：向被叫的所有在线设备广播来电信令
     */
    private void sendCallInvite(Long calleeId, Long callerId, String callId, Integer callType, Long tenantId, String deviceId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.invite")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("callType", callType)
            .set("callerId", String.valueOf(callerId))
            .set("calleeId", String.valueOf(calleeId))
            .set("initiateTime", System.currentTimeMillis())
            .set("deviceId", deviceId);
        
        // 获取被叫的所有在线设备
        List<NettySession> calleeSessions = sessionManager.getSessionsByUserId(calleeId);
        
        if (calleeSessions.isEmpty()) {
            log.info("[CallSignal] 被叫无在线设备, calleeId={}", calleeId);
            return;
        }
        
        // 向所有在线设备广播来电信令
        for (NettySession session : calleeSessions) {
            try {
                sendSystemNotify(calleeId, callerId, payload, tenantId);
                log.info("[CallSignal] 向设备发送来电通知, calleeId={}, deviceId={}, deviceType={}", 
                    calleeId, session.getDeviceId(), session.getDeviceType());
            } catch (Exception e) {
                log.error("[CallSignal] 向设备发送来电通知失败, deviceId={}", session.getDeviceId(), e);
            }
        }
        
        log.info("[CallSignal] 多设备来电广播完成, calleeId={}, 在线设备数={}", calleeId, calleeSessions.size());
    }

    /**
     * 发送接听通知（call.accepted）
     * 多设备同步：向主叫发送接听通知，同时向被叫的其他设备广播接听状态，让它们关闭来电界面
     */
    private void sendCallAccepted(Long callerId, Long calleeId, String callId, String acceptedDeviceId, Long tenantId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.accepted")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("calleeId", String.valueOf(calleeId))
            .set("acceptedDeviceId", acceptedDeviceId)
            .set("acceptedTime", System.currentTimeMillis());
        
        // 1. 向主叫发送接听通知
        sendSystemNotify(callerId, calleeId, payload, tenantId);
        
        // 2. 向被叫的所有设备广播接听状态（用于多设备同步）
        List<NettySession> calleeSessions = sessionManager.getSessionsByUserId(calleeId);
        for (NettySession session : calleeSessions) {
            try {
                sendSystemNotify(calleeId, callerId, payload, tenantId);
                log.debug("[CallSignal] 向被叫设备同步接听状态, calleeId={}, deviceId={}", 
                    calleeId, session.getDeviceId());
            } catch (Exception e) {
                log.error("[CallSignal] 向被叫设备同步接听状态失败, deviceId={}", session.getDeviceId(), e);
            }
        }
        
        log.info("[CallSignal] 接听通知广播完成, callerId={}, calleeId={}, acceptedDeviceId={}, 被叫在线设备数={}", 
            callerId, calleeId, acceptedDeviceId, calleeSessions.size());
    }

    /**
     * 发送拒绝通知（call.rejected）
     */
    private void sendCallRejected(Long callerId, Long calleeId, String callId, String reason, Long tenantId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.rejected")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("calleeId", String.valueOf(calleeId))
            .set("reason", reason)
            .set("rejectedTime", System.currentTimeMillis());
        
        sendSystemNotify(callerId, calleeId, payload, tenantId);
    }

    /**
     * 发送挂断通知（call.ended）
     */
    private void sendCallEnded(Long targetUserId, Long userId, String callId, Integer duration, Long tenantId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.ended")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("endedBy", String.valueOf(userId))
            .set("duration", duration)
            .set("endedTime", System.currentTimeMillis());
        
        sendSystemNotify(targetUserId, userId, payload, tenantId);
    }

    /**
     * 发送忙线通知（call.busy）
     */
    private void sendCallBusy(Long callerId, Long calleeId, String callId, Long tenantId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.busy")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("calleeId", String.valueOf(calleeId))
            .set("busyTime", System.currentTimeMillis());
        
        sendSystemNotify(callerId, calleeId, payload, tenantId);
    }

    /**
     * 发送媒体控制信令（call.media_control）
     */
    private void sendMediaControl(Long targetUserId, Long userId, String callId, String extraData, Long tenantId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.media_control")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("userId", String.valueOf(userId))
            .set("extraData", extraData);
        
        sendSystemNotify(targetUserId, userId, payload, tenantId);
    }

    /**
     * 发送通话记录消息（CALL_RECORD=209）
     * 
     * 向通话双方发送通话记录消息，用于在聊天界面显示通话记录气泡
     */
    private void sendCallRecordMessage(ImCallRecordDO callRecord, Long tenantId) {
        try {
            // 构建通话记录 payload
            JSONObject payload = JSONUtil.createObj()
                .set("callId", callRecord.getCallId())
                .set("callType", callRecord.getCallType())
                .set("status", callRecord.getStatus())
                .set("duration", callRecord.getDuration())
                .set("callerId", String.valueOf(callRecord.getCallerId()))
                .set("calleeId", String.valueOf(callRecord.getCalleeId()))
                .set("initiateTime", callRecord.getStartTime() != null ? 
                    callRecord.getStartTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() : 
                    System.currentTimeMillis());
            
            // 发送给主叫
            sendSystemNotify(callRecord.getCallerId(), 0L, payload, tenantId);
            
            // 发送给被叫
            sendSystemNotify(callRecord.getCalleeId(), 0L, payload, tenantId);
            
            log.info("[CallSignal] 发送通话记录消息成功, callId={}, callerId={}, calleeId={}", 
                callRecord.getCallId(), callRecord.getCallerId(), callRecord.getCalleeId());
        } catch (Exception e) {
            log.error("[CallSignal] 发送通话记录消息失败, callId={}", callRecord.getCallId(), e);
        }
    }

    /**
     * 发送 SYSTEM_NOTIFY 消息
     */
    private void sendSystemNotify(Long targetUserId, Long senderId, JSONObject payload, Long tenantId) {
        // 构建 SYSTEM_NOTIFY 消息体
        // 注意：这里使用 TextMessage 作为消息体，实际内容在 payload 中
        com.shengyu.framework.websocket.core.protocol.TextMessage textMessage = 
            com.shengyu.framework.websocket.core.protocol.TextMessage.newBuilder()
                .setContent(payload.toString())
                .build();
        
        // 发送 SYSTEM_NOTIFY 消息
        messageSender.sendToUser(targetUserId, MessageType.SYSTEM_NOTIFY, textMessage, senderId, tenantId);
        
        log.debug("[CallSignal] 发送 SYSTEM_NOTIFY 消息, targetUserId={}, type={}", targetUserId, payload.getStr("type"));
    }

    /**
     * 记录通话事件
     */
    private void recordCallEvent(String callId, Integer signalType, Long senderId, String deviceId, String payloadJson) {
        ImCallEventDO event = ImCallEventDO.builder()
            .callId(callId)
            .eventId(IdUtil.simpleUUID())
            .signalType(signalType)
            .senderId(senderId)
            .deviceId(deviceId)
            .payloadJson(payloadJson)
            .createTime(LocalDateTime.now())
            .build();
        
        callService.recordCallEvent(event);
    }
}
