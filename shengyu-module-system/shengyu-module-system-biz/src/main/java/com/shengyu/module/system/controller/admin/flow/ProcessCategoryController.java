package com.shengyu.module.system.controller.admin.flow;

import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.common.validation.group.Update;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessCategory;
import com.shengyu.module.system.service.flow.IFlwProcessCategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 流程分类 前端控制器
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Tag(name = "流程分类")
@RestController
@AllArgsConstructor
@RequestMapping("/v1/process-category")
public class ProcessCategoryController {
    private IFlwProcessCategoryService flwProcessCategoryService;

    @Operation(summary = "根据 id 修改信息")
    @PreAuthorize("@ss.hasPermission('flw:processCategory:update')")
    @PostMapping("/update")
    public boolean update(@Validated(Update.class) @RequestBody FlwProcessCategory flwProcessCategory) {
        return flwProcessCategoryService.updateById(flwProcessCategory);
    }

    @Operation(summary = "所有列表")
    @PreAuthorize("@ss.hasPermission('flw:processCategory:listAll')")
    @PostMapping("/list-all")
    public List<FlwProcessCategory> listAll() {
        return flwProcessCategoryService.listAll();
    }

    @Operation(summary = "创建添加")
    @PreAuthorize("@ss.hasPermission('flw:processCategory:create')")
    @PostMapping("/create")
    public boolean create(@Validated(Create.class) @RequestBody FlwProcessCategory flwProcessCategory) {
        return flwProcessCategoryService.save(flwProcessCategory);
    }

    @Operation(summary = "根据 ids 删除")
    @PreAuthorize("@ss.hasPermission('flw:processCategory:delete')")
    @PostMapping("/delete")
    public boolean delete(@NotEmpty @RequestBody List<Long> ids) {
        return flwProcessCategoryService.removeCategoryByIds(ids);
    }
}
