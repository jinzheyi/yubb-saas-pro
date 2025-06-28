package com.shengyu.module.system.controller.admin.flow;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.common.validation.group.Update;
import com.shengyu.framework.flowlong.engine.core.PageParam;
import com.shengyu.module.system.dal.dataobject.flow.FlwFormTemplate;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.module.system.service.flow.IFlwFormTemplateService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 流程表单模板 前端控制器
 *
 * @author hubin
 * @since 2024-05-19
 */
@Tag(name = "流程表单模板")
@RestController
@AllArgsConstructor
@RequestMapping("/v1/form-template")
public class FormTemplateController {
    private IFlwFormTemplateService flwFormTemplateService;

    @Operation(summary = "分页列表")
    @PreAuthorize("@ss.hasPermission('flw:formTemplate:page')")
    @PostMapping("/page")
    public CommonResult<Page<FlwFormTemplate>> getPage(@RequestBody PageParam<FlwFormTemplate> dto) {
        return success(flwFormTemplateService.page(dto.page(), dto.getData()));
    }

    @Operation(summary = "简单分页列表")
    @PreAuthorize("@ss.hasPermission('flw:formTemplate:pageSimple')")
    @PostMapping("/page-simple")
    public CommonResult<Page<FlwFormTemplate>> getPageSimple(@RequestBody PageParam<FlwFormTemplate> dto) {
        return success(flwFormTemplateService.pageSimple(dto.page(), dto.getData()));
    }

    @Operation(summary = "查询 id 信息")
    @PreAuthorize("@ss.hasPermission('flw:formTemplate:get')")
    @GetMapping("/get")
    public CommonResult<FlwFormTemplate> get(@RequestParam Long id) {
        return success(flwFormTemplateService.getById(id));
    }

    @Operation(summary = "根据 id 修改信息")
    @PreAuthorize("@ss.hasPermission('flw:formTemplate:update')")
    @PostMapping("/update")
    public CommonResult<Boolean> update(@Validated(Update.class) @RequestBody FlwFormTemplate flwFormTemplate) {
        return success(flwFormTemplateService.updateById(flwFormTemplate));
    }

    @Operation(summary = "根据 id 修改状态")
    @PreAuthorize("@ss.hasPermission('flw:formTemplate:status')")
    @PostMapping("/status/{id}")
    public CommonResult<Boolean> status(@PathVariable("id") Long id, @RequestParam Integer status) {
        return success(flwFormTemplateService.updateStatusById(id, status));
    }

    @Operation(summary = "创建添加")
    @PreAuthorize("@ss.hasPermission('flw:formTemplate:create')")
    @PostMapping("/create")
    public CommonResult<Boolean> create(@Validated(Create.class) @RequestBody FlwFormTemplate flwFormTemplate) {
        return success(flwFormTemplateService.save(flwFormTemplate));
    }

    @Operation(summary = "根据 ids 删除")
    @PreAuthorize("@ss.hasPermission('flw:formTemplate:delete')")
    @PostMapping("/delete")
    public CommonResult<Boolean> delete(@NotEmpty @RequestBody List<Long> ids) {
        return success(flwFormTemplateService.removeNotBindByIds(ids));
    }
}
