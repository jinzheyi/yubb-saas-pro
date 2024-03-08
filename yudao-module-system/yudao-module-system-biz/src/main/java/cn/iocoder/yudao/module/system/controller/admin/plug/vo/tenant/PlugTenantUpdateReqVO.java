package cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 租户应用上下架 Request VO")
@Data
public class PlugTenantUpdateReqVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "30424")
    @NotNull(message = "id不能为空")
    private Long id;

    @Schema(description = "状态（0上架 1下架）", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "状态（0上架 1下架）不能为空")
    private Integer status;

}
