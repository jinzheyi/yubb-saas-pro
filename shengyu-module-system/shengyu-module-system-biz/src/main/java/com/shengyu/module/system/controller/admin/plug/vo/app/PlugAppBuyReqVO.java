package com.shengyu.module.system.controller.admin.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import java.util.List;

@Schema(description = "管理后台 - 插件购买 Request VO")
@Data
public class PlugAppBuyReqVO {

    @Schema(description = "插件应用id", requiredMode = Schema.RequiredMode.REQUIRED, example = "14004")
    @NotNull(message = "应用插件id参数必传")
    private Long id;

    @Schema(description = "下单原因备注")
    private String note;

}
