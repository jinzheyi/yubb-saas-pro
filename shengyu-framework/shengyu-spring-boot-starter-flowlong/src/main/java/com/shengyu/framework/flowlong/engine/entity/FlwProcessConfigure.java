package com.shengyu.framework.flowlong.engine.entity;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/**
 * 流程定义配置
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
@ToString
public class FlwProcessConfigure extends FlowEntity {

	/**
	 * 流程定义ID
	 */
	protected Long processId;

	/**
	 * 流程分类ID
	 */
	protected Long categoryId;

	/**
	 * 流程设置
	 */
	protected FlwProcessSetting processSetting;

	/**
	 * 流程表单
	 */
	protected String processForm;

}
