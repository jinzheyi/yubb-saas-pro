package cn.iocoder.yudao.module.platform.controller.platform.plug.vo.order;

import cn.iocoder.yudao.framework.common.enums.CommonConstants;
import cn.iocoder.yudao.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static cn.iocoder.yudao.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - 插件订单分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderPageReqVO extends PageParam {

    @Schema(description = "订单编号")
    private String orderNo;

    /**
     * 订单状态 0：待审核,1：审核通过,2：审核不通过
     *
     * 枚举 {@link CommonConstants.PlugOrderStatusEnum}
     */
    @Schema(description = "订单状态 0：待审核,1：通过,2：不通过, 3:拒绝。 CommonConstants.PlugOrderStatusEnum", example = "2")
    private Integer orderStatus;

    @Schema(description = "多租户编号", example = "17933")
    private Long tenantId;

    @Schema(description = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] createTime;

}
