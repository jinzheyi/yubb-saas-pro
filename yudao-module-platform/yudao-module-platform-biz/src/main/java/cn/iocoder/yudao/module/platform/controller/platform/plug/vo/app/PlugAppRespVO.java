package cn.iocoder.yudao.module.platform.controller.platform.plug.vo.app;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - 插件应用 Response VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugAppRespVO extends PlugAppBaseVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "12255")
    private Long id;

    @Schema(description = "条码")
    private String appSn;

    /**
     * 状态（0上架 1下架）,影响的是租户不能下单购买
     *
     * 枚举 {@link CommonStatusEnum}
     */
    @Schema(description = "状态（0上架 1下架）,影响的是租户不能下单购买")
    private Integer status;
    /**
     * 状态（0启用 1停用）平台端操作，停用后租户不能使用该插件
     *
     * 枚举 {@link CommonStatusEnum}
     */
    @Schema(description = "状态（0启用 1停用）平台端操作，停用后租户不能使用该插件")
    private Integer enable;

    @Schema(description = "创建时间", required = true)
    private LocalDateTime createTime;

    @Schema(description = "概要描述")
    private String outline;

    @Schema(description = "描述", example = "你猜")
    private String description;

}
