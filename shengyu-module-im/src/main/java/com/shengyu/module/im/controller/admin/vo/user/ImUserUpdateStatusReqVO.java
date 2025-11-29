package com.shengyu.module.im.controller.admin.vo.user;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 用户在线状态更新 Request VO")
@Data
public class ImUserUpdateStatusReqVO {

    @Schema(description = "在线状态：0-离线，1-在线，2-忙碌，3-离开", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "在线状态不能为空")
    private Integer onlineStatus;

}
