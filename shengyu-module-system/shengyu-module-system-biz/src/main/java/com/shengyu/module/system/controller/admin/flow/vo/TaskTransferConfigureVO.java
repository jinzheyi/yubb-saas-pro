package com.shengyu.module.system.controller.admin.flow.vo;

import com.shengyu.module.system.dal.dataobject.flow.FlwTransferConfigure;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程转办配置VO
 *
 * @author 青苗
 * @since 2025-08-17
 */
@Getter
@Setter
public class TaskTransferConfigureVO extends FlwTransferConfigure {

    @Schema(description = "转办人员")
    private String transferName;

}
