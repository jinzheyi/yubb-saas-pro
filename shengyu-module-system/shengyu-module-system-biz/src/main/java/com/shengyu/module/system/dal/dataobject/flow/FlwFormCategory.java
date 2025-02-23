package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.module.system.framework.bpm.engine.core.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程表单分类
 *
 * @author hubin
 * @since 2024-05-19
 */
@Data
@TableName("flw_form_category")
@EqualsAndHashCode(callSuper = true)
public class FlwFormCategory extends TenantFlowBaseDO {

	/**
	 * 父ID
	 */
	private Long pid;

	/**
	 * 名称
	 */
	private String name;

	/**
	 * 备注
	 */
	private String remark;

	/**
	 * 状态 0、禁用 1、正常
	 */
	private Short status;

	/**
	 * 排序
	 */
	private Short sort;

}
