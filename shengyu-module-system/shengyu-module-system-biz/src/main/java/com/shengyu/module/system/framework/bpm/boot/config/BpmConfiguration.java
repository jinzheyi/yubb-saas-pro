package com.shengyu.module.system.framework.bpm.boot.config;

import com.shengyu.module.system.framework.bpm.engine.FlowLongEngine;
import com.shengyu.module.system.framework.bpm.engine.FlowLongScheduler;
import com.shengyu.module.system.framework.bpm.engine.TaskReminder;
import com.shengyu.module.system.framework.bpm.engine.assist.DateUtils;
import com.shengyu.module.system.framework.bpm.engine.scheduling.JobLock;
import com.shengyu.module.system.framework.bpm.engine.spring.autoconfigure.FlowLongProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@Configuration
public class BpmConfiguration {

    @Bean
    @ConditionalOnMissingBean
    public TaskReminder taskReminder() {
        return (context, instanceId, currentTask) -> {
            System.out.println("测试提醒：" + instanceId);
            return DateUtils.toDate(DateUtils.now().plusHours(1));
        };
    }

    @Bean
    @ConditionalOnMissingBean
    public FlowLongScheduler springBootScheduler(FlowLongEngine flowLongEngine, FlowLongProperties properties, JobLock jobLock) {
        FlowLongScheduler scheduler = new BpmScheduler();
        scheduler.setFlowLongEngine(flowLongEngine);
        scheduler.setRemindParam(properties.getRemind());
        scheduler.setJobLock(jobLock);
        return scheduler;
    }
}
