package cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods;

import lombok.*;
import java.math.BigDecimal;
import io.swagger.annotations.*;
import javax.validation.constraints.*;

/**
* 应用商品 Base VO，提供给添加、修改、详细的子 VO 使用
* 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
*/
@Data
public class PlugGoodsBaseVO {

    @ApiModelProperty(value = "商品图片", required = true)
    @NotNull(message = "商品图片不能为空")
    private String goodsPic;

    @ApiModelProperty(value = "商品名称", required = true)
    @NotNull(message = "商品名称不能为空")
    private String goodsName;

    @ApiModelProperty(value = "商品条码", required = true)
    @NotNull(message = "商品条码不能为空")
    private String goodsSn;

    @ApiModelProperty(value = "原价", required = true, example = "0")
    @NotNull(message = "原价不能为空")
    private BigDecimal goodsPrice;

    @ApiModelProperty(value = "售价", required = true, example = "0")
    @NotNull(message = "售价不能为空")
    private BigDecimal payPrice;

    @ApiModelProperty(value = "状态 上下架", required = true)
    @NotNull(message = "状态 上下架不能为空")
    private Integer appStatus;

}
