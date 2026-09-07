package com.shengyu.module.platform.controller.platform.apprelease.vo;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Schema(description = "平台管理后台 - 应用版本分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformAppReleasePageReqVO extends PageParam {

    @Schema(description = "应用标识", example = "yuxin")
    private String appKey;

    @Schema(description = "平台", example = "android")
    private String platform;

    @Schema(description = "渠道", example = "prod")
    private String channel;

    @Schema(description = "版本名", example = "1.0.4")
    private String versionName;

    @Schema(description = "更新类型", example = "FULL")
    private String updateType;

    @Schema(description = "状态", example = "PUBLISHED")
    private String status;

}
