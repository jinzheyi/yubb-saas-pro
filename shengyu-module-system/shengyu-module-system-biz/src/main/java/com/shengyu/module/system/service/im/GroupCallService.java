package com.shengyu.module.system.service.im;

import cn.hutool.core.util.IdUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImCallStateEnum;
import com.shengyu.module.system.enums.im.ImCallStatusEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.IM_CALL_USER_BUSY;

/**
 * 群组通话服务
 * 
 * 处理多人语音/视频会议的业务逻辑：
 * - 发起群组通话邀请
 * - 处理参与者加入/离开
 * - 使用确定性的 LiveKit 房间名进行多人媒体会话
 * - 广播群组通话事件给所有参与者
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class GroupCallService {

    /** WeChat-style small group call: initiator plus at most eight invitees. */
    private static final int MAX_PARTICIPANTS = 9;

    @Resource
    private ImCallService callService;

    @Resource
    private CallEventPublisher callEventPublisher;

    @Resource
    private ImCallParticipantMapper callParticipantMapper;

    @Resource
    private com.shengyu.module.system.dal.mysql.im.ImGroupUserMapper groupUserMapper;

    @Resource
    private AdminUserMapper adminUserMapper;

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
    @Transactional(rollbackFor = Exception.class)
    public String initiateGroupCall(Long callerId, Long chatId, Long groupId, List<Long> inviteeIds,
                                     Integer callType, String deviceId) {
        Long tenantId = com.shengyu.framework.tenant.core.context.TenantContextHolder.getTenantId();
        if (tenantId == null) {
            throw new IllegalStateException("租户上下文缺失");
        }
        if (inviteeIds == null) {
            throw new IllegalArgumentException("群组通话邀请成员不能为空");
        }
        List<Long> uniqueInvitees = new ArrayList<>(new LinkedHashSet<>(inviteeIds));
        uniqueInvitees.remove(null);
        uniqueInvitees.remove(callerId);
        if (uniqueInvitees.isEmpty() || uniqueInvitees.size() + 1 > MAX_PARTICIPANTS) {
            throw new IllegalArgumentException("群组通话参与人数必须在 2-" + MAX_PARTICIPANTS + " 人之间");
        }
        if (groupUserMapper.selectByGroupIdAndUserId(groupId, callerId) == null) {
            throw new IllegalStateException("发起人不是群成员");
        }
        if (callService.isUserBusy(callerId)) {
            throw exception(IM_CALL_USER_BUSY);
        }
        for (Long inviteeId : uniqueInvitees) {
            if (groupUserMapper.selectByGroupIdAndUserId(groupId, inviteeId) == null) {
                throw new IllegalArgumentException("被邀请用户不是群成员: " + inviteeId);
            }
            if (callService.isUserBusy(inviteeId)) {
                // 返回稳定业务错误码，且不把成员 userId 暴露给终端用户。
                throw exception(IM_CALL_USER_BUSY);
            }
        }
        // 生成通话ID。房间、记录和完整受邀名单在发邀请前处于同一事务中，
        // 消除过去“先建单聊、再扩成群聊”的接听竞态。
        String callId = IdUtil.simpleUUID();
        String livekitRoom = "im_" + tenantId + "_" + callId;
        
        log.info("[GroupCall] 发起群组通话, callerId={}, groupId={}, inviteeIds={}, callType={}", 
            callerId, groupId, uniqueInvitees, callType);
        
        // 1. 创建通话记录（calleeId 设置为群组ID，表示群通话）
        ImCallRecordDO callRecord = ImCallRecordDO.builder()
            .callId(callId)
            .callType(callType)
            .callerId(callerId)
            .calleeId(groupId) // 群通话时 calleeId 为群组ID
            .chatId(chatId)
            .groupId(groupId)
            .provider("LIVEKIT")
            .callMode("GROUP")
            .ownerId(callerId)
            .livekitRoom(livekitRoom)
            .stateVersion(1)
            .startTime(LocalDateTime.now())
            .duration(0)
            .status(ImCallStatusEnum.MISSED.getStatus())
            .state(ImCallStateEnum.INIT.getState())
            .build();
        
        callService.saveCallRecord(callRecord);

        // Persist both the initiator and invited members before broadcasting.
        // Previously the participant table stayed empty, so join/leave events
        // had no recipients and a restarted server lost the group-call roster.
        saveParticipant(callId, callerId, deviceId, 1, 1);
        for (Long inviteeId : uniqueInvitees) {
            saveParticipant(callId, inviteeId, null, 2, 2);
        }
        
        // 2. 更新状态为 RINGING
        callService.updateCallState(callId, ImCallStateEnum.RINGING.getState(), 
            ImCallStateEnum.INIT.getState());
        
        // 3. 向所有被邀请者发送群组通话邀请（call.group_invite）
        sendGroupCallInvite(callId, callerId, chatId, groupId, uniqueInvitees, callType, deviceId);
        
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
    @Transactional(rollbackFor = Exception.class)
    public void joinGroupCall(String callId, Long userId, String deviceId) {
        log.info("[GroupCall] 用户加入群组通话, callId={}, userId={}, deviceId={}", 
            callId, userId, deviceId);
        
        // 1. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[GroupCall] 通话记录不存在, callId={}", callId);
            return;
        }
        
        ImCallParticipantDO participant = callParticipantMapper.selectByCallIdAndUserId(callId, userId);
        if (participant == null) {
            log.warn("[GroupCall] 非受邀用户尝试加入, callId={}, userId={}", callId, userId);
            return;
        }
        // A repeated join from the same device is idempotent.
        participant.setDeviceId(deviceId);
        participant.setStatus(1);
        participant.setLeaveTime(null);
        if (participant.getJoinTime() == null) {
            participant.setJoinTime(LocalDateTime.now());
        }
        callParticipantMapper.updateById(participant);

        // 2. 如果是第一个加入的用户（发起者），更新状态为 CONNECTED
        if (callRecord.getCallerId().equals(userId) && 
            ImCallStateEnum.RINGING.getState().equals(callRecord.getState())) {
            callService.updateCallState(callId, ImCallStateEnum.CONNECTED.getState(), 
                ImCallStateEnum.RINGING.getState());
            callService.updateCallStatus(callId, ImCallStatusEnum.ANSWERED.getStatus());
            callService.updateAcceptedDeviceId(callId, deviceId);
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
    @Transactional(rollbackFor = Exception.class)
    public void leaveGroupCall(String callId, Long userId) {
        log.info("[GroupCall] 用户离开群组通话, callId={}, userId={}", callId, userId);
        
        // 1. 获取通话记录
        ImCallRecordDO callRecord = callService.getCallRecord(callId);
        if (callRecord == null) {
            log.error("[GroupCall] 通话记录不存在, callId={}", callId);
            return;
        }
        
        // 2. 仅已加入成员可以离开；持久化状态后再广播，重连时可恢复真实名单。
        if (callParticipantMapper.updateStatus(callId, userId, 3) == 0) {
            log.warn("[GroupCall] 非参与者尝试离开, callId={}, userId={}", callId, userId);
            return;
        }

        // A group call has no useful lifetime after its last joined member
        // leaves.  End the persisted session here rather than relying on a
        // client timer, otherwise a CONNECTED call can remain busy forever.
        boolean hasOnlineParticipant = callParticipantMapper.selectByCallId(callId).stream()
                .anyMatch(participant -> Integer.valueOf(1).equals(participant.getStatus()));
        if (!hasOnlineParticipant) {
            Long ownerId = callRecord.getOwnerId() != null ? callRecord.getOwnerId() : callRecord.getCallerId();
            callService.hangupCall(callId, ownerId, "NO_PARTICIPANTS");
            ImCallRecordDO endedRecord = callService.getCallRecord(callId);
            sendGroupEnded(callId, userId, callRecord.getGroupId(),
                    endedRecord != null ? endedRecord.getDuration() : 0);
            log.info("[GroupCall] 最后一名成员离开，结束群通话, callId={}", callId);
            return;
        }

        // 3. 向所有参与者广播离开事件（call.group_leave）
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

    private void saveParticipant(String callId, Long userId, String deviceId, int role, int status) {
        callParticipantMapper.insert(ImCallParticipantDO.builder()
                .callId(callId)
                .userId(userId)
                .deviceId(deviceId)
                .role(role)
                .joinTime(LocalDateTime.now())
                .status(status)
                .inviteState(status == 1 ? "ACCEPTED" : "PENDING")
                .joinState(status == 1 ? "JOINED" : "NOT_JOINED")
                .joinedAt(status == 1 ? LocalDateTime.now() : null)
                .build());
    }

    /**
     * 发送群组通话邀请（call.group_invite）
     */
    private void sendGroupCallInvite(String callId, Long callerId, Long chatId, Long groupId,
                                      List<Long> inviteeIds, Integer callType, String deviceId) {
        AdminUserDO caller = adminUserMapper.selectById(callerId);
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.group_invite")
            .set("callSessionId", callId)
            .set("callId", callId)
            .set("chatId", String.valueOf(chatId))
            .set("groupId", String.valueOf(groupId))
            .set("callerId", String.valueOf(callerId))
            .set("callerName", caller != null ? caller.getNickname() : "")
            .set("callerAvatar", caller != null ? caller.getAvatar() : null)
            .set("inviteeIds", inviteeIds.stream().map(String::valueOf).toArray())
            .set("callType", callType)
            .set("initiateTime", System.currentTimeMillis())
            .set("deviceId", deviceId);
        
        callEventPublisher.publish(inviteeIds, callerId,
                com.shengyu.framework.tenant.core.context.TenantContextHolder.getTenantId(), payload);
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

    /** 广播群组业务事件；实际投递与重试均由 outbox 唯一出口负责。 */
    private void broadcastGroupEvent(String callId, Long groupId, JSONObject payload) {
        List<ImCallParticipantDO> participants = callParticipantMapper.selectByCallId(callId);
        if (participants == null || participants.isEmpty()) {
            log.warn("[GroupCall] 群组通话参与者列表为空, callId={}", callId);
            return;
        }
        Set<Long> participantUserIds = participants.stream()
            .map(ImCallParticipantDO::getUserId)
            .collect(Collectors.toSet());
        Long actorId = payload.getLong("userId", payload.getLong("endedBy", 0L));
        callEventPublisher.publish(participantUserIds, actorId,
                com.shengyu.framework.tenant.core.context.TenantContextHolder.getTenantId(), payload);
        log.info("[GroupCall] 群组事件已写入 outbox, callId={}, type={}, participants={}",
                callId, payload.getStr("type"), participantUserIds.size());
    }
}
