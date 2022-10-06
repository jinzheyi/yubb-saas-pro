package cn.iocoder.yudao.module.platform.dal.dataobject.plug;

import cn.iocoder.yudao.framework.tenant.core.db.TenantBaseDO;
import lombok.*;
import java.util.*;
import java.math.BigDecimal;
import com.baomidou.mybatisplus.annotation.*;
import cn.iocoder.yudao.framework.mybatis.core.dataobject.BaseDO;

/**
 * 订单 DO
 *
 * @author 朱述勇
 */
@TableName("plug_order")
@KeySequence("plug_order_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlugOrderDO extends TenantBaseDO {

    /**
     * 订单id
     */
    @TableId
    private Long id;
    /**
     * 订单编号
     */
    private String orderNo;
    /**
     * 支付金额，单位：钰豆
     */
    private BigDecimal totalAmount;
    /**
     * 应付金额（实际支付金额）
     */
    private BigDecimal payAmount;
    /**
     * 促销优化金额（促销价、满减、阶梯价）
     */
    private BigDecimal promotionAmount;
    /**
     * 管理员后台调整订单使用的折扣金额
     */
    private BigDecimal discountAmount;
    /**
     * 订单类型：0->正常订单；1->赠送订单
     *
     * 枚举 {@link TODO plug_order_type 对应的类}
     */
    private Integer orderType;
    /**
     * 订单状态 未付款,已付款,已安装
     *
     * 枚举 {@link TODO plug_order_status 对应的类}
     */
    private Integer orderStatus;
    /**
     * 用户 IP
     */
    private String userIp;
    /**
     * 购买者编号
     */
    private Long userId;
    /**
     * 订单失效时间
     */
    private Date expireTime;
    /**
     * 订单支付成功时间
     */
    private Date successTime;
    /**
     * 可以获得的积分
     */
    private Long integration;
    /**
     * 可以活动的成长值
     */
    private Long growth;
    /**
     * 订单备注
     */
    private String note;

}
