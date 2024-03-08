package cn.iocoder.yudao.module.system.controller.admin.plug.vo.orderitem;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - 订单项 Response VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderItemRespVO extends PlugOrderItemBaseVO {

    @Schema(description = "订单项id", requiredMode = Schema.RequiredMode.REQUIRED, example = "6002")
    private Long id;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

    @Schema(description = "应用图片")
    private String appPic;

    @Schema(description = "应用名称", example = "赵六")
    private String appName;

    @Schema(description = "应用条码")
    private String appSn;

}
