package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - 通话状态 Response VO")
@Data
public class AppCallStateRespVO {

    @Schema(description = "通话会话ID", example = "abc123def456")
    private String callSessionId;

    @Schema(description = "通话类型：audio-语音 video-视频", example = "video")
    private String callType;

    @Schema(description = "通话状态", example = "ringing")
    private String status;

    @Schema(description = "状态机状态", example = "connected")
    private String state;

    @Schema(description = "通话时长（秒）", example = "120")
    private Integer duration;
}
