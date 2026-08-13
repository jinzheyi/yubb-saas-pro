package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.service.OfflinePushService;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;

/**
 * 通话推送服务
 * 
 * 负责处理未接来电推送、离线消息推送等场景
 * 
 * @author 圣钰科技
 */
@Service
@Slf4j
public class CallPushService {

    @Resource
    private ObjectProvider<NettyMessageSender> nettyMessageSenderProvider;

    @Resource
    private NettySessionManager sessionManager;

    @Resource
    private AdminUserMapper adminUserMapper;

    @Resource
    private OfflinePushService offlinePushService;

    /**
     * Sends one call-domain event to every online device of each recipient.
     *
     * <p>Call REST endpoints and the low-level CALL_SIGNAL processor must use the
     * same SYSTEM_NOTIFY envelope.  Keeping this in one place avoids the previous
     * situation where REST only changed the database and the peer never learned
     * about invite/accept/cancel/hangup.</p>
     */
    public void publishCallEvent(Collection<Long> recipientIds, Long senderId, Long tenantId, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null || recipientIds == null || recipientIds.isEmpty()) {
            return;
        }
        TextMessage textMessage = TextMessage.newBuilder().setContent("").build();
        // Java 8 compatible de-duplication; do not send the same event twice
        // when caller and callee resolve to the same account in malformed input.
        for (Long recipientId : new LinkedHashSet<>(recipientIds)) {
            if (recipientId == null) {
                continue;
            }
            try {
                messageSender.sendToUserWithExtra(recipientId, MessageType.SYSTEM_NOTIFY, textMessage,
                        senderId, recipientId, 0L, null, null, null, null, null, null, payload.toString());
            } catch (Exception e) {
                // Signalling delivery is best effort; state sync remains the recovery source of truth.
                log.error("[CallPush] 通话信令推送失败, recipientId={}, type={}", recipientId,
                        payload.getStr("type"), e);
            }
        }
    }

    /**
     * 推送未接来电通知
     * 
     * 当被叫用户离线或通话超时时，向被叫推送未接来电通知
     * 
     * @param callRecord 通话记录
     */
    public void pushMissedCallNotification(ImCallRecordDO callRecord) {
        if (callRecord == null) {
            log.warn("[CallPush] 通话记录为空，跳过推送");
            return;
        }

        Long calleeId = callRecord.getCalleeId();
        Long callerId = callRecord.getCallerId();
        
        if (calleeId == null || callerId == null) {
            log.warn("[CallPush] 主叫或被叫ID为空，跳过推送");
            return;
        }

        // 查询主叫用户信息
        AdminUserDO caller = adminUserMapper.selectById(callerId);
        if (caller == null) {
            log.warn("[CallPush] 主叫用户不存在，跳过推送，callerId={}", callerId);
            return;
        }

        // 检查被叫是否在线
        List<NettySession> calleeSessions = sessionManager.getSessionsByUserId(calleeId);
        boolean isCalleeOnline = !calleeSessions.isEmpty();

        // 构建推送内容
        String callerName = caller.getNickname();
        String callType = callRecord.getCallType() == 2 ? "视频通话" : "语音通话";
        String title = "未接来电";
        String body = String.format("%s 呼叫过你（%s）", callerName, callType);

        log.info("[CallPush] 推送未接来电通知，calleeId={}, callerId={}, callerName={}, isCalleeOnline={}", 
            calleeId, callerId, callerName, isCalleeOnline);

        // 构建 SYSTEM_NOTIFY 消息（action=call.missed）
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.missed")
            .set("callId", callRecord.getCallId())
            .set("callType", callRecord.getCallType())
            .set("callerId", String.valueOf(callerId))
            .set("callerName", callerName)
            .set("calleeId", String.valueOf(calleeId))
            .set("title", title)
            .set("body", body)
            .set("initiateTime", callRecord.getStartTime() != null ? 
                callRecord.getStartTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() : 
                System.currentTimeMillis());

        // 向被叫的所有在线设备推送
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[CallPush] NettyMessageSender 不可用，跳过推送");
            return;
        }

        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();

        // 如果用户在线，通过 WebSocket 推送
        if (isCalleeOnline) {
            for (NettySession session : calleeSessions) {
                try {
                    messageSender.sendToUserWithExtra(
                        calleeId, 
                        MessageType.SYSTEM_NOTIFY, 
                        textMessage,
                        callerId, 
                        calleeId, 
                        0L, 
                        null, 
                        null, 
                        null, 
                        null,
                        null, 
                        null, 
                        payload.toString()
                    );
                    log.info("[CallPush] 向被叫设备推送未接来电通知，calleeId={}, deviceId={}", 
                        calleeId, session.getDeviceId());
                } catch (Exception e) {
                    log.error("[CallPush] 向被叫设备推送失败，deviceId={}", session.getDeviceId(), e);
                }
            }
        } else {
            // 如果用户离线，通过 APNs/FCM 推送
            log.info("[CallPush] 被叫离线，通过 APNs/FCM 推送，calleeId={}, body={}", calleeId, body);
            try {
                boolean pushSuccess = offlinePushService.pushSystemNotify(calleeId, title, body);
                if (pushSuccess) {
                    log.info("[CallPush] APNs/FCM 推送成功，calleeId={}", calleeId);
                } else {
                    log.warn("[CallPush] APNs/FCM 推送失败，calleeId={}", calleeId);
                }
            } catch (Exception e) {
                log.error("[CallPush] APNs/FCM 推送异常，calleeId={}", calleeId, e);
            }
        }
    }

    /**
     * 推送通话结束通知
     * 
     * @param callRecord 通话记录
     */
    public void pushCallEndedNotification(ImCallRecordDO callRecord) {
        if (callRecord == null) {
            return;
        }

        Long callerId = callRecord.getCallerId();
        Long calleeId = callRecord.getCalleeId();

        log.info("[CallPush] 推送通话结束通知，callerId={}, calleeId={}, callId={}", 
            callerId, calleeId, callRecord.getCallId());

        // 构建 SYSTEM_NOTIFY 消息（action=call.ended）
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.ended")
            .set("callId", callRecord.getCallId())
            .set("callType", callRecord.getCallType())
            .set("duration", callRecord.getDuration())
            .set("callerId", String.valueOf(callerId))
            .set("calleeId", String.valueOf(calleeId))
            .set("endTime", System.currentTimeMillis());

        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[CallPush] NettyMessageSender 不可用，跳过推送");
            return;
        }

        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();

        // 向主叫推送
        try {
            messageSender.sendToUserWithExtra(
                callerId, 
                MessageType.SYSTEM_NOTIFY, 
                textMessage,
                calleeId, 
                callerId, 
                0L, 
                null, 
                null, 
                null, 
                null,
                null, 
                null, 
                payload.toString()
            );
        } catch (Exception e) {
            log.error("[CallPush] 向主叫推送通话结束通知失败，callerId={}", callerId, e);
        }

        // 向被叫推送
        try {
            messageSender.sendToUserWithExtra(
                calleeId, 
                MessageType.SYSTEM_NOTIFY, 
                textMessage,
                callerId, 
                calleeId, 
                0L, 
                null, 
                null, 
                null, 
                null,
                null, 
                null, 
                payload.toString()
            );
        } catch (Exception e) {
            log.error("[CallPush] 向被叫推送通话结束通知失败，calleeId={}", calleeId, e);
        }
    }
}
