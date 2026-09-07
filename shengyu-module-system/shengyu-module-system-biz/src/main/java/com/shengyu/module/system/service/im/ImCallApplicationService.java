package com.shengyu.module.system.service.im;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.api.user.AdminUserApi;
import com.shengyu.module.system.api.user.dto.AdminUserRespDTO;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import com.shengyu.module.system.dal.mysql.im.ImCallRecordMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.enums.im.ImCallStateEnum;
import com.shengyu.module.system.enums.im.ImCallTypeEnum;
import com.shengyu.module.system.service.im.vo.CallInviteResultVO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.stream.Collectors;

/**
 * 通话应用层唯一业务编排入口：事务内执行状态变更并写 outbox。
 * Controller 不拼事件，媒体服务器也不参与业务状态裁决。
 */
@Service
public class ImCallApplicationService {

    @Resource
    private ImCallService callService;
    @Resource
    private CallEventPublisher callEventPublisher;
    @Resource
    private ImCallParticipantMapper participantMapper;
    @Resource
    private ImCallRecordMapper callRecordMapper;
    @Resource
    private AdminUserApi adminUserApi;
    @Resource
    private GroupCallService groupCallService;
    @Resource
    private ImChatMapper chatMapper;

    @Transactional(rollbackFor = Exception.class)
    public CallInviteResultVO createDirect(Long callerId, Long calleeId, String chatId,
                                           Integer callType, String deviceId) {
        CallInviteResultVO result = callService.createCallInvite(callerId, calleeId, chatId, callType, deviceId);
        AdminUserRespDTO caller = adminUserApi.getUser(callerId);
        JSONObject callerProfile = JSONUtil.createObj()
                .set("userId", String.valueOf(callerId))
                .set("displayName", caller != null ? caller.getNickname() : "")
                .set("avatarUrl", caller != null ? caller.getAvatar() : null);
        JSONObject payload = envelope("call.invite", result.getCallSessionId(), callerId)
                .set("chatId", result.getChatId())
                .set("callType", result.getCallType())
                .set("callerId", String.valueOf(callerId))
                .set("calleeId", String.valueOf(calleeId))
                .set("callerProfile", callerProfile)
                .set("initiateTime", System.currentTimeMillis());
        callEventPublisher.publish(Collections.singleton(calleeId), callerId,
                TenantContextHolder.getTenantId(), payload);
        return result;
    }

    /**
     * 原子创建群通话、完整受邀名单与发起人的 LiveKit 凭据。
     * Token 签发失败时整个事务回滚，禁止留下永久占线的半成品记录。
     */
    @Transactional(rollbackFor = Exception.class)
    public CallInviteResultVO createGroup(Long callerId, Long chatId, Long groupId,
                                          List<Long> inviteeIds, Integer callType, String deviceId) {
        ImChatDO chat = chatMapper.selectById(chatId);
        if (chat == null || !Objects.equals(chat.getGroupId(), groupId)) {
            throw new IllegalArgumentException("会话与群组不匹配");
        }
        String callId = groupCallService.initiateGroupCall(
                callerId, chatId, groupId, inviteeIds, callType, deviceId);
        LiveKitConnectionInfo connection = callService.issueLiveKitConnection(callId, callerId, deviceId);
        return CallInviteResultVO.builder()
                .callSessionId(callId)
                .inviteId(callId)
                .chatId(String.valueOf(chatId))
                .callType(ImCallTypeEnum.VIDEO.getType().equals(callType) ? "video" : "audio")
                .status("ringing")
                .rtcRoom(CallInviteResultVO.RtcRoomInfo.builder()
                        .callSessionId(callId)
                        .roomName(connection.getRoomName())
                        .publisherId(String.valueOf(callerId))
                        .livekitUrl(connection.getServerUrl())
                        .token(connection.getAccessToken())
                        .build())
                .build();
    }

    @Transactional(rollbackFor = Exception.class)
    public LiveKitConnectionInfo accept(String callId, Long userId, String deviceId) {
        callService.acceptCall(callId, userId, deviceId);
        ImCallRecordDO record = callService.getCallRecord(callId);
        if (record != null && record.getGroupId() != null) {
            publishGroupJoin(record, userId);
        } else {
            publishState(callId, "call.accepted", userId, null);
        }
        return callService.issueLiveKitConnection(callId, userId, deviceId);
    }

    public LiveKitConnectionInfo connection(String callId, Long userId, String deviceId) {
        return callService.issueLiveKitConnection(callId, userId, deviceId);
    }

    public ImCallRecordDO getAuthorizedState(String callId, Long userId) {
        ImCallRecordDO record = callService.getCallRecord(callId);
        if (record == null) return null;
        boolean directParticipant = Objects.equals(userId, record.getCallerId())
                || (record.getGroupId() == null && Objects.equals(userId, record.getCalleeId()));
        boolean groupParticipant = record.getGroupId() != null
                && participantMapper.selectByCallIdAndUserId(callId, userId) != null;
        if (!directParticipant && !groupParticipant) {
            throw new IllegalStateException("无权查看该通话状态");
        }
        return record;
    }

    /**
     * 返回用户唯一可恢复的通话。WebSocket 是低延迟通知通道而不是事实来源；
     * 登录、重新鉴权和回前台均通过本查询补偿连接切换窗口内漏掉的事件。
     */
    public ImCallRecordDO getActiveCall(Long userId) {
        List<ImCallRecordDO> candidates = new ArrayList<>();
        ImCallRecordDO direct = callRecordMapper.selectLatestActiveByUserId(userId);
        if (direct != null) {
            candidates.add(direct);
        }
        List<String> groupCallIds = participantMapper.selectRecoverableByUserId(userId).stream()
                .map(ImCallParticipantDO::getCallId)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
        candidates.addAll(callRecordMapper.selectActiveByCallIds(groupCallIds));
        return candidates.stream()
                .filter(Objects::nonNull)
                .max(Comparator.comparing(ImCallRecordDO::getCreateTime,
                        Comparator.nullsFirst(Comparator.naturalOrder())))
                .orElse(null);
    }

    @Transactional(rollbackFor = Exception.class)
    public void leaveGroup(String callId, Long userId) {
        ImCallRecordDO record = getAuthorizedState(callId, userId);
        if (record == null || record.getGroupId() == null) {
            throw new IllegalArgumentException("不是有效的群组通话");
        }
        groupCallService.leaveGroupCall(callId, userId);
    }

    @Transactional(rollbackFor = Exception.class)
    public void reject(String callId, Long userId) {
        callService.rejectCall(callId, userId, "REJECT");
        ImCallRecordDO record = callService.getCallRecord(callId);
        if (record != null && record.getGroupId() != null) {
            publishGroupLeave(callId, userId);
        } else {
            publishState(callId, "call.rejected", userId, "REJECT");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public void cancel(String callId, Long userId) {
        callService.cancelCall(callId, userId, "CANCEL");
        publishState(callId, "call.cancelled", userId, "CANCEL");
    }

    @Transactional(rollbackFor = Exception.class)
    public void timeout(String callId, Long userId) {
        ImCallRecordDO record = getAuthorizedState(callId, userId);
        if (record == null || ImCallStateEnum.ENDED.getState().equals(record.getState())) {
            return;
        }
        callService.timeoutCall(callId);
    }

    @Transactional(rollbackFor = Exception.class)
    public void hangup(String callId, Long userId) {
        callService.hangupCall(callId, userId, "HANGUP");
        publishState(callId, "call.ended", userId, "HANGUP");
    }

    private void publishState(String callId, String eventType, Long actorId, String reason) {
        ImCallRecordDO record = callService.getCallRecord(callId);
        if (record == null) return;
        if ("call.accepted".equals(eventType) && !ImCallStateEnum.CONNECTED.getState().equals(record.getState())) return;
        if (("call.rejected".equals(eventType) || "call.cancelled".equals(eventType) || "call.ended".equals(eventType))
                && (!ImCallStateEnum.ENDED.getState().equals(record.getState())
                || !Objects.equals(reason, record.getEndReason()))) return;

        JSONObject payload = envelope(eventType, callId, actorId)
                .set("acceptedDeviceId", record.getAcceptedDeviceId())
                .set("duration", record.getDuration())
                .set("reason", reason);
        callEventPublisher.publish(recipients(record), actorId, record.getTenantId(), payload);
    }

    private void publishGroupLeave(String callId, Long userId) {
        ImCallRecordDO record = callService.getCallRecord(callId);
        if (record == null || record.getGroupId() == null) return;
        JSONObject payload = envelope("call.group_leave", callId, userId)
                .set("groupId", String.valueOf(record.getGroupId()))
                .set("userId", String.valueOf(userId))
                .set("leaveTime", System.currentTimeMillis());
        callEventPublisher.publish(recipients(record), userId, record.getTenantId(), payload);
    }

    private void publishGroupJoin(ImCallRecordDO record, Long userId) {
        JSONObject payload = envelope("call.group_join", record.getCallId(), userId)
                .set("groupId", String.valueOf(record.getGroupId()))
                .set("userId", String.valueOf(userId))
                .set("joinTime", System.currentTimeMillis());
        callEventPublisher.publish(recipients(record), userId, record.getTenantId(), payload);
    }

    private Collection<Long> recipients(ImCallRecordDO record) {
        if (record.getGroupId() == null) return Arrays.asList(record.getCallerId(), record.getCalleeId());
        return participantMapper.selectByCallId(record.getCallId()).stream()
                .map(ImCallParticipantDO::getUserId).collect(Collectors.toList());
    }

    private JSONObject envelope(String type, String callId, Long actorId) {
        return JSONUtil.createObj()
                .set("type", type)
                .set("callSessionId", callId)
                .set("callId", callId)
                .set("actorId", String.valueOf(actorId))
                .set("eventTime", System.currentTimeMillis());
    }
}
