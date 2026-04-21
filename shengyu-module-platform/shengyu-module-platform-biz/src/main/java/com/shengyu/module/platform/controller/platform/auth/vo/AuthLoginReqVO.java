package com.shengyu.module.platform.controller.platform.auth.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.Length;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.Pattern;

@Schema(description = "管理后台 - 账号密码登录 Request VO，如果登录并绑定社交用户，需要传递 social 开头的参数")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthLoginReqVO {

    @Schema(description = "账号", requiredMode = Schema.RequiredMode.REQUIRED, example = "shengyuyuanma")
    @NotEmpty(message = "{validation.auth.account.required}")
    @Length(min = 4, max = 16, message = "{validation.auth.account.length}")
    @Pattern(regexp = "^[A-Za-z0-9]+$", message = "{validation.auth.account.invalid}")
    private String username;

    @Schema(description = "密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "buzhidao")
    @NotEmpty(message = "{validation.auth.password.required}")
    @Length(min = 4, max = 50, message = "{validation.auth.password.length}")
    private String password;

    // ========== 图片验证码相关 ==========

    @Schema(description = "验证码，验证码开启时，需要传递", requiredMode = Schema.RequiredMode.REQUIRED,
            example = "PfcH6mgr8tpXuMWFjvW6YVaqrswIuwmWI5dsVZSg7sGpWtDCUbHuDEXl3cFB1+VvCC/rAkSwK8Fad52FSuncVg==")
    @NotEmpty(message = "{validation.auth.captcha.required}", groups = CodeEnableGroup.class)
    private String captchaVerification;

    /**
     * 开启验证码的 Group
     */
    public interface CodeEnableGroup {}

}
