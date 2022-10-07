package cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods;

import lombok.*;
import java.util.*;
import io.swagger.annotations.*;

@ApiModel("管理后台 - 应用商品 Response VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugGoodsRespVO extends PlugGoodsBaseVO {

    @ApiModelProperty(value = "编号", required = true)
    private Long id;

    @ApiModelProperty(value = "创建时间", required = true)
    private Date createTime;

    @ApiModelProperty(value = "商品概要")
    private String goodsOutline;

    @ApiModelProperty(value = "商品赠送积分", example = "0")
    private Long giftIntegration;

    @ApiModelProperty(value = "商品赠送成长值", example = "0")
    private Long giftGrowth;

    @ApiModelProperty(value = "商品祥情描述")
    private String appContents;

}
