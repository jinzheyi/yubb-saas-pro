package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.shengyu.framework.tenant.core.db.TenantFlowBaseDO;
import com.shengyu.module.system.dal.dataobject.flow.model.FlwProcessSetting;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程定义配置
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "flw_process_configure", autoResultMap = true)
public class FlwProcessConfigureDO extends TenantFlowBaseDO {

	/**
	 * 流程定义ID
	 */
	private Long processId;

	/**
	 * 流程分类ID
	 */
	private Long categoryId;

	/**
	 * 流程设置
	 */
	@TableField(typeHandler = JacksonTypeHandler.class)
	private FlwProcessSetting processSetting;

	/**
	 * 流程表单
	 */
	private String processForm;

}
