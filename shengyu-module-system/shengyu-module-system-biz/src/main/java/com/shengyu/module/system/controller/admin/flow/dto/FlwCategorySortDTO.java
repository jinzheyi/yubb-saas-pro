package com.shengyu.module.system.controller.admin.flow.dto;

import com.aizuda.boot.modules.flw.entity.FlwProcessCategory;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class FlwCategorySortDTO {

    @Schema(description = "流程分类ID")
    private Long categoryId;

    @Schema(description = "流程ID列表")
    private List<Long> processIds;

    public FlwProcessCategory toFlwProcessCategory(Integer sort) {
        FlwProcessCategory fpc = new FlwProcessCategory();
        fpc.setId(categoryId);
        fpc.setSort(sort);
        return fpc;
    }
}
