package cn.iocoder.yudao.module.platform.dal.dataobject.plug;

import lombok.*;
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
     * 商品id
     */
    private Long goodsId;
    /**
     * 商品图片
     */
    private String goodsPic;
    /**
     * 商品名称
     */
    private String goodsName;
    /**
     * 商品条码
     */
    private String goodsSn;
    /**
     * 原单价
     */
    private BigDecimal goodsPrice;
    /**
     * 购买可以使用的天数
     */
    private Integer payDay;
    /**
     * 续期类型  0（永久）1（年）2（月）3（季）
     */
    private Integer renewalType;
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
