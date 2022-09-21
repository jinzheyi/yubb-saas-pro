package cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods;

import lombok.*;
import io.swagger.annotations.*;

@ApiModel("管理后台 - 应用商品创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugGoodsCreateReqVO extends PlugGoodsBaseVO {

    @ApiModelProperty(value = "应用概要")
    private String appOutline;

    @ApiModelProperty(value = "商品赠送积分", example = "0")
    private Long giftIntegration;

    @ApiModelProperty(value = "商品赠送成长值", example = "0")
    private Long giftGrowth;

    @ApiModelProperty(value = "应用业务信息")
    private String appInfo;

    @ApiModelProperty(value = "商品祥情描述")
    private String appContents;

}
