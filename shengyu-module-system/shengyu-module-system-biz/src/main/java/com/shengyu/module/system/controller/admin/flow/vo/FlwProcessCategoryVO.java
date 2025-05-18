package com.shengyu.module.system.controller.admin.flow.vo;

import com.aizuda.boot.modules.flw.entity.FlwProcessCategory;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

/**
 * 流程定义分类VO
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
public class FlwProcessCategoryVO {

    @Schema(description = "流程分类ID")
    private Long categoryId;

    @Schema(description = "流程分类名称")
    private String categoryName;

    @Schema(description = "备注")
    private String categoryRemark;

    @Schema(description = "排序")
    private Integer categorySort;

    @Schema(description = "流程定义信息列表")
    private List<FlwProcessVO> processList;

    public static FlwProcessCategoryVO of(FlwProcessCategory fpc) {
        FlwProcessCategoryVO vo = new FlwProcessCategoryVO();
        vo.setCategoryId(fpc.getId());
        vo.setCategoryName(fpc.getName());
        vo.setCategoryRemark(fpc.getRemark());
        vo.setCategorySort(fpc.getSort());
        return vo;
    }
}
