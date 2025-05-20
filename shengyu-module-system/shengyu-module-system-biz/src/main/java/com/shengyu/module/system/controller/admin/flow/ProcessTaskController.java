package com.shengyu.module.system.controller.admin.flow;

import com.shengyu.module.system.dal.dataobject.flow.dto.*;
import com.shengyu.module.system.dal.dataobject.flow.vo.*;
import com.aizuda.boot.modules.flw.flow.FlowHelper;
import com.aizuda.boot.modules.flw.service.IProcessTaskService;
import com.aizuda.core.api.ApiController;
import com.aizuda.core.api.PageParam;
import com.baomidou.kisso.annotation.Permission;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

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
public class ProcessTaskController extends ApiController {
    private IProcessTaskService processTaskService;

    @Operation(summary = "待认领任务分页列表")
    @Permission("flw:processTask:pagePendingClaim")
    @PostMapping("/page-pending-claim")
    public Page<PendingClaimTaskVO> pagePendingClaim(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return processTaskService.pagePendingClaim(pageParam);
    }

    @Operation(summary = "待审批任务分页列表")
    @Permission("flw:processTask:pagePendingApproval")
    @PostMapping("/page-pending-approval")
    public Page<PendingApprovalTaskVO> pagePendingApproval(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return processTaskService.pagePendingApproval(pageParam);
    }

    @Operation(summary = "我收到的任务分页列表")
    @Permission("flw:processTask:pageMyReceived")
    @PostMapping("/page-my-received")
    public Page<ProcessTaskVO> pageMyReceived(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return processTaskService.pageMyReceived(pageParam);
    }

    @Operation(summary = "我的申请任务分页列表")
    @Permission("flw:processTask:pageMyApplication")
    @PostMapping("/page-my-application")
    public Page<ProcessTaskVO> pageMyApplication(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return processTaskService.pageMyApplication(pageParam);
    }

    @Operation(summary = "已审批任务分页列表")
    @Permission("flw:processTask:pageApproved")
    @PostMapping("/page-approved")
    public Page<ProcessTaskVO> pageApproved(@RequestBody PageParam<ProcessTaskDTO> pageParam) {
        return processTaskService.pageApproved(pageParam);
    }

    @Operation(summary = "审批信息")
    @Permission("flw:processTask:approvalInfo")
    @PostMapping("/approval-info")
    public TaskApprovalVO approvalInfo(@Validated @RequestBody ProcessInfoDTO dto) {
        return processTaskService.approvalInfo(dto);
    }

    @Operation(summary = "以前的节点名称列表")
    @Permission("flw:processTask:previousNodes")
    @PostMapping("/previous-nodes/{taskId}")
    public List<Map<String, String>> previousNodes(@PathVariable("taskId") Long taskId) {
        return processTaskService.listPreviousNodes(taskId);
    }

    @Operation(summary = "获取下一个节点列表")
    @Permission("flw:processTask:nextNodes")
    @PostMapping("/next-nodes")
    public Map<String, Object> nextNodes(@Validated @RequestBody NextNodesDTO dto) {
        return processTaskService.listNextNodes(dto);
    }

    @Operation(summary = "审批评论")
    @Permission("flw:processTask:approval")
    @PostMapping("/comment")
    public boolean comment(@Validated @RequestBody ProcessApprovalDTO dto) {
        return processTaskService.comment(dto);
    }

    @Operation(summary = "审批同意")
    @Permission("flw:processTask:approval")
    @PostMapping("/consent")
    public boolean consent(@Validated @RequestBody TaskApprovalDTO dto) {
        return processTaskService.consent(dto);
    }

    @Operation(summary = "审批拒绝")
    @Permission("flw:processTask:approval")
    @PostMapping("/rejection")
    public boolean rejection(@Validated @RequestBody TaskApprovalDTO dto) {
        return processTaskService.rejection(dto);
    }

    @Operation(summary = "设置已阅读")
    @Permission("flw:processTask:viewed")
    @PostMapping("/viewed-{taskId}")
    public boolean viewed(@PathVariable("taskId") Long taskId) {
        return processTaskService.viewed(taskId);
    }

    @Operation(summary = "拿回任务")
    @Permission("flw:processTask:reclaim")
    @PostMapping("/reclaim-{taskId}")
    public boolean reclaim(@PathVariable("taskId") Long taskId) {
        return processTaskService.reclaim(taskId, FlowHelper.getFlowCreator());
    }

    @Operation(summary = "认领任务")
    @Permission("flw:processTask:resume")
    @PostMapping("/claim-{taskId}")
    public boolean claim(@PathVariable("taskId") Long taskId) {
        return processTaskService.claim(taskId, FlowHelper.getFlowCreator());
    }

    @Operation(summary = "流程实例撤销（用于错误发起审批申请，发起人主动撤销）")
    @Permission("flw:processTask:revoke")
    @PostMapping("/revoke")
    public boolean revoke(@Validated @RequestBody ProcessApprovalDTO dto) {
        return processTaskService.revoke(dto, FlowHelper.getFlowCreator());
    }

    @Operation(summary = "转交任务")
    @Permission("flw:processTask:transfer")
    @PostMapping("/transfer")
    public boolean transfer(@Validated @RequestBody TaskAssigneeDTO dto) {
        return processTaskService.transfer(dto);
    }

    @Operation(summary = "执行任务")
    @Permission("flw:processTask:execute")
    @PostMapping("/execute")
    public boolean execute(@Validated @RequestBody ExecuteTaskDTO dto) {
        return processTaskService.execute(dto);
    }

    @Operation(summary = "驳回至上一步任务")
    @Permission("flw:processTask:reject")
    @PostMapping("/reject")
    public boolean reject(@Validated @RequestBody RejectTaskDTO dto) {
        return processTaskService.reject(dto);
    }

    @Operation(summary = "手动抄送任务")
    @Permission("flw:processTask:carbonCopy")
    @PostMapping("/carbon-copy")
    public boolean carbonCopy(@Validated @RequestBody TaskCarbonCopyDTO dto) {
        return processTaskService.carbonCopy(dto);
    }

    @Operation(summary = "审批加签")
    @Permission("flw:processTask:appendNode")
    @PostMapping("/append-node")
    public boolean appendNode(@Validated @RequestBody TaskAppendNodeDTO dto) {
        return processTaskService.appendNode(dto);
    }

    @Operation(summary = "跳到指定节点任务")
    @Permission("flw:processTask:withdraw")
    @PostMapping("/jump")
    public boolean jump(@Validated @RequestBody TaskJumpDTO dto) {
        return processTaskService.jump(dto);
    }

    @Operation(summary = "当前用户待办任务数量")
    @Permission("flw:processTask:countPendingApproval")
    @PostMapping("/count-pending-approval")
    public Integer countPendingApproval() {
        return processTaskService.countPendingApproval();
    }

    @Operation(summary = "查询流程实例ID的审批历史")
    @Permission("flw:processTask:reject")
    @PostMapping("/list-his-task/{instanceId}")
    public List<FlwHisTaskVO> listHisTask(@PathVariable("instanceId") Long instanceId) {
        return processTaskService.listHisTaskByInstanceId(instanceId);
    }

    @Operation(summary = "任务催办")
    @Permission("flw:processTask:urge")
    @PostMapping("/urge/{instanceId}")
    public boolean urge(@PathVariable("instanceId") Long instanceId) {
        return processTaskService.urgeByInstanceId(instanceId);
    }

}
