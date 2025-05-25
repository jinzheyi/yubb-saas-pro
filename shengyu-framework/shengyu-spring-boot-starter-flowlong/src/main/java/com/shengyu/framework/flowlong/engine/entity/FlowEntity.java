/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.engine.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程表实体基类
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class FlowEntity extends TenantBaseDO {
    /**
     * 主键ID
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
