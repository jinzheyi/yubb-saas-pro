package com.shengyu.module.system.framework.flow;

import com.shengyu.framework.flowlong.engine.core.Execution;
import com.shengyu.framework.flowlong.engine.core.FlowLongContext;
import com.shengyu.framework.flowlong.engine.entity.FlwInstance;
import com.shengyu.framework.flowlong.engine.handler.impl.SimpleConditionNodeHandler;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import com.shengyu.module.system.service.flow.IFlwProcessFormService;
import java.util.Objects;
import javax.annotation.Resource;
import org.apache.commons.collections4.MapUtils;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class FlowConditionNodeHandler extends SimpleConditionNodeHandler {

    @Resource
    private IFlwProcessFormService flwProcessFormService;

    @Override
    public Map<String, Object> getArgs(FlowLongContext flowLongContext, Execution execution, NodeModel nodeModel) {
        FlwInstance flwInstance = execution.getFlwInstance();
        if (null != flwInstance) {
            NodeModel parentNode = nodeModel.getParentNode();
            if (null != parentNode && parentNode.triggerNode() && Objects.equals(2, parentNode.getTriggerType())) {
                Map<String, Object> formArgs = flwProcessFormService.getArgsByInstanceId(flwInstance.getId());
                if (MapUtils.isNotEmpty(execution.getArgs())) {
                    formArgs.putAll(execution.getArgs());
                }
                return formArgs;
            }
        }
        return FlowForm.flowArgs(execution.getArgs());
    }

}
