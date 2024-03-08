package cn.iocoder.yudao.module.platform.controller.platform.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import javax.validation.constraints.NotBlank;

@Schema(description = "管理后台 - 插件应用创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugAppCreateReqVO extends PlugAppBaseVO {

    //TODO 插件业务编码可以后台把枚举类转数组传到页面上，添加时选择传递
    @Schema(description = "插件业务编码")
    @NotBlank(message = "插件应用业务编码不能为空")
    private String appSn;

    @Schema(description = "概要描述")
    @NotBlank(message = "概要描述不能为空")
    private String outline;

    @Schema(description = "描述", example = "你猜")
    private String description;

}
