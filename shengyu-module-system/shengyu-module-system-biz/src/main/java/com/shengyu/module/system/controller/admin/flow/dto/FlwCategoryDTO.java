package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FlwCategoryDTO {

    @Schema(description = "名称")
    private String name;

    @Schema(description = "备注")
    private String remark;

}
