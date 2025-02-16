package com.shengyu.module.system.controller.admin.flow.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FlwHisTaskActorVO {

    @Schema(description = "任务ID")
    protected Long taskId;

    @Schema(description = "参与者")
    private String actorName;

    @Schema(description = "头像")
    private String avatar;

    @Schema(description = "权重")
    protected Integer weight;

}
