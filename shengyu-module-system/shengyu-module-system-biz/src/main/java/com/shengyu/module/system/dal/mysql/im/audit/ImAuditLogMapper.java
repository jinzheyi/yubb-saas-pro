package com.shengyu.module.system.dal.mysql.im.audit;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.controller.admin.im.vo.auditlog.AuditLogPageReqVO;
import com.shengyu.module.system.dal.dataobject.im.audit.ImAuditLogDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * IM 审计日志 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImAuditLogMapper extends BaseMapperX<ImAuditLogDO> {

    /**
     * 审计日志分页查询
     *
     * @param reqVO 分页查询条件
     * @return 分页结果
     */
    default PageResult<ImAuditLogDO> selectPage(AuditLogPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ImAuditLogDO>()
                .eqIfPresent(ImAuditLogDO::getTenantId, reqVO.getTenantId())
                .eqIfPresent(ImAuditLogDO::getUserId, reqVO.getUserId())
                .eqIfPresent(ImAuditLogDO::getEventType, reqVO.getEventType())
                .eqIfPresent(ImAuditLogDO::getDeviceType, reqVO.getDeviceType())
                .likeIfPresent(ImAuditLogDO::getDeviceId, reqVO.getDeviceId())
                .betweenIfPresent(ImAuditLogDO::getTimestamp, reqVO.getTimestampBegin(), reqVO.getTimestampEnd())
                .orderByDesc(ImAuditLogDO::getTimestamp));
    }
}
