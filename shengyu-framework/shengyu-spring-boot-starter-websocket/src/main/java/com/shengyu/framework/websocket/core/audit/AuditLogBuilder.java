package com.shengyu.framework.websocket.core.audit;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * IM 审计日志传输对象
 * 用于在框架层和业务层之间传递审计日志数据
 *
 * @author 圣钰科技
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditLogBuilder {

    /**
     * 事件类型
     */
    private String eventType;

    /**
     * 事件名称
     */
    private String eventName;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 租户ID
     */
    private Long tenantId;

    /**
     * 设备ID
     */
    private String deviceId;

    /**
     * 设备类型
     */
    private Integer deviceType;

    /**
     * IP 地址
     */
    private String ipAddress;

    /**
     * 客户端信息
     */
    private String userAgent;

    /**
     * 详细信息（JSON 格式）
     */
    private String details;

    /**
     * 事件时间戳（毫秒）
     */
    private Long timestamp;

}
