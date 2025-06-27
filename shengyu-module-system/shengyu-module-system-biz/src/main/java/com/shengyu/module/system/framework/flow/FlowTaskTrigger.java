package com.shengyu.module.system.framework.flow;

import com.shengyu.framework.flowlong.engine.TaskTrigger;
import com.shengyu.framework.flowlong.engine.core.Execution;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import java.util.concurrent.CompletableFuture;
import java.util.function.Supplier;
import org.springframework.stereotype.Component;

@Component
public class FlowTaskTrigger implements TaskTrigger {

    @Override
    public boolean execute(NodeModel nodeModel, Execution execution, Supplier<Boolean> finish) {
        CompletableFuture.runAsync(() -> asyncExec(finish));
        System.out.println("FlowTaskTrigger = " + nodeModel.getNodeName());
        return true;
    }

    public void asyncExec(Supplier<Boolean> finish) {
        try {
            Thread.sleep(5000);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        } finally {
            System.out.println("进入异步调用完成触发器完成函数");
            finish.get();
        }
    }
}
