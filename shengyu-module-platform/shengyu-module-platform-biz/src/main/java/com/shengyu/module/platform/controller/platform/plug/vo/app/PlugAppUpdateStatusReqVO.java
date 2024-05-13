package com.shengyu.module.platform.controller.platform.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 插件应用上下架 Request VO")
@Data
public class PlugAppUpdateStatusReqVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "12255")
    @NotNull(message = "id不能为空")
    private Long id;

    @Schema(description = "状态（0上架 1下架）见 CommonStatusEnum 枚举,影响的是租户不能下单购买", required = true)
    @NotNull(message = "上下架状态不能为空")
    private Integer status;

}
