package com.shengyu.module.system.dal.dataobject.plug;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 租户应用 DO
 *
 * @author zhusy
 */
@TableName("plug_tenant")
@KeySequence("plug_tenant_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class PlugTenantDO extends TenantBaseDO {

    /**
     * id
     */
    @TableId
    private Long id;
    /**
     * 插件应用id
     */
    private Long plugAppId;

    /**
     * 状态（0上架 1下架），租户内部自己的操作
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;

    /**
     * 状态（0启用 1停用）平台端操作，停用后租户不能使用该插件
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer enable;

}
