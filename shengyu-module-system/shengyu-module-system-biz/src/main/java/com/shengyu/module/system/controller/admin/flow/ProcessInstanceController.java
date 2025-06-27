package com.shengyu.module.system.controller.admin.flow;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.framework.flowlong.engine.FlowLongEngine;
import com.shengyu.framework.flowlong.engine.core.PageParam;
import com.shengyu.module.system.controller.admin.flow.dto.DestroyInstanceDTO;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessInstanceDTO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwInstanceVO;
import com.shengyu.module.system.framework.flow.FlowHelper;
import com.shengyu.module.system.service.flow.IFlwProcessService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Map;
import javax.annotation.Resource;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
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

    @Operation(summary = "流程实例分页列表")
    @PreAuthorize("@ss.hasPermission('flw:processInstance:page')")
    @PostMapping("/page")
    public Page<FlwInstanceVO> pageInstance(@RequestBody PageParam<FlwProcessInstanceDTO> dto) {
        return flwProcessService.pageInstance(dto.page(), dto.getData());
    }

    @Operation(summary = "获取所有分类流程定义列表")
    @PreAuthorize("@ss.hasPermission('flw:processInstance:listAll')")
    @Parameters({
            @Parameter(name = "processId", description = "流程ID", in = ParameterIn.PATH)
    })
    @PostMapping("/start/{processId}")
    public boolean start(@PathVariable("processId") Long processId) {
        return flowLongEngine.startInstanceById(processId, FlowHelper.getFlowCreator()).isPresent();
    }

    @Operation(summary = "根据流程实例ID获取流程变量")
    @PreAuthorize("@ss.hasPermission('flw:processInstance:variable')")
    @Parameters({
      @Parameter(name = "instanceId", description = "流程实例ID", in = ParameterIn.PATH)
    })
    @PostMapping("/variable/{instanceId}")
    public Map<String, Object> variable(@PathVariable("instanceId") Long instanceId) {
        return flwProcessService.getVariableByInstanceId(instanceId);
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

    @Operation(summary = "作废流程实例")
    @PreAuthorize("@ss.hasPermission('flw:processInstance:destroy')")
    @PostMapping("/destroy")
    public boolean destroy(@Validated @RequestBody DestroyInstanceDTO dto) {
        return flwProcessService.destroyProcessByInstanceId(dto);
    }

}
