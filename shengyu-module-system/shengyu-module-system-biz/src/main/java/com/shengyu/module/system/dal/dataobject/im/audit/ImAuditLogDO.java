package com.shengyu.module.system.dal.dataobject.im.audit;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

/**
 * IM 审计日志 DO
 * 等保三级合规要求：记录所有安全相关操作
 *
 * @author 圣钰科技
 */
@TableName("im_audit_log")
@KeySequence("im_audit_log_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImAuditLogDO extends BaseDO {

    /**
     * 主键
     */
    @TableId
    private Long id;

    /**
     * 租户编号
     */
    private Long tenantId;

    /**
     * 用户编号
     */
    private Long userId;

    /**
     * 事件类型
     */
    private String eventType;

    /**
     * 事件名称
     */
    private String eventName;

    /**
     * 设备 ID
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
     * 详细信息 (JSON)
     */
    private String details;

    /**
     * 事件时间戳（毫秒）
     */
    private Long timestamp;

}
