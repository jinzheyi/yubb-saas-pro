/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.framework.engine.spring.event;

import com.shengyu.module.system.framework.engine.core.FlowCreator;
import com.shengyu.module.system.framework.engine.core.enums.InstanceEventType;
import com.shengyu.module.system.dal.dataobject.flow.FlwHisInstance;
import com.shengyu.module.system.framework.engine.listener.InstanceListener;
import com.shengyu.module.system.framework.engine.model.NodeModel;
import org.springframework.context.ApplicationEventPublisher;

import java.util.function.Supplier;

/**
 * Spring boot Event 异步实例监听处理器
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public class EventInstanceListener implements InstanceListener {
    private final ApplicationEventPublisher eventPublisher;

    public EventInstanceListener(ApplicationEventPublisher eventPublisher) {
        this.eventPublisher = eventPublisher;
    }

    @Override
    public boolean notify(InstanceEventType eventType, Supplier<FlwHisInstance> supplier, NodeModel nodeModel, FlowCreator flowCreator) {
        InstanceEvent instanceEvent = new InstanceEvent();
        instanceEvent.setEventType(eventType);
        instanceEvent.setFlwInstance(supplier.get());
        instanceEvent.setNodeModel(nodeModel);
        instanceEvent.setFlowCreator(flowCreator);
        eventPublisher.publishEvent(instanceEvent);
        return true;
    }
}
