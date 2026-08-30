package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - 创建通话邀请 Request VO")
@Data
public class AppCallCreateInviteReqVO {

    @Schema(description = "会话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "30001")
    @NotBlank(message = "会话ID不能为空")
    private String chatId;

    @Schema(description = "通话类型：audio-语音 video-视频", requiredMode = Schema.RequiredMode.REQUIRED, example = "video")
    @NotBlank(message = "通话类型不能为空")
    private String callType;

    @Schema(description = "被叫方ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "40002")
    @NotNull(message = "被叫方ID不能为空")
    private Long calleeId;

    @Schema(description = "发起设备的稳定标识", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "发起设备ID不能为空")
    private String deviceId;
}
