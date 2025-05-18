package com.shengyu.module.system.controller.admin.flow.vo;

import com.aizuda.core.ApiConstants;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 流程认领任务 VO
 *
 * @author 青苗
 * @since 2024-01-07
 */
@Getter
@Setter
public class PendingClaimTaskVO {

    @Schema(description = "流程ID")
    private Long processId;

    @Schema(description = "流程名称")
    private String processName;

    @Schema(description = "流程类型")
    private String processType;

    @Schema(description = "流程实例ID")
    private Long instanceId;

    @Schema(description = "当前状态")
    private Integer instanceState;

    @Schema(description = "发起人")
    private String launchBy;

    @JsonFormat(pattern = ApiConstants.DATE_MM)
    @Schema(description = "发起时间")
    private Date launchTime;

    @Schema(description = "当前任务ID")
    private Long taskId;

    @JsonFormat(pattern = ApiConstants.DATE_MM)
    @Schema(description = "创建时间")
    private Date createTime;

    @Schema(description = "当前任务名称")
    private String taskName;

    @Schema(description = "任务 key 唯一标识")
    private String taskKey;
    /**
     * 任务类型 {@link com.aizuda.bpm.engine.core.enums.TaskType}
     */
    @Schema(description = "任务类型")
    protected Integer taskType;
    /**
     * 参与方式 {@link com.aizuda.bpm.engine.core.enums.PerformType}
     */
    @Schema(description = "参与方式")
    protected Integer performType;

    @JsonFormat(pattern = ApiConstants.DATE_MM)
    @Schema(description = "期望任务完成时间")
    protected Date expireTime;

    @JsonFormat(pattern = ApiConstants.DATE_MM)
    @Schema(description = "提醒时间")
    protected Date remindTime;

    @Schema(description = "提醒次数")
    protected Integer remindRepeat;

}
