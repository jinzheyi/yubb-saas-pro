/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.dal.dataobject.flow;

import com.aizuda.bpm.engine.core.enums.ActorType;
import com.aizuda.bpm.engine.model.NodeAssignee;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

/**
 * 历史任务参与者实体类
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
@Data
@TableName("flw_his_task_actor")
@EqualsAndHashCode(callSuper = true)
public class FlwHisTaskActorDO extends FlwTaskActorDO {

    public static FlwHisTaskActorDO ofNodeAssignee(NodeAssignee nodeAssignee, Long instanceId, Long taskId) {
        FlwHisTaskActorDO his = new FlwHisTaskActorDO();
        his.setTenantId(nodeAssignee.getTenantId());
        his.setInstanceId(instanceId);
        his.setTaskId(taskId);
        his.setActorId(nodeAssignee.getId());
        his.setActorName(nodeAssignee.getName());
        his.setWeight(nodeAssignee.getWeight());
        his.setActorType(ActorType.user.getValue());
        return his;
    }

    public static FlwHisTaskActorDO ofFlwHisTask(FlwHisTaskDO flwHisTask) {
        FlwHisTaskActorDO his = new FlwHisTaskActorDO();
        his.setTenantId(flwHisTask.getTenantId());
        his.setInstanceId(flwHisTask.getInstanceId());
        his.setTaskId(flwHisTask.getId());
        his.setActorId(flwHisTask.getCreator());
        his.setActorName(flwHisTask.getCreateBy());
        his.setActorType(ActorType.user.getValue());
        return his;
    }

    public static FlwHisTaskActorDO of(FlwTaskActorDO taskActor) {
        FlwHisTaskActorDO his = new FlwHisTaskActorDO();
        his.setTenantId(taskActor.getTenantId());
        his.setInstanceId(taskActor.getInstanceId());
        his.setTaskId(taskActor.getTaskId());
        his.setActorId(taskActor.getActorId());
        his.setActorName(taskActor.getActorName());
        his.setWeight(taskActor.getWeight());
        his.setActorType(taskActor.getActorType());
        his.setAgentId(taskActor.getAgentId());
        his.setAgentType(taskActor.getAgentType());
        his.setExtend(taskActor.getExtend());
        return his;
    }
}
