package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FlwProcessHistoryDTO {

    @Schema(description = "流程定义ID")
    @NotNull
    @PositiveOrZero
    private Long processId;

    @Schema(description = "流程定义名称")
    private String processName;

}
