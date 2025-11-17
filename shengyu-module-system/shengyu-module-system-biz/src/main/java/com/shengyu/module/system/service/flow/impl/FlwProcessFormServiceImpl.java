package com.shengyu.module.system.service.flow.impl;

import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.entity.FlwHisInstance;
import com.shengyu.framework.mybatis.core.service.BaseServiceImpl;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessForm;
import com.shengyu.module.system.dal.mysql.flow.FlwProcessFormMapper;
import com.shengyu.module.system.framework.flow.FlowForm;
import com.shengyu.module.system.service.flow.IFlwProcessFormService;
import java.util.HashMap;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * 流程定义表单 服务实现类
 *
 * @author hubin
 * @since 2024-02-29
 */
@Service
public class FlwProcessFormServiceImpl extends BaseServiceImpl<FlwProcessFormMapper, FlwProcessForm> implements IFlwProcessFormService {

    @Resource
    private FlowLongEngine flowLongEngine;

    @Override
    public boolean saveForm(Long instanceId, String content) {
        Long fiId = this.getParentInstanceId(flowLongEngine.queryService().getHistInstance(instanceId));
        if (null == fiId) {
            return false;
        }
        FlwProcessForm fpf = this.getByInstanceId(fiId);
        if (null == fpf) {
            // 保存表单内容
            fpf = new FlwProcessForm();
            fpf.setInstanceId(instanceId);
            fpf.setContent(content);
            return super.save(fpf);
        }

        // 更新表单内容
        fpf.setContent(content);
        return super.updateById(fpf);
    }

    @Override
    public Long getParentInstanceId(FlwHisInstance fhi) {
        Long instanceId = null;
        if (null != fhi) {
            instanceId = fhi.getId();
            if (null != fhi.getParentInstanceId()) {
                FlwHisInstance fhiParent = flowLongEngine.queryService().getHistInstance(fhi.getParentInstanceId());
                if (null == fhiParent.getParentInstanceId()) {
                    // 父流程为顶级流程，设置返回实例ID
                    instanceId = fhiParent.getId();
                } else {
                    // 递归找到顶级父流程
                    return this.getParentInstanceId(fhiParent);
                }
            }
        }
        return instanceId;
    }

    private FlwProcessForm getByInstanceId(Long instanceId) {
        return lambdaQuery().eq(FlwProcessForm::getInstanceId, instanceId).one();
    }

    @Override
    public String getFormContentByFlwHisInstance(FlwHisInstance fhi) {
        Long instanceId = this.getParentInstanceId(fhi);
        if (null == instanceId) {
            return null;
        }
        FlwProcessForm flwProcessForm = this.getByInstanceId(instanceId);
        return null == flwProcessForm ? null : flwProcessForm.getContent();
    }

    @Override
    public Map<String, Object> getArgsByInstanceId(Long instanceId) {
        FlwProcessForm flwProcessForm = this.getByInstanceId(instanceId);
        if (null != flwProcessForm) {
            return FlowForm.convertArgs(flwProcessForm.getContent());
        }
        return new HashMap<>();
    }

}
