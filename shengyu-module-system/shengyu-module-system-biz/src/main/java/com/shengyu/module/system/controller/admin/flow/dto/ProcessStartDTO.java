package com.shengyu.module.system.controller.admin.flow.dto;

import com.shengyu.module.system.framework.engine.model.DynamicAssignee;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;

/**
 * 流程发起 DTO
 *
 * @author 青苗
 * @since 2023-12-12
 */
@Getter
@Setter
public class ProcessStartDTO {

    @Schema(description = "流程ID")
    private Long processId;

    @Schema(description = "流程表单JSON内容")
    private String processForm;

    @Schema(description = "业务KEY")
    private String businessKey;

    @Schema(description = "动态分配处理人员")
    private Map<String, DynamicAssignee> assigneeMap;

}
