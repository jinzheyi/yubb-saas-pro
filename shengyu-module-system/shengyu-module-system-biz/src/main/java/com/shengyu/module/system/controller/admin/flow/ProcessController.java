package com.shengyu.module.system.controller.admin.flow;

import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.flowlong.engine.core.PageParam;
import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.module.system.controller.admin.flow.dto.FlwCategorySortDTO;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessDTO;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessHistoryDTO;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessStartDTO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwProcessCategoryVO;
import com.shengyu.module.system.framework.flow.FlowHelper;
import com.shengyu.module.system.service.flow.IFlwProcessService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 流程定义 前端控制器
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Tag(name = "流程定义")
@RestController
@AllArgsConstructor
@RequestMapping("/v1/process")
public class ProcessController {
    private IFlwProcessService flwProcessService;

    @Operation(summary = "历史分页列表")
    @PreAuthorize("@ss.hasPermission('flw:process:page')")
    @PostMapping("/page-history")
    public Page<FlwProcess> getPageHistory(@RequestBody PageParam<FlwProcessHistoryDTO> dto) {
        return flwProcessService.pageHistory(dto.page(), dto.getData());
    }

    @Operation(summary = "获取所有分类流程定义列表")
    @PreAuthorize("@ss.hasPermission('flw:process:listCategory')")
    @Parameters({
            @Parameter(name = "keyword", description = "关键词")
    })
    @PostMapping("/list-category")
    public List<FlwProcessCategoryVO> listCategory(@RequestParam(required = false) String keyword) {
        return flwProcessService.listCategoryAll(keyword);
    }

    @Operation(summary = "获取发起分类流程定义列表")
    @PreAuthorize("@ss.hasPermission('flw:process:listLaunch')")
    @Parameters({
            @Parameter(name = "keyword", description = "关键词")
    })
    @PostMapping("/list-launch")
    public List<FlwProcessCategoryVO> listLaunch(@RequestParam(required = false) String keyword) {
        return flwProcessService.listLaunch(keyword);
    }

    @Operation(summary = "查询满足条件前10条子流程列表")
    @PreAuthorize("@ss.hasPermission('flw:process:listStart')")
    @Parameters({
            @Parameter(name = "keyword", description = "关键词")
    })
    @PostMapping("/list-child-top10")
    public List<FlwProcess> listChildTop10(@RequestParam(required = false) String keyword) {
        return flwProcessService.listChildTop10(keyword);
    }

    @Operation(summary = "发起流程")
    @PreAuthorize("@ss.hasPermission('flw:process:launch')")
    @PostMapping("/launch")
    public boolean launchProcess(@RequestBody ProcessStartDTO dto) {
        return flwProcessService.launchProcess(dto, FlowHelper.getFlowCreator()) != null;
    }

    @Operation(summary = "根据 id 获取模型")
    @Parameters({
            @Parameter(name = "id", description = "流程ID")
    })
    @PreAuthorize("@ss.hasPermission('flw:process:nodeModel')")
    @PostMapping("/node-model")
    public String nodeModel(@RequestParam Long id) {
        return flwProcessService.getNodeModelById(id);
    }

    @Operation(summary = "查询 id 信息")
    @Parameters({
            @Parameter(name = "id", description = "流程ID")
    })
    @PreAuthorize("@ss.hasPermission('flw:process:get')")
    @GetMapping("/get")
    public FlwProcessDTO get(@RequestParam Long id) {
        return flwProcessService.getDtoById(id);
    }

    @Operation(summary = "查询 key 业务流程信息")
    @Parameters({
            @Parameter(name = "key", description = "流程KEY")
    })
    @PreAuthorize("@ss.hasPermission('flw:process:business')")
    @GetMapping("/business")
    public FlwProcessDTO business(@RequestParam String key) {
        return flwProcessService.getDtoByKey(key);
    }

    @Operation(summary = "查询 id 克隆流程定义信息")
    @Parameters({
            @Parameter(name = "id", description = "流程ID")
    })
    @PreAuthorize("@ss.hasPermission('flw:process:clone')")
    @GetMapping("/clone")
    public boolean clone(@RequestParam Long id) {
        return flwProcessService.cloneById(id);
    }

    @Operation(summary = "创建添加")
    @PreAuthorize("@ss.hasPermission('flw:process:create')")
    @PostMapping("/create")
    public Long create(@Validated @RequestBody FlwProcessDTO dto) {
        return flwProcessService.saveDto(dto);
    }

    @Operation(summary = "根据流程定义ID删除流程定义相关信息")
    @Parameters({
            @Parameter(name = "id", description = "主键ID")
    })
    @PreAuthorize("@ss.hasPermission('flw:process:delete')")
    @PostMapping("/delete")
    public boolean delete(@RequestParam Long id) {
        return flwProcessService.removeProcessInfo(id);
    }

    @Operation(summary = "流程排序")
    @PreAuthorize("@ss.hasPermission('flw:process:sort')")
    @PostMapping("/sort")
    public boolean sort(@Validated(Create.class) @RequestBody List<FlwCategorySortDTO> dtoList) {
        return flwProcessService.sort(dtoList);
    }

    @Operation(summary = "根据流程定义ID更新流程状态")
    @Parameters({
            @Parameter(name = "id", description = "主键ID"),
            @Parameter(name = "state", description = "流程状态 0，不可用 1，可用")
    })
    @PreAuthorize("@ss.hasPermission('flw:process:updateSate')")
    @PostMapping("/update-state-{id}")
    public boolean updateSate(@PathVariable("id") Long id, @RequestParam Integer state) {
        return flwProcessService.updateSateById(id, state);
    }

    @Operation(summary = "根据指定ID签出历史流程")
    @Parameters({
            @Parameter(name = "id", description = "流程ID")
    })
    @PreAuthorize("@ss.hasPermission('flw:process:checkout')")
    @PostMapping("/checkout")
    public boolean checkout(@RequestParam Long id) {
        return flwProcessService.checkoutById(id);
    }

}
