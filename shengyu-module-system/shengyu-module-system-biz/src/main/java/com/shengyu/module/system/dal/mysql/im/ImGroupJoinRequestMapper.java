package com.shengyu.module.system.dal.mysql.im;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImGroupJoinRequestDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collections;
import java.util.List;

@Mapper
public interface ImGroupJoinRequestMapper extends BaseMapperX<ImGroupJoinRequestDO> {

    default ImGroupJoinRequestDO selectPendingByGroupIdAndApplicantUserId(Long groupId, Long applicantUserId) {
        return selectOne(new LambdaQueryWrapper<ImGroupJoinRequestDO>()
                .eq(ImGroupJoinRequestDO::getGroupId, groupId)
                .eq(ImGroupJoinRequestDO::getApplicantUserId, applicantUserId)
                .eq(ImGroupJoinRequestDO::getStatus, 1)
                .orderByDesc(ImGroupJoinRequestDO::getCreateTime)
                .last("LIMIT 1"));
    }

    default List<ImGroupJoinRequestDO> selectListByGroupIdAndStatus(Long groupId, Integer status) {
        LambdaQueryWrapper<ImGroupJoinRequestDO> wrapper = new LambdaQueryWrapper<ImGroupJoinRequestDO>()
                .eq(ImGroupJoinRequestDO::getGroupId, groupId)
                .orderByAsc(ImGroupJoinRequestDO::getStatus)
                .orderByDesc(ImGroupJoinRequestDO::getCreateTime);
        if (status != null) {
            wrapper.eq(ImGroupJoinRequestDO::getStatus, status);
        }
        return selectList(wrapper);
    }

    default Long selectPendingCountByGroupId(Long groupId) {
        return selectCount(new LambdaQueryWrapper<ImGroupJoinRequestDO>()
                .eq(ImGroupJoinRequestDO::getGroupId, groupId)
                .eq(ImGroupJoinRequestDO::getStatus, 1));
    }

    default Long selectPendingCountByGroupIds(List<Long> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return 0L;
        }
        return selectCount(new LambdaQueryWrapper<ImGroupJoinRequestDO>()
                .in(ImGroupJoinRequestDO::getGroupId, groupIds)
                .eq(ImGroupJoinRequestDO::getStatus, 1));
    }
}
