package com.shengyu.module.system.controller.admin.flow.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.shengyu.framework.common.enums.SyConstants;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

@Getter
@Setter
public class FlwProcessInstanceDTO {

    @Schema(description = "流程分类ID")
    protected Long processCategoryId;

    @Schema(description = "已经完成（默认否）")
    protected Boolean completed;

    @Schema(description = "流程定义名称")
    protected String processName;

    @Schema(description = "当前所在节点名称")
    protected String currentNodeName;

    @Schema(description = "流程实例ID")
    private Long instanceId;

    @Schema(description = "流程实例状态 -1，暂存待审 0，审批中 1，审批通过 2，审批拒绝 3，撤销审批 4，超时结束 5，强制终止")
    private Integer instanceState;

    @Schema(description = "发起人ID")
    private String createId;

    @Schema(description = "创建人")
    private String createBy;

    @JsonFormat(timezone = "GMT+8", pattern = SyConstants.DATE_MM_SS)
    @Schema(description = "开始时间")
    private Date beginTime;

    @JsonFormat(timezone = "GMT+8", pattern = SyConstants.DATE_MM_SS)
    @Schema(description = "结束时间")
    private Date endTime;

}
