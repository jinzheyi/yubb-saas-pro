package com.shengyu.module.system.controller.admin.flow.vo;

import com.shengyu.module.system.dal.dataobject.flow.FlwFormTemplate;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessApproval;
import com.shengyu.framework.flowlong.engine.entity.FlwProcessSetting;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 任务审批 VO
 *
 * @author 青苗
 * @since 2024-03-03
 */
@Getter
@Setter
public class TaskApprovalVO {

    @Schema(description = "流程实例ID")
    private Long instanceId;

    @Schema(description = "流程实例状态 0，审批中 1，审批通过 2，审批拒绝 3，撤销审批 4，超时结束 5，强制终止")
    private Integer instanceState;

    @Schema(description = "任务ID")
    private Long taskId;

    @Schema(description = "任务类型")
    private Integer taskType;

    @Schema(description = "任务处理的url")
    private String actionUrl;

    @Schema(description = "创建ID")
    private String createId;

    @Schema(description = "创建人")
    private String createBy;

    @Schema(description = "创建时间")
    private LocalDateTime createTime;

    @Schema(description = "流程模型JSON")
    private String modelContent;

    @Schema(description = "渲染节点列表 map 对象 value 值 0 已执行 1 正在执行")
    private Map<String, Integer> renderNodes;

    @Schema(description = "表单内容")
    private String formContent;

    @Schema(description = "表单权限配置")
    private Object formConfig;

    @Schema(description = "允许转交")
    private Boolean allowTransfer;

    @Schema(description = "允许加签/减签")
    private Boolean allowAppendNode;

    @Schema(description = "允许回退")
    private Boolean allowRollback;

    @Schema(description = "允许审批节点手动创建抄送任务")
    private Boolean allowCc;

    @Schema(description = "允许审批节点手动创建传阅任务")
    private Boolean allowCirculate;

    @Schema(description = "允许驳回")
    private Boolean allowRejection;

    @Schema(description = "允许拒绝")
    private Boolean allowRefuse;

    @Schema(description = "驳回策略")
    private Integer rejectStrategy;

    @Schema(description = "允许拿回任务ID")
    private Long reclaimTaskId;

    @Schema(description = "流程设置")
    private FlwProcessSetting processSetting;

    @Schema(description = "流程表单模板")
    private FlwFormTemplate formTemplate;

    @Schema(description = "流程审批记录列表")
    private List<FlwProcessApproval> processApprovals;

}
