package com.shengyu.module.system.controller.admin.flow.dto;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

/**
 * 传阅任务已阅 DTO
 *
 * @author 朱述勇
 * @since 2025-03-30
 */
@Getter
@Setter
public class TaskCirculateViewDTO {

    @Schema(description = "任务参与者记录ID")
    @NotNull(message = "任务参与者记录ID不能为空")
    @PositiveOrZero
    private Long hisTaskActorId;

    @Schema(description = "意见评论")
    private String content;

}
