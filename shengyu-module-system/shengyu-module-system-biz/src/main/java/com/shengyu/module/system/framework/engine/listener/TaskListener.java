/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.framework.engine.listener;

import com.shengyu.module.system.framework.engine.core.enums.TaskEventType;
import com.shengyu.module.system.dal.dataobject.flow.FlwTask;

/**
 * 流程任务监听
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public interface TaskListener extends FlowLongListener<TaskEventType, FlwTask> {

}
