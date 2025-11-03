package com.shengyu.module.system.framework.flow;

import com.shengyu.framework.flowlong.engine.TaskTrigger;
import com.shengyu.framework.flowlong.engine.core.Execution;
import com.shengyu.framework.flowlong.engine.entity.FlwTask;
import com.shengyu.framework.flowlong.engine.model.NodeModel;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Function;
import java.util.function.Supplier;
import org.springframework.stereotype.Component;

@Component
public class FlowTaskTrigger implements TaskTrigger {

    private final Map<Long, ReentrantLock> taskLocks = new ConcurrentHashMap<>();

    @Override
    public boolean execute(NodeModel nodeModel, Execution execution, Function<Execution, Boolean> finish) {
        // 定时触发器，避免定时任务重复执行设置临时状态 execution.setSaveAsDraft(true); 执行 finish.apply(execution); 回调完成，
        // 再去执行异步逻辑，调用 flowlongEngine.executeFinishTrigger 执行完成触发器任务
        // 处理任务逻辑
        CompletableFuture.runAsync(() -> asyncExec(execution, finish));
        System.out.println("FlowTaskTrigger = " + nodeModel.getNodeName());
        return true;
    }

    public void asyncExec(Execution execution, Function<Execution, Boolean> finish) {
        FlwTask flwTask = execution.getFlwTask();
        // 加锁避免定时触发多次执行，分布式情况使用分布式锁
        ReentrantLock lock = taskLocks.computeIfAbsent(flwTask.getId(), k -> new ReentrantLock());
        if (lock.tryLock()) {
            try {
                lock.lock();
                // 异步执行延迟情况，注意不要超过定时触发时长，避免多次触发执行问题
                Thread.sleep(5000);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            } finally {
                System.out.println("进入异步调用完成触发器完成函数");
                finish.apply(execution);
                lock.unlock();
            }
        }
    }
}
