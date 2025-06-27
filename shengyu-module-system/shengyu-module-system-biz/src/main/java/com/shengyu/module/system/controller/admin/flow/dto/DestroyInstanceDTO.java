package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class DestroyInstanceDTO {

    @Schema(description = "流程实例ID")
    @NotNull
    @PositiveOrZero
    private Long instanceId;

    @Schema(description = "审批意见")
    private String opinion;

}
