package com.shengyu.module.system.controller.app.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

@Schema(description = "移动端 - 用户聊天气泡偏好更新 Request VO")
@Data
public class AppUserChatBubbleUpdateReqVO {

    @Schema(description = "聊天气泡颜色", requiredMode = Schema.RequiredMode.REQUIRED, example = "#D2E3FC")
    @NotBlank(message = "聊天气泡颜色不能为空")
    @Pattern(regexp = "#[0-9A-Fa-f]{6}", message = "聊天气泡颜色格式不合法")
    private String chatBubbleColor;

    @Schema(description = "聊天气泡模式", requiredMode = Schema.RequiredMode.REQUIRED, example = "preset")
    @NotBlank(message = "聊天气泡模式不能为空")
    @Pattern(regexp = "preset|custom", message = "聊天气泡模式不合法")
    private String chatBubbleMode;

}
