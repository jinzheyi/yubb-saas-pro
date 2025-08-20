package com.shengyu.module.system.controller.admin.flow.dto;

import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程任务转交（转办、委派、代理） DTO
 *
 * @author 青苗
 * @since 2025-08-16
 */
@Getter
@Setter
public class TaskTransferDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "类型 0，转办 1，委派 2，代理")
    @NotNull
    private Integer type;

    @Schema(description = "流程任务处理人列表，转办委派一个人，代理人允许多个人")
    @NotEmpty
    private List<TaskAssigneeDTO> assigneeList;

    @Schema(description = "意见评论")
    private String content;

    public List<FlowCreator> toFlowCreators() {
        return assigneeList.stream().map(TaskAssigneeDTO::toFlowCreator).toList();
    }
}
