package com.shengyu.module.system.controller.app.im.vo.device;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "移动端 - IM 登录设备 Response VO")
@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LoginDeviceRespVO {

    @Schema(description = "设备类型(1-Web 2-iOS 3-Android 4-小程序)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer deviceType;

    @Schema(description = "设备类型名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "Web")
    private String deviceTypeName;

    @Schema(description = "设备ID", example = "device-abc123")
    private String deviceId;

    @Schema(description = "设备名称", example = "Chrome 浏览器")
    private String deviceName;

    @Schema(description = "登录时间戳（毫秒）", example = "1776466200000")
    private Long loginTime;

    @Schema(description = "最后业务活跃时间戳（毫秒）", example = "1776466200000")
    private Long lastActiveTime;

    @Schema(description = "是否活跃", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    private Boolean isActive;
}
