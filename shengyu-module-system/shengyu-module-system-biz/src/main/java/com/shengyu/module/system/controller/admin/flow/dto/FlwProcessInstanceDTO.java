package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FlwProcessInstanceDTO {

    @Schema(description = "流程分类ID")
    protected Long processCategoryId;

    @Schema(description = "已经完成（默认否）")
    protected Boolean completed;

    @Schema(description = "流程定义名称")
    protected String processName;

    @Schema(description = "当前所在节点名称")
    protected String currentNodeName;

}
