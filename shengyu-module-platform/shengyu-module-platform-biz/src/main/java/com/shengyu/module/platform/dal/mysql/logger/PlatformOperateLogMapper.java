package com.shengyu.module.platform.dal.mysql.logger;

import com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.logger.vo.operatelog.OperateLogExportReqVO;
import com.shengyu.module.platform.controller.platform.logger.vo.operatelog.OperateLogPageReqVO;
import com.shengyu.module.platform.dal.dataobject.logger.PlatformOperateLogDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

@Mapper
public interface PlatformOperateLogMapper extends BaseMapperX<PlatformOperateLogDO> {

    default PageResult<PlatformOperateLogDO> selectPage(OperateLogPageReqVO reqVO, Collection<Long> userIds) {
        LambdaQueryWrapperX<PlatformOperateLogDO> query = new LambdaQueryWrapperX<PlatformOperateLogDO>()
                .likeIfPresent(PlatformOperateLogDO::getModule, reqVO.getModule())
                .inIfPresent(PlatformOperateLogDO::getUserId, userIds)
                .eqIfPresent(PlatformOperateLogDO::getType, reqVO.getType())
                .betweenIfPresent(PlatformOperateLogDO::getStartTime, reqVO.getStartTime());
        if (Boolean.TRUE.equals(reqVO.getSuccess())) {
            query.eq(PlatformOperateLogDO::getResultCode, GlobalErrorCodeConstants.SUCCESS.getCode());
        } else if (Boolean.FALSE.equals(reqVO.getSuccess())) {
            query.gt(PlatformOperateLogDO::getResultCode, GlobalErrorCodeConstants.SUCCESS.getCode());
        }
        query.orderByDesc(PlatformOperateLogDO::getId); // 降序
        return selectPage(reqVO, query);
    }

    default List<PlatformOperateLogDO> selectList(OperateLogExportReqVO reqVO, Collection<Long> userIds) {
        LambdaQueryWrapperX<PlatformOperateLogDO> query = new LambdaQueryWrapperX<PlatformOperateLogDO>()
                .likeIfPresent(PlatformOperateLogDO::getModule, reqVO.getModule())
                .inIfPresent(PlatformOperateLogDO::getUserId, userIds)
                .eqIfPresent(PlatformOperateLogDO::getType, reqVO.getType())
                .betweenIfPresent(PlatformOperateLogDO::getStartTime, reqVO.getStartTime());
        if (Boolean.TRUE.equals(reqVO.getSuccess())) {
            query.eq(PlatformOperateLogDO::getResultCode, GlobalErrorCodeConstants.SUCCESS.getCode());
        } else if (Boolean.FALSE.equals(reqVO.getSuccess())) {
            query.gt(PlatformOperateLogDO::getResultCode, GlobalErrorCodeConstants.SUCCESS.getCode());
        }
        query.orderByDesc(PlatformOperateLogDO::getId); // 降序
        return selectList(query);
    }

}
