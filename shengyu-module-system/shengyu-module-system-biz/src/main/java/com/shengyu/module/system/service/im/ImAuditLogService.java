package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.websocket.core.audit.AuditLogBuilder;
import com.shengyu.module.system.controller.admin.im.vo.auditlog.AuditLogPageReqVO;
import com.shengyu.module.system.dal.dataobject.im.audit.ImAuditLogDO;

/**
 * IM 审计日志 Service 接口
 * 等保三级合规要求：记录所有安全相关操作
 *
 * @author 圣钰科技
 */
public interface ImAuditLogService {

    /**
     * 异步记录审计日志（不阻塞业务）
     *
     * @param log 审计日志数据
     */
    void logAsync(AuditLogBuilder log);

    /**
     * 查询审计日志分页列表（管理后台）
     *
     * @param reqVO 分页查询条件
     * @return 分页结果
     */
    PageResult<ImAuditLogDO> getAuditLogPage(AuditLogPageReqVO reqVO);

    /**
     * 根据 ID 查询审计日志详情
     *
     * @param id 日志编号
     * @return 审计日志
     */
    ImAuditLogDO getAuditLog(Long id);
}
