package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;

/**
 * 获取下一个节点DTO
 *
 * @author 青苗
 * @since 2024-12-19
 */
@Getter
@Setter
public class NextNodesDTO {

    @Schema(description = "流程实例ID")
    @NotNull
    @PositiveOrZero
    private Long instanceId;

    @Schema(description = "执行参数")
    private Map<String, Object> args;

}
