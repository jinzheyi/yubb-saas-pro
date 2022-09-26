package cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods;

import cn.iocoder.yudao.framework.common.pojo.PageParam;
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import org.springframework.format.annotation.DateTimeFormat;

import java.math.BigDecimal;
import java.util.Date;

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

    @ApiModelProperty(value = "创建时间", example = "[2022-07-01 00:00:00,2022-07-01 23:59:59]")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private Date[] createTime;

}
