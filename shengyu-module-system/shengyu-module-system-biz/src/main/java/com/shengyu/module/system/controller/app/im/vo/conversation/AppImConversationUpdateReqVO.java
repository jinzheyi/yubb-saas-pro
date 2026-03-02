package com.shengyu.module.system.controller.app.im.vo.conversation;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 会话更新 Request VO")
@Data
public class AppImConversationUpdateReqVO {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "ChatID不能为空")
    private Long chatId;

    @Schema(description = "是否置顶", example = "true")
    private Boolean isPinned;

    @Schema(description = "是否免打扰", example = "true")
    private Boolean noDisturb;

}
