package com.shengyu.module.system.controller.admin.flow.dto;

import com.shengyu.module.system.framework.engine.core.FlowCreator;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程任务分派（委派、转办） DTO
 *
 * @author 青苗
 * @since 2024-03-08
 */
@Getter
@Setter
public class TaskAssigneeDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "类型 0，转办 1，委派")
    @NotNull
    private Integer type;

    @Schema(description = "用户ID")
    @NotNull
    @PositiveOrZero
    private Long userId;

    @Schema(description = "用户名")
    @NotBlank
    private String username;

    @Schema(description = "意见评论")
    private String content;

    public FlowCreator toFlowCreator() {
        return FlowCreator.of(String.valueOf(this.userId), this.username);
    }
}
