package com.shengyu.module.system.controller.app.im.vo.badge;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - IM 会话角标 Response")
@Data
public class AppImConversationBadgeRespVO {

    @Schema(description = "ChatID", requiredMode = Schema.RequiredMode.REQUIRED)
    private Long chatId;

    @Schema(description = "未读数", requiredMode = Schema.RequiredMode.REQUIRED)
    private Integer unreadCount;

}
