package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程定义表单
 *
 * @author hubin
 * @since 2024-02-29
 */
@Getter
@Setter
@Schema(name = "FlwProcessForm", description = "流程定义表单")
@TableName("flw_process_form")
public class FlwProcessForm extends TenantBaseDO {

	@TableId
	private Long id;

	@Schema(description = "流程实例ID")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Long instanceId;

	@Schema(description = "表单内容")
	@NotBlank(groups = Create.class)
	private String content;

}
