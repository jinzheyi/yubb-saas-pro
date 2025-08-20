package com.shengyu.module.system.controller.admin.flow.vo;

import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程任务转办待处理人VO
 *
 * @author 青苗
 * @since 2025-08-17
 */
@Getter
@Setter
public class TaskTransferVO {

    @Schema(description = "用户ID")
    private Long id;

    @Schema(description = "用户名")
    private String username;

    public FlowCreator toFlowCreator() {
        return FlowCreator.of(String.valueOf(id), username);
    }
}
