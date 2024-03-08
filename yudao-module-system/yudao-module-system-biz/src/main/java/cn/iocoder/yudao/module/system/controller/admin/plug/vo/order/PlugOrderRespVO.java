package cn.iocoder.yudao.module.system.controller.admin.plug.vo.order;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import java.time.LocalDateTime;

@Schema(description = "管理后台 - 插件订单 Response VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderRespVO extends PlugOrderBaseVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "14004")
    private Long id;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
