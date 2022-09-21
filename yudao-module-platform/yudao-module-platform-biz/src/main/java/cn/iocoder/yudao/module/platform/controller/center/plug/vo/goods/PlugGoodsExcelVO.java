package cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods;

import lombok.*;
import java.util.*;
import java.math.BigDecimal;
import io.swagger.annotations.*;

import com.alibaba.excel.annotation.ExcelProperty;
import cn.iocoder.yudao.framework.excel.core.annotations.DictFormat;
import cn.iocoder.yudao.framework.excel.core.convert.DictConvert;


/**
 * 应用商品 Excel VO
 *
 * @author 朱述勇
 */
@Data
public class PlugGoodsExcelVO {

    @ExcelProperty("应用编号")
    private Long id;

    @ExcelProperty("应用图片")
    private String appPic;

    @ExcelProperty("应用名称")
    private String appName;

    @ExcelProperty("商品条码")
    private String appSn;

    @ExcelProperty("原价")
    private BigDecimal appPrice;

    @ExcelProperty("售价")
    private BigDecimal payPrice;

    @ExcelProperty("数量")
    private Integer appNum;

    @ExcelProperty(value = "状态 上下架", converter = DictConvert.class)
    @DictFormat("up_down_shelf_status") // TODO 代码优化：建议设置到对应的 XXXDictTypeConstants 枚举类中
    private Integer appStatus;

    @ExcelProperty("创建时间")
    private Date createTime;

}
