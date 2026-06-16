package com.shengyu.module.system.controller.admin.im.vo.auditlog;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - IM 审计日志 Response VO")
@Data
public class AuditLogRespVO {

    @Schema(description = "主键", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "租户编号", example = "1")
    private Long tenantId;

    @Schema(description = "用户编号", example = "1001")
    private Long userId;

    @Schema(description = "用户昵称", example = "张三")
    private String userNickname;

    @Schema(description = "事件类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "AUTH_SUCCESS")
    private String eventType;

    @Schema(description = "事件名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "认证成功")
    private String eventName;

    @Schema(description = "设备 ID", example = "device-001")
    private String deviceId;

    @Schema(description = "设备类型", example = "1")
    private Integer deviceType;

    @Schema(description = "IP 地址", example = "192.168.1.100")
    private String ipAddress;

    @Schema(description = "客户端信息", example = "Chrome/120.0.0.0")
    private String userAgent;

    @Schema(description = "详细信息 (JSON)")
    private String details;

    @Schema(description = "事件时间戳（毫秒）", requiredMode = Schema.RequiredMode.REQUIRED)
    private Long timestamp;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
