package cn.iocoder.yudao.module.platform.controller.center.plug.vo.order;

import lombok.*;
import java.util.*;
import io.swagger.annotations.*;
import javax.validation.constraints.*;
import org.springframework.format.annotation.DateTimeFormat;

import static cn.iocoder.yudao.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@ApiModel("管理后台 - 订单创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderCreateReqVO extends PlugOrderBaseVO {

    @ApiModelProperty(value = "订单编号", required = true)
    @NotNull(message = "订单编号不能为空")
    private String orderNo;

    @ApiModelProperty(value = "支付金额，单位：钰豆", required = true)
    @NotNull(message = "支付金额，单位：钰豆不能为空")
    private BigDecimal totalAmount;

    @ApiModelProperty(value = "应付金额（实际支付金额）", required = true)
    @NotNull(message = "应付金额（实际支付金额）不能为空")
    private BigDecimal payAmount;

    @ApiModelProperty(value = "促销优化金额（促销价、满减、阶梯价）")
    private BigDecimal promotionAmount;

    @ApiModelProperty(value = "订单类型：0->正常订单；1->赠送订单", required = true)
    @NotNull(message = "订单类型：0->正常订单；1->赠送订单不能为空")
    private Integer orderType;

    @ApiModelProperty(value = "订单状态 未付款,已付款,已安装", required = true)
    @NotNull(message = "订单状态 未付款,已付款,已安装不能为空")
    private Integer orderStatus;

    @ApiModelProperty(value = "用户 IP", required = true)
    @NotNull(message = "用户 IP不能为空")
    private String userIp;

    @ApiModelProperty(value = "购买者编号", required = true)
    @NotNull(message = "购买者编号不能为空")
    private Long userId;

    @ApiModelProperty(value = "订单失效时间", required = true)
    @NotNull(message = "订单失效时间不能为空")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private Date expireTime;

    @ApiModelProperty(value = "订单支付成功时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private Date successTime;

    @ApiModelProperty(value = "可以获得的积分")
    private Long integration;

    @ApiModelProperty(value = "可以活动的成长值")
    private Long growth;

}
