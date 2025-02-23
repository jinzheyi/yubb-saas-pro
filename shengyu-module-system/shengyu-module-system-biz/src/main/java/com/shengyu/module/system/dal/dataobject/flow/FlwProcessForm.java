package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.module.system.framework.bpm.engine.core.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程定义表单
 *
 * @author hubin
 * @since 2024-02-29
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("flw_process_form")
public class FlwProcessForm extends TenantFlowBaseDO {

	/**
	 * 流程实例ID
	 */
	private Long instanceId;

	/**
	 * 表单内容
	 */
	private String content;

}
