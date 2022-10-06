package cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item;

import lombok.*;
import java.util.*;
import java.math.BigDecimal;
import io.swagger.annotations.*;
import javax.validation.constraints.*;

/**
* 订单项 Base VO，提供给添加、修改、详细的子 VO 使用
* 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
*/
@Data
public class OrderItemBaseVO {

    @ApiModelProperty(value = "订单id", required = true)
    @NotNull(message = "订单id不能为空")
    private Long orderId;

    @ApiModelProperty(value = "商品id", required = true)
    @NotNull(message = "商品id不能为空")
    private Long goodsId;

    @ApiModelProperty(value = "商品图片")
    private String goodsPic;

    @ApiModelProperty(value = "商品名称")
    private String goodsName;

    @ApiModelProperty(value = "商品条码")
    private String goodsSn;

    @ApiModelProperty(value = "原单价")
    private BigDecimal goodsPrice;

    @ApiModelProperty(value = "购买可以使用的天数")
    private Integer payDay;

    @ApiModelProperty(value = "续期类型  0（永久）1（年）2（月）3（季）")
    private Integer renewalType;

    @ApiModelProperty(value = "促销优化金额（促销价、满减、阶梯价）")
    private BigDecimal promotionAmount;

    @ApiModelProperty(value = "管理员后台调整订单使用的折扣金额")
    private BigDecimal discountAmount;

    @ApiModelProperty(value = "商品赠送积分", required = true)
    @NotNull(message = "商品赠送积分不能为空")
    private Long giftIntegration;

    @ApiModelProperty(value = "商品赠送成长值", required = true)
    @NotNull(message = "商品赠送成长值不能为空")
    private Long giftGrowth;

}
