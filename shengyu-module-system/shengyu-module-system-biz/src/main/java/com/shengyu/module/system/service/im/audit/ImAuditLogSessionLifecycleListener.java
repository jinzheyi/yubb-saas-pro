package com.shengyu.module.system.service.im.audit;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.framework.websocket.core.audit.AuditLogBuilder;
import com.shengyu.framework.websocket.core.audit.AuditLogEvent;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionLifecycleListener;
import com.shengyu.module.system.service.im.ImAuditLogService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * IM 审计日志会话生命周期监听器
 * 将 Netty 会话生命周期事件写入审计日志，满足等保三级合规要求
 *
 * @author 圣钰科技
 */
@Component
@Slf4j
public class ImAuditLogSessionLifecycleListener implements NettySessionLifecycleListener {

    @Resource
    private ImAuditLogService imAuditLogService;

    @Override
    public void onSessionAdded(NettySession session) {
        if (session == null) {
            return;
        }
        runWithSessionTenant(session, () -> {
            // 记录认证成功事件
            logEvent(session, AuditLogEvent.AUTH_SUCCESS,
                    buildDetails("认证成功", session.getDeviceName(), session.getClientVersion()));

            // 记录设备登录事件
            logEvent(session, AuditLogEvent.DEVICE_LOGIN,
                    buildDetails("设备登录", session.getDeviceName(), session.getClientVersion()));
        });
    }

    @Override
    public void onSessionRemoved(NettySession session) {
        if (session == null) {
            return;
        }
        runWithSessionTenant(session, () -> {
            // 如果是租约过期导致的下线，记录 SESSION_EXPIRED
            if (session.isLeaseExpired()) {
                logEvent(session, AuditLogEvent.SESSION_EXPIRED,
                        buildDetails("会话过期", "租约到期", null));
            }
        });
    }

    /**
     * 记录审计日志事件
     */
    private void logEvent(NettySession session, AuditLogEvent event, String details) {
        try {
            AuditLogBuilder builder = AuditLogBuilder.builder()
                    .eventType(event.getType())
                    .eventName(event.getName())
                    .userId(session.getUserId())
                    .tenantId(session.getTenantId())
                    .deviceId(session.getDeviceId())
                    .deviceType(session.getDeviceType())
                    .userAgent(buildUserAgent(session))
                    .details(details)
                    .timestamp(System.currentTimeMillis())
                    .build();
            imAuditLogService.logAsync(builder);
        } catch (Exception e) {
            log.error("[AuditLogLifecycle] 记录审计日志失败, eventType: {}, userId: {}",
                    event.getType(), session.getUserId(), e);
        }
    }

    private String buildUserAgent(NettySession session) {
        StringBuilder sb = new StringBuilder();
        if (StrUtil.isNotBlank(session.getClientVersion())) {
            sb.append("ClientVersion: ").append(session.getClientVersion());
        }
        if (StrUtil.isNotBlank(session.getDeviceName())) {
            if (sb.length() > 0) {
                sb.append("; ");
            }
            sb.append("Device: ").append(session.getDeviceName());
        }
        if (StrUtil.isNotBlank(session.getLocale())) {
            if (sb.length() > 0) {
                sb.append("; ");
            }
            sb.append("Locale: ").append(session.getLocale());
        }
        return sb.length() > 0 ? sb.toString() : null;
    }

    private String buildDetails(String message, String deviceName, String clientVersion) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"message\":\"").append(message).append("\"");
        if (StrUtil.isNotBlank(deviceName)) {
            sb.append(",\"deviceName\":\"").append(deviceName).append("\"");
        }
        if (StrUtil.isNotBlank(clientVersion)) {
            sb.append(",\"clientVersion\":\"").append(clientVersion).append("\"");
        }
        sb.append("}");
        return sb.toString();
    }

    private void runWithSessionTenant(NettySession session, Runnable runnable) {
        if (session == null || runnable == null) {
            return;
        }
        Long tenantId = session.getTenantId();
        if (tenantId != null) {
            TenantUtils.execute(tenantId, runnable);
            return;
        }
        runnable.run();
    }
}
