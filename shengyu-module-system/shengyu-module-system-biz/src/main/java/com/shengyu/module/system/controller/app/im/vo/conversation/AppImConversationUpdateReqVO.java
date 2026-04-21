package com.shengyu.module.system.controller.app.im.vo.conversation;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.AssertTrue;
import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 会话更新 Request VO")
@Data
public class AppImConversationUpdateReqVO {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "{validation.im.chat_id.required}")
    private Long chatId;

    @Schema(description = "是否置顶", example = "true")
    private Boolean isPinned;

    @Schema(description = "是否免打扰", example = "true")
    private Boolean noDisturb;

    @AssertTrue(message = "{validation.im.conversation_update.required}")
    public boolean isAnySettingPresent() {
        return isPinned != null || noDisturb != null;
    }

}
