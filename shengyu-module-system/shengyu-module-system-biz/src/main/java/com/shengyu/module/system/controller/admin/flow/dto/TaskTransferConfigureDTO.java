package com.shengyu.module.system.controller.admin.flow.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.shengyu.framework.common.enums.SyConstants;
import com.shengyu.framework.flowlong.engine.core.BeanConvert;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Date;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程转办配置DTO
 *
 * @author 青苗
 * @since 2025-08-17
 */
@Getter
@Setter
public class TaskTransferConfigureDTO implements BeanConvert {

    @Schema(description = "用户ID")
    @PositiveOrZero
    private Long userId;

    @Schema(description = "转办开始时间")
    @JsonFormat(pattern = SyConstants.DATE_MM_SS)
    private Date beginTime;

    @Schema(description = "转办结束时间")
    @JsonFormat(pattern = SyConstants.DATE_MM_SS)
    private Date endTime;

    @Schema(description = "转办人ID")
    @PositiveOrZero
    private Long transferId;

}
