package com.shengyu.module.system.dal.dataobject.flow.model;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程定义配置
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
public class FlwProcessSetting {

    /**
     * 第一个审批节点通过后，提交人仍可撤销申请（配置前已发起ssss的申请不生效）
     */
    @Schema(description = "允许撤销审批中的申请")
    private Boolean allowRevocation;

    /**
     * 员工可申请撤销已通过的审批（配置前已通过的审批不可撤销）
     */
    @Schema(description = "允许撤销指定天内通过的审批")
    private Boolean allowRevocationDay;

    /**
     * 提交人可申请修改已通过的审批，用于销假等场景（仅可修改一次，配置前已发起的审批不可修改）
     */
    @Schema(description = "允许修改指定天内通过的审批")
    private Boolean allowUpdateDay;

    /**
     * 代提人和实际提交人都需在该审批的发起范围内，提交后将共享审批单后续状态
     */
    @Schema(description = "允许代他人提交")
    private Boolean allowDelegate;

    /**
     * 勾选后，审批人在处理此流程的任务时，可一次批量处理多个任务
     */
    @Schema(description = "允许审批人批量处理")
    private Boolean allowBatchOperate;

    /**
     * 若审批人浏览单据小于3秒或通过快捷审批处理，系统会在审批记录中进行标记
     */
    @Schema(description = "开启秒批提示")
    private Boolean secondOperatePrompt;

    /**
     * 1，仅审批一次，后续重复的审批节点均自动同意
     * 2，仅针对连续审批的节点自动同意
     * 3，不自动同意，每个节点都需要审批
     */
    @Schema(description = "重复审批跳过")
    private Boolean repeatOperateSkip;

}
