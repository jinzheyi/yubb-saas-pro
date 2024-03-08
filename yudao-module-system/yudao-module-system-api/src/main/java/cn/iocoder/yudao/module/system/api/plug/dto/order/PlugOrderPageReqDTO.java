package cn.iocoder.yudao.module.system.api.plug.dto.order;

import cn.iocoder.yudao.framework.common.enums.CommonConstants;
import cn.iocoder.yudao.framework.common.pojo.PageParam;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static cn.iocoder.yudao.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderPageReqDTO extends PageParam {

    /**
     * 订单编号
     */
    private String orderNo;

    /**
     * 订单状态 0：待审核,1：审核通过,2：审核不通过
     *
     * 枚举 {@link CommonConstants.PlugOrderStatusEnum}
     */
    private Integer orderStatus;

    /**
     * 多租户编号
     */
    private Long tenantId;

    /**
     * 创建时间
     */
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] createTime;

}
