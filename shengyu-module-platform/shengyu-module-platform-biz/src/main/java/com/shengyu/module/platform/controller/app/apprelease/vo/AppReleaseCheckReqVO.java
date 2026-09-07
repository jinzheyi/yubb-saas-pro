package com.shengyu.module.platform.controller.app.apprelease.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - 应用版本检查 Request VO")
@Data
public class AppReleaseCheckReqVO {

    @Schema(description = "应用标识", requiredMode = Schema.RequiredMode.REQUIRED, example = "yuxin")
    @NotBlank(message = "应用标识不能为空")
    private String appKey;

    @Schema(description = "平台", requiredMode = Schema.RequiredMode.REQUIRED, example = "android")
    @NotBlank(message = "平台不能为空")
    private String platform;

    @Schema(description = "当前版本名", requiredMode = Schema.RequiredMode.REQUIRED, example = "1.0.3")
    @NotBlank(message = "版本名不能为空")
    private String versionName;

    @Schema(description = "当前构建号", requiredMode = Schema.RequiredMode.REQUIRED, example = "103")
    @NotNull(message = "构建号不能为空")
    @Min(value = 1, message = "构建号必须大于 0")
    private Integer versionCode;

    @Schema(description = "渠道", example = "prod")
    private String channel;

}
