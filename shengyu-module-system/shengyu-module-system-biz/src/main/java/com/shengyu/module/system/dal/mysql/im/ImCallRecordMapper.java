package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;
import java.util.List;

/**
 * IM 通话记录 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImCallRecordMapper extends BaseMapperX<ImCallRecordDO> {

    /**
     * 根据通话ID查询通话记录
     *
     * @param callId 通话ID
     * @return 通话记录
     */
    default ImCallRecordDO selectByCallId(String callId) {
        return selectOne(ImCallRecordDO::getCallId, callId);
    }

    default ImCallRecordDO selectByLivekitRoom(String roomName) {
        return selectOne(ImCallRecordDO::getLivekitRoom, roomName);
    }

    /**
     * 查询用户的通话记录列表
     *
     * @param userId 用户ID
     * @param limit 限制数量
     * @return 通话记录列表
     */
    default List<ImCallRecordDO> selectByUserId(Long userId, Integer limit) {
        LambdaQueryWrapper<ImCallRecordDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.and(w -> w.eq(ImCallRecordDO::getCallerId, userId)
                .or()
                .eq(ImCallRecordDO::getCalleeId, userId));
        wrapper.orderByDesc(ImCallRecordDO::getStartTime);
        if (limit != null && limit > 0) {
            wrapper.last("LIMIT " + limit);
        }
        return selectList(wrapper);
    }

    /**
     * 查询两个用户之间的通话记录
     *
     * @param userId1 用户1 ID
     * @param userId2 用户2 ID
     * @param limit 限制数量
     * @return 通话记录列表
     */
    default List<ImCallRecordDO> selectByTwoUsers(Long userId1, Long userId2, Integer limit) {
        LambdaQueryWrapper<ImCallRecordDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.and(w -> w.and(w1 -> w1.eq(ImCallRecordDO::getCallerId, userId1)
                        .eq(ImCallRecordDO::getCalleeId, userId2))
                .or(w2 -> w2.eq(ImCallRecordDO::getCallerId, userId2)
                        .eq(ImCallRecordDO::getCalleeId, userId1)));
        wrapper.orderByDesc(ImCallRecordDO::getStartTime);
        if (limit != null && limit > 0) {
            wrapper.last("LIMIT " + limit);
        }
        return selectList(wrapper);
    }

    /**
     * 按会话ID查询通话记录
     *
     * @param chatId  会话ID
     * @param userId  当前用户ID（必须是通话参与者）
     * @param limit   限制数量
     * @return 通话记录列表
     */
    default List<ImCallRecordDO> selectByChatId(Long chatId, Long userId, Integer limit) {
        LambdaQueryWrapper<ImCallRecordDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallRecordDO::getChatId, chatId);
        // 确保当前用户是通话参与者
        wrapper.and(w -> w.eq(ImCallRecordDO::getCallerId, userId)
                .or()
                .eq(ImCallRecordDO::getCalleeId, userId));
        wrapper.orderByDesc(ImCallRecordDO::getStartTime);
        if (limit != null && limit > 0) {
            wrapper.last("LIMIT " + limit);
        }
        return selectList(wrapper);
    }

    /**
     * 检查用户是否存在忙线通话（RINGING/CONNECTING/CONNECTED 状态）
     *
     * @param userId 用户ID
     * @param states 状态列表
     * @return 是否存在
     */
    default boolean existsBusyCall(Long userId, String... states) {
        LambdaQueryWrapper<ImCallRecordDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.and(w -> w.eq(ImCallRecordDO::getCallerId, userId)
                .or()
                .eq(ImCallRecordDO::getCalleeId, userId));
        wrapper.in(ImCallRecordDO::getState, (Object[]) states);
        return selectCount(wrapper) > 0;
    }

    /** 查询用户作为单聊双方或群通话发起人时的唯一活跃通话。 */
    default ImCallRecordDO selectLatestActiveByUserId(Long userId) {
        LambdaQueryWrapper<ImCallRecordDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.and(w -> w.eq(ImCallRecordDO::getCallerId, userId)
                .or()
                .eq(ImCallRecordDO::getCalleeId, userId));
        wrapper.in(ImCallRecordDO::getState, "RINGING", "CONNECTING", "CONNECTED");
        wrapper.orderByDesc(ImCallRecordDO::getCreateTime);
        wrapper.last("LIMIT 1");
        return selectOne(wrapper);
    }

    /** 查询群成员恢复所需的活跃通话，并保持确定性的最新优先顺序。 */
    default List<ImCallRecordDO> selectActiveByCallIds(List<String> callIds) {
        if (callIds == null || callIds.isEmpty()) {
            return java.util.Collections.emptyList();
        }
        LambdaQueryWrapper<ImCallRecordDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.in(ImCallRecordDO::getCallId, callIds);
        wrapper.in(ImCallRecordDO::getState, "RINGING", "CONNECTING", "CONNECTED");
        wrapper.orderByDesc(ImCallRecordDO::getCreateTime);
        return selectList(wrapper);
    }

    /**
     * 回收指定用户过期但未结束的邀请状态。
     *
     * <p>这是创建新通话前的兜底，不依赖 Quartz 已经被部署或正常运行。状态条件
     * 保留在更新语句中，因此不会结束在检查期间刚刚接通的通话。</p>
     */
    default int expirePendingCallsForUser(Long userId, LocalDateTime before,
                                          Integer missedStatus, LocalDateTime endTime) {
        LambdaUpdateWrapper<ImCallRecordDO> wrapper = new LambdaUpdateWrapper<>();
        wrapper.and(w -> w.eq(ImCallRecordDO::getCallerId, userId)
                        .or()
                        .eq(ImCallRecordDO::getCalleeId, userId))
                .in(ImCallRecordDO::getState, "RINGING", "CONNECTING")
                .le(ImCallRecordDO::getStartTime, before)
                .set(ImCallRecordDO::getState, "ENDED")
                .set(ImCallRecordDO::getStatus, missedStatus)
                .set(ImCallRecordDO::getEndTime, endTime)
                .set(ImCallRecordDO::getDuration, 0)
                .set(ImCallRecordDO::getEndReason, "TIMEOUT");
        return update(null, wrapper);
    }

    /** 查询在指定时刻之前进入某状态的通话，用于服务端权威的超时回收。 */
    default List<ImCallRecordDO> selectByStateBefore(String state, LocalDateTime before) {
        LambdaQueryWrapper<ImCallRecordDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallRecordDO::getState, state);
        wrapper.le(ImCallRecordDO::getStartTime, before);
        return selectList(wrapper);
    }

    /**
     * 接听的数据库 CAS：同一通话只有一个 RINGING -> CONNECTED 可以成功。
     */
    default boolean acceptIfRinging(String callId, String deviceId, LocalDateTime acceptedAt, Integer answeredStatus) {
        LambdaUpdateWrapper<ImCallRecordDO> wrapper = new LambdaUpdateWrapper<>();
        wrapper.eq(ImCallRecordDO::getCallId, callId)
                .eq(ImCallRecordDO::getState, "RINGING")
                .set(ImCallRecordDO::getState, "CONNECTED")
                .set(ImCallRecordDO::getStatus, answeredStatus)
                .set(ImCallRecordDO::getStartTime, acceptedAt)
                .set(ImCallRecordDO::getAcceptedDeviceId, deviceId);
        return update(null, wrapper) == 1;
    }

    /**
     * 终态数据库 CAS。返回 false 表示已被另一设备/节点处理，无需重复推送。
     */
    default boolean endIfState(String callId, String expectedState, Integer status,
                               LocalDateTime endTime, Integer duration, String reason) {
        LambdaUpdateWrapper<ImCallRecordDO> wrapper = new LambdaUpdateWrapper<>();
        wrapper.eq(ImCallRecordDO::getCallId, callId)
                .eq(ImCallRecordDO::getState, expectedState)
                .set(ImCallRecordDO::getState, "ENDED")
                .set(ImCallRecordDO::getStatus, status)
                .set(ImCallRecordDO::getEndTime, endTime)
                .set(ImCallRecordDO::getDuration, duration)
                .set(ImCallRecordDO::getEndReason, reason);
        return update(null, wrapper) == 1;
    }

    default boolean transitionState(String callId, String expectedState, String targetState) {
        LambdaUpdateWrapper<ImCallRecordDO> wrapper = new LambdaUpdateWrapper<>();
        wrapper.eq(ImCallRecordDO::getCallId, callId)
                .eq(ImCallRecordDO::getState, expectedState)
                .set(ImCallRecordDO::getState, targetState);
        return update(null, wrapper) == 1;
    }

    /** 为同一通话分配严格递增的业务事件版本，避免群成员事件被 outbox 去重误吞。 */
    default int allocateNextStateVersion(String callId) {
        for (int attempt = 0; attempt < 8; attempt++) {
            ImCallRecordDO record = selectByCallId(callId);
            if (record == null) {
                return 0;
            }
            int current = record.getStateVersion() == null ? 0 : record.getStateVersion();
            int next = current + 1;
            LambdaUpdateWrapper<ImCallRecordDO> wrapper = new LambdaUpdateWrapper<>();
            wrapper.eq(ImCallRecordDO::getCallId, callId)
                    .eq(ImCallRecordDO::getStateVersion, current)
                    .set(ImCallRecordDO::getStateVersion, next);
            if (update(null, wrapper) == 1) {
                return next;
            }
        }
        throw new IllegalStateException("通话事件版本分配冲突: " + callId);
    }

}
