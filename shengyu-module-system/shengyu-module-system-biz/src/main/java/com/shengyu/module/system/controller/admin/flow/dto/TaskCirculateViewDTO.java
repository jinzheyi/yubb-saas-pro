package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.annotations.ApiModelProperty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
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

    @ApiModelProperty(value = "任务参与者记录ID")
    @NotNull(message = "任务参与者记录ID不能为空")
    @PositiveOrZero
    private Long hisTaskActorId;

    @ApiModelProperty(value = "意见评论")
    private String content;

}
