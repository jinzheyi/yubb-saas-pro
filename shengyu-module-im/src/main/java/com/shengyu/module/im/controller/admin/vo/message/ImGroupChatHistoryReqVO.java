package com.shengyu.module.im.controller.admin.vo.message;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 群聊历史消息 Request VO")
@Data
public class ImGroupChatHistoryReqVO {

    @Schema(description = "群组ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1001")
    @NotNull(message = "群组ID不能为空")
    private Long groupId;

    @Schema(description = "限制条数", example = "20")
    private Integer limit = 20;

    @Schema(description = "偏移量", example = "0")
    private Integer offset = 0;

}
