package cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item;

import lombok.*;
import java.util.*;
import io.swagger.annotations.*;
import javax.validation.constraints.*;

@ApiModel("管理后台 - 订单项更新 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class OrderItemUpdateReqVO extends OrderItemBaseVO {

    @ApiModelProperty(value = "订单项id", required = true)
    @NotNull(message = "订单项id不能为空")
    private Long id;

}
