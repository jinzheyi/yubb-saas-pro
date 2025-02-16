package com.shengyu.module.system.dal.dataobject.flow;

import com.aizuda.bpm.engine.FlowConstants;
import com.aizuda.bpm.engine.ProcessModelCache;
import com.aizuda.bpm.engine.core.FlowLongContext;
import com.aizuda.bpm.engine.model.ProcessModel;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.function.Supplier;

@Data
@TableName("flw_ext_instance")
@EqualsAndHashCode(callSuper = true)
public class FlwExtInstanceDO extends TenantFlowBaseDO implements ProcessModelCache {

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

    public static FlwExtInstanceDO of(FlwInstanceDO flwInstance, FlwProcessDO flwProcess) {
        FlwExtInstanceDO ext = new FlwExtInstanceDO();
        ext.id = flwInstance.getId();
        ext.setTenantId(flwInstance.getTenantId());
        ext.processId = flwInstance.getProcessId();
        ext.processName = flwProcess.getProcessName();
        ext.processType = flwProcess.getProcessType();
        ext.modelContent = flwProcess.getModelContent();
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
