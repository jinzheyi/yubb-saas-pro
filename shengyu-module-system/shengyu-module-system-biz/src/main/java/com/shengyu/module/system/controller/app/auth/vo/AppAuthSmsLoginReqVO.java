package com.shengyu.module.system.controller.app.auth.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;

/**
 * 移动端 - 短信验证码登录 Request VO
 * 
 * 与 Web 端的区别：
 * 1. 增加设备信息字段（deviceType、deviceId、clientVersion）
 * 2. 支持多端登录策略（同设备类型互踢，不同设备类型共存）
 *
 * @author 圣钰科技
 */
@Schema(description = "移动端 - 短信验证码登录 Request VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppAuthSmsLoginReqVO {

    @Schema(description = "手机号", requiredMode = Schema.RequiredMode.REQUIRED, example = "yudaoyuanma")
    @NotEmpty(message = "手机号不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String mobile;

    @Schema(description = "短信验证码", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotEmpty(message = "验证码不能为空")
    private String code;

    // ========== 设备信息相关（移动端特有） ==========

    @Schema(description = "设备类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "3")
    @NotNull(message = "设备类型不能为空")
    private Integer deviceType;

    @Schema(description = "设备ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1234567890-abcdef")
    @NotEmpty(message = "设备ID不能为空")
    private String deviceId;

    @Schema(description = "客户端版本", requiredMode = Schema.RequiredMode.REQUIRED, example = "1.0.0")
    @NotEmpty(message = "客户端版本不能为空")
    private String clientVersion;

}
