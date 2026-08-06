package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;
import java.util.List;

/**
 * IM 通话参与者 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImCallParticipantMapper extends BaseMapperX<ImCallParticipantDO> {

    /**
     * 根据通话ID查询所有参与者
     *
     * @param callId 通话ID
     * @return 参与者列表
     */
    default List<ImCallParticipantDO> selectByCallId(String callId) {
        LambdaQueryWrapper<ImCallParticipantDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallParticipantDO::getCallId, callId);
        wrapper.orderByAsc(ImCallParticipantDO::getJoinTime);
        return selectList(wrapper);
    }

    /**
     * 根据通话ID和用户ID查询参与者
     *
     * @param callId 通话ID
     * @param userId 用户ID
     * @return 参与者
     */
    default ImCallParticipantDO selectByCallIdAndUserId(String callId, Long userId) {
        LambdaQueryWrapper<ImCallParticipantDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallParticipantDO::getCallId, callId);
        wrapper.eq(ImCallParticipantDO::getUserId, userId);
        return selectOne(wrapper);
    }

    /**
     * 根据通话ID、用户ID和设备ID查询参与者
     *
     * @param callId 通话ID
     * @param userId 用户ID
     * @param deviceId 设备ID
     * @return 参与者
     */
    default ImCallParticipantDO selectByCallIdAndUserIdAndDeviceId(String callId, Long userId, String deviceId) {
        LambdaQueryWrapper<ImCallParticipantDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallParticipantDO::getCallId, callId);
        wrapper.eq(ImCallParticipantDO::getUserId, userId);
        wrapper.eq(ImCallParticipantDO::getDeviceId, deviceId);
        return selectOne(wrapper);
    }

    /**
     * 更新参与者状态
     *
     * @param callId 通话ID
     * @param userId 用户ID
     * @param status 状态
     * @return 更新数量
     */
    default int updateStatus(String callId, Long userId, Integer status) {
        LambdaUpdateWrapper<ImCallParticipantDO> wrapper = new LambdaUpdateWrapper<>();
        wrapper.eq(ImCallParticipantDO::getCallId, callId);
        wrapper.eq(ImCallParticipantDO::getUserId, userId);
        wrapper.set(ImCallParticipantDO::getStatus, status);
        
        // 如果状态变为已离开，设置离开时间
        if (status == 3) {
            wrapper.set(ImCallParticipantDO::getLeaveTime, LocalDateTime.now());
        }
        
        return update(null, wrapper);
    }

    /**
     * 根据通话ID删除所有参与者
     *
     * @param callId 通话ID
     * @return 删除数量
     */
    default int deleteByCallId(String callId) {
        LambdaQueryWrapper<ImCallParticipantDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallParticipantDO::getCallId, callId);
        return delete(wrapper);
    }

    /**
     * 查询用户当前正在参与的通话
     *
     * @param userId 用户ID
     * @param status 状态（1-在线）
     * @return 参与者列表
     */
    default List<ImCallParticipantDO> selectActiveByUserId(Long userId, Integer status) {
        LambdaQueryWrapper<ImCallParticipantDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallParticipantDO::getUserId, userId);
        wrapper.eq(ImCallParticipantDO::getStatus, status);
        return selectList(wrapper);
    }
}
