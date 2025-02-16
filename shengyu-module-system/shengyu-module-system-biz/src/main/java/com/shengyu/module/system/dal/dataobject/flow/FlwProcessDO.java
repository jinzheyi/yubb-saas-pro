package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程定义表
 *
 * @author hubin
 * @since 2024-02-29
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("flw_process")
public class FlwProcessDO extends TenantFlowBaseDO {

	/**
	 * 流程定义 key 唯一标识
	 */
	private String processKey;

	/**
	 * 流程定义名称
	 */
	private String processName;

	/**
	 * 流程图标地址
	 */
	private String processIcon;

	/**
	 * 流程定义类型
	 */
	private String processType;

	/**
	 * 流程定义版本
	 */
	private Integer processVersion;

	/**
	 * 实例地址
	 */
	private String instanceUrl;

	/**
	 * 备注说明
	 */
	private String remark;

	/**
	 * 使用范围 0，全员 1，指定人员（业务关联） 2，均不可提交
	 */
	private Integer useScope;

	/**
	 * 流程状态 0，不可用 1，可用 2，历史版本
	 */
	protected Integer processState;

	/**
	 * 流程模型定义JSON内容
	 */
	private String modelContent;

	/**
	 * 排序
	 */
	private Integer sort;

}
