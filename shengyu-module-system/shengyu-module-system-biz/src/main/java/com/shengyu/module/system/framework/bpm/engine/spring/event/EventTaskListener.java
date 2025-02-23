/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.framework.bpm.engine.spring.event;

import com.shengyu.module.system.framework.bpm.engine.core.FlowCreator;
import com.shengyu.module.system.framework.bpm.engine.core.enums.TaskEventType;
import com.shengyu.module.system.dal.dataobject.flow.FlwTask;
import com.shengyu.module.system.framework.bpm.engine.listener.TaskListener;
import com.shengyu.module.system.framework.bpm.engine.model.NodeModel;
import org.springframework.context.ApplicationEventPublisher;

import java.util.function.Supplier;

/**
 * Spring boot Event 异步任务监听处理器
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public class EventTaskListener implements TaskListener {
    private final ApplicationEventPublisher eventPublisher;

    public EventTaskListener(ApplicationEventPublisher eventPublisher) {
        this.eventPublisher = eventPublisher;
    }

    @Override
    public boolean notify(TaskEventType eventType, Supplier<FlwTask> supplier, NodeModel nodeModel, FlowCreator flowCreator) {
        TaskEvent taskEvent = new TaskEvent();
        taskEvent.setEventType(eventType);
        taskEvent.setFlwTask(supplier.get());
        taskEvent.setNodeModel(nodeModel);
        taskEvent.setFlowCreator(flowCreator);
        eventPublisher.publishEvent(taskEvent);
        return true;
    }
}
