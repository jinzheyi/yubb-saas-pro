package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.shengyu.module.system.framework.engine.core.TenantFlowBaseDO;
import com.shengyu.module.system.dal.dataobject.flow.model.ApprovalContent;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程审批记录
 *
 * @author hubin
 * @since 2024-03-03
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "flw_process_approval", autoResultMap = true)
public class FlwProcessApproval extends TenantFlowBaseDO {

    /**
     * 流程实例ID
     */
    private Long instanceId;

    /**
     * 流程任务ID
     */
    private Long taskId;

    /**
     * 任务名称
     */
    private String taskName;

    /**
     * 任务 key 唯一标识
     */
    private String taskKey;

    /**
     * 审批类型 -1，待审 0，评论 1，发起 2，抄送 3，办理 4，驳回 5，认领 6，转办 7，委派 8，跳转 9，拿回 10，唤醒 11，前加签 12，并加签 13，后加签 14，减签 15，撤销 16，终止 17，超时 18，委派归还任务 19，自动跳转 20，自动完成 21，自动拒绝 22，调用外部流程任务【办理子流程】 23，触发器任务
     */
    private Integer type;

    /**
     * 操作 json 内容
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private ApprovalContent content;

    /**
     * 附件 json 内容
     */
    private String attachments;

}
