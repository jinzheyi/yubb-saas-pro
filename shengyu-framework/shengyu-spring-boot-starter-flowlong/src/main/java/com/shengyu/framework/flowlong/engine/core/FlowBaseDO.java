package com.shengyu.framework.flowlong.engine.core;

import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 拓展多租户的 BaseDO 基类
 *
 * @author 圣钰科技
 */
@Data
@EqualsAndHashCode(callSuper = true)
public abstract class FlowBaseDO extends TenantBaseDO {

    /**
     * 创建人
     */
    protected String createBy;

}
