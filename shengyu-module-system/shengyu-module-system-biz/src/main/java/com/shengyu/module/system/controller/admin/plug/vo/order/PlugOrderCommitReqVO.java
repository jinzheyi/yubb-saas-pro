package com.shengyu.module.system.controller.admin.plug.vo.order;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 插件订单重提审核 Request VO")
@Data
public class PlugOrderCommitReqVO {

    @Schema(description = "插件订单id", requiredMode = Schema.RequiredMode.REQUIRED, example = "14004")
    @NotNull(message = "插件订单id参数必传")
    private Long id;

    @Schema(description = "重提审核原因备注")
    private String note;

}
