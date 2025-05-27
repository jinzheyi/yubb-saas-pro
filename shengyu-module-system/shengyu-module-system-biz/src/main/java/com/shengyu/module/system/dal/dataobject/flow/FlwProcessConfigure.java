package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.flowlong.engine.core.FlowBaseDO;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程定义配置
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
@TableName(autoResultMap = true)
@Schema(name = "FlwProcessConfigure", description = "流程定义配置")
public class FlwProcessConfigure extends FlowBaseDO {

	@TableId
	private Long id;

	@Schema(description = "流程定义ID")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Long processId;

	@Schema(description = "流程分类ID")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Long categoryId;

	@Schema(description = "流程设置")
	@TableField(typeHandler = JacksonTypeHandler.class)
	private FlwProcessSetting processSetting;

	@Schema(description = "流程表单")
	private String processForm;

}
