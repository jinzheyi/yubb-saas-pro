package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.module.system.framework.engine.core.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程定义参与者
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("flw_form_template")
public class FlwProcessActor extends TenantFlowBaseDO {

	/**
	 * 流程定义ID
	 */
	private Long processId;

	/**
	 * 参与者ID
	 */
	private Long actorId;

	/**
	 * 参与者
	 */
	private String actorName;

	/**
	 * 参与者类型 0，角色 1，部门
	 */
	private Integer actorType;

}
