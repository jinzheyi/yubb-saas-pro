package com.shengyu.module.system.service.im.audit;

import com.shengyu.framework.websocket.core.audit.AuditLogBuilder;
import com.shengyu.framework.websocket.core.session.AuditLogPublisher;
import com.shengyu.module.system.service.im.ImAuditLogService;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * IM 审计日志发布器实现
 * 将框架层的审计日志事件转发到 ImAuditLogService
 *
 * @author 圣钰科技
 */
@Component
public class ImAuditLogPublisher implements AuditLogPublisher {

    @Resource
    private ImAuditLogService imAuditLogService;

    @Override
    public void publish(AuditLogBuilder builder) {
        imAuditLogService.logAsync(builder);
    }
}
