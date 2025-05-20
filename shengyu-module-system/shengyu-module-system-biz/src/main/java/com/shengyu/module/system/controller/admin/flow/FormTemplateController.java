package com.shengyu.module.system.controller.admin.flow;

import com.shengyu.module.system.dal.dataobject.flow.FlwFormTemplate;
import com.aizuda.boot.modules.flw.service.IFlwFormTemplateService;
import com.aizuda.core.api.ApiController;
import com.aizuda.core.api.PageParam;
import com.aizuda.core.validation.Create;
import com.aizuda.core.validation.Update;
import com.baomidou.kisso.annotation.Permission;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
public class FormTemplateController extends ApiController {
    private IFlwFormTemplateService flwFormTemplateService;

    @Operation(summary = "分页列表")
    @Permission("flw:formTemplate:page")
    @PostMapping("/page")
    public Page<FlwFormTemplate> getPage(@RequestBody PageParam<FlwFormTemplate> dto) {
        return flwFormTemplateService.page(dto.page(), dto.getData());
    }

    @Operation(summary = "简单分页列表")
    @Permission("flw:formTemplate:pageSimple")
    @PostMapping("/page-simple")
    public Page<FlwFormTemplate> getPageSimple(@RequestBody PageParam<FlwFormTemplate> dto) {
        return flwFormTemplateService.pageSimple(dto.page(), dto.getData());
    }

    @Operation(summary = "查询 id 信息")
    @Permission("flw:formTemplate:get")
    @GetMapping("/get")
    public FlwFormTemplate get(@RequestParam Long id) {
        return flwFormTemplateService.getById(id);
    }

    @Operation(summary = "根据 id 修改信息")
    @Permission("flw:formTemplate:update")
    @PostMapping("/update")
    public boolean update(@Validated(Update.class) @RequestBody FlwFormTemplate flwFormTemplate) {
        return flwFormTemplateService.updateById(flwFormTemplate);
    }

    @Operation(summary = "根据 id 修改状态")
    @Permission("flw:formTemplate:status")
    @PostMapping("/status/{id}")
    public boolean status(@PathVariable("id") Long id, @RequestParam Integer status) {
        return flwFormTemplateService.updateStatusById(id, status);
    }

    @Operation(summary = "创建添加")
    @Permission("flw:formTemplate:create")
    @PostMapping("/create")
    public boolean create(@Validated(Create.class) @RequestBody FlwFormTemplate flwFormTemplate) {
        return flwFormTemplateService.save(flwFormTemplate);
    }

    @Operation(summary = "根据 ids 删除")
    @Permission("flw:formTemplate:delete")
    @PostMapping("/delete")
    public boolean delete(@NotEmpty @RequestBody List<Long> ids) {
        return flwFormTemplateService.removeNotBindByIds(ids);
    }
}
