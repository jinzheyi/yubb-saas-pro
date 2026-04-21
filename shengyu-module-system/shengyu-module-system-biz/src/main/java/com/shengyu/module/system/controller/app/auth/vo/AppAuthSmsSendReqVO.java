package com.shengyu.module.system.controller.app.auth.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.Pattern;

/**
 * 移动端 - 发送短信验证码 Request VO
 *
 * @author 圣钰科技
 */
@Schema(description = "移动端 - 发送短信验证码 Request VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppAuthSmsSendReqVO {

    @Schema(description = "手机号", requiredMode = Schema.RequiredMode.REQUIRED, example = "15601691300")
    @NotEmpty(message = "{validation.auth.mobile.required}")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "{validation.auth.mobile.invalid}")
    private String mobile;

    @Schema(description = "短信场景", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotEmpty(message = "{validation.auth.sms_scene.required}")
    private String scene;

}
