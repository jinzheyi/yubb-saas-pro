package com.shengyu.module.system.controller.admin.flow.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 流程定义分类VO
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
public class FlwProcessVO {

    @JsonIgnore
    @Schema(description = "流程分类ID")
    private Long categoryId;

    @Schema(description = "流程定义ID")
    private Long processId;

    @Schema(description = "流程定义 key 唯一标识")
    private String processKey;

    @Schema(description = "流程定义名称")
    private String processName;

    @Schema(description = "流程定义图标地址")
    private String processIcon;

    @Schema(description = "流程类型")
    private String processType;

    @Schema(description = "流程定义版本")
    private Integer processVersion;

    @Schema(description = "实例地址")
    private String instanceUrl;

    @Schema(description = "备注说明")
    private String remark;

    @Schema(description = "使用范围 0，全员 1，指定人员（业务关联） 2，均不可提交")
    private Integer useScope;

    @Schema(description = "流程状态 0，不可用 1，可用")
    private Integer processState;

    @Schema(description = "流程定义排序")
    private Integer processSort;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm")
    @Schema(description = "创建时间")
    private Date createTime;

}
