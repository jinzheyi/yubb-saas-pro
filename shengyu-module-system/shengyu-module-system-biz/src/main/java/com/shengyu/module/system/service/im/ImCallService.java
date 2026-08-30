package com.shengyu.module.system.service.im;

import com.shengyu.module.system.dal.dataobject.im.ImCallEventDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.service.im.vo.CallInviteResultVO;

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
     * @param deviceId 设备ID
     * @return 通话ID
     */
    String initiateCall(Long callerId, Long calleeId, Integer callType, String deviceId);

    /**
     * 接听通话
     * 更新通话记录状态为已接听
     *
     * @param callId 通话ID
     * @param userId 用户ID
     * @param deviceId 设备ID
     */
    void acceptCall(String callId, Long userId, String deviceId);

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
     * 取消通话（主叫方）
     * 更新通话记录状态为已取消
     *
     * @param callId 通话ID
     * @param userId 用户ID（必须是主叫方）
     * @param reason 取消原因
     */
    void cancelCall(String callId, Long userId, String reason);

    /**
     * 挂断通话
     * 更新通话记录状态并计算通话时长
     *
     * @param callId 通话ID
     * @param userId 用户ID
     * @param reason 结束原因
     */
    void hangupCall(String callId, Long userId, String reason);

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

    ImCallRecordDO getCallRecordByLivekitRoom(String roomName);

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

    /**
     * 更新通话状态机状态
     *
     * @param callId 通话ID
     * @param newState 新状态
     * @param expectedState 期望的当前状态（用于CAS）
     * @return 是否更新成功
     */
    boolean updateCallState(String callId, String newState, String expectedState);

    /**
     * 检查用户是否忙线
     *
     * @param userId 用户ID
     * @return 是否忙线
     */
    boolean isUserBusy(Long userId);

    /**
     * 记录通话事件
     *
     * @param event 通话事件
     */
    void recordCallEvent(ImCallEventDO event);

    /**
     * 获取通话事件列表
     *
     * @param callId 通话ID
     * @return 事件列表
     */
    List<ImCallEventDO> getCallEvents(String callId);

    /**
     * 更新接听设备ID
     *
     * @param callId 通话ID
     * @param deviceId 设备ID
     */
    void updateAcceptedDeviceId(String callId, String deviceId);

    /**
     * 更新关联会话ID
     *
     * @param callId 通话ID
     * @param chatId 会话ID
     */
    void updateChatId(String callId, Long chatId);

    /**
     * 更新通话记录消息ID
     *
     * @param callId 通话ID
     * @param messageId 消息ID
     */
    void updateRecordMessageId(String callId, Long messageId);

    /**
     * 处理用户登出时的通话清理
     * 终止用户所有进行中的通话，保存通话记录
     *
     * @param userId 用户ID
     * @param deviceId 设备ID
     */
    void handleUserLogout(Long userId, String deviceId);

    /**
     * 处理设备被踢下线时的通话清理
     * 终止该设备上的所有通话，保存通话记录
     *
     * @param userId 用户ID
     * @param deviceId 设备ID
     * @param reason 踢出原因
     */
    void handleDeviceKicked(Long userId, String deviceId, String reason);

    /**
     * 创建通话邀请
     * 创建 LiveKit 通话业务记录并签发主叫方短时加入凭据
     *
     * @param callerId 呼叫者ID
     * @param calleeId 被叫者ID
     * @param chatId 会话ID
     * @param callType 通话类型(1-语音 2-视频)
     * @return 通话邀请结果
     */
    CallInviteResultVO createCallInvite(Long callerId, Long calleeId, String chatId, Integer callType, String deviceId);

    /** 为当前通话参与者签发短时 LiveKit 入会凭据。 */
    LiveKitConnectionInfo issueLiveKitConnection(String callId, Long userId, String deviceId);

    /**
     * 根据用户ID分页查询通话记录
     *
     * @param userId 用户ID
     * @param callType 通话类型（可选）
     * @param startTime 开始时间（可选）
     * @param endTime 结束时间（可选）
     * @param chatId 会话ID（可选）
     * @param pageNo 页码
     * @param pageSize 每页大小
     * @return 通话记录分页结果
     */
    com.shengyu.framework.common.pojo.PageResult<com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO> getCallRecordPageByUserId(
            Long userId, Integer callType, java.time.LocalDateTime startTime,
            java.time.LocalDateTime endTime, Long chatId, Integer pageNo, Integer pageSize);

}
