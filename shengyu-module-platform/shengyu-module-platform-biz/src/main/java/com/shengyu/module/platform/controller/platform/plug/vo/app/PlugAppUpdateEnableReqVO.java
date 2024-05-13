package com.shengyu.module.platform.controller.platform.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 插件应用上下架 Request VO")
@Data
public class PlugAppUpdateEnableReqVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "12255")
    @NotNull(message = "id不能为空")
    private Long id;

    @Schema(description = "状态（0启用 1停用）平台端操作，停用后租户不能使用该插件", required = true)
    @NotNull(message = "是否停用状态不能为空")
    private Integer enable;

}
