package com.shengyu.module.system.controller.admin.flow.dto;

import com.shengyu.framework.flowlong.engine.core.FlowCreator;
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

    @Schema(description = "用户ID")
    @NotNull
    @PositiveOrZero
    private Long userId;

    @Schema(description = "用户名")
    @NotBlank
    private String username;

    public FlowCreator toFlowCreator() {
        return FlowCreator.of(String.valueOf(this.userId), this.username);
    }
}
