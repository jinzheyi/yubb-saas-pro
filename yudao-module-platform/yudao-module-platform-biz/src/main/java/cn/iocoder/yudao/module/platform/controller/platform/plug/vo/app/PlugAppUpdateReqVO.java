package cn.iocoder.yudao.module.platform.controller.platform.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 插件应用更新 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugAppUpdateReqVO extends PlugAppBaseVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "12255")
    @NotNull(message = "id不能为空")
    private Long id;

    @Schema(description = "概要描述")
    private String outline;

    @Schema(description = "描述", example = "你猜")
    private String description;

}
