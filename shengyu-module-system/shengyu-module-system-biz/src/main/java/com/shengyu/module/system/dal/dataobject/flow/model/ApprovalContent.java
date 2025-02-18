package com.shengyu.module.system.dal.dataobject.flow.model;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.module.system.framework.engine.model.NodeAssignee;
import com.shengyu.module.system.dal.dataobject.flow.FlwTaskActor;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.List;
import java.util.Objects;

/**
 * 流程审批记录-操作json内容
 */
@Getter
@Setter
public class ApprovalContent {

    /**
     * 审批评论或意见
     */
    @Schema(description = "审批评论或意见")
    private String opinion;

    /**
     * 节点分配处理用户
     */
    @Schema(description = "节点分配处理用户")
    private List<NodeAssignee> nodeUserList;

    /**
     * 调用外部流程
     */
    @Schema(description = "调用外部流程")
    private String callProcess;

    /**
     * 节点分配处理角色
     */
    @Schema(description = "节点分配处理角色")
    private List<NodeAssignee> nodeRoleList;

    public void appendNodeAssignee(List<FlwTaskActor> flwTaskActors) {
        if (CollUtil.isNotEmpty(flwTaskActors)) {
            List<NodeAssignee> nodeAssigneeList = flwTaskActors.stream().map(t -> {
                NodeAssignee nodeAssignee = new NodeAssignee();
                nodeAssignee.setTenantId(t.getTenantId());
                nodeAssignee.setId(t.getActorId());
                nodeAssignee.setName(t.getActorName());
                nodeAssignee.setWeight(t.getWeight());
                return nodeAssignee;
            }).toList();
            // 参与者类型 0，用户 1，角色 2，部门
            FlwTaskActor flwTaskActor = flwTaskActors.get(0);
            if (Objects.equals(0, flwTaskActor.getActorType())) {
                this.setNodeUserList(nodeAssigneeList);
            } else {
                this.setNodeRoleList(nodeAssigneeList);
            }
        }
    }
}
