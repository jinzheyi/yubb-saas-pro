package com.shengyu.module.system.controller.admin.flow.dto;

import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.model.DynamicAssignee;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Map;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程任务审批 DTO
 *
 * @author 朱述勇
 * @since 2024-03-04
 */
@Getter
@Setter
public class TaskRefuseDTO {

    @Schema(description = "流程任务ID")
    @NotNull
    @PositiveOrZero
    private Long taskId;

    @Schema(description = "流程表单JSON内容")
    private String processForm;

    @Schema(description = "意见评论")
    private String content;

    @Schema(description = "动态分配处理人员")
    private Map<String, DynamicAssignee> assigneeMap;

    @Schema(description = "执行参数")
    private Map<String, Object> args;

    @Schema(description = "操作者。如果传递了这个参数会取传递的，主要为了兼容外部系统调用的判断")
    private FlowCreator flowCreator;

}
