package cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item;

import lombok.*;
import java.util.*;
import io.swagger.annotations.*;

@ApiModel("管理后台 - 订单项 Response VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class OrderItemRespVO extends OrderItemBaseVO {

    @ApiModelProperty(value = "订单项id", required = true)
    private Long id;

    @ApiModelProperty(value = "创建时间", required = true)
    private Date createTime;

}
