package com.shengyu.module.system.controller.app.im.vo.conversation;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import jakarta.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 会话更新 Request VO")
@Data
public class AppImConversationUpdateReqVO {

    @Schema(description = "会话ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "会话ID不能为空")
    private Long id;

    @Schema(description = "是否置顶", example = "true")
    private Boolean isPinned;

    @Schema(description = "是否免打扰", example = "true")
    private Boolean noDisturb;

}
