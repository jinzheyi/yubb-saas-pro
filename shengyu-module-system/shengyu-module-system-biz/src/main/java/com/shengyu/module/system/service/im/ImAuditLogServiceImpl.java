package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.websocket.core.audit.AuditLogBuilder;
import com.shengyu.module.system.controller.admin.im.vo.auditlog.AuditLogPageReqVO;
import com.shengyu.module.system.dal.dataobject.im.audit.ImAuditLogDO;
import com.shengyu.module.system.dal.mysql.im.audit.ImAuditLogMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * IM 审计日志 Service 实现类
 * 等保三级合规要求：记录所有安全相关操作
 *
 * @author 圣钰科技
 */
@Service
@Validated
@Slf4j
public class ImAuditLogServiceImpl implements ImAuditLogService {

    /**
     * 审计日志保留天数
     * 超过该天数的日志会被自动清理
     */
    private static final int AUDIT_LOG_RETAIN_DAYS = 180;

    @Resource
    private ImAuditLogMapper imAuditLogMapper;

    @Override
    @Async
    public void logAsync(AuditLogBuilder builder) {
        try {
            ImAuditLogDO auditLog = ImAuditLogDO.builder()
                    .tenantId(builder.getTenantId())
                    .userId(builder.getUserId())
                    .eventType(builder.getEventType())
                    .eventName(builder.getEventName())
                    .deviceId(builder.getDeviceId())
                    .deviceType(builder.getDeviceType())
                    .ipAddress(builder.getIpAddress())
                    .userAgent(builder.getUserAgent())
                    .details(truncateDetails(builder.getDetails()))
                    .timestamp(builder.getTimestamp())
                    .build();
            imAuditLogMapper.insert(auditLog);
        } catch (Exception e) {
            // 审计日志写入失败不应影响业务，仅记录错误日志
            log.error("[ImAuditLogService] 异步写入审计日志失败, eventType: {}, userId: {}",
                    builder.getEventType(), builder.getUserId(), e);
        }
    }

    @Override
    public PageResult<ImAuditLogDO> getAuditLogPage(AuditLogPageReqVO reqVO) {
        return imAuditLogMapper.selectPage(reqVO);
    }

    @Override
    public ImAuditLogDO getAuditLog(Long id) {
        return imAuditLogMapper.selectById(id);
    }

    /**
     * 截断详细信息，避免数据库字段过长
     */
    private static String truncateDetails(String details) {
        if (StrUtil.isBlank(details)) {
            return details;
        }
        if (details.length() > 4000) {
            return details.substring(0, 4000);
        }
        return details;
    }
}
