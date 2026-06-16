package com.shengyu.framework.websocket.core.session;

import com.shengyu.framework.websocket.core.audit.AuditLogBuilder;

/**
 * 审计日志发布器接口
 * 用于在框架层触发审计日志事件，由业务模块提供实现
 *
 * @author 圣钰科技
 */
@FunctionalInterface
public interface AuditLogPublisher {

    /**
     * 发布审计日志
     *
     * @param builder 审计日志数据
     */
    void publish(AuditLogBuilder builder);
}
