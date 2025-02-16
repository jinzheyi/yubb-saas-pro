package com.shengyu.module.system.controller.admin.flow.dto;

import com.aizuda.bpm.engine.model.ModelHelper;
import com.aizuda.bpm.engine.model.NodeAssignee;
import com.aizuda.bpm.engine.model.NodeModel;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

import java.util.Collections;

/**
 * 流程任务加签 DTO
 *
 * @author 青苗
 * @since 2024-03-08
 */
@Getter
@Setter
public class TaskAppendNodeDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "用户ID")
    @NotNull
    @PositiveOrZero
    private Long userId;

    @Schema(description = "用户名")
    @NotBlank
    private String username;

    @Schema(description = "加签类型 9，前加签 10，并加签 11，后加签")
    @NotNull
    @PositiveOrZero
    private Integer type;

    @Schema(description = "加签节点名称")
    @NotBlank
    private String nodeName;

    @Schema(description = "意见评论")
    private String content;

    /**
     * 构建加签节点
     */
    public NodeModel toNodeModel() {
        NodeModel nodeModel = new NodeModel();
        nodeModel.setNodeName(this.nodeName);
        nodeModel.setNodeKey(ModelHelper.generateNodeKey());
        nodeModel.setType(1);
        nodeModel.setSetType(1);
        NodeAssignee nodeAssignee = new NodeAssignee();
        nodeAssignee.setId(String.valueOf(this.userId));
        nodeAssignee.setName(this.username);
        nodeModel.setNodeAssigneeList(Collections.singletonList(nodeAssignee));
        return nodeModel;
    }
}
