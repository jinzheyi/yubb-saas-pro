package com.shengyu.module.system.framework.bpm.boot.handle;

import com.shengyu.module.system.framework.bpm.engine.core.Execution;
import com.shengyu.module.system.framework.bpm.engine.core.FlowLongContext;
import com.shengyu.module.system.framework.bpm.engine.handler.impl.SimpleConditionNodeHandler;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class FlowConditionNodeHandler extends SimpleConditionNodeHandler {

    @Override
    public Map<String, Object> getArgs(FlowLongContext flowLongContext, Execution execution) {
        return FlowForm.flowArgs(execution.getArgs());
    }
}
