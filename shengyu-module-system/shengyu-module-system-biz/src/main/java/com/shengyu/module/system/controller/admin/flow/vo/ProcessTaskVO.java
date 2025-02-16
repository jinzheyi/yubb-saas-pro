package com.shengyu.module.system.controller.admin.flow.vo;

import com.aizuda.core.ApiConstants;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 流程任务VO
 *
 * @author 青苗
 * @since 2023-12-11
 */
@Getter
@Setter
public class ProcessTaskVO {

    @Schema(description = "流程ID")
    private Long processId;

    @Schema(description = "流程名称")
    private String processName;

    @Schema(description = "流程类型")
    private String processType;

    @Schema(description = "当前所在节点名称")
    private String currentNodeName;

    @Schema(description = "当前所在节点key")
    private String currentNodeKey;

    @Schema(description = "流程实例ID")
    private Long instanceId;

    @Schema(description = "当前状态")
    private Integer instanceState;

    @Schema(description = "发起人ID")
    private String createId;

    @Schema(description = "发起人")
    private String createBy;

    @JsonFormat(pattern = ApiConstants.DATE_MM)
    @Schema(description = "创建时间")
    private Date createTime;

    @JsonFormat(pattern = ApiConstants.DATE_MM)
    @Schema(description = "期望完成时间")
    private Date expireTime;

    @JsonFormat(pattern = ApiConstants.DATE_MM)
    @Schema(description = "结束时间")
    private Date endTime;

    @Schema(description = "处理耗时")
    private Long duration;

}
