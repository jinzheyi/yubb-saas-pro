package com.shengyu.module.system.controller.admin.flow.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.shengyu.framework.flowlong.engine.core.CirculateArgs;
import com.shengyu.framework.flowlong.engine.core.enums.TaskType;
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

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm")
    @Schema(description = "创建时间")
    private Date createTime;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm")
    @Schema(description = "期望完成时间")
    private Date expireTime;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm")
    @Schema(description = "结束时间")
    private Date endTime;

    @Schema(description = "处理耗时")
    private Long duration;

    @Schema(description = "任务参与者记录id")
    private Long hisTaskActorId;

    @Schema(description = "模型第一个节点key")
    private String firstNodeKey;

    @Schema(description = "当前任务ID")
    private Long taskId;

    /**
     * 任务类型 {@link TaskType}
     */
    @Schema(description = "任务类型")
    private Integer taskType;

    @Schema(description = "历史任务ID")
    private Long hisTaskId;

    @Schema(description = "传阅的配置")
    private String extend;

    @Schema(description = "传阅的配置")
    private CirculateArgs circulateArgs;

    @Schema(description = "是否已阅 0，否 1，是")
    private Integer viewed;

}
