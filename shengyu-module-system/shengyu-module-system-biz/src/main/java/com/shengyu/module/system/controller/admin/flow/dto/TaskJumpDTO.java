package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程任务审批 DTO
 *
 * @author 青苗
 * @since 2024-03-13
 */
@Getter
@Setter
public class TaskJumpDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "节点名称")
    private String nodeName;

    @Schema(description = "节点key")
    private String nodeKey;

    @Schema(description = "意见评论")
    private String content;


}
