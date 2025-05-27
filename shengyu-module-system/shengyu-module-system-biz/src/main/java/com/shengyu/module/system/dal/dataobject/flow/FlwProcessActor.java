package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableId;
import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.flowlong.engine.core.FlowBaseDO;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import javax.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程定义参与者
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
@Schema(name = "FlwProcessActor", description = "流程定义参与者")
public class FlwProcessActor extends FlowBaseDO {

	@TableId
	private Long id;

	@Schema(description = "流程定义ID")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Long processId;

	@Schema(description = "参与者ID")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Long actorId;

	@Schema(description = "参与者")
	@NotBlank(groups = Create.class)
	@Size(max = 255)
	private String actorName;

	@Schema(description = "参与者类型 0，角色 1，部门")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Integer actorType;

}
