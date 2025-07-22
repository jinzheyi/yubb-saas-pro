/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.engine.impl;

import com.shengyu.framework.flowlong.engine.TaskActorProvider;
import com.shengyu.framework.flowlong.engine.assist.ObjectUtils;
import com.shengyu.framework.flowlong.engine.core.Execution;
import com.shengyu.framework.flowlong.engine.core.enums.NodeSetType;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.shengyu.framework.flowlong.engine.model.NodeAssignee;
import com.shengyu.framework.flowlong.engine.model.NodeModel;

import java.util.ArrayList;
import java.util.List;

/**
 * 普遍的任务参与者提供处理类
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public class GeneralTaskActorProvider implements TaskActorProvider {

    public List<FlwTaskActor> getTaskActors(NodeModel nodeModel, Execution execution) {
        List<FlwTaskActor> flwTaskActors = new ArrayList<>();
        if (ObjectUtils.isNotEmpty(nodeModel.getNodeAssigneeList())) {
            final Integer actorType = this.getActorType(nodeModel);
            if (null != actorType) {
                for (NodeAssignee nodeAssignee : nodeModel.getNodeAssigneeList()) {
                    flwTaskActors.add(FlwTaskActor.of(nodeAssignee, actorType));
                }
            }
        }
        return ObjectUtils.isEmpty(flwTaskActors) ? null : flwTaskActors;
    }

    @Override
    public Integer getActorType(NodeModel nodeModel) {
        // 非全部人员参与审批分组策略
        if (!nodeModel.allJoinGroupStrategy()) {

            // 1，角色
            if (NodeSetType.role.eq(nodeModel.getSetType())) {
                return 1;
            }

            // 2，部门
            if (NodeSetType.department.eq(nodeModel.getSetType())) {
                return 2;
            }
        }

        // 0，用户
        return 0;
    }
}
