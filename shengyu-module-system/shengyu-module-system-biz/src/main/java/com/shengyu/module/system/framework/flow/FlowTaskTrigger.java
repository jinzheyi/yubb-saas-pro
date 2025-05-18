package com.shengyu.module.system.framework.flow;

import com.aizuda.bpm.engine.TaskTrigger;
import com.aizuda.bpm.engine.core.Execution;
import com.aizuda.bpm.engine.model.NodeModel;
import org.springframework.stereotype.Component;

@Component
public class FlowTaskTrigger implements TaskTrigger {

    @Override
    public boolean execute(NodeModel nodeModel, Execution execution) {
        System.out.println("FlowTaskTrigger = " + nodeModel.getNodeName());
        return true;
    }
}
