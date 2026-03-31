package com.shengyu.module.system.dal.mysql.notify;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.framework.mybatis.core.query.QueryWrapperX;
import com.shengyu.module.system.controller.admin.notify.vo.message.NotifyMessageMyPageReqVO;
import com.shengyu.module.system.controller.admin.notify.vo.message.NotifyMessagePageReqVO;
import com.shengyu.module.system.dal.dataobject.notify.NotifyMessageDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

@Mapper
public interface NotifyMessageMapper extends BaseMapperX<NotifyMessageDO> {

    default PageResult<NotifyMessageDO> selectPage(NotifyMessagePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<NotifyMessageDO>()
                .eqIfPresent(NotifyMessageDO::getUserId, reqVO.getUserId())
                .eqIfPresent(NotifyMessageDO::getUserType, reqVO.getUserType())
                .likeIfPresent(NotifyMessageDO::getTemplateCode, reqVO.getTemplateCode())
                .eqIfPresent(NotifyMessageDO::getTemplateType, reqVO.getTemplateType())
                .betweenIfPresent(NotifyMessageDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(NotifyMessageDO::getCreateTime));
    }

    default PageResult<NotifyMessageDO> selectPage(NotifyMessageMyPageReqVO reqVO, Long userId, Integer userType) {
        return selectPage(reqVO, new LambdaQueryWrapperX<NotifyMessageDO>()
                .eqIfPresent(NotifyMessageDO::getReadStatus, reqVO.getReadStatus())
                .betweenIfPresent(NotifyMessageDO::getCreateTime, reqVO.getCreateTime())
                .eq(NotifyMessageDO::getUserId, userId)
                .eq(NotifyMessageDO::getUserType, userType)
                .orderByDesc(NotifyMessageDO::getCreateTime));
    }

    default int updateListRead(Collection<Long> ids, Long userId, Integer userType) {
        return update(new NotifyMessageDO().setReadStatus(true).setReadTime(LocalDateTime.now()),
                new LambdaQueryWrapperX<NotifyMessageDO>()
                        .in(NotifyMessageDO::getId, ids)
                        .eq(NotifyMessageDO::getUserId, userId)
                        .eq(NotifyMessageDO::getUserType, userType)
                        .eq(NotifyMessageDO::getReadStatus, false));
    }

    default int updateListRead(Long userId, Integer userType) {
        return update(new NotifyMessageDO().setReadStatus(true).setReadTime(LocalDateTime.now()),
                new LambdaQueryWrapperX<NotifyMessageDO>()
                        .eq(NotifyMessageDO::getUserId, userId)
                        .eq(NotifyMessageDO::getUserType, userType)
                        .eq(NotifyMessageDO::getReadStatus, false));
    }

    default List<NotifyMessageDO> selectUnreadListByUserIdAndUserType(Long userId, Integer userType, Integer size) {
        return selectList(new LambdaQueryWrapperX<NotifyMessageDO>() // 由于要使用 limitN 语句，所以只能用 QueryWrapperX
                .eq(NotifyMessageDO::getUserId, userId)
                .eq(NotifyMessageDO::getUserType, userType)
                .eq(NotifyMessageDO::getReadStatus, false)
                .orderByDesc(NotifyMessageDO::getCreateTime).last("LIMIT " + size));
    }

    default Long selectUnreadCountByUserIdAndUserType(Long userId, Integer userType) {
        return selectCount(new LambdaQueryWrapperX<NotifyMessageDO>()
                .eq(NotifyMessageDO::getReadStatus, false)
                .eq(NotifyMessageDO::getUserId, userId)
                .eq(NotifyMessageDO::getUserType, userType));
    }

}
