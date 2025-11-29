package com.shengyu.module.im.controller.admin.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 单聊历史消息 Request VO")
@Data
public class ImSingleChatHistoryReqVO {

    @Schema(description = "发送者ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotNull(message = "发送者ID不能为空")
    private Long senderId;

    @Schema(description = "接收者ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "2048")
    @NotNull(message = "接收者ID不能为空")
    private Long receiverId;

    @Schema(description = "限制条数", example = "20")
    private Integer limit = 20;

    @Schema(description = "偏移量", example = "0")
    private Integer offset = 0;

}
