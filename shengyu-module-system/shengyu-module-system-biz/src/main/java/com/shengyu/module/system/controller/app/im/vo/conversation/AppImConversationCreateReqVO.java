package com.shengyu.module.system.controller.app.im.vo.conversation;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import jakarta.validation.constraints.NotNull;

@Schema(description = "移动端 - IM 会话创建 Request VO")
@Data
public class AppImConversationCreateReqVO {

    @Schema(description = "目标ID(单聊为对方用户ID,群聊为群ID)", requiredMode = Schema.RequiredMode.REQUIRED, example = "100")
    @NotNull(message = "目标ID不能为空")
    private Long targetId;

    @Schema(description = "会话类型(1-单聊 2-群聊)", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "会话类型不能为空")
    private Integer conversationType;

}
