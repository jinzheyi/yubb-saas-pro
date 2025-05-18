package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

/**
 * 流程任务抄送 DTO
 *
 * @author 青苗
 * @since 2025-03-30
 */
@Getter
@Setter
public class TaskCarbonCopyDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "用户ID列表")
    @NotEmpty
    private List<Long> userIds;

    @Schema(description = "意见评论")
    private String content;

}
