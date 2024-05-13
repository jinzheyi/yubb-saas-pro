package com.shengyu.module.system.dal.dataobject.plug;

import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 插件订单 DO
 *
 * @author zhusy
 */
@TableName("plug_order")
@KeySequence("plug_order_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class PlugOrderDO extends TenantBaseDO {

    /**
     * id
     */
    @TableId
    private Long id;
    /**
     * 订单编号
     */
    private String orderNo;
    /**
     * 订单状态 0：待审核,1：审核通过,2：审核不通过
     *
     * 枚举 {@link CommonConstants.PlugOrderStatusEnum}
     */
    private Integer orderStatus;
    /**
     * 审核描述
     */
    private String auditNote;
    /**
     * 用户 IP
     */
    private String userIp;
    /**
     * 申请者编号
     */
    private Long userId;
    /**
     * 订单申请成功时间
     */
    private LocalDateTime successTime;
    /**
     * 订单备注
     */
    private String note;

}
