package com.shengyu.module.system.service.im;

import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;

import java.util.List;

/**
 * IM 通话服务接口
 *
 * @author 圣钰科技
 */
public interface ImCallService {

    /**
     * 发起通话
     * 创建通话记录并发送通话信令
     *
     * @param callerId 呼叫者ID
     * @param calleeId 被叫者ID
     * @param callType 通话类型(1-语音 2-视频)
     * @return 通话ID
     */
    String initiateCall(Long callerId, Long calleeId, Integer callType);

    /**
     * 接听通话
     * 更新通话记录状态为已接听
     *
     * @param callId 通话ID
     * @param userId 用户ID
     */
    void acceptCall(String callId, Long userId);

    /**
     * 拒绝通话
     * 更新通话记录状态为已拒绝
     *
     * @param callId 通话ID
     * @param userId 用户ID
     * @param reason 拒绝原因
     */
    void rejectCall(String callId, Long userId, String reason);

    /**
     * 挂断通话
     * 更新通话记录状态并计算通话时长
     *
     * @param callId 通话ID
     * @param userId 用户ID
     */
    void hangupCall(String callId, Long userId);

    /**
     * 转发通话信令
     * 用于转发WebRTC信令数据
     *
     * @param callId 通话ID
     * @param fromUserId 发送者ID
     * @param toUserId 接收者ID
     * @param signalData 信令数据
     */
    void forwardCallSignal(String callId, Long fromUserId, Long toUserId, String signalData);

    /**
     * 保存通话记录
     *
     * @param callRecord 通话记录
     * @return 通话记录ID
     */
    Long saveCallRecord(ImCallRecordDO callRecord);

    /**
     * 获取通话记录
     *
     * @param callId 通话ID
     * @return 通话记录
     */
    ImCallRecordDO getCallRecord(String callId);

    /**
     * 获取用户的通话记录列表
     *
     * @param userId 用户ID
     * @param limit 限制数量
     * @return 通话记录列表
     */
    List<ImCallRecordDO> getCallRecords(Long userId, Integer limit);

    /**
     * 获取两个用户之间的通话记录
     *
     * @param userId1 用户1 ID
     * @param userId2 用户2 ID
     * @param limit 限制数量
     * @return 通话记录列表
     */
    List<ImCallRecordDO> getCallRecordsBetweenUsers(Long userId1, Long userId2, Integer limit);

    /**
     * 更新通话记录状态
     *
     * @param callId 通话ID
     * @param status 新状态
     */
    void updateCallStatus(String callId, Integer status);

    /**
     * 计算并更新通话时长
     *
     * @param callId 通话ID
     */
    void calculateAndUpdateDuration(String callId);

}
