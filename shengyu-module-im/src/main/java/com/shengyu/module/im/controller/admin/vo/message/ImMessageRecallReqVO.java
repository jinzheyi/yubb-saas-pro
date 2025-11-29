package com.shengyu.module.im.controller.admin.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotEmpty;

@Schema(description = "管理后台 - 消息撤回 Request VO")
@Data
public class ImMessageRecallReqVO {

    @Schema(description = "消息ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "msg_1234567890")
    @NotEmpty(message = "消息ID不能为空")
    private String messageId;

}
