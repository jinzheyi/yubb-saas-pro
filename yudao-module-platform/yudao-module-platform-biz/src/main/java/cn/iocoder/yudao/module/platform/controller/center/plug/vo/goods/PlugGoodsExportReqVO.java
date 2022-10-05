package cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods;

import lombok.*;

import java.util.*;
import io.swagger.annotations.*;
import org.springframework.format.annotation.DateTimeFormat;

import static cn.iocoder.yudao.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@ApiModel(value = "平台管理后台 - 插件商品 Excel 导出 Request VO", description = "参数和 PlugGoodsPageReqVO 是一致的")
@Data
public class PlugGoodsExportReqVO {

    @ApiModelProperty(value = "商品名称")
    private String goodsName;

    @ApiModelProperty(value = "商品条码")
    private String goodsSn;

    @ApiModelProperty(value = "状态 上下架")
    private Integer appStatus;

    @ApiModelProperty(value = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private Date[] createTime;

}
