package com.shengyu.module.system.controller.app.im.vo.badge;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "移动端 - IM 角标数据 Response")
@Data
public class AppImBadgeRespVO {

    @Schema(description = "总未读数", requiredMode = Schema.RequiredMode.REQUIRED)
    private Integer unreadCount;

    @Schema(description = "会话角标列表", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<AppImConversationBadgeRespVO> conversationBadges;

    @Schema(description = "菜单角标列表", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<AppImMenuBadgeRespVO> menuBadges;

}
