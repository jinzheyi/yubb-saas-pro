package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程审批 DTO
 */
@Getter
@Setter
public class ProcessInfoDTO {

    @Schema(description = "流程实例ID")
    @NotNull
    @PositiveOrZero
    private Long instanceId;

    @Schema(description = "流程任务ID")
    @PositiveOrZero
    private Long taskId;

}
