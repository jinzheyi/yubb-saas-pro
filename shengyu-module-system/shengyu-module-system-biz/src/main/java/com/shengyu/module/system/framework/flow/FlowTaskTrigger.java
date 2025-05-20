package com.shengyu.module.system.framework.flow;

import com.shengyu.framework.flowlong.engine.TaskTrigger;
import com.shengyu.framework.flowlong.engine.core.Execution;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import org.springframework.stereotype.Component;

@Component
public class FlowTaskTrigger implements TaskTrigger {

    @Override
    public boolean execute(NodeModel nodeModel, Execution execution) {
        System.out.println("FlowTaskTrigger = " + nodeModel.getNodeName());
        return true;
    }
}
