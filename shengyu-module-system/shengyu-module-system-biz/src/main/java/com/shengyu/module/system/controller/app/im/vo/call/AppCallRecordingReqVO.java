package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;

@Schema(description = "移动端 - 通话录制 Request VO")
@Data
public class AppCallRecordingReqVO {

    @Schema(description = "通话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123def456")
    @NotBlank(message = "通话ID不能为空")
    private String callId;

    @Schema(description = "录制文件路径（停止录制时使用）", example = "/path/to/recording.mp3")
    private String recordingFilePath;
}
