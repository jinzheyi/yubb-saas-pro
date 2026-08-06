package com.shengyu.module.system.service.im;

import cn.hutool.core.util.IdUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import com.shengyu.module.system.enums.im.ImCallStateEnum;
import com.shengyu.module.system.enums.im.ImCallStatusEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 群组通话服务
 * 
 * 处理多人语音/视频会议的业务逻辑：
 * - 发起群组通话邀请
 * - 处理参与者加入/离开
 * - 管理 Janus 多人房间
 * - 广播群组通话事件给所有参与者
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class GroupCallService {

    @Resource
    private ImCallService callService;

    @Resource
    private ObjectProvider<NettyMessageSender> nettyMessageSenderProvider;

    @Resource
    private NettySessionManager sessionManager;

    @Resource
    private ImCallParticipantMapper callParticipantMapper;

    /**
     * 发起群组通话
     * 
     * @param callerId 发起者ID
     * @param groupId 群组ID
     * @param inviteeIds 被邀请者ID列表
     * @param callType 通话类型（1-语音 2-视频）
     * @param deviceId 设备ID
     * @return 通话ID
     */
    public String initiateGroupCall(Long callerId, Long groupId, List<Long> inviteeIds, 
                                     Integer callType, String deviceId) {
        // 生成通话ID
        String callId = IdUtil.simpleUUID();
        
        log.info("[GroupCall] 发起群组通话, callerId={}, groupId={}, inviteeIds={}, callType={}", 
            callerId, groupId, inviteeIds, callType);
        
        // 1. 创建通话记录（calleeId 设置为群组ID，表示群通话）
        ImCallRecordDO callRecord = ImCallRecordDO.builder()
            .callId(callId)
            .callType(callType)
            .callerId(callerId)
            .calleeId(groupId) // 群通话时 calleeId 为群组ID
            .groupId(groupId)
            .startTime(LocalDateTime.now())
            .duration(0)
            .status(ImCallStatusEnum.MISSED.getStatus())
            .state(ImCallStateEnum.INIT.getState())
            .build();
        
        callService.saveCallRecord(callRecord);
        
        // 2. 更新状态为 RINGING
        callService.updateCallState(callId, ImCallStateEnum.RINGING.getState(), 
            ImCallStateEnum.INIT.getState());
        
        // 3. 向所有被邀请者发送群组通话邀请（call.group_invite）
        sendGroupCallInvite(callId, callerId, groupId, inviteeIds, callType, deviceId);
        
        log.info("[GroupCall] 发起群组通话成功, callId={}", callId);
        return callId;
    }

    /**
     * 加入群组通话
     * 
     * @param callId 通话ID
     * @param userId 用户ID
     * @param deviceId 设备ID
     */
    public void joinGroupCall(String callId, Long userId, String deviceId) {
        log.info("[GroupCall] 用户加入群组通话, callId={}, userId={}, deviceId={}", 
            callId, userId, deviceId);
        
        // 1. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[GroupCall] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 2. 如果是第一个加入的用户（发起者），更新状态为 CONNECTED
        if (callRecord.getCallerId().equals(userId) && 
            ImCallStateEnum.RINGING.getState().equals(callRecord.getState())) {
            callService.updateCallState(callId, ImCallStateEnum.CONNECTED.getState(), 
                ImCallStateEnum.RINGING.getState());
            callRecord.setStatus(ImCallStatusEnum.ANSWERED.getStatus());
            callRecord.setAcceptedDeviceId(deviceId);
        }
        
        // 3. 向所有参与者广播加入事件（call.group_join）
        sendGroupJoin(callId, userId, callRecord.getGroupId());
        
        log.info("[GroupCall] 用户加入群组通话成功, callId={}, userId={}", callId, userId);
    }

    /**
     * 离开群组通话
     * 
     * @param callId 通话ID
     * @param userId 用户ID
     */
    public void leaveGroupCall(String callId, Long userId) {
        log.info("[GroupCall] 用户离开群组通话, callId={}, userId={}", callId, userId);
        
        // 1. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[GroupCall] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 2. 向所有参与者广播离开事件（call.group_leave）
        sendGroupLeave(callId, userId, callRecord.getGroupId());
        
        log.info("[GroupCall] 用户离开群组通话成功, callId={}, userId={}", callId, userId);
    }

    /**
     * 结束群组通话
     * 
     * @param callId 通话ID
     * @param userId 用户ID
     * @param reason 结束原因
     */
    public void endGroupCall(String callId, Long userId, String reason) {
        log.info("[GroupCall] 结束群组通话, callId={}, userId={}, reason={}", callId, userId, reason);
        
        // 1. 挂断通话
        callService.hangupCall(callId, userId, reason);
        
        // 2. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[GroupCall] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 3. 向所有参与者广播结束事件（call.group_ended）
        sendGroupEnded(callId, userId, callRecord.getGroupId(), callRecord.getDuration());
        
        log.info("[GroupCall] 结束群组通话成功, callId={}, duration={}", callId, callRecord.getDuration());
    }

    // ===== 发送群组通话事件 =====

    /**
     * 发送群组通话邀请（call.group_invite）
     */
    private void sendGroupCallInvite(String callId, Long callerId, Long groupId, 
                                      List<Long> inviteeIds, Integer callType, String deviceId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.group_invite")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("groupId", String.valueOf(groupId))
            .set("callerId", String.valueOf(callerId))
            .set("inviteeIds", inviteeIds.stream().map(String::valueOf).toArray())
            .set("callType", callType)
            .set("initiateTime", System.currentTimeMillis())
            .set("deviceId", deviceId);
        
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[GroupCall] NettyMessageSender 不可用，跳过推送");
            return;
        }
        
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();
        
        // 向所有被邀请者发送
        for (Long inviteeId : inviteeIds) {
            try {
                messageSender.sendToUserWithExtra(
                    inviteeId, 
                    MessageType.SYSTEM_NOTIFY, 
                    textMessage,
                    callerId, 
                    inviteeId, 
                    0L, 
                    null, 
                    null, 
                    null, 
                    null,
                    null, 
                    null, 
                    payload.toString()
                );
                log.info("[GroupCall] 向用户发送群组通话邀请, inviteeId={}", inviteeId);
            } catch (Exception e) {
                log.error("[GroupCall] 向用户发送群组通话邀请失败, inviteeId={}", inviteeId, e);
            }
        }
    }

    /**
     * 发送加入群组通话通知（call.group_join）
     */
    private void sendGroupJoin(String callId, Long userId, Long groupId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.group_join")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("groupId", String.valueOf(groupId))
            .set("userId", String.valueOf(userId))
            .set("joinTime", System.currentTimeMillis());
        
        broadcastGroupEvent(callId, groupId, payload);
    }

    /**
     * 发送离开群组通话通知（call.group_leave）
     */
    private void sendGroupLeave(String callId, Long userId, Long groupId) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.group_leave")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("groupId", String.valueOf(groupId))
            .set("userId", String.valueOf(userId))
            .set("leaveTime", System.currentTimeMillis());
        
        broadcastGroupEvent(callId, groupId, payload);
    }

    /**
     * 发送群组通话结束通知（call.group_ended）
     */
    private void sendGroupEnded(String callId, Long userId, Long groupId, Integer duration) {
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.group_ended")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("groupId", String.valueOf(groupId))
            .set("endedBy", String.valueOf(userId))
            .set("duration", duration)
            .set("endedTime", System.currentTimeMillis());
        
        broadcastGroupEvent(callId, groupId, payload);
    }

    /**
     * 广播群组通话事件给所有在线参与者
     */
    private void broadcastGroupEvent(String callId, Long groupId, JSONObject payload) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[GroupCall] NettyMessageSender 不可用，跳过广播");
            return;
        }
        
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();
        
        // 查询群组通话参与者列表
        List<ImCallParticipantDO> participants = callParticipantMapper.selectByCallId(callId);
        if (participants == null || participants.isEmpty()) {
            log.warn("[GroupCall] 群组通话参与者列表为空, callId={}", callId);
            return;
        }
        
        // 获取参与者用户ID集合
        Set<Long> participantUserIds = participants.stream()
            .map(ImCallParticipantDO::getUserId)
            .collect(Collectors.toSet());
        
        int sentCount = 0;
        // 只向在线的通话参与者广播
        for (Long participantUserId : participantUserIds) {
            List<NettySession> sessions = sessionManager.getSessionsByUserId(participantUserId);
            for (NettySession session : sessions) {
                try {
                    messageSender.sendToUserWithExtra(
                        participantUserId, 
                        MessageType.SYSTEM_NOTIFY, 
                        textMessage,
                        0L, 
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
                } catch (Exception e) {
                    log.error("[GroupCall] 广播群组事件失败, userId={}", participantUserId, e);
                }
            }
        }
        
        log.info("[GroupCall] 广播群组事件完成, callId={}, type={}, 参与者数={}, 实际发送数={}", 
            callId, payload.getStr("type"), participantUserIds.size(), sentCount);
    }
}
