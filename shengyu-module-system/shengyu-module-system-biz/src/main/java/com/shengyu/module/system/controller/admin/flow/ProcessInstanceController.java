package com.shengyu.module.system.controller.admin.flow;

import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.module.system.framework.flow.FlowHelper;
import com.shengyu.module.system.service.flow.IFlwProcessService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.annotation.Resource;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 流程实例 前端控制器
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Tag(name = "流程实例")
@RestController
@RequestMapping("/v1/process-instance")
public class ProcessInstanceController {
    @Resource
    private IFlwProcessService flwProcessService;
    @Resource
    private FlowLongEngine flowLongEngine;

    @Operation(summary = "获取所有分类流程定义列表")
    @PreAuthorize("@ss.hasPermission('flw:processInstance:listAll')")
    @Parameters({
            @Parameter(name = "processId", description = "流程ID", in = ParameterIn.PATH)
    })
    @PostMapping("/start/{processId}")
    public boolean start(@PathVariable("processId") Long processId) {
        return flowLongEngine.startInstanceById(processId, FlowHelper.getFlowCreator()).isPresent();
    }

    @Operation(summary = "根据流程实例ID删除暂存待审流程实例")
    @PreAuthorize("@ss.hasPermission('flw:processInstance:remove')")
    @Parameters({
            @Parameter(name = "instanceId", description = "流程实例ID", in = ParameterIn.PATH)
    })
    @PostMapping("/remove/{instanceId}")
    public boolean remove(@PathVariable("instanceId") Long instanceId) {
        return flwProcessService.removeProcessByInstanceId(instanceId);
    }

    @Operation(summary = "根据流程实例ID唤醒撤销拒审终止流程实例")
    @PreAuthorize("@ss.hasPermission('flw:processInstance:resume')")
    @Parameters({
            @Parameter(name = "instanceId", description = "流程实例ID", in = ParameterIn.PATH)
    })
    @PostMapping("/resume/{instanceId}")
    public boolean resume(@PathVariable("instanceId") Long instanceId) {
        return flwProcessService.resumeProcessByInstanceId(instanceId);
    }

}
