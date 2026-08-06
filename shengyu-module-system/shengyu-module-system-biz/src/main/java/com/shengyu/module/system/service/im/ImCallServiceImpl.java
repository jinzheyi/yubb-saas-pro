package com.shengyu.module.system.service.im;

import cn.hutool.core.util.IdUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import com.shengyu.framework.websocket.core.protocol.TextMessage;
import com.shengyu.framework.websocket.core.sender.NettyMessageSender;
import com.shengyu.module.system.dal.dataobject.im.ImCallEventDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImCallEventMapper;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import com.shengyu.module.system.dal.mysql.im.ImCallRecordMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.dal.mysql.im.ImConversationUserStateMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImCallStateEnum;
import com.shengyu.module.system.enums.im.ImCallStatusEnum;
import com.shengyu.module.system.enums.im.ImCallTypeEnum;
import com.shengyu.module.system.enums.im.ImMessageTypeEnum;
import com.shengyu.module.system.service.im.ImCursorVersionService;
import com.shengyu.module.system.service.im.vo.CallInviteResultVO;
import com.shengyu.module.system.service.im.vo.GroupInviteResultVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 通话服务实现
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImCallServiceImpl implements ImCallService {

    @Resource
    private ImCallRecordMapper callRecordMapper;

    @Resource
    private ImCallEventMapper callEventMapper;

    @Resource
    private ImCallParticipantMapper callParticipantMapper;

    @Resource
    private ImChatMapper chatMapper;

    @Resource
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImConversationUserStateMapper conversationUserStateMapper;

    @Resource
    private ImCursorVersionService cursorVersionService;

    @Resource
    private AdminUserMapper adminUserMapper;

    @Resource
    private ImBadgeService imBadgeService;

    @Resource
    private ObjectProvider<NettyMessageSender> nettyMessageSenderProvider;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String initiateCall(Long callerId, Long calleeId, Integer callType, String deviceId) {
        // 生成通话ID
        String callId = IdUtil.simpleUUID();

        // 创建通话记录
        ImCallRecordDO callRecord = ImCallRecordDO.builder()
                .callId(callId)
                .callType(callType)
                .callerId(callerId)
                .calleeId(calleeId)
                .startTime(LocalDateTime.now())
                .duration(0)
                .status(ImCallStatusEnum.MISSED.getStatus()) // 初始状态为未接听
                .state(ImCallStateEnum.INIT.getState()) // 初始状态机状态
                .build();

        callRecordMapper.insert(callRecord);

        log.info("[initiateCall] 发起通话成功, callId={}, callerId={}, calleeId={}, callType={}, deviceId={}",
                callId, callerId, calleeId, callType, deviceId);

        return callId;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void acceptCall(String callId, Long userId, String deviceId) {
        // 查询通话记录
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 验证是否是被叫者
        if (!callRecord.getCalleeId().equals(userId)) {
            throw exception(CALL_PERMISSION_DENIED);
        }

        // 更新状态为已接听
        callRecord.setStatus(ImCallStatusEnum.ANSWERED.getStatus());
        callRecord.setState(ImCallStateEnum.CONNECTED.getState());
        callRecord.setStartTime(LocalDateTime.now()); // 更新实际开始时间
        callRecord.setAcceptedDeviceId(deviceId);
        callRecordMapper.updateById(callRecord);

        log.info("[acceptCall] 接听通话成功, callId={}, userId={}, deviceId={}", callId, userId, deviceId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void rejectCall(String callId, Long userId, String reason) {
        // 保存租户上下文（可能在异步回调中丢失）
        Long tenantId = TenantContextHolder.getTenantId();
        
        // 查询通话记录
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 验证是否是被叫者
        if (!callRecord.getCalleeId().equals(userId)) {
            throw exception(CALL_PERMISSION_DENIED);
        }

        // 更新状态为已拒绝
        callRecord.setStatus(ImCallStatusEnum.REJECTED.getStatus());
        callRecord.setEndTime(LocalDateTime.now());
        callRecord.setDuration(0);
        callRecordMapper.updateById(callRecord);

        log.info("[rejectCall] 拒绝通话成功, callId={}, userId={}, reason={}", callId, userId, reason);

        // 创建通话记录消息（type=11）并广播给所有参与者
        createCallRecordMessage(callRecord, tenantId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelCall(String callId, Long userId, String reason) {
        // 保存租户上下文（可能在异步回调中丢失）
        Long tenantId = TenantContextHolder.getTenantId();
        
        // 查询通话记录
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 验证是否是主叫者
        if (!callRecord.getCallerId().equals(userId)) {
            throw exception(CALL_PERMISSION_DENIED);
        }

        // 更新状态为已取消
        callRecord.setStatus(ImCallStatusEnum.CANCELLED.getStatus());
        callRecord.setEndTime(LocalDateTime.now());
        callRecord.setDuration(0);
        callRecordMapper.updateById(callRecord);

        log.info("[cancelCall] 取消通话成功, callId={}, userId={}, reason={}", callId, userId, reason);

        // 创建通话记录消息（type=11）并广播给所有参与者
        createCallRecordMessage(callRecord, tenantId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void hangupCall(String callId, Long userId, String reason) {
        // 保存租户上下文（可能在异步回调中丢失）
        Long tenantId = TenantContextHolder.getTenantId();
        
        // 查询通话记录
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 验证是否是通话参与者
        if (!Objects.equals(callRecord.getCallerId(), userId) && !Objects.equals(callRecord.getCalleeId(), userId)) {
            throw exception(CALL_PERMISSION_DENIED);
        }

        // 设置结束时间
        LocalDateTime endTime = LocalDateTime.now();
        callRecord.setEndTime(endTime);
        callRecord.setEndReason(reason);

        // 计算通话时长（如果已接听）
        if (ImCallStatusEnum.ANSWERED.getStatus().equals(callRecord.getStatus())) {
            Duration duration = Duration.between(callRecord.getStartTime(), endTime);
            callRecord.setDuration((int) duration.getSeconds());
        } else {
            // 如果未接听，更新状态为已取消
            callRecord.setStatus(ImCallStatusEnum.CANCELLED.getStatus());
            callRecord.setDuration(0); // 未接听的通话时长为 0
        }
        
        // 关键修复：无论是否接听，挂断时都必须将状态机状态更新为 ENDED
        // 确保前端查询通话状态时，状态机状态一致
        callRecord.setState(ImCallStateEnum.ENDED.getState());

        callRecordMapper.updateById(callRecord);

        log.info("[hangupCall] 挂断通话成功, callId={}, userId={}, reason={}, duration={}",
                callId, userId, reason, callRecord.getDuration());

        // 创建通话记录消息（type=11）并广播给所有参与者
        createCallRecordMessage(callRecord, tenantId);
    }

    @Override
    public void forwardCallSignal(String callId, Long fromUserId, Long toUserId, String signalData) {
        // 验证通话记录存在
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 验证是否是通话参与者
        if (!callRecord.getCallerId().equals(fromUserId) && !callRecord.getCalleeId().equals(fromUserId)) {
            throw exception(CALL_PERMISSION_DENIED);
        }

        // 信令转发逻辑由WebSocket中间件处理
        // 这里只做验证和日志记录
        log.info("[forwardCallSignal] 转发通话信令, callId={}, from={}, to={}", callId, fromUserId, toUserId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveCallRecord(ImCallRecordDO callRecord) {
        callRecordMapper.insert(callRecord);
        log.info("[saveCallRecord] 保存通话记录成功, callId={}", callRecord.getCallId());
        return callRecord.getId();
    }

    @Override
    public ImCallRecordDO getCallRecord(String callId) {
        return callRecordMapper.selectByCallId(callId);
    }

    @Override
    public List<ImCallRecordDO> getCallRecords(Long userId, Integer limit) {
        return callRecordMapper.selectByUserId(userId, limit);
    }

    @Override
    public List<ImCallRecordDO> getCallRecordsBetweenUsers(Long userId1, Long userId2, Integer limit) {
        return callRecordMapper.selectByTwoUsers(userId1, userId2, limit);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateCallStatus(String callId, Integer status) {
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        callRecord.setStatus(status);
        callRecordMapper.updateById(callRecord);

        log.info("[updateCallStatus] 更新通话状态成功, callId={}, status={}", callId, status);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void calculateAndUpdateDuration(String callId) {
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 只有已接听的通话才计算时长
        if (!ImCallStatusEnum.ANSWERED.getStatus().equals(callRecord.getStatus())) {
            return;
        }

        // 如果没有结束时间，使用当前时间
        LocalDateTime endTime = callRecord.getEndTime() != null ? callRecord.getEndTime() : LocalDateTime.now();
        Duration duration = Duration.between(callRecord.getStartTime(), endTime);
        callRecord.setDuration((int) duration.getSeconds());

        if (callRecord.getEndTime() == null) {
            callRecord.setEndTime(endTime);
        }

        callRecordMapper.updateById(callRecord);

        log.info("[calculateAndUpdateDuration] 计算通话时长成功, callId={}, duration={}",
                callId, callRecord.getDuration());
    }

    // ===== 状态机与事件管理 =====

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateCallState(String callId, String newState, String expectedState) {
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // CAS 校验：只有当前状态等于期望状态时才更新
        if (!expectedState.equals(callRecord.getState())) {
            log.warn("[updateCallState] CAS 失败, callId={}, expectedState={}, actualState={}, newState={}",
                    callId, expectedState, callRecord.getState(), newState);
            return false;
        }

        callRecord.setState(newState);
        callRecordMapper.updateById(callRecord);

        log.info("[updateCallState] 状态机更新成功, callId={}, {} -> {}", callId, expectedState, newState);
        return true;
    }

    @Override
    public boolean isUserBusy(Long userId) {
        // 查询用户是否有 RINGING/CONNECTING/CONNECTED 状态的通话
        return callRecordMapper.existsBusyCall(userId,
                ImCallStateEnum.RINGING.getState(),
                ImCallStateEnum.CONNECTING.getState(),
                ImCallStateEnum.CONNECTED.getState());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recordCallEvent(ImCallEventDO event) {
        try {
            callEventMapper.insert(event);
            log.debug("[recordCallEvent] 记录通话事件成功, callId={}, eventId={}, signalType={}",
                    event.getCallId(), event.getEventId(), event.getSignalType());
        } catch (DuplicateKeyException e) {
            // 幂等处理：重复事件忽略
            log.warn("[recordCallEvent] 通话事件重复, callId={}, eventId={}", event.getCallId(), event.getEventId());
        }
    }

    @Override
    public List<ImCallEventDO> getCallEvents(String callId) {
        return callEventMapper.selectByCallId(callId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateAcceptedDeviceId(String callId, String deviceId) {
        callRecordMapper.update(null, new LambdaUpdateWrapper<ImCallRecordDO>()
                .eq(ImCallRecordDO::getCallId, callId)
                .set(ImCallRecordDO::getAcceptedDeviceId, deviceId));
        log.info("[updateAcceptedDeviceId] 更新接听设备ID, callId={}, deviceId={}", callId, deviceId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateChatId(String callId, Long chatId) {
        callRecordMapper.update(null, new LambdaUpdateWrapper<ImCallRecordDO>()
                .eq(ImCallRecordDO::getCallId, callId)
                .set(ImCallRecordDO::getChatId, chatId));
        log.info("[updateChatId] 更新关联会话ID, callId={}, chatId={}", callId, chatId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateRecordMessageId(String callId, Long messageId) {
        callRecordMapper.update(null, new LambdaUpdateWrapper<ImCallRecordDO>()
                .eq(ImCallRecordDO::getCallId, callId)
                .set(ImCallRecordDO::getRecordMessageId, messageId));
        log.info("[updateRecordMessageId] 更新通话记录消息ID, callId={}, messageId={}", callId, messageId);
    }

    // ===== 通话邀请、转接、录制相关方法 =====

    @Override
    @Transactional(rollbackFor = Exception.class)
    public CallInviteResultVO createCallInvite(Long callerId, Long calleeId, String chatId, Integer callType) {
        // 生成通话ID和邀请ID
        String callId = IdUtil.simpleUUID();
        String inviteId = IdUtil.simpleUUID();

        // TODO: 调用 JanusRoomManager 创建房间（需要注入）
        String roomId = "room_" + callId;
        String token = "mock_token_" + callId; // TODO: 调用 CallTokenService 生成真实 Token

        // 创建通话记录
        ImCallRecordDO callRecord = ImCallRecordDO.builder()
                .callId(callId)
                .callType(callType)
                .callerId(callerId)
                .calleeId(calleeId)
                .chatId(chatId != null ? Long.parseLong(chatId) : null)
                .startTime(LocalDateTime.now())
                .duration(0)
                .status(ImCallStatusEnum.MISSED.getStatus())
                .state(ImCallStateEnum.RINGING.getState())
                .build();

        callRecordMapper.insert(callRecord);

        log.info("[createCallInvite] 创建通话邀请成功, callId={}, inviteId={}, callerId={}, callType={}, roomId={}",
                callId, inviteId, callerId, callType, roomId);

        // 构建 RTC 房间信息
        CallInviteResultVO.RtcRoomInfo rtcRoom = CallInviteResultVO.RtcRoomInfo.builder()
                .callSessionId(callId)
                .roomId(roomId)
                .publisherId(callerId.toString())
                .displayName("")
                .janusUrl("")
                .turnUrls(Collections.emptyList())
                .turnUsername("")
                .turnCredential("")
                .token(token)
                .build();

        // 构建响应 VO
        return CallInviteResultVO.builder()
                .callSessionId(callId)
                .inviteId(inviteId)
                .chatId(chatId)
                .callType(ImCallTypeEnum.VIDEO.getType().equals(callType) ? "video" : "audio")
                .status(ImCallStateEnum.RINGING.getState())
                .rtcRoom(rtcRoom)
                .build();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public GroupInviteResultVO inviteGroupMembers(String callSessionId, String groupId, Long inviterId, List<Long> inviteeIds) {
        // 验证通话是否存在
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callSessionId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 关键修复：群组通话权限验证需要检查多个维度
        // 1. 主叫方（发起人）可以邀请
        // 2. 被叫方（1v1场景）可以邀请
        // 3. 已经是通话参与者的人也可以邀请（群组通话场景）
        boolean isCaller = callRecord.getCallerId().equals(inviterId);
        boolean isCallee = callRecord.getCalleeId().equals(inviterId);
        boolean isParticipant = false;
        
        if (!isCaller && !isCallee) {
            // 检查是否是群组通话的已加入参与者
            ImCallParticipantDO participant = callParticipantMapper.selectByCallIdAndUserId(callSessionId, inviterId);
            isParticipant = (participant != null);
        }
        
        if (!isCaller && !isCallee && !isParticipant) {
            throw exception(CALL_PERMISSION_DENIED);
        }

        // 获取邀请者信息
        AdminUserDO inviterUser = adminUserMapper.selectById(inviterId);
        String inviterName = inviterUser != null ? inviterUser.getNickname() : "未知用户";
        String inviterAvatar = inviterUser != null ? inviterUser.getAvatar() : null;
        
        // 关键修复：从通话记录中获取实际的 callType，而非硬编码
        Integer callTypeInt = callRecord.getCallType();
        String callTypeStr = ImCallTypeEnum.VIDEO.getType().equals(callTypeInt) ? "video" : "audio";

        // 生成邀请ID列表
        List<String> inviteIds = new ArrayList<>();
        for (Long inviteeId : inviteeIds) {
            String inviteId = IdUtil.simpleUUID();
            inviteIds.add(inviteId);

            // 发送 WebSocket 通知给被邀请者
            sendGroupInviteWebSocket(callSessionId, groupId, inviterId, inviterName, inviterAvatar, inviteeId, inviteId, callTypeStr);
        }

        // 构建响应 VO
        return GroupInviteResultVO.builder()
                .callSessionId(callSessionId)
                .inviteIds(inviteIds)
                .invitedCount(inviteeIds.size())
                .build();
    }

    /**
     * 发送群组通话邀请 WebSocket 通知
     * 
     * @param callType 通话类型（"audio" 或 "video"），从通话记录中动态获取
     */
    private void sendGroupInviteWebSocket(String callSessionId, String groupId, Long inviterId, 
                                          String inviterName, String inviterAvatar, 
                                          Long inviteeId, String inviteId, String callType) {
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[sendGroupInviteWebSocket] NettyMessageSender 不可用，跳过通知");
            return;
        }

        // 关键修复：查询群组对应的 chatId，前端 onGroupInvite 需要此字段
        Long chatId = null;
        try {
            Long groupIdLong = Long.parseLong(groupId);
            ImChatDO groupChat = chatMapper.selectGroupChat(groupIdLong, 2); // chatType=2 表示群聊
            if (groupChat != null) {
                chatId = groupChat.getId();
            }
        } catch (Exception e) {
            log.warn("[sendGroupInviteWebSocket] 查询群组 chatId 失败, groupId={}", groupId, e);
        }

        // 构建群组邀请 payload
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.group-invite")
            .set("callSessionId", callSessionId)
            .set("groupId", groupId)
            .set("chatId", chatId != null ? String.valueOf(chatId) : "")  // 关键修复：补充 chatId 字段
            .set("inviteId", inviteId)
            .set("callerId", String.valueOf(inviterId))
            .set("callerName", inviterName)
            .set("callerAvatar", inviterAvatar)
            .set("callType", callType); // 关键修复：使用动态 callType，而非硬编码

        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();

        try {
            messageSender.sendToUserWithExtra(
                inviteeId,
                MessageType.SYSTEM_NOTIFY,
                textMessage,
                inviterId,
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
            log.info("[sendGroupInviteWebSocket] 发送群组通话邀请成功, callSessionId={}, inviteeId={}, inviteId={}", 
                callSessionId, inviteeId, inviteId);
        } catch (Exception e) {
            log.error("[sendGroupInviteWebSocket] 发送群组通话邀请失败, callSessionId={}, inviteeId={}", 
                callSessionId, inviteeId, e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void initiateCallTransfer(String callId, Long fromUserId, Long targetUserId, String targetUserName) {
        // 验证通话是否存在
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 验证操作权限
        if (!callRecord.getCallerId().equals(fromUserId) && !callRecord.getCalleeId().equals(fromUserId)) {
            throw exception(CALL_PERMISSION_DENIED);
        }

        // TODO: 实现通话转接逻辑（需要 CallTransferService）
        log.info("[initiateCallTransfer] 发起通话转接, callId={}, fromUserId={}, targetUserId={}",
                callId, fromUserId, targetUserId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void acceptCallTransfer(String callId, Long userId) {
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // TODO: 实现接受通话转接逻辑
        log.info("[acceptCallTransfer] 接受通话转接, callId={}, userId={}", callId, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void rejectCallTransfer(String callId, Long userId) {
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // TODO: 实现拒绝通话转接逻辑
        log.info("[rejectCallTransfer] 拒绝通话转接, callId={}, userId={}", callId, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelCallTransfer(String callId, Long userId) {
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // TODO: 实现取消通话转接逻辑
        log.info("[cancelCallTransfer] 取消通话转接, callId={}, userId={}", callId, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void startCallRecording(String callId, Long userId) {
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // TODO: 实现开始通话录制逻辑（需要 CallRecordingService）
        log.info("[startCallRecording] 开始通话录制, callId={}, userId={}", callId, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void stopCallRecording(String callId, Long userId, String recordingFilePath) {
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // TODO: 实现停止通话录制逻辑
        log.info("[stopCallRecording] 停止通话录制, callId={}, userId={}, filePath={}",
                callId, userId, recordingFilePath);
    }

    @Override
    public com.shengyu.framework.common.pojo.PageResult<ImCallRecordDO> getCallRecordPageByUserId(
            Long userId, Integer callType, java.time.LocalDateTime startTime,
            java.time.LocalDateTime endTime, Long chatId, Integer pageNo, Integer pageSize) {
        // 构建查询条件
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<ImCallRecordDO> wrapper =
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        wrapper.and(w -> w.eq(ImCallRecordDO::getCallerId, userId)
                .or()
                .eq(ImCallRecordDO::getCalleeId, userId));

        // 通话类型筛选
        if (callType != null) {
            wrapper.eq(ImCallRecordDO::getCallType, callType);
        }

        // 时间范围筛选
        if (startTime != null) {
            wrapper.ge(ImCallRecordDO::getStartTime, startTime);
        }
        if (endTime != null) {
            wrapper.le(ImCallRecordDO::getStartTime, endTime);
        }

        // 会话ID筛选
        if (chatId != null) {
            wrapper.eq(ImCallRecordDO::getChatId, chatId);
        }

        // 按开始时间倒序
        wrapper.orderByDesc(ImCallRecordDO::getStartTime);

        // 分页查询
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<ImCallRecordDO> page =
                new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(pageNo, pageSize);
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<ImCallRecordDO> resultPage =
                callRecordMapper.selectPage(page, wrapper);

        return new com.shengyu.framework.common.pojo.PageResult<>(resultPage.getRecords(), resultPage.getTotal());
    }

    // ===== 边界场景处理：用户登出/设备被踢时的通话清理 =====

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void handleUserLogout(Long userId, String deviceId) {
        log.info("[handleUserLogout] 用户登出，开始清理通话, userId={}, deviceId={}", userId, deviceId);

        try {
            // 1. 查询用户所有进行中的通话（作为主叫或被叫）
            List<ImCallRecordDO> activeCalls = callRecordMapper.selectList(
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<ImCallRecordDO>()
                            .and(wrapper -> wrapper
                                    .eq(ImCallRecordDO::getCallerId, userId)
                                    .or()
                                    .eq(ImCallRecordDO::getCalleeId, userId)
                            )
                            .in(ImCallRecordDO::getState,
                                    ImCallStateEnum.RINGING.getState(),
                                    ImCallStateEnum.CONNECTING.getState(),
                                    ImCallStateEnum.CONNECTED.getState())
            );

            if (activeCalls.isEmpty()) {
                log.info("[handleUserLogout] 用户无进行中的通话, userId={}", userId);
                return;
            }

            log.info("[handleUserLogout] 发现 {} 个进行中的通话, userId={}", activeCalls.size(), userId);

            // 2. 逐个处理通话
            for (ImCallRecordDO callRecord : activeCalls) {
                try {
                    // 设置结束时间
                    LocalDateTime endTime = LocalDateTime.now();
                    callRecord.setEndTime(endTime);
                    callRecord.setState(ImCallStateEnum.ENDED.getState());
                    callRecord.setEndReason("USER_LOGOUT");

                    // 计算通话时长（如果已接听）
                    if (ImCallStatusEnum.ANSWERED.getStatus().equals(callRecord.getStatus())) {
                        Duration duration = Duration.between(callRecord.getStartTime(), endTime);
                        callRecord.setDuration((int) duration.getSeconds());
                    } else {
                        // 如果未接听，更新状态为已取消
                        callRecord.setStatus(ImCallStatusEnum.CANCELLED.getStatus());
                    }

                    callRecordMapper.updateById(callRecord);

                    log.info("[handleUserLogout] 终止通话成功, callId={}, userId={}, reason=USER_LOGOUT",
                            callRecord.getCallId(), userId);
                } catch (Exception e) {
                    log.error("[handleUserLogout] 终止通话失败, callId={}, userId={}", callRecord.getCallId(), userId, e);
                }
            }

            log.info("[handleUserLogout] 用户登出通话清理完成, userId={}, 处理通话数={}", userId, activeCalls.size());
        } catch (Exception e) {
            log.error("[handleUserLogout] 用户登出通话清理异常, userId={}", userId, e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void handleDeviceKicked(Long userId, String deviceId, String reason) {
        log.info("[handleDeviceKicked] 设备被踢下线，开始清理通话, userId={}, deviceId={}, reason={}",
                userId, deviceId, reason);

        try {
            // 1. 查询该用户在该设备上的进行中通话
            // 注意：这里简化处理，实际应该根据 deviceId 查询，但当前表结构没有 deviceId 字段
            // 所以查询用户所有进行中的通话
            List<ImCallRecordDO> activeCalls = callRecordMapper.selectList(
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<ImCallRecordDO>()
                            .and(wrapper -> wrapper
                                    .eq(ImCallRecordDO::getCallerId, userId)
                                    .or()
                                    .eq(ImCallRecordDO::getCalleeId, userId)
                            )
                            .in(ImCallRecordDO::getState,
                                    ImCallStateEnum.RINGING.getState(),
                                    ImCallStateEnum.CONNECTING.getState(),
                                    ImCallStateEnum.CONNECTED.getState())
            );

            if (activeCalls.isEmpty()) {
                log.info("[handleDeviceKicked] 用户无进行中的通话, userId={}, deviceId={}", userId, deviceId);
                return;
            }

            log.info("[handleDeviceKicked] 发现 {} 个进行中的通话, userId={}, deviceId={}",
                    activeCalls.size(), userId, deviceId);

            // 2. 逐个处理通话
            for (ImCallRecordDO callRecord : activeCalls) {
                try {
                    // 设置结束时间
                    LocalDateTime endTime = LocalDateTime.now();
                    callRecord.setEndTime(endTime);
                    callRecord.setState(ImCallStateEnum.ENDED.getState());
                    callRecord.setEndReason("DEVICE_KICKED:" + reason);

                    // 计算通话时长（如果已接听）
                    if (ImCallStatusEnum.ANSWERED.getStatus().equals(callRecord.getStatus())) {
                        Duration duration = Duration.between(callRecord.getStartTime(), endTime);
                        callRecord.setDuration((int) duration.getSeconds());
                    } else {
                        // 如果未接听，更新状态为已取消
                        callRecord.setStatus(ImCallStatusEnum.CANCELLED.getStatus());
                    }

                    callRecordMapper.updateById(callRecord);

                    log.info("[handleDeviceKicked] 终止通话成功, callId={}, userId={}, deviceId={}, reason={}",
                            callRecord.getCallId(), userId, deviceId, reason);
                } catch (Exception e) {
                    log.error("[handleDeviceKicked] 终止通话失败, callId={}, userId={}, deviceId={}",
                            callRecord.getCallId(), userId, deviceId, e);
                }
            }

            log.info("[handleDeviceKicked] 设备被踢通话清理完成, userId={}, deviceId={}, 处理通话数={}",
                    userId, deviceId, activeCalls.size());
        } catch (Exception e) {
            log.error("[handleDeviceKicked] 设备被踢通话清理异常, userId={}, deviceId={}", userId, deviceId, e);
        }
    }

    @Override
    public void updateMediaState(String callSessionId, Long userId, Boolean cameraEnabled, Boolean microphoneEnabled) {
        // 查询通话记录
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callSessionId);
        if (callRecord == null) {
            log.warn("[updateMediaState] 通话记录不存在, callSessionId={}", callSessionId);
            return;
        }

        // 确定对端用户ID
        Long targetUserId = callRecord.getCallerId().equals(userId) ? callRecord.getCalleeId() : callRecord.getCallerId();
        if (targetUserId == null) {
            log.warn("[updateMediaState] 对端用户ID为空, callSessionId={}", callSessionId);
            return;
        }

        // 构建 WebSocket 消息
        JSONObject payload = JSONUtil.createObj()
            .set("type", "call.media-state-update")
            .set("callSessionId", callSessionId)
            .set("fromUserId", String.valueOf(userId))
            .set("cameraEnabled", cameraEnabled)
            .set("microphoneEnabled", microphoneEnabled);

        // 通过 WebSocket 广播给对端
        NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
        if (messageSender == null) {
            log.warn("[updateMediaState] NettyMessageSender 不可用，跳过广播");
            return;
        }

        TextMessage textMessage = TextMessage.newBuilder()
            .setContent("")
            .build();

        try {
            messageSender.sendToUserWithExtra(
                targetUserId,
                MessageType.SYSTEM_NOTIFY,
                textMessage,
                userId,
                targetUserId,
                0L,
                null,
                null,
                null,
                null,
                null,
                null,
                payload.toString()
            );
            log.info("[updateMediaState] 广播媒体状态成功, callSessionId={}, fromUserId={}, targetUserId={}, cameraEnabled={}, microphoneEnabled={}",
                callSessionId, userId, targetUserId, cameraEnabled, microphoneEnabled);
        } catch (Exception e) {
            log.error("[updateMediaState] 广播媒体状态失败, callSessionId={}, targetUserId={}", callSessionId, targetUserId, e);
        }
    }

    /**
     * 创建通话记录消息并广播给所有会话参与者
     * 
     * @param callRecord 通话记录
     * @param tenantId 租户ID（用于恢复租户上下文）
     */
    private void createCallRecordMessage(ImCallRecordDO callRecord, Long tenantId) {
        try {
            // 获取会话ID（群通话时 chatId 可能为 null，需要通过 groupId 查找）
            Long chatId = callRecord.getChatId();
            Long groupId = callRecord.getGroupId();
            boolean isGroupCall = groupId != null;
            
            if (chatId == null && isGroupCall) {
                // 群通话：通过 groupId 查找对应的会话
                ImChatDO groupChat = chatMapper.selectGroupChat(groupId, 2); // chatType=2 表示群聊
                if (groupChat != null) {
                    chatId = groupChat.getId();
                    // 回填 chatId 到通话记录
                    callRecord.setChatId(chatId);
                }
            }
            
            if (chatId == null) {
                log.warn("[createCallRecordMessage] 通话记录没有关联的会话ID, callId={}", callRecord.getCallId());
                return;
            }

            // 查询主叫用户昵称和头像
            String callerName = null;
            String callerAvatar = null;
            try {
                AdminUserDO callerUser = adminUserMapper.selectById(callRecord.getCallerId());
                if (callerUser != null) {
                    callerName = callerUser.getNickname();
                    callerAvatar = callerUser.getAvatar();
                }
            } catch (Exception e) {
                log.warn("[createCallRecordMessage] 查询主叫用户信息失败, callId={}", callRecord.getCallId(), e);
            }

            // 查询被叫用户昵称（1v1通话）或参与者昵称列表（群通话）
            String calleeName = null;
            List<String> inviteeNames = new ArrayList<>();
            
            if (isGroupCall) {
                // 群通话：查询所有参与者昵称
                try {
                    List<ImCallParticipantDO> participants = callParticipantMapper.selectByCallId(callRecord.getCallId());
                    for (ImCallParticipantDO participant : participants) {
                        AdminUserDO participantUser = adminUserMapper.selectById(participant.getUserId());
                        if (participantUser != null && participantUser.getNickname() != null) {
                            inviteeNames.add(participantUser.getNickname());
                        }
                    }
                } catch (Exception e) {
                    log.warn("[createCallRecordMessage] 查询群通话参与者昵称失败, callId={}", callRecord.getCallId(), e);
                }
            } else {
                // 1v1通话：查询被叫用户昵称
                try {
                    AdminUserDO calleeUser = adminUserMapper.selectById(callRecord.getCalleeId());
                    if (calleeUser != null) {
                        calleeName = calleeUser.getNickname();
                    }
                } catch (Exception e) {
                    log.warn("[createCallRecordMessage] 查询被叫用户昵称失败, callId={}", callRecord.getCallId(), e);
                }
            }

            // 构建通话记录消息的 extra 字段
            // 关键修复：同时提供前端 CallRecordDto.fromJson 期望的所有字段名
            // - status: 前端 CallRecordDto 使用 'status'，兼容旧字段 'callStatus'
            // - conversationType: 前端使用 'conversationType'(int: 1=单聊, 2=群聊)，兼容旧字段 'isGroupCall'
            // - startTime/endTime: 前端 CallRecordDto.fromJson 使用 ISO 8601 字符串格式
            // - initiateTime: 兼容旧版本前端（毫秒时间戳）
            int conversationType = isGroupCall ? 2 : 1;
            String startTimeIso = callRecord.getStartTime() != null
                ? callRecord.getStartTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toString()
                : null;
            String endTimeIso = callRecord.getEndTime() != null
                ? callRecord.getEndTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toString()
                : null;
            JSONObject extra = JSONUtil.createObj()
                .set("callId", callRecord.getCallId())
                .set("chatId", String.valueOf(chatId))  // 关键修复：前端 CallRecordDto.fromJson 需要 chatId
                .set("callType", callRecord.getCallType())
                .set("callStatus", callRecord.getStatus())
                .set("status", callRecord.getStatus())  // 关键修复：前端 CallRecordDto.fromJson 使用 'status'
                .set("callerId", String.valueOf(callRecord.getCallerId()))
                .set("calleeId", String.valueOf(callRecord.getCalleeId()))
                .set("callerName", callerName)
                .set("callerAvatar", callerAvatar)
                .set("calleeName", calleeName)
                .set("duration", callRecord.getDuration() != null ? callRecord.getDuration() : 0)
                .set("startTime", startTimeIso)  // 关键修复：前端 CallRecordDto.fromJson 使用 ISO 8601 格式
                .set("endTime", endTimeIso)      // 关键修复：前端 CallRecordDto.fromJson 使用 ISO 8601 格式
                .set("initiateTime", callRecord.getStartTime() != null ? 
                    callRecord.getStartTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() : 0)  // 兼容旧版本
                .set("isGroupCall", isGroupCall)
                .set("conversationType", conversationType);  // 关键修复：前端 CallRecordDto.fromJson 使用 'conversationType'
            
            // 群通话时添加参与者昵称列表
            if (isGroupCall && !inviteeNames.isEmpty()) {
                extra.set("inviteeNames", inviteeNames);
            }

            // 生成消息内容摘要（用于会话列表显示）
            String callTypeText = callRecord.getCallType() == 2 ? "视频" : "语音";
            String contentSummary = buildCallRecordContentSummary(callRecord, callTypeText);

            // 创建消息记录
            ImChatMessageDO message = ImChatMessageDO.builder()
                .chatId(chatId)
                .senderId(callRecord.getCallerId()) // 发起者作为消息发送者
                .messageType(ImMessageTypeEnum.CALL_RECORD.getType())
                .content(contentSummary) // 设置摘要内容，用于会话列表显示
                .extra(extra.toString())
                .sendTime(LocalDateTime.now())
                .rev(1L)
                .status(1) // 已发送状态
                .build();

            // 获取下一个 sequence
            Long sequence = chatMapper.nextSequence(chatId);
            message.setSequence(sequence);

            // 插入消息
            chatMessageMapper.insert(message);

            log.info("[createCallRecordMessage] 创建通话记录消息成功, messageId={}, callId={}, chatId={}, isGroupCall={}, type={}",
                message.getId(), callRecord.getCallId(), chatId, isGroupCall, ImMessageTypeEnum.CALL_RECORD.getType());

            // 更新通话记录的 recordMessageId
            callRecord.setRecordMessageId(message.getId());
            callRecordMapper.updateById(callRecord);

            // 【关键修复】更新会话状态，确保刷新后会话列表能正确显示通话记录
            updateConversationStateAfterCallRecord(message, callRecord, tenantId);

            // 广播消息给所有会话参与者
            broadcastCallRecordMessage(message, callRecord, tenantId);
            
        } catch (Exception e) {
            log.error("[createCallRecordMessage] 创建通话记录消息失败, callId={}", callRecord.getCallId(), e);
        }
    }

    /**
     * 广播通话记录消息给所有会话参与者
     * 
     * @param message 消息记录
     * @param callRecord 通话记录
     * @param tenantId 租户ID（用于恢复租户上下文）
     */
    private void broadcastCallRecordMessage(ImChatMessageDO message, ImCallRecordDO callRecord, Long tenantId) {
        try {
            NettyMessageSender messageSender = nettyMessageSenderProvider.getIfAvailable();
            if (messageSender == null) {
                log.warn("[broadcastCallRecordMessage] NettyMessageSender 不可用，跳过广播");
                return;
            }

            Long chatId = message.getChatId();
            
            // 【关键修复】查询会话参与者前，先保存并恢复租户上下文
            // 因为此方法可能在异步回调或非请求线程中被调用，TenantContextHolder 可能为空
            Long savedTenantId = com.shengyu.framework.tenant.core.context.TenantContextHolder.getTenantId();
            boolean needRestoreTenant = false;
            if (savedTenantId == null && tenantId != null) {
                // 从入口方法传递的 tenantId 设置到上下文
                com.shengyu.framework.tenant.core.context.TenantContextHolder.setTenantId(tenantId);
                needRestoreTenant = true;
                log.debug("[broadcastCallRecordMessage] 临时设置租户上下文, tenantId={}", tenantId);
            }
            
            try {
                // 查询会话的所有参与者（使用 LambdaQueryWrapper）
                List<ImChatUserDO> chatUsers = chatUserMapper.selectList(
                    new LambdaQueryWrapper<ImChatUserDO>()
                        .eq(ImChatUserDO::getChatId, chatId)
                );
                if (chatUsers == null || chatUsers.isEmpty()) {
                    log.warn("[broadcastCallRecordMessage] 会话没有参与者, chatId={}", chatId);
                    return;
                }

                // 查询发送者头像和昵称（用于前端显示）
                String senderAvatar = null;
                String senderNickname = null;
                try {
                    AdminUserDO senderUser = adminUserMapper.selectById(message.getSenderId());
                    if (senderUser != null) {
                        senderAvatar = senderUser.getAvatar();
                        senderNickname = senderUser.getNickname();
                    }
                } catch (Exception e) {
                    log.warn("[broadcastCallRecordMessage] 查询发送者信息失败, senderId={}", message.getSenderId(), e);
                }

                // 广播给所有参与者（包含发送者，确保发送方也能实时收到通话记录消息）
                for (ImChatUserDO chatUser : chatUsers) {
                    try {
                        // 为每个接收者构建个性化的消息体（包含 isOutgoing 字段）
                        boolean isOutgoing = chatUser.getUserId().equals(message.getSenderId());
                        
                        // 【关键修复】为每个接收者注入 isCaller 字段到 extra 中
                        // 前端 CallRecordDto.fromJson 期望 extra 中包含 isCaller 字段
                        // isCaller 是接收者维度的：标识该接收者是否是通话的主叫方
                        String personalizedExtra = message.getExtra();
                        try {
                            JSONObject extraObj = JSONUtil.parseObj(message.getExtra());
                            extraObj.set("isCaller", chatUser.getUserId().equals(callRecord.getCallerId()));
                            personalizedExtra = extraObj.toString();
                        } catch (Exception e) {
                            log.warn("[broadcastCallRecordMessage] 解析 extra 失败, 使用原始 extra, userId={}", chatUser.getUserId(), e);
                        }
                        
                        JSONObject messageBody = JSONUtil.createObj()
                            .set("messageId", String.valueOf(message.getId()))
                            .set("chatId", String.valueOf(chatId))
                            .set("senderId", String.valueOf(message.getSenderId()))
                            .set("senderAvatar", senderAvatar)
                            .set("senderNickname", senderNickname)
                            .set("type", message.getMessageType())
                            .set("content", message.getContent())
                            .set("extra", personalizedExtra)  // 关键修复：使用包含 isCaller 的个性化 extra
                            .set("sequence", String.valueOf(message.getSequence()))
                            .set("rev", String.valueOf(message.getRev()))
                            .set("status", message.getStatus())
                            .set("sendTime", message.getSendTime() != null ? 
                                message.getSendTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() : 0)
                            .set("isOutgoing", isOutgoing)  // 关键：为每个接收者设置正确的消息方向
                            .set("isSelf", isOutgoing);  // 兼容字段

                        // 【关键修复】使用 sendToUserWithFullInfo 传递发送者头像和昵称
                        messageSender.sendToUserWithFullInfo(
                            chatUser.getUserId(),
                            MessageType.CALL_RECORD,  // 使用通话记录消息类型（209）
                            TextMessage.newBuilder().setContent(messageBody.toString()).build(),
                            message.getSenderId(),
                            senderNickname,  // senderNickname - 传递发送者昵称
                            senderAvatar,    // senderAvatar - 传递发送者头像
                            null,  // receiverId
                            null,  // groupId
                            tenantId,  // tenantId - 传递实际的租户ID
                            message.getId(),  // messageId (Long)
                            message.getSequence(),  // sequence (Long)
                            chatId,  // chatId (Long)
                            null,  // cursorVersion
                            null,  // conversationVersion
                            message.getExtra()  // headerExtra
                        );
                        log.debug("[broadcastCallRecordMessage] 广播消息成功, userId={}, messageId={}", 
                            chatUser.getUserId(), message.getId());
                    } catch (Exception e) {
                        log.error("[broadcastCallRecordMessage] 广播消息失败, userId={}, messageId={}", 
                            chatUser.getUserId(), message.getId(), e);
                    }
                }

                log.info("[broadcastCallRecordMessage] 广播通话记录消息完成, messageId={}, chatId={}, participantCount={}",
                    message.getId(), chatId, chatUsers.size());
            } finally {
                // 【关键修复】如果是我们临时设置的租户上下文，用完必须恢复原状
                if (needRestoreTenant) {
                    if (savedTenantId != null) {
                        com.shengyu.framework.tenant.core.context.TenantContextHolder.setTenantId(savedTenantId);
                    } else {
                        com.shengyu.framework.tenant.core.context.TenantContextHolder.clear();
                    }
                    log.debug("[broadcastCallRecordMessage] 恢复租户上下文, tenantId={}", savedTenantId);
                }
            }

        } catch (Exception e) {
            log.error("[broadcastCallRecordMessage] 广播通话记录消息失败, messageId={}", message.getId(), e);
        }
    }

    /**
     * 通话记录消息创建后更新会话状态
     * 
     * 更新 im_conversation_user_state 和 im_chat_user 表的 last_message_* 字段
     * 确保刷新后会话列表能正确显示通话记录
     * 
     * @param message 通话记录消息
     * @param callRecord 通话记录
     * @param tenantId 租户ID
     */
    private void updateConversationStateAfterCallRecord(ImChatMessageDO message, ImCallRecordDO callRecord, Long tenantId) {
        try {
            // 【关键修复】查询会话参与者前，先保存并恢复租户上下文
            // 因为此方法可能在异步回调或非请求线程中被调用，TenantContextHolder 可能为空
            Long savedTenantId = com.shengyu.framework.tenant.core.context.TenantContextHolder.getTenantId();
            boolean needRestoreTenant = false;
            if (savedTenantId == null && tenantId != null) {
                // 从入口方法传递的 tenantId 设置到上下文
                com.shengyu.framework.tenant.core.context.TenantContextHolder.setTenantId(tenantId);
                needRestoreTenant = true;
                log.debug("[updateConversationStateAfterCallRecord] 临时设置租户上下文, tenantId={}", tenantId);
            }
            
            try {
                Long chatId = message.getChatId();
                Long senderId = message.getSenderId();
                LocalDateTime sendTime = message.getSendTime();
                String contentSummary = message.getContent();
                Integer messageType = message.getMessageType();
                Long messageSequence = message.getSequence();
                Long messageId = message.getId();

                // 查询会话的所有参与者
                List<ImChatUserDO> chatUsers = chatUserMapper.selectList(
                    new LambdaQueryWrapper<ImChatUserDO>()
                        .eq(ImChatUserDO::getChatId, chatId)
                );

                if (chatUsers == null || chatUsers.isEmpty()) {
                    log.warn("[updateConversationStateAfterCallRecord] 会话没有参与者, chatId={}", chatId);
                    return;
                }

                // 为每个参与者更新会话状态
                for (ImChatUserDO chatUser : chatUsers) {
                    Long userId = chatUser.getUserId();
                    boolean isSender = userId.equals(senderId);

                    // 分配 cursor version
                    Long cursorVersion = cursorVersionService.allocateNextCursorVersion(tenantId, userId);

                    // 更新 im_conversation_user_state
                    if (isSender) {
                        // 发送者：unread_count = 0
                        conversationUserStateMapper.upsertAfterMessageForSender(
                            tenantId,
                            chatId,
                            userId,
                            cursorVersion,
                            messageSequence,  // lastReadSequence
                            sendTime,         // lastReadTime
                            messageId,
                            messageSequence,
                            senderId,
                            messageType,
                            contentSummary,
                            false,            // lastMessageHasAtMe
                            sendTime
                        );
                    } else {
                        // 接收者：unread_count + 1
                        conversationUserStateMapper.upsertAfterMessage(
                            tenantId,
                            chatId,
                            userId,
                            cursorVersion,
                            1,                // unreadDelta
                            messageSequence,  // lastReadSequence
                            sendTime,         // lastReadTime
                            messageId,
                            messageSequence,
                            senderId,
                            messageType,
                            contentSummary,
                            false,            // lastMessageHasAtMe
                            sendTime
                        );
                    }

                    // 更新 im_chat_user（使用 8 参数版本，确保 lastMessageType 被正确更新）
                    chatUserMapper.updateLastMessageAndIncrementUnread(
                        chatUser.getId(),
                        messageId,
                        messageSequence,
                        messageType,          // lastMessageType - 关键修复：确保通话记录类型被持久化
                        contentSummary,
                        sendTime,
                        isSender ? 0 : 1,     // unreadIncrement
                        chatUser.getNoDisturb() != null && chatUser.getNoDisturb()
                    );

                    // 【关键修复】发送者：推进 last_read_sequence 到当前消息，
                    // 因为 im_chat_user 的未读数按 last_message_sequence - last_read_sequence 隐式计算
                    // 否则即使 unread_count 显式不增加，差值计算也会给出未读数
                    if (isSender) {
                        chatUserMapper.markReadToSequence(userId, chatId, messageSequence);
                    }
                }

                // 【关键修复】推送实时角标更新：
                // 1. 发送者：unread=0，确保自己产生的通话记录不产生角标
                // 2. 接收者：unread+1，确保实时收到角标
                for (ImChatUserDO chatUser : chatUsers) {
                    Long userId = chatUser.getUserId();
                    boolean isSender = userId.equals(senderId);
                    boolean muted = chatUser.getNoDisturb() != null && chatUser.getNoDisturb();
                    try {
                        if (isSender) {
                            // 发送者：推送 unread=0 的角标，避免任何残留
                            imBadgeService.pushIncrementalBadgeUpdate(userId, chatId, 0);
                        } else if (!muted) {
                            // 接收者：推送 unread+1 的角标
                            imBadgeService.pushIncrementalBadgeUpdate(userId, chatId, 1);
                        }
                    } catch (Exception e) {
                        log.warn("[updateConversationStateAfterCallRecord] 推送角标失败, userId={}, chatId={}",
                            userId, chatId, e);
                    }
                }

                log.info("[updateConversationStateAfterCallRecord] 更新会话状态成功, messageId={}, chatId={}, participantCount={}",
                    messageId, chatId, chatUsers.size());
            } finally {
                // 【关键修复】如果是我们临时设置的租户上下文，用完必须恢复原状
                if (needRestoreTenant) {
                    if (savedTenantId != null) {
                        com.shengyu.framework.tenant.core.context.TenantContextHolder.setTenantId(savedTenantId);
                    } else {
                        com.shengyu.framework.tenant.core.context.TenantContextHolder.clear();
                    }
                    log.debug("[updateConversationStateAfterCallRecord] 恢复租户上下文, tenantId={}", savedTenantId);
                }
            }

        } catch (Exception e) {
            log.error("[updateConversationStateAfterCallRecord] 更新会话状态失败, messageId={}", message.getId(), e);
        }
    }

    /**
     * 生成通话记录消息摘要（用于会话列表显示）
     * 
     * @param callRecord 通话记录
     * @param callTypeText 通话类型文本（"语音" 或 "视频"）
     * @return 摘要文本，如 "[语音通话]" 或 "[视频通话]"
     */
    private String buildCallRecordContentSummary(ImCallRecordDO callRecord, String callTypeText) {
        // 统一返回格式：[语音通话] 或 [视频通话]
        return "[" + callTypeText + "通话]";
    }

}
