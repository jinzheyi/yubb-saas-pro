package com.shengyu.module.system.controller.admin.flow.vo;

import com.aizuda.boot.modules.flw.entity.FlwFormCategory;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class FlwFormCategoryVO extends FlwFormCategory {

    /**
     * 父级部门
     */
    private String parentName;
    /**
     * 子部门
     */
    private List<FlwFormCategoryVO> children;
}
