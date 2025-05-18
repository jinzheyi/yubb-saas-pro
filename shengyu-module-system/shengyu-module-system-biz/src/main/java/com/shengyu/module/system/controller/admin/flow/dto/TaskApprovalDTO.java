package com.shengyu.module.system.controller.admin.flow.dto;

import com.aizuda.bpm.engine.model.DynamicAssignee;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;

/**
 * 流程任务审批 DTO
 *
 * @author 青苗
 * @since 2024-03-04
 */
@Getter
@Setter
public class TaskApprovalDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "流程表单JSON内容")
    private String processForm;

    @Schema(description = "意见评论")
    private String content;

    @Schema(description = "终止流程")
    private boolean termination;

    @Schema(description = "动态分配处理人员")
    private Map<String, DynamicAssignee> assigneeMap;

    @Schema(description = "驳回流程节点Key")
    private String nodeKey;

    @Schema(description = "执行参数")
    private Map<String, Object> args;

}
