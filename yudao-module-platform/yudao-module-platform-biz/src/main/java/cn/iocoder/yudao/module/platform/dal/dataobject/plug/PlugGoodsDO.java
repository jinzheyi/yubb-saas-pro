package cn.iocoder.yudao.module.platform.dal.dataobject.plug;

import lombok.*;
import java.util.*;
import java.math.BigDecimal;
import com.baomidou.mybatisplus.annotation.*;
import cn.iocoder.yudao.framework.mybatis.core.dataobject.BaseDO;

/**
 * 应用商品 DO
 *
 * @author 朱述勇
 */
@TableName("plug_goods")
@KeySequence("plug_goods_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlugGoodsDO extends BaseDO {

    /**
     * 应用编号
     */
    @TableId
    private Long id;
    /**
     * 应用图片
     */
    private String appPic;
    /**
     * 应用名称
     */
    private String appName;
    /**
     * 应用概要
     */
    private String appOutline;
    /**
     * 商品条码
     */
    private String appSn;
    /**
     * 原价
     */
    private BigDecimal appPrice;
    /**
     * 售价
     */
    private BigDecimal payPrice;
    /**
     * 数量
     */
    private Integer appNum;
    /**
     * 商品赠送积分
     */
    private Long giftIntegration;
    /**
     * 商品赠送成长值
     */
    private Long giftGrowth;
    /**
     * 状态 上下架
     *
     * 枚举 {@link TODO up_down_shelf_status 对应的类}
     */
    private Integer appStatus;
    /**
     * 应用业务信息
     */
    private String appInfo;
    /**
     * 商品祥情描述
     */
    private String appContents;

}
