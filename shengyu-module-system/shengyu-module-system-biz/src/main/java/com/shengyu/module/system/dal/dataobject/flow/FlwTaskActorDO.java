/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.dal.dataobject.flow;

import com.aizuda.bpm.engine.core.FlowCreator;
import com.aizuda.bpm.engine.core.FlowLongContext;
import com.aizuda.bpm.engine.core.enums.AgentType;
import com.aizuda.bpm.engine.model.NodeAssignee;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

/**
 * 任务参与者实体类
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("flw_task_actor")
public class FlwTaskActorDO extends TenantFlowBaseDO {

    /**
     * 流程实例ID
     */
    protected Long instanceId;
    /**
     * 关联的任务ID
     */
    protected Long taskId;
    /**
     * 关联的参与者ID（参与者可以为用户、部门、角色）
     */
    protected String actorId;
    /**
     * 关联的参与者名称
     */
    protected String actorName;
    /**
     * 参与者类型 0，用户 1，角色 2，部门
     */
    protected Integer actorType;
    /**
     * 权重
     * <p>
     * 票签任务时，该值为不同处理人员的分量比例
     * </p>
     * <p>
     * 代理任务时，该值为 1 时为代理人
     * </p>
     * <p>
     * 或签任务时，该值为 1 时为或签处理人
     * </p>
     */
    protected Integer weight;
    /**
     * 代理人ID
     */
    protected String agentId;
    /**
     * 代理人类型 0，代理 1，被代理 2，认领角色 3，认领部门
     */
    protected Integer agentType;
    /**
     * 扩展json
     */
    protected String extend;

    /**
     * 是否为代理人
     *
     * @return true 是 false 否
     */
    public boolean agentActor() {
        return Objects.equals(0, this.actorType);
    }

    public boolean eqActorId(String actorId) {
        return Objects.equals(this.actorId, actorId);
    }

    public static FlwTaskActorDO of(FlowCreator flowCreator, FlwTaskDO flwTask) {
        FlwTaskActorDO flwTaskActor = ofUser(flowCreator.getTenantId(), flowCreator.getCreateId(), flowCreator.getCreateBy());
        flwTaskActor.setInstanceId(flwTask.getInstanceId());
        flwTaskActor.setTaskId(flwTask.getId());
        return flwTaskActor;
    }

    public static FlwTaskActorDO ofAgentIt(FlowCreator flowCreator) {
        FlwTaskActorDO flwTaskActor = new FlwTaskActorDO();
        flwTaskActor.setAgentId(flowCreator.getCreateId());
        flwTaskActor.setAgentType(1);
        Map<String, Object> map = new HashMap<>();
        map.put("createBy", flowCreator.getCreateBy());
        flwTaskActor.setExtendOf(map);
        return flwTaskActor;
    }

    public static FlwTaskActorDO ofAgent(AgentType agentType, FlowCreator flowCreator, FlwTaskDO flwTask, FlwTaskActorDO agentTaskActor) {
        FlwTaskActorDO flwTaskActor = of(flowCreator, flwTask);
        flwTaskActor.setAgentId(agentTaskActor.getActorId());
        flwTaskActor.setAgentType(agentType.getValue());
        Map<String, Object> map = new HashMap<>();
        map.put("actorType", agentTaskActor.getActorType());
        map.put("actorName", agentTaskActor.getActorName());
        flwTaskActor.setExtendOf(map);
        return flwTaskActor;
    }

    public static FlwTaskActorDO ofFlwTask(FlwTaskDO flwTask) {
        FlwTaskActorDO flwTaskActor = FlwTaskActorDO.ofUser(flwTask.getTenantId(),
                flwTask.getCreator(), flwTask.getCreateBy());
        flwTaskActor.setInstanceId(flwTask.getInstanceId());
        flwTaskActor.setTaskId(flwTask.getId());
        return flwTaskActor;
    }

    public static FlwTaskActorDO ofFlowCreator(FlowCreator flowCreator) {
        return ofUser(flowCreator.getTenantId(), flowCreator.getCreateId(), flowCreator.getCreateBy());
    }

    public static FlwTaskActorDO ofFlwInstance(FlwInstanceDO flwInstance, Long taskId) {
        FlwTaskActorDO flwTaskActor = ofUser(flwInstance.getTenantId(), flwInstance.getCreator(), flwInstance.getCreateBy());
        flwTaskActor.setInstanceId(flwInstance.getId());
        flwTaskActor.setTaskId(taskId);
        return flwTaskActor;
    }

    public static FlwTaskActorDO ofNodeAssignee(NodeAssignee nodeAssignee) {
        return ofUser(nodeAssignee.getTenantId(), nodeAssignee.getId(), nodeAssignee.getName());
    }

    public static FlwTaskActorDO ofUser(Long tenantId, String actorId, String actorName) {
        return of(tenantId, actorId, actorName, 0, null);
    }

    public static FlwTaskActorDO ofRole(String tenantId, String actorId, String actorName) {
        return of(tenantId, actorId, actorName, 1, null);
    }

    public static FlwTaskActorDO ofDepartment(String tenantId, String actorId, String actorName) {
        return of(tenantId, actorId, actorName, 2, null);
    }

    public static FlwTaskActorDO of(NodeAssignee nodeAssignee, Integer actorType) {
        return of(nodeAssignee.getTenantId(), nodeAssignee.getId(), nodeAssignee.getName(), actorType, nodeAssignee.getWeight());
    }

    public static FlwTaskActorDO of(Long taskId, FlwHisTaskActorDO t) {
        FlwTaskActorDO flwTaskActor = of(t.getTenantId(), t.getActorId(), t.getActorName(), t.getActorType(), t.getWeight());
        flwTaskActor.setTaskId(taskId);
        flwTaskActor.setInstanceId(t.getInstanceId());
        return flwTaskActor;
    }

    protected static FlwTaskActorDO of(Long tenantId, String actorId, String actorName, Integer actorType, Integer weight) {
        FlwTaskActorDO taskActor = new FlwTaskActorDO();
        taskActor.setTenantId(tenantId);
        taskActor.setActorId(actorId);
        taskActor.setActorName(actorName);
        taskActor.setActorType(actorType);
        taskActor.setWeight(weight);
        return taskActor;
    }

    public static FlwTaskActorDO ofFlwHisTaskActor(Long taskId, FlwHisTaskActorDO hta) {
        FlwTaskActorDO taskActor = new FlwTaskActorDO();
        taskActor.setTenantId(hta.getTenantId());
        taskActor.setInstanceId(hta.getInstanceId());
        taskActor.setTaskId(taskId);
        taskActor.setActorId(hta.getActorId());
        taskActor.setActorName(hta.getActorName());
        taskActor.setActorType(hta.getActorType());
        taskActor.setWeight(hta.getWeight());
        taskActor.setAgentId(hta.getAgentId());
        taskActor.setAgentType(hta.getAgentType());
        taskActor.setExtend(hta.getExtend());
        return taskActor;
    }

    public void setExtendOf(Object object) {
        this.extend = FlowLongContext.toJson(object);
    }
}
