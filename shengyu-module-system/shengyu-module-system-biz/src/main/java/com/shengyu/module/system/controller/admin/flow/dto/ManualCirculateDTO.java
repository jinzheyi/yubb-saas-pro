package com.shengyu.module.system.controller.admin.flow.dto;

import io.swagger.annotations.ApiModelProperty;
import java.util.List;
import javax.validation.constraints.NotEmpty;
import lombok.Getter;
import lombok.Setter;

/**
 * @author 朱述勇
 * @data: 2025-08-21  10:16
 * @Description: 手动传阅任务入参dto
 * @Version: 江西财信科技版权所有 1.0
 */
@Getter
@Setter
public class ManualCirculateDTO {

  @ApiModelProperty(value = "流程任务ID，如果是审批节点进行传阅得时候传递此值")
  private Long taskId;

  @ApiModelProperty(value = "流程历史任务ID，在我收到得传阅中再进行传阅传递此值")
  private Long hisTaskId;

  @ApiModelProperty(value = "可提交意见")
  private Boolean allowOpinion = false;

  @ApiModelProperty(value = "可传阅")
  private Boolean allowCirculate = false;

  @ApiModelProperty(value = "阅知后通知我")
  private Boolean notifyMe = false;

  @ApiModelProperty(value = "用户ID列表")
  @NotEmpty
  private List<Long> userIdList;

  @ApiModelProperty(value = "意见评论")
  private String content;

}
