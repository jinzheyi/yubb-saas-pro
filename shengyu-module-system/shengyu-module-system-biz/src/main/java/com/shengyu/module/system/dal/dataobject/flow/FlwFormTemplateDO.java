package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程表单模板
 *
 * @author hubin
 * @since 2024-05-19
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("flw_form_template")
public class FlwFormTemplateDO extends TenantFlowBaseDO {

	/**
	 * 表单分类ID
	 */
	private Long formCategoryId;

	/**
	 * 名称
	 */
	private String name;

	/**
	 * 唯一编号
	 */
	private String code;

	/**
	 * 类型 0，设计表单 1，系统表单
	 */
	private Integer type;

	/**
	 * PC端地址
	 */
	private String pcUrl;

	/**
	 * APP端地址
	 */
	private String appUrl;

	/**
	 * 内容
	 */
	private String content;

	/**
	 * 备注
	 */
	private String remark;

	/**
	 * 状态 0、禁用 1、正常 3，绑定
	 */
	private Integer status;

	/**
	 * 排序
	 */
	private Integer sort;

}
