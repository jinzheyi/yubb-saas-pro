package cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods;

import lombok.*;

import java.math.BigDecimal;
import java.util.*;
import io.swagger.annotations.*;
import cn.iocoder.yudao.framework.common.pojo.PageParam;
import org.springframework.format.annotation.DateTimeFormat;

import static cn.iocoder.yudao.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@ApiModel("管理后台 - 应用商品分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class PlugGoodsPageReqVO extends PageParam {

    @ApiModelProperty(value = "应用名称")
    private String appName;

    @ApiModelProperty(value = "商品条码")
    private String appSn;

    @ApiModelProperty(value = "原价", example = "0")
    private BigDecimal[] appPrice;

    @ApiModelProperty(value = "售价", example = "0")
    private BigDecimal[] payPrice;

    @ApiModelProperty(value = "数量", example = "1")
    private Integer appNum;

    @ApiModelProperty(value = "状态 上下架")
    private Integer appStatus;

    @ApiModelProperty(value = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private Date[] createTime;

}
