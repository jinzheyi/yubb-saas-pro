package cn.iocoder.yudao.module.platform.controller.center.plug.vo.order;

import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item.OrderItemUpdateReqVO;
import lombok.*;
import io.swagger.annotations.*;

import javax.validation.Valid;
import javax.validation.constraints.*;
import java.util.List;

@ApiModel("管理后台 - 订单更新 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugOrderUpdateReqVO extends PlugOrderBaseVO {

    @ApiModelProperty(value = "订单id", required = true)
    @NotNull(message = "订单id不能为空")
    private Long id;

    @ApiModelProperty(value = "订单项")
    @Valid
    List<OrderItemUpdateReqVO> item;

}
