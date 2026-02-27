package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import org.apache.ibatis.annotations.Mapper;

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

}
