package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.shengyu.framework.common.enums.SyConstants;
import com.shengyu.framework.flowlong.engine.core.FlowBaseDO;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Date;
import javax.validation.constraints.PositiveOrZero;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程转办配置
 *
 * @author 青苗
 * @since 2025-08-17
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(name = "FlwTransferConfigure", description = "流程转办配置")
@TableName("flw_transfer_configure")
public class FlwTransferConfigure extends FlowBaseDO {

	@TableId
	private Long id;

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
