package cn.iocoder.yudao.module.platform.controller.center.plug.vo.order;

import lombok.*;

import java.math.BigDecimal;
import java.util.*;
import io.swagger.annotations.*;
import cn.iocoder.yudao.framework.common.pojo.PageParam;
import org.springframework.format.annotation.DateTimeFormat;

import static cn.iocoder.yudao.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@ApiModel("管理后台 - 订单分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderPageReqVO extends PageParam {

    @ApiModelProperty(value = "订单编号")
    private String orderNo;

    @ApiModelProperty(value = "订单类型")
    private Integer orderType;

    @ApiModelProperty(value = "订单状态")
    private Integer orderStatus;

    @ApiModelProperty(value = "订单失效时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private Date[] expireTime;

    @ApiModelProperty(value = "订单支付成功时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private Date[] successTime;

    @ApiModelProperty(value = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private Date[] createTime;

}
