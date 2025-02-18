package com.shengyu.module.system.controller.admin.flow.vo;

import com.shengyu.module.system.dal.dataobject.flow.FlwHisTask;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class FlwHisTaskVO extends FlwHisTask {

    @Schema(description = "参与者列表")
    private List<FlwHisTaskActorVO> actorList;

}
