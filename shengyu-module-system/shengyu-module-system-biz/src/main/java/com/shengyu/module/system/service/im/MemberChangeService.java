package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 成员变更通知服务
 * 
 * 处理通话过程中的成员变更事件：
 * - 用户被移除：通知被移除的用户和通话中的其他用户
 * - 设备被踢：通知被踢设备和通话中的其他用户
 * - 用户被拉黑：通知被拉黑用户和通话中的其他用户
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class MemberChangeService {

    @Resource
    private ObjectProvider<NettyMessageSender> nettyMessageSenderProvider;

    @Resource
    private NettySessionManager sessionManager;

    @Resource
    private ImCallParticipantMapper callParticipantMapper;

    /**
     * 通知用户被移除
     * 
     * @param callId 通话ID
     * @param userId 被移除的用户ID
     * @param operatorId 操作者ID
     * @param reason 移除原因
     */
    public void notifyUserRemoved(String callId, Long userId, Long operatorId, String reason) {
        log.info("[MemberChange] 通知用户被移除, callId={}, userId={}, operatorId={}, reason={}", 
            callId, userId, operatorId, reason);
        
        // 构建移除通知消息
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.member_removed")
            .set("callSessionId", callId)
            .set("userId", String.valueOf(userId))
            .set("operatorId", String.valueOf(operatorId))
            .set("reason", reason)
            .set("timestamp", System.currentTimeMillis());
        
        // 向被移除的用户发送通知
        sendToUser(userId, payload);
        
        // 向通话中的其他用户广播成员移除事件
        broadcastToCallParticipants(callId, userId, payload);
    }

    /**
     * 通知设备被踢
     * 
     * @param callId 通话ID
     * @param userId 用户ID
     * @param deviceId 被踢的设备ID
     * @param reason 踢出原因
     */
    public void notifyDeviceKicked(String callId, Long userId, String deviceId, String reason) {
        log.info("[MemberChange] 通知设备被踢, callId={}, userId={}, deviceId={}, reason={}", 
            callId, userId, deviceId, reason);
        
        // 构建设备被踢通知消息
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.device_kicked")
            .set("callSessionId", callId)
            .set("userId", String.valueOf(userId))
            .set("deviceId", deviceId)
            .set("reason", reason)
            .set("timestamp", System.currentTimeMillis());
        
        // 向被踢的设备发送通知
        sendToDevice(userId, deviceId, payload);
        
        // 向通话中的其他用户广播设备被踢事件
        broadcastToCallParticipants(callId, userId, payload);
    }

    /**
     * 通知用户被拉黑
     * 
     * @param callId 通话ID
     * @param userId 被拉黑的用户ID
     * @param operatorId 操作者ID
     * @param reason 拉黑原因
     */
    public void notifyUserBlocked(String callId, Long userId, Long operatorId, String reason) {
        log.info("[MemberChange] 通知用户被拉黑, callId={}, userId={}, operatorId={}, reason={}", 
            callId, userId, operatorId, reason);
        
        // 构建拉黑通知消息
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.member_blocked")
            .set("callSessionId", callId)
            .set("userId", String.valueOf(userId))
            .set("operatorId", String.valueOf(operatorId))
            .set("reason", reason)
            .set("timestamp", System.currentTimeMillis());
        
        // 向被拉黑的用户发送通知
        sendToUser(userId, payload);
        
        // 向通话中的其他用户广播成员拉黑事件
        broadcastToCallParticipants(callId, userId, payload);
    }

    /**
     * 向指定用户发送消息
     */
    private void sendToUser(Long userId, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[MemberChange] NettyMessageSender 不可用，跳过发送");
            return;
        }
        
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();
        
        List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
        for (NettySession session : sessions) {
            try {
                messageSender.sendToUserWithExtra(
                    userId, 
                    MessageType.SYSTEM_NOTIFY, 
                    textMessage,
                    userId, 
                    userId, 
                    0L, 
                    null, 
                    null, 
                    null, 
                    null,
                    null, 
                    null, 
                    payload.toString()
                );
                log.debug("[MemberChange] 向用户发送消息成功, userId={}, deviceId={}", 
                    userId, session.getDeviceId());
            } catch (Exception e) {
                log.error("[MemberChange] 向用户发送消息失败, userId={}, deviceId={}", 
                    userId, session.getDeviceId(), e);
            }
        }
    }

    /**
     * 向指定设备发送消息
     */
    private void sendToDevice(Long userId, String deviceId, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[MemberChange] NettyMessageSender 不可用，跳过发送");
            return;
        }
        
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();
        
        try {
            messageSender.sendToUserWithExtra(
                userId, 
                MessageType.SYSTEM_NOTIFY, 
                textMessage,
                userId, 
                userId, 
                0L, 
                null, 
                null, 
                null, 
                null,
                null, 
                null, 
                payload.toString()
            );
            log.debug("[MemberChange] 向设备发送消息成功, userId={}, deviceId={}", userId, deviceId);
        } catch (Exception e) {
            log.error("[MemberChange] 向设备发送消息失败, userId={}, deviceId={}", userId, deviceId, e);
        }
    }

    /**
     * 向通话中的其他参与者广播消息
     */
    private void broadcastToCallParticipants(String callId, Long excludeUserId, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[MemberChange] NettyMessageSender 不可用，跳过广播");
            return;
        }
        
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();
        
        // 查询通话参与者列表
        List<ImCallParticipantDO> participants = callParticipantMapper.selectByCallId(callId);
        if (participants == null || participants.isEmpty()) {
            log.warn("[MemberChange] 通话参与者列表为空, callId={}", callId);
            return;
        }
        
        // 获取参与者用户ID集合
        Set<Long> participantUserIds = participants.stream()
            .map(ImCallParticipantDO::getUserId)
            .collect(Collectors.toSet());
        
        int sentCount = 0;
        // 只向在线的通话参与者广播
        for (Long participantUserId : participantUserIds) {
            // 排除指定的用户
            if (participantUserId.equals(excludeUserId)) {
                continue;
            }
            
            List<NettySession> sessions = sessionManager.getSessionsByUserId(participantUserId);
            for (NettySession session : sessions) {
                try {
                    messageSender.sendToUserWithExtra(
                        participantUserId, 
                        MessageType.SYSTEM_NOTIFY, 
                        textMessage,
                        participantUserId, 
                        participantUserId, 
                        0L, 
                        null, 
                        null, 
                        null, 
                        null,
                        null, 
                        null, 
                        payload.toString()
                    );
                    sentCount++;
                    log.debug("[MemberChange] 向通话参与者广播消息成功, userId={}", participantUserId);
                } catch (Exception e) {
                    log.error("[MemberChange] 向通话参与者广播消息失败, userId={}", participantUserId, e);
                }
            }
        }
        
        log.info("[MemberChange] 广播消息完成, callId={}, type={}, 参与者数={}, 实际发送数={}", 
            callId, payload.getStr("type"), participantUserIds.size(), sentCount);
    }
}
