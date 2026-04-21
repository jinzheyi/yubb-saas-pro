package com.shengyu.module.system.controller.admin.auth.vo;

import com.shengyu.framework.common.validation.InEnum;
import com.shengyu.framework.common.validation.Mobile;
import com.shengyu.framework.common.enums.sms.SmsSceneEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 发送手机验证码 Request VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthSmsSendReqVO {

    @Schema(description = "手机号", requiredMode = Schema.RequiredMode.REQUIRED, example = "shengyuyuanma")
    @NotEmpty(message = "{validation.auth.mobile.required}")
    @Mobile
    private String mobile;

    @Schema(description = "短信场景", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "{validation.auth.sms_scene.required}")
    @InEnum(SmsSceneEnum.class)
    private Integer scene;

}
