package com.shengyu.module.system.controller.admin.flow;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.common.validation.group.Update;
import com.shengyu.framework.flowlong.engine.core.PageParam;
import com.shengyu.module.system.controller.admin.flow.vo.FlwFormCategoryVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwFormCategory;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.module.system.service.flow.IFlwFormCategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.annotation.Resource;
import javax.validation.constraints.NotEmpty;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 流程表单分类 前端控制器
 *
 * @author hubin
 * @since 2024-05-19
 */
@Tag(name = "流程表单分类")
@RestController
@RequestMapping("/v1/form-category")
public class FormCategoryController {
    @Resource
    private IFlwFormCategoryService flwFormCategoryService;

    @Operation(summary = "分页列表")
    @PreAuthorize("@ss.hasPermission('flw:formCategory:page')")
    @PostMapping("/page")
    public CommonResult<Page<FlwFormCategory>> getPage(@RequestBody PageParam<FlwFormCategory> dto) {
        return success(flwFormCategoryService.page(dto.page(), dto.getData()));
    }

    @Operation(summary = "树列表")
    @PreAuthorize("@ss.hasPermission('flw:formCategory:listTree')")
    @PostMapping("/list-tree")
    public CommonResult<List<FlwFormCategoryVO>> listTree(@RequestBody FlwFormCategory flwFormCategory) {
        return success(flwFormCategoryService.listTree(flwFormCategory));
    }

    @Operation(summary = "列表（显示所有部门）")
    @PreAuthorize("@ss.hasPermission('flw:formCategory:listAll')")
    @GetMapping("/list-all")
    public CommonResult<List<FlwFormCategory>> listAll() {
        return success(flwFormCategoryService.listAll());
    }

    @Operation(summary = "查询 id 信息")
    @PreAuthorize("@ss.hasPermission('flw:formCategory:get')")
    @GetMapping("/get")
    public CommonResult<FlwFormCategory> get(@RequestParam Long id) {
        return success(flwFormCategoryService.getById(id));
    }

    @Operation(summary = "根据 id 修改信息")
    @PreAuthorize("@ss.hasPermission('flw:formCategory:update')")
    @PostMapping("/update")
    public CommonResult<Boolean> update(@Validated(Update.class) @RequestBody FlwFormCategory flwFormCategory) {
        return success(flwFormCategoryService.updateById(flwFormCategory));
    }

    @Operation(summary = "创建添加")
    @PreAuthorize("@ss.hasPermission('flw:formCategory:create')")
    @PostMapping("/create")
    public CommonResult<Boolean> create(@Validated(Create.class) @RequestBody FlwFormCategory flwFormCategory) {
        return success(flwFormCategoryService.save(flwFormCategory));
    }

    @Operation(summary = "根据 ids 删除")
    @PreAuthorize("@ss.hasPermission('flw:formCategory:delete')")
    @PostMapping("/delete")
    public CommonResult<Boolean> delete(@NotEmpty @RequestBody List<Long> ids) {
        return success(flwFormCategoryService.removeByIds(ids));
    }
}
