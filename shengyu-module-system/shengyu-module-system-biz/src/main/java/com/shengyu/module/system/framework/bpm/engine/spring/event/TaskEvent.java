/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.framework.bpm.engine.spring.event;

import com.shengyu.module.system.framework.bpm.engine.core.FlowCreator;
import com.shengyu.module.system.framework.bpm.engine.core.enums.TaskEventType;
import com.shengyu.module.system.dal.dataobject.flow.FlwTask;
import com.shengyu.module.system.framework.bpm.engine.model.NodeModel;
import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;

/**
 * 流程任务事件对象
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
@Getter
@Setter
public class TaskEvent implements Serializable {
    private TaskEventType eventType;
    private FlwTask flwTask;
    private NodeModel nodeModel;
    private FlowCreator flowCreator;

}
