package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 任务拿回 DTO
 */
@Getter
@Setter
public class TaskReclaimDTO {

    @Schema(description = "流程实例ID")
    @NotNull
    @PositiveOrZero
    private Long instanceId;

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "审批意见")
    private String opinion;

}
