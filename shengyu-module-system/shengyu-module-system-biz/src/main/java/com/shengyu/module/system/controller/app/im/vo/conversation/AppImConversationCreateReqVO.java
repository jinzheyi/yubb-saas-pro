package com.shengyu.module.system.controller.app.im.vo.conversation;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 会话创建 Request VO")
@Data
public class AppImConversationCreateReqVO {

    @Schema(description = "目标ID(单聊为对方用户ID,群聊为群ID)", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
    @NotNull(message = "{validation.im.target_id.required}")
    private Long targetId;

    @Schema(description = "会话类型(1-单聊 2-群聊)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "{validation.im.conversation_type.required}")
    private Integer conversationType;

}
