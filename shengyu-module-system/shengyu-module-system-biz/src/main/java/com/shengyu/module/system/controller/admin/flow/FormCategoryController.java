package com.shengyu.module.system.controller.admin.flow;

import com.shengyu.module.system.dal.dataobject.flow.FlwFormCategory;
import com.shengyu.module.system.dal.dataobject.flow.vo.FlwFormCategoryVO;
import com.aizuda.boot.modules.flw.service.IFlwFormCategoryService;
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
 * 流程表单分类 前端控制器
 *
 * @author hubin
 * @since 2024-05-19
 */
@Tag(name = "流程表单分类")
@RestController
@AllArgsConstructor
@RequestMapping("/v1/form-category")
public class FormCategoryController extends ApiController {
    private IFlwFormCategoryService flwFormCategoryService;

    @Operation(summary = "分页列表")
    @Permission("flw:formCategory:page")
    @PostMapping("/page")
    public Page<FlwFormCategory> getPage(@RequestBody PageParam<FlwFormCategory> dto) {
        return flwFormCategoryService.page(dto.page(), dto.getData());
    }

    @Operation(summary = "树列表")
    @Permission("flw:formCategory:listTree")
    @PostMapping("/list-tree")
    public List<FlwFormCategoryVO> listTree(@RequestBody FlwFormCategory flwFormCategory) {
        return flwFormCategoryService.listTree(flwFormCategory);
    }

    @Operation(summary = "列表（显示所有部门）")
    @Permission("flw:formCategory:listAll")
    @GetMapping("/list-all")
    public List<FlwFormCategory> listAll() {
        return flwFormCategoryService.listAll();
    }

    @Operation(summary = "查询 id 信息")
    @Permission("flw:formCategory:get")
    @GetMapping("/get")
    public FlwFormCategory get(@RequestParam Long id) {
        return flwFormCategoryService.getById(id);
    }

    @Operation(summary = "根据 id 修改信息")
    @Permission("flw:formCategory:update")
    @PostMapping("/update")
    public boolean update(@Validated(Update.class) @RequestBody FlwFormCategory flwFormCategory) {
        return flwFormCategoryService.updateById(flwFormCategory);
    }

    @Operation(summary = "创建添加")
    @Permission("flw:formCategory:create")
    @PostMapping("/create")
    public boolean create(@Validated(Create.class) @RequestBody FlwFormCategory flwFormCategory) {
        return flwFormCategoryService.save(flwFormCategory);
    }

    @Operation(summary = "根据 ids 删除")
    @Permission("flw:formCategory:delete")
    @PostMapping("/delete")
    public boolean delete(@NotEmpty @RequestBody List<Long> ids) {
        return flwFormCategoryService.removeByIds(ids);
    }
}
