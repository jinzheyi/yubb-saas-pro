package cn.iocoder.yudao.module.system.controller.admin.plug.vo.order;

import cn.iocoder.yudao.module.system.controller.admin.plug.vo.orderitem.PlugOrderItemRespVO;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import java.time.LocalDateTime;
import java.util.List;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2023/4/15 17:21
 */
@Schema(description = "管理后台 - 插件订单 Response VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderDetailRespVO extends PlugOrderBaseVO {

    @Schema(description = "id", requiredMode = Schema.RequiredMode.REQUIRED, example = "14004")
    private Long id;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

    /**
     * 租户编号
     */
    @Schema(description = "租户编号", requiredMode = Schema.RequiredMode.REQUIRED)
    private Long tenantId;

    @Schema(description = "订单明细", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<PlugOrderItemRespVO> itemRespVOS;
}
