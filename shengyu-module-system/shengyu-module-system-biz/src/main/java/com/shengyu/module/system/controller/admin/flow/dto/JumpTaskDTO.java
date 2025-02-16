package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

/**
 * 跳转任务DTO
 *
 * @author 青苗
 * @since 2024-01-09
 */
@Getter
@Setter
public class JumpTaskDTO extends ExecuteTaskDTO {

    @Schema(description = "退回节点")
    private String nodeName;

}
