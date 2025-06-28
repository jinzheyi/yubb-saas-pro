package com.shengyu.module.system.controller.admin.flow;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.flowlong.engine.core.PageParam;
import com.shengyu.module.system.controller.admin.flow.dto.*;
import com.shengyu.module.system.controller.admin.flow.vo.*;
import com.shengyu.module.system.framework.flow.FlowHelper;
import com.shengyu.module.system.service.flow.IFlwProcessTaskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 流程任务 前端控制器
 *
 * @author 青苗
 * @since 2023-12-11
 */
@Tag(name = "流程任务")
@RestController
@AllArgsConstructor
@RequestMapping("/v1/process-task")
public class ProcessTaskController {
    private IFlwProcessTaskService processTaskService;

    @Operation(summary = "待认领任务分页列表")
    @PreAuthorize("@ss.hasPermission('flw:processTask:pagePendingClaim')")
    @PostMapping("/page-pending-claim")
    public CommonResult<Page<PendingClaimTaskVO>> pagePendingClaim(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return success(processTaskService.pagePendingClaim(pageParam));
    }

    @Operation(summary = "待审批任务分页列表")
    @PreAuthorize("@ss.hasPermission('flw:processTask:pagePendingApproval')")
    @PostMapping("/page-pending-approval")
    public CommonResult<Page<PendingApprovalTaskVO>> pagePendingApproval(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return success(processTaskService.pagePendingApproval(pageParam));
    }

    @Operation(summary = "我收到的任务分页列表")
    @PreAuthorize("@ss.hasPermission('flw:processTask:pageMyReceived')")
    @PostMapping("/page-my-received")
    public CommonResult<Page<ProcessTaskVO>> pageMyReceived(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return success(processTaskService.pageMyReceived(pageParam));
    }

    @Operation(summary = "我的申请任务分页列表")
    @PreAuthorize("@ss.hasPermission('flw:processTask:pageMyApplication')")
    @PostMapping("/page-my-application")
    public CommonResult<Page<ProcessTaskVO>> pageMyApplication(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return success(processTaskService.pageMyApplication(pageParam));
    }

    @Operation(summary = "已审批任务分页列表")
    @PreAuthorize("@ss.hasPermission('flw:processTask:pageApproved')")
    @PostMapping("/page-approved")
    public CommonResult<Page<ProcessTaskVO>> pageApproved(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return success(processTaskService.pageApproved(pageParam));
    }

    @Operation(summary = "审批信息")
    @PreAuthorize("@ss.hasPermission('flw:processTask:approvalInfo')")
    @PostMapping("/approval-info")
    public CommonResult<TaskApprovalVO> approvalInfo(@Validated @RequestBody ProcessInfoDTO dto) {
        return success(processTaskService.approvalInfo(dto));
    }

    @Operation(summary = "以前的节点名称列表")
    @PreAuthorize("@ss.hasPermission('flw:processTask:previousNodes')")
    @PostMapping("/previous-nodes/{taskId}")
    public CommonResult<List<Map<String, String>>> previousNodes(@PathVariable("taskId") Long taskId) {
        return success(processTaskService.listPreviousNodes(taskId));
    }

    @Operation(summary = "获取下一个节点列表")
    @PreAuthorize("@ss.hasPermission('flw:processTask:nextNodes')")
    @PostMapping("/next-nodes")
    public CommonResult<Map<String, Object>> nextNodes(@Validated @RequestBody NextNodesDTO dto) {
        return success(processTaskService.listNextNodes(dto));
    }

    @Operation(summary = "审批评论")
    @PreAuthorize("@ss.hasPermission('flw:processTask:approval')")
    @PostMapping("/comment")
    public CommonResult<Boolean> comment(@Validated @RequestBody ProcessApprovalDTO dto) {
        return success(processTaskService.comment(dto));
    }

    @Operation(summary = "审批同意")
    @PreAuthorize("@ss.hasPermission('flw:processTask:approval')")
    @PostMapping("/consent")
    public CommonResult<Boolean> consent(@Validated @RequestBody TaskApprovalDTO dto) {
        return success(processTaskService.consent(dto));
    }

    @Operation(summary = "审批拒绝")
    @PreAuthorize("@ss.hasPermission('flw:processTask:approval')")
    @PostMapping("/rejection")
    public CommonResult<Boolean> rejection(@Validated @RequestBody TaskApprovalDTO dto) {
        return success(processTaskService.rejection(dto));
    }

    @Operation(summary = "设置已阅读")
    @PreAuthorize("@ss.hasPermission('flw:processTask:viewed')")
    @PostMapping("/viewed-{taskId}")
    public CommonResult<Boolean> viewed(@PathVariable("taskId") Long taskId) {
        return success(processTaskService.viewed(taskId));
    }

    @Operation(summary = "拿回任务")
    @PreAuthorize("@ss.hasPermission('flw:processTask:reclaim')")
    @PostMapping("/reclaim-{taskId}")
    public CommonResult<Boolean> reclaim(@PathVariable("taskId") Long taskId) {
        return success(processTaskService.reclaim(taskId, FlowHelper.getFlowCreator()));
    }

    @Operation(summary = "认领任务")
    @PreAuthorize("@ss.hasPermission('flw:processTask:resume')")
    @PostMapping("/claim-{taskId}")
    public CommonResult<Boolean> claim(@PathVariable("taskId") Long taskId) {
        return success(processTaskService.claim(taskId, FlowHelper.getFlowCreator()));
    }

    @Operation(summary = "流程实例撤销（用于错误发起审批申请，发起人主动撤销）")
    @PreAuthorize("@ss.hasPermission('flw:processTask:revoke')")
    @PostMapping("/revoke")
    public CommonResult<Boolean> revoke(@Validated @RequestBody ProcessApprovalDTO dto) {
        return success(processTaskService.revoke(dto, FlowHelper.getFlowCreator()));
    }

    @Operation(summary = "转交任务")
    @PreAuthorize("@ss.hasPermission('flw:processTask:transfer')")
    @PostMapping("/transfer")
    public CommonResult<Boolean> transfer(@Validated @RequestBody TaskAssigneeDTO dto) {
        return success(processTaskService.transfer(dto));
    }

    @Operation(summary = "执行任务")
    @PreAuthorize("@ss.hasPermission('flw:processTask:execute')")
    @PostMapping("/execute")
    public CommonResult<Boolean> execute(@Validated @RequestBody ExecuteTaskDTO dto) {
        return success(processTaskService.execute(dto));
    }

    @Operation(summary = "驳回至上一步任务")
    @PreAuthorize("@ss.hasPermission('flw:processTask:reject')")
    @PostMapping("/reject")
    public CommonResult<Boolean> reject(@Validated @RequestBody RejectTaskDTO dto) {
        return success(processTaskService.reject(dto));
    }

    @Operation(summary = "手动抄送任务")
    @PreAuthorize("@ss.hasPermission('flw:processTask:carbonCopy')")
    @PostMapping("/carbon-copy")
    public CommonResult<Boolean> carbonCopy(@Validated @RequestBody TaskCarbonCopyDTO dto) {
        return success(processTaskService.carbonCopy(dto));
    }

    @Operation(summary = "审批加签")
    @PreAuthorize("@ss.hasPermission('flw:processTask:appendNode')")
    @PostMapping("/append-node")
    public CommonResult<Boolean> appendNode(@Validated @RequestBody TaskAppendNodeDTO dto) {
        return success(processTaskService.appendNode(dto));
    }

    @Operation(summary = "跳到指定节点任务")
    @PreAuthorize("@ss.hasPermission('flw:processTask:withdraw')")
    @PostMapping("/jump")
    public CommonResult<Boolean> jump(@Validated @RequestBody TaskJumpDTO dto) {
        return success(processTaskService.jump(dto));
    }

    @Operation(summary = "当前用户待办任务数量")
    @PreAuthorize("@ss.hasPermission('flw:processTask:countPendingApproval')")
    @PostMapping("/count-pending-approval")
    public CommonResult<Integer> countPendingApproval() {
        return success(processTaskService.countPendingApproval());
    }

    @Operation(summary = "查询流程实例ID的审批历史")
    @PreAuthorize("@ss.hasPermission('flw:processTask:reject')")
    @PostMapping("/list-his-task/{instanceId}")
    public CommonResult<List<FlwHisTaskVO>> listHisTask(@PathVariable("instanceId") Long instanceId) {
        return success(processTaskService.listHisTaskByInstanceId(instanceId));
    }

    @Operation(summary = "任务催办")
    @PreAuthorize("@ss.hasPermission('flw:processTask:urge')")
    @PostMapping("/urge/{instanceId}")
    public CommonResult<Boolean> urge(@PathVariable("instanceId") Long instanceId) {
        return success(processTaskService.urgeByInstanceId(instanceId));
    }

}
