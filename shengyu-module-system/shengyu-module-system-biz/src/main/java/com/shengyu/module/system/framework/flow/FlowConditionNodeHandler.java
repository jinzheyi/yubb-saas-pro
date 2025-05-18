package com.shengyu.module.system.framework.flow;

import com.aizuda.bpm.engine.core.Execution;
import com.aizuda.bpm.engine.core.FlowLongContext;
import com.aizuda.bpm.engine.handler.impl.SimpleConditionNodeHandler;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class FlowConditionNodeHandler extends SimpleConditionNodeHandler {

    @Override
    public Map<String, Object> getArgs(FlowLongContext flowLongContext, Execution execution) {
        return FlowForm.flowArgs(execution.getArgs());
    }
}
