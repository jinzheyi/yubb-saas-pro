package com.shengyu.module.platform.controller.platform.apprelease.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Schema(description = "平台管理后台 - 应用版本创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformAppReleaseCreateReqVO extends PlatformAppReleaseBaseVO {
}
