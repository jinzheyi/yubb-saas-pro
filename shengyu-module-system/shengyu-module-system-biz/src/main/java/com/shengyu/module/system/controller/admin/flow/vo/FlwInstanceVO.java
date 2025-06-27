package com.shengyu.module.system.controller.admin.flow.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Date;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FlwInstanceVO {

    @Schema(description = "流程分类ID")
    private Long id;

    @Schema(description = "创建人名称")
    private String createBy;

    @Schema(description = "流程定义ID")
    private Long processId;

    @Schema(description = "流程定义名称")
    private String processName;

    @Schema(description = "当前所在节点名称")
    private String currentNodeName;

    @Schema(description = "流程实例期望完成时间")
    private Date expireTime;

    @Schema(description = "流程实例状态")
    private Integer instanceState;

    @Schema(description = "结束时间")
    private Date endTime;

}
