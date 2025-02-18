package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程审批 DTO
 */
@Getter
@Setter
public class ProcessApprovalDTO {

    @Schema(description = "流程实例ID")
    @NotNull
    @PositiveOrZero
    private Long instanceId;

    @Schema(description = "流程任务ID")
    private Long taskId;

    @Schema(description = "意见评论")
    @NotBlank
    private String content;

}
