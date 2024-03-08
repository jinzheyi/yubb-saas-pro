package cn.iocoder.yudao.module.system.dal.dataobject.plug;

import cn.iocoder.yudao.framework.mybatis.core.dataobject.BaseDO;
import cn.iocoder.yudao.framework.tenant.core.db.TenantBaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 订单项 DO
 *
 * @author zhusy
 */
@TableName("plug_order_item")
@KeySequence("plug_order_item_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class PlugOrderItemDO extends TenantBaseDO {

    /**
     * 订单项id
     */
    @TableId
    private Long id;

    /**
     * 插件应用id
     */
    private Long plugAppId;

    /**
     * 订单编号
     */
    private String orderNo;

}
