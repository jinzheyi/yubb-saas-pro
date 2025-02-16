package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;

/**
 * 驳回流程任务DTO
 *
 * @author 青苗
 * @since 2023-12-31
 */
@Getter
@Setter
public class RejectTaskDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "驳回到指定节点key（当驳回策略为 3，驳回到指定节点 该参数有效）")
    private String nodeKey;

    @Schema(description = "执行参数")
    private Map<String, Object> args;

    @Schema(description = "原因")
    private String reason;

}
