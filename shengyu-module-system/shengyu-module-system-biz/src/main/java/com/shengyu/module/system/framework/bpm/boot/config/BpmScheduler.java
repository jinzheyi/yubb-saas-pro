package com.shengyu.module.system.framework.bpm.boot.config;

import com.shengyu.module.system.framework.bpm.engine.FlowLongScheduler;
import com.shengyu.module.system.framework.bpm.engine.core.FlowCreator;
import org.springframework.scheduling.annotation.SchedulingConfigurer;
import org.springframework.scheduling.config.ScheduledTaskRegistrar;
import org.springframework.scheduling.support.CronTrigger;

public class BpmScheduler extends FlowLongScheduler implements SchedulingConfigurer {

    @Override
    public void configureTasks(ScheduledTaskRegistrar taskRegistrar) {
        taskRegistrar.addTriggerTask(this::remind, triggerContext ->
                new CronTrigger(getRemindParam().getCron()).nextExecution(triggerContext));
    }

    @Override
    public FlowCreator getAutoFlowCreator() {
        // 这里业务系统，可以根据实际情况配置默认审批创建人
        return FlowCreator.ADMIN;
    }
}
