package com.shengyu.framework.tenant.core.db;

import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 基于flow拓展多租户的 BaseDO 基类
 *
 * @author 圣钰科技
 */
@Data
@EqualsAndHashCode(callSuper = true)
public abstract class TenantFlowBaseDO extends TenantBaseDO {

    /**
     * 用户ID
     */
    @TableId
    protected Long id;

    /**
     * 创建人ID
     */
    protected String createId;

    /**
     * 创建人名称
     */
    protected String createBy;

}
