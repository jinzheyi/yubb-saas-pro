package com.shengyu.module.system.service.flow;

import com.shengyu.module.system.controller.admin.flow.dto.*;
import com.shengyu.module.system.controller.admin.flow.vo.*;
import com.shengyu.module.system.framework.engine.core.FlowCreator;
import com.aizuda.core.api.PageParam;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;

import java.util.List;
import java.util.Map;

/**
 * 流程任务 服务类
 *
 * @author 青苗
 * @since 2023-12-11
 */
public interface ProcessTaskService {

    /**
     * 待认领任务分页列表
     */
    Page<PendingClaimTaskVO> pagePendingClaim(PageParam<ProcessTaskDTO> pageParam);

    /**
     * 待审批任务分页列表
     */
    Page<PendingApprovalTaskVO> pagePendingApproval(PageParam<ProcessTaskDTO> pageParam);

    /**
     * 我的申请任务分页列表
     */
    Page<ProcessTaskVO> pageMyApplication(PageParam<ProcessTaskDTO> pageParam);

    /**
     * 我收到的任务分页列表
     */
    Page<ProcessTaskVO> pageMyReceived(PageParam<ProcessTaskDTO> pageParam);

    /**
     * 已审批任务分页列表
     */
    Page<ProcessTaskVO> pageApproved(PageParam<ProcessTaskDTO> pageParam);

    /**
     * 审批信息
     */
    TaskApprovalVO approvalInfo(ProcessInfoDTO dto);

    /**
     * 根据任务ID查询以前的节点Map列表
     *
     * @param taskId 任务ID
     */
    List<Map<String, String>> listPreviousNodes(Long taskId);

    /**
     * 获取下一个节点列表
     *
     * @param dto {@link NextNodesDTO}
     */
    Map<String, Object> listNextNodes(NextNodesDTO dto);

    /**
     * 设置任务为已阅状态
     *
     * @param taskId 任务ID
     */
    boolean viewed(Long taskId);

    /**
     * 拿回任务
     *
     * @param taskId      任务ID
     * @param flowCreator 任务创建者
     */
    boolean reclaim(Long taskId, FlowCreator flowCreator);

    /**
     * 认领任务
     *
     * @param taskId      任务ID
     * @param flowCreator 任务创建者
     */
    boolean claim(Long taskId, FlowCreator flowCreator);

    /**
     * 发起人撤回任务
     *
     * @param taskId      任务ID
     * @param flowCreator 任务创建者
     */
    boolean withdraw(Long taskId, FlowCreator flowCreator);

    /**
     * 流程实例撤销（用于错误发起审批申请，发起人主动撤销）
     */
    boolean revoke(ProcessApprovalDTO dto, FlowCreator flowCreator);

    /**
     * 执行流程任务
     */
    boolean execute(ExecuteTaskDTO dto);

    /**
     * 查询流程实例ID的审批历史
     *
     * @param instanceId 流程实例ID
     * @return 审批历史VO列表
     */
    List<FlwHisTaskVO> listHisTaskByInstanceId(Long instanceId);

    /**
     * 驳回至上一步任务
     */
    boolean reject(RejectTaskDTO dto);

    /**
     * 转交
     */
    boolean transfer(TaskAssigneeDTO dto);

    /**
     * 审批评论
     */
    boolean comment(ProcessApprovalDTO dto);

    /**
     * 审批同意
     */
    boolean consent(TaskApprovalDTO dto);

    /**
     * 审批拒绝
     */
    boolean rejection(TaskApprovalDTO dto);

    /**
     * 加签
     */
    boolean appendNode(TaskAppendNodeDTO dto);

    /**
     * 执行节点跳转任务
     */
    boolean jump(TaskJumpDTO dto);

    /**
     * 当前用户待办任务数量
     */
    Integer countPendingApproval();

    /**
     * 流程任务催办
     */
    boolean urgeByInstanceId(Long instanceId);
}
