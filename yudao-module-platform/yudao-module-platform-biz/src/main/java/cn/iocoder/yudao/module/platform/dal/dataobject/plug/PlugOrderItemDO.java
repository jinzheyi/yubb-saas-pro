package cn.iocoder.yudao.module.platform.dal.dataobject.plug;

import lombok.*;
import java.util.*;
import java.math.BigDecimal;
import com.baomidou.mybatisplus.annotation.*;
import cn.iocoder.yudao.framework.mybatis.core.dataobject.BaseDO;

/**
 * 订单项 DO
 *
 * @author 朱述勇
 */
@TableName("plug_order_item")
@KeySequence("plug_order_item_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlugOrderItemDO extends BaseDO {

    /**
     * 订单项id
     */
    @TableId
    private Long id;
    /**
     * 订单id
     */
    private Long orderId;
    /**
     * 应用id
     */
    private Long appId;
    /**
     * 应用图片
     */
    private String appPic;
    /**
     * 应用名称
     */
    private String appName;
    /**
     * 商品条码
     */
    private String appSn;
    /**
     * 原单价
     */
    private BigDecimal appPrice;
    /**
     * 购买数量
     */
    private Integer payNum;
    /**
     * 促销优化金额（促销价、满减、阶梯价）
     */
    private BigDecimal promotionAmount;
    /**
     * 管理员后台调整订单使用的折扣金额
     */
    private BigDecimal discountAmount;
    /**
     * 商品赠送积分
     */
    private Long giftIntegration;
    /**
     * 商品赠送成长值
     */
    private Long giftGrowth;
    /**
     * 应用业务信息
     */
    private String appInfo;

}
