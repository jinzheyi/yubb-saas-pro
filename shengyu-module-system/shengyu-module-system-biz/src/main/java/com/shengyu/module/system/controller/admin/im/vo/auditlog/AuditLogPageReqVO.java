package com.shengyu.module.system.controller.admin.im.vo.auditlog;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "管理后台 - IM 审计日志分页列表 Request VO")
@Data
public class AuditLogPageReqVO extends PageParam {

    @Schema(description = "租户编号", example = "1")
    private Long tenantId;

    @Schema(description = "用户编号", example = "1001")
    private Long userId;

    @Schema(description = "事件类型", example = "AUTH_SUCCESS")
    private String eventType;

    @Schema(description = "设备类型", example = "1")
    private Integer deviceType;

    @Schema(description = "设备 ID", example = "device-001")
    private String deviceId;

    @Schema(description = "开始时间戳（毫秒）", example = "1704067200000")
    private Long timestampBegin;

    @Schema(description = "结束时间戳（毫秒）", example = "1704153600000")
    private Long timestampEnd;

}
