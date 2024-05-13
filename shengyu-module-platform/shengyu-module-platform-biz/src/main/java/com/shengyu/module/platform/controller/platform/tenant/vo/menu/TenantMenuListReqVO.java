package com.shengyu.module.platform.controller.platform.tenant.vo.menu;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Schema(description = "管理后台 - 菜单列表 Request VO")
@Data
public class TenantMenuListReqVO {

    @Schema(description = "菜单名称,模糊匹配", example = "芋道")
    private String name;

    @Schema(description = "展示状态,参见 CommonStatusEnum 枚举类", example = "1")
    private Integer status;

    @Schema(description = "菜单维度,参见 CommonConstants.MenuDimensionEnum 枚举类", example = "0")
    private Integer dimension;

    @Schema(description = "应用插件编码", example = "圣钰SaaS")
    private String plugAppSn;

    @Schema(description = "应用插件id数组", example = "圣钰SaaS")
    private List<Long> plugIds;

    @Schema(description = "应用插件编码数组", example = "圣钰SaaS")
    private List<String> plugAppSns;

    @Schema(description = "菜单id数组", example = "圣钰SaaS")
    private List<Long> ids;

}
