package com.shengyu.framework.flowlong.engine.entity;

import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.shengyu.framework.flowlong.engine.model.NodeAssignee;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;
import java.util.List;
import java.util.Objects;

@Getter
@Setter
public class ApprovalContent {

    @Schema(description = "审批评论或意见")
    private String opinion;

    @Schema(description = "节点分配处理用户")
    private List<NodeAssignee> nodeUserList;

    @Schema(description = "调用外部流程")
    private String callProcess;

    @Schema(description = "节点分配处理角色")
    private List<NodeAssignee> nodeRoleList;

    public void appendNodeAssignee(List<FlwTaskActor> flwTaskActors) {
        if (CollectionUtils.isNotEmpty(flwTaskActors)) {
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
