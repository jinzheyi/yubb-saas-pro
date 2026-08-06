package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - 媒体状态更新 Request VO")
@Data
public class AppCallMediaStateReqVO {

    @Schema(description = "通话会话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123def456")
    @NotBlank(message = "通话会话ID不能为空")
    private String callSessionId;

    @Schema(description = "摄像头是否开启", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    @NotNull(message = "摄像头状态不能为空")
    private Boolean cameraEnabled;

    @Schema(description = "麦克风是否开启", requiredMode = Schema.RequiredMode.REQUIRED, example = "true")
    @NotNull(message = "麦克风状态不能为空")
    private Boolean microphoneEnabled;
}
