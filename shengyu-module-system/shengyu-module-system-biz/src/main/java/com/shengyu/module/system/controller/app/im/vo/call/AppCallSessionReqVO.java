package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;

@Schema(description = "移动端 - 通话会话操作 Request VO")
@Data
public class AppCallSessionReqVO {

    @Schema(description = "通话会话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "abc123def456")
    @NotBlank(message = "通话会话ID不能为空")
    private String callSessionId;
}
