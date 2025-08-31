/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.engine.entity;

import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.flowlong.engine.FlowConstants;
import com.shengyu.framework.flowlong.engine.ProcessModelCache;
import com.shengyu.framework.flowlong.engine.core.FlowLongContext;
import com.shengyu.framework.flowlong.engine.model.ProcessModel;
import java.util.Objects;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.util.function.Supplier;

/**
 * 扩展流程实例实体类
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
@Getter
@Setter
@ToString
public class FlwExtInstance extends FlowEntity implements ProcessModelCache, Serializable {

    /**
     * 流程定义ID
     */
    private Long processId;
    /**
     * 流程定义名称（冗余业务直接可用）
     */
    protected String processName;
    /**
     * 流程定义类型（冗余业务直接可用）
     */
    protected String processType;
    /**
     * 流程模型定义JSON内容
     * <p>
     * 在发起的时候拷贝自流程定义模型内容，用于记录当前实例节点的动态改变。
     * </p>
     */
    private String modelContent;

    /**
     * 流程设置定义JSON内容
     * <p>
     *  在发起的时候拷贝自流程定义模型流程设置。
     * </p>
     */
    private String processSetting;

    /**
     * 模型第一个节点key（发起人）
     */
    private String taskKey;

    public static FlwExtInstance of(FlwInstance flwInstance, FlwProcess flwProcess, FlwProcessConfigure flwProcessConfigure) {
        FlwExtInstance ext = new FlwExtInstance();
        ext.id = flwInstance.getId();
        ext.tenantId = flwInstance.getTenantId();
        ext.processId = flwInstance.getProcessId();
        ext.processName = flwProcess.getProcessName();
        ext.processType = flwProcess.getProcessType();
        ext.modelContent = flwProcess.getModelContent();
        ext.taskKey = FlowLongContext.fromJson(flwProcess.getModelContent(), ProcessModel.class).getNodeConfig().getNodeKey();
        ext.processSetting = Objects.nonNull(flwProcessConfigure)? JsonUtils.toJsonString(flwProcessConfigure.getProcessSetting()) : null;
        return ext;
    }

    @Override
    public String modelCacheKey() {
        return FlowConstants.processInstanceCacheKey + this.id;
    }

    public static ProcessModel cacheProcessModelById(Long id, Supplier<ProcessModel> supplier) {
        ProcessModel processModel = FlowLongContext.parseProcessModel(null, FlowConstants.processInstanceCacheKey + id, false);
        if (null == processModel && null != supplier) {
            processModel = supplier.get();
        }
        return processModel;
    }

}
