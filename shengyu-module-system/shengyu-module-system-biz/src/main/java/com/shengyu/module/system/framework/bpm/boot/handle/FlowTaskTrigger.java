package com.shengyu.module.system.framework.bpm.boot.handle;

import com.shengyu.module.system.framework.bpm.engine.TaskTrigger;
import com.shengyu.module.system.framework.bpm.engine.core.Execution;
import com.shengyu.module.system.framework.bpm.engine.model.NodeModel;
import org.springframework.stereotype.Component;

@Component
public class FlowTaskTrigger implements TaskTrigger {

    @Override
    public boolean execute(NodeModel nodeModel, Execution execution) {
        System.out.println("FlowTaskTrigger = " + nodeModel.getNodeName());
        return true;
    }
}
