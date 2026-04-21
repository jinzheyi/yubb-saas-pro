package com.shengyu.module.system.controller.app.auth.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.Length;

import javax.validation.constraints.Email;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * 移动端 - 账号密码登录 Request VO
 * 
 * 与 Web 端的区别：
 * 1. 增加设备信息字段（deviceType、deviceId、clientVersion）
 * 2. 支持多端登录策略（同设备类型互踢，不同设备类型共存）
 *
 * @author 圣钰科技
 */
@Schema(description = "移动端 - 账号密码登录 Request VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppAuthLoginReqVO {

    @Schema(description = "邮箱账号", requiredMode = Schema.RequiredMode.REQUIRED, example = "jin_zheyicn@qq.com")
    @NotEmpty(message = "{validation.auth.username.required}")
    @Email(message = "{validation.auth.username.email}")
    @Size(max = 50, message = "{validation.auth.username.max}")
    private String username;

    @Schema(description = "密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "buzhidao")
    @NotEmpty(message = "{validation.auth.password.required}")
    @Length(min = 4, max = 50, message = "{validation.auth.password.length}")
    private String password;

    // ========== 图片验证码相关 ==========

    @Schema(description = "验证码，验证码开启时，需要传递", example = "PfcH6mgr8tpXuMWFjvW6YVaqrswIuwmWI5dsVZSg7sGpWtDCUbHuDEXl3cFB1+VvCC/rAkSwK8Fad52FSuncVg==")
    private String captchaVerification;

    // ========== 设备信息相关（移动端特有） ==========

    @Schema(description = "设备类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "3")
    @NotNull(message = "{validation.auth.device_type.required}")
    private Integer deviceType;

    @Schema(description = "设备ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1234567890-abcdef")
    @NotEmpty(message = "{validation.auth.device_id.required}")
    private String deviceId;

    @Schema(description = "客户端版本", requiredMode = Schema.RequiredMode.REQUIRED, example = "1.0.0")
    @NotEmpty(message = "{validation.auth.client_version.required}")
    private String clientVersion;

}
