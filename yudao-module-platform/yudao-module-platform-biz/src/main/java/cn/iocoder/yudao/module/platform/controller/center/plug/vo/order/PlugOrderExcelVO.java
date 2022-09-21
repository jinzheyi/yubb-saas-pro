package cn.iocoder.yudao.module.platform.controller.center.plug.vo.order;

import lombok.*;
import java.util.*;
import java.math.BigDecimal;
import io.swagger.annotations.*;

import com.alibaba.excel.annotation.ExcelProperty;
import cn.iocoder.yudao.framework.excel.core.annotations.DictFormat;
import cn.iocoder.yudao.framework.excel.core.convert.DictConvert;


/**
 * 订单 Excel VO
 *
 * @author 朱述勇
 */
@Data
public class PlugOrderExcelVO {

    @ExcelProperty("订单id")
    private Long id;

    @ExcelProperty("订单编号")
    private String orderNo;

    @ExcelProperty("支付金额，单位：钰豆")
    private BigDecimal totalAmount;

    @ExcelProperty("应付金额（实际支付金额）")
    private BigDecimal payAmount;

    @ExcelProperty("促销优化金额（促销价、满减、阶梯价）")
    private BigDecimal promotionAmount;

    @ExcelProperty("管理员后台调整订单使用的折扣金额")
    private BigDecimal discountAmount;

    @ExcelProperty(value = "订单类型：0->正常订单；1->赠送订单", converter = DictConvert.class)
    @DictFormat("plug_order_type") // TODO 代码优化：建议设置到对应的 XXXDictTypeConstants 枚举类中
    private Integer orderType;

    @ExcelProperty(value = "订单状态 未付款,已付款,已安装", converter = DictConvert.class)
    @DictFormat("plug_order_status") // TODO 代码优化：建议设置到对应的 XXXDictTypeConstants 枚举类中
    private Integer orderStatus;

    @ExcelProperty("用户 IP")
    private String userIp;

    @ExcelProperty("购买者编号")
    private Long userId;

    @ExcelProperty("订单失效时间")
    private Date expireTime;

    @ExcelProperty("订单支付成功时间")
    private Date successTime;

    @ExcelProperty("可以获得的积分")
    private Long integration;

    @ExcelProperty("可以活动的成长值")
    private Long growth;

    @ExcelProperty("订单备注")
    private String note;

    @ExcelProperty("创建时间")
    private Date createTime;

}
