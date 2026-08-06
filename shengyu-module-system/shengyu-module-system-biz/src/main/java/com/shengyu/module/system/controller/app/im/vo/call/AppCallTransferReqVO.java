package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - 通话转接 Request VO")
@Data
public class AppCallTransferReqVO {

    @Schema(description = "通话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123def456")
    @NotBlank(message = "通话ID不能为空")
    private String callId;

    @Schema(description = "目标用户ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "40003")
    @NotNull(message = "目标用户ID不能为空")
    private Long targetUserId;

    @Schema(description = "目标用户名称", example = "王五")
    private String targetUserName;
}
