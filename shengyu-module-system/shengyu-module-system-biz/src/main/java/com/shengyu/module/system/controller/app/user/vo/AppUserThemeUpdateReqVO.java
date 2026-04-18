package com.shengyu.module.system.controller.app.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

@Schema(description = "移动端 - 用户主题偏好更新 Request VO")
@Data
public class AppUserThemeUpdateReqVO {

    @Schema(description = "主题模式", requiredMode = Schema.RequiredMode.REQUIRED, example = "dark")
    @NotBlank(message = "主题模式不能为空")
    @Pattern(regexp = "light|dark|system", message = "主题模式不合法")
    private String themeMode;

}
