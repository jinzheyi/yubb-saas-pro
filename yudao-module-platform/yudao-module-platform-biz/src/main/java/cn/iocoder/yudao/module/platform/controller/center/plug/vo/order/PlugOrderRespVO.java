package cn.iocoder.yudao.module.platform.controller.center.plug.vo.order;

import lombok.*;
import java.util.*;
import io.swagger.annotations.*;

@ApiModel("管理后台 - 订单 Response VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderRespVO extends PlugOrderBaseVO {

    @ApiModelProperty(value = "订单id", required = true)
    private Long id;

    @ApiModelProperty(value = "订单编号", required = true)
    private String orderNo;

    @ApiModelProperty(value = "支付金额，单位：钰豆", required = true)
    private BigDecimal totalAmount;

    @ApiModelProperty(value = "应付金额（实际支付金额）", required = true)
    private BigDecimal payAmount;

    @ApiModelProperty(value = "促销优化金额（促销价、满减、阶梯价）")
    private BigDecimal promotionAmount;

    @ApiModelProperty(value = "订单类型：0->正常订单；1->赠送订单", required = true)
    private Integer orderType;

    @ApiModelProperty(value = "订单状态 未付款,已付款,已安装", required = true)
    private Integer orderStatus;

    @ApiModelProperty(value = "用户 IP", required = true)
    private String userIp;

    @ApiModelProperty(value = "购买者编号", required = true)
    private Long userId;

    @ApiModelProperty(value = "订单失效时间", required = true)
    private Date expireTime;

    @ApiModelProperty(value = "订单支付成功时间")
    private Date successTime;

    @ApiModelProperty(value = "可以获得的积分")
    private Long integration;

    @ApiModelProperty(value = "可以活动的成长值")
    private Long growth;

    @ApiModelProperty(value = "创建时间", required = true)
    private Date createTime;

}
