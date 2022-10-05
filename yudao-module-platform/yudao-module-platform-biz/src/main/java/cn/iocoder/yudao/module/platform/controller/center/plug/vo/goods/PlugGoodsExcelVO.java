package cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods;

import lombok.*;
import java.util.*;
import java.math.BigDecimal;
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

    @ExcelProperty("编号")
    private Long id;

    @ExcelProperty("商品图片")
    private String goodsPic;

    @ExcelProperty("商品名称")
    private String goodsName;

    @ExcelProperty("商品条码")
    private String goodsSn;

    @ExcelProperty("原价")
    private BigDecimal goodsPrice;

    @ExcelProperty("售价")
    private BigDecimal payPrice;

    @ExcelProperty(value = "状态 上下架", converter = DictConvert.class)
    @DictFormat("up_down_shelf_status") // TODO 代码优化：建议设置到对应的 XXXDictTypeConstants 枚举类中
    private Integer appStatus;

    @ExcelProperty("创建时间")
    private Date createTime;

}
