package com.shengyu.module.platform.controller.platform.apprelease.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

import javax.validation.constraints.NotNull;

@Schema(description = "平台管理后台 - 应用版本更新 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformAppReleaseUpdateReqVO extends PlatformAppReleaseBaseVO {

    @Schema(description = "编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "编号不能为空")
    private Long id;

}
