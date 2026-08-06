package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImCallEventDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM 通话事件 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImCallEventMapper extends BaseMapperX<ImCallEventDO> {

    /**
     * 根据通话ID查询事件列表
     *
     * @param callId 通话ID
     * @return 事件列表
     */
    default List<ImCallEventDO> selectByCallId(String callId) {
        LambdaQueryWrapper<ImCallEventDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallEventDO::getCallId, callId);
        wrapper.orderByAsc(ImCallEventDO::getCreateTime);
        return selectList(wrapper);
    }

    /**
     * 根据通话ID和事件ID查询事件（用于幂等性检查）
     *
     * @param callId 通话ID
     * @param eventId 事件ID
     * @return 事件
     */
    default ImCallEventDO selectByCallIdAndEventId(String callId, String eventId) {
        LambdaQueryWrapper<ImCallEventDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallEventDO::getCallId, callId);
        wrapper.eq(ImCallEventDO::getEventId, eventId);
        return selectOne(wrapper);
    }

    /**
     * 根据通话ID删除所有事件
     *
     * @param callId 通话ID
     * @return 删除数量
     */
    default int deleteByCallId(String callId) {
        LambdaQueryWrapper<ImCallEventDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImCallEventDO::getCallId, callId);
        return delete(wrapper);
    }

}
