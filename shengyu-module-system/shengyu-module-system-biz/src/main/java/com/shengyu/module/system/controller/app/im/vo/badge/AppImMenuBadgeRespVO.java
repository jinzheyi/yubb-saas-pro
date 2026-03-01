package com.shengyu.module.system.controller.app.im.vo.badge;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - IM 菜单角标 Response")
@Data
public class AppImMenuBadgeRespVO {

    @Schema(description = "菜单 ID", requiredMode = Schema.RequiredMode.REQUIRED)
    private String menuId;

    @Schema(description = "角标数量", requiredMode = Schema.RequiredMode.REQUIRED)
    private Integer badgeCount;

}
