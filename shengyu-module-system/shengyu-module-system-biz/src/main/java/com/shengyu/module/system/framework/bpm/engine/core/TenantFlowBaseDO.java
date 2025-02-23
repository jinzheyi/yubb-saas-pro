package com.shengyu.module.system.framework.bpm.engine.core;

import com.baomidou.mybatisplus.annotation.TableId;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 基于flow拓展多租户的 BaseDO 基类
 *
 * @author 圣钰科技
 */
@Data
@EqualsAndHashCode(callSuper = true)
public abstract class TenantFlowBaseDO extends TenantBaseDO implements BeanConvert {

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

    public void setFlowCreator(FlowCreator flowCreator) {
        this.tenantId = flowCreator.getTenantId();
        this.createId = flowCreator.getCreateId();
        this.createBy = flowCreator.getCreateBy();
    }

}
