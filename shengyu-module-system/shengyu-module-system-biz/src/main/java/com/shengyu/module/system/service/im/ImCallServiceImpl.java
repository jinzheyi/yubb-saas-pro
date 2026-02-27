package com.shengyu.module.system.service.im;

import cn.hutool.core.util.IdUtil;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.mysql.im.ImCallRecordMapper;
import com.shengyu.module.system.enums.im.ImCallStatusEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;

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

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String initiateCall(Long callerId, Long calleeId, Integer callType) {
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
                .build();

        callRecordMapper.insert(callRecord);

        log.info("[initiateCall] 发起通话成功, callId={}, callerId={}, calleeId={}, callType={}",
                callId, callerId, calleeId, callType);

        return callId;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void acceptCall(String callId, Long userId) {
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
        callRecord.setStartTime(LocalDateTime.now()); // 更新实际开始时间
        callRecordMapper.updateById(callRecord);

        log.info("[acceptCall] 接听通话成功, callId={}, userId={}", callId, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void rejectCall(String callId, Long userId, String reason) {
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
        callRecordMapper.updateById(callRecord);

        log.info("[rejectCall] 拒绝通话成功, callId={}, userId={}, reason={}", callId, userId, reason);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void hangupCall(String callId, Long userId) {
        // 查询通话记录
        ImCallRecordDO callRecord = callRecordMapper.selectByCallId(callId);
        if (callRecord == null) {
            throw exception(CALL_RECORD_NOT_EXISTS);
        }

        // 验证是否是通话参与者
        if (!callRecord.getCallerId().equals(userId) && !callRecord.getCalleeId().equals(userId)) {
            throw exception(CALL_PERMISSION_DENIED);
        }

        // 设置结束时间
        LocalDateTime endTime = LocalDateTime.now();
        callRecord.setEndTime(endTime);

        // 计算通话时长（如果已接听）
        if (ImCallStatusEnum.ANSWERED.getStatus().equals(callRecord.getStatus())) {
            Duration duration = Duration.between(callRecord.getStartTime(), endTime);
            callRecord.setDuration((int) duration.getSeconds());
        } else {
            // 如果未接听，更新状态为已取消
            callRecord.setStatus(ImCallStatusEnum.CANCELLED.getStatus());
        }

        callRecordMapper.updateById(callRecord);

        log.info("[hangupCall] 挂断通话成功, callId={}, userId={}, duration={}",
                callId, userId, callRecord.getDuration());
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

}
