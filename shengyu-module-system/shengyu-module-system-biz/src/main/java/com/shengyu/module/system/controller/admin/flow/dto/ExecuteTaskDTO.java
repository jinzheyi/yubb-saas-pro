package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

import java.util.List;
import java.util.Map;

/**
 * 执行流程任务DTO
 *
 * @author 青苗
 * @since 2023-12-17
 */
@Getter
@Setter
public class ExecuteTaskDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "执行参数")
    private Map<String, Object> args;

    @Schema(description = "附件文件ID列表")
    private List<Long> fileIds;

    @Schema(description = "审批意见")
    private String opinion;

}
