package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.module.system.framework.bpm.engine.core.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 流程分类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("flw_process_category")
public class FlwProcessCategory extends TenantFlowBaseDO {

	/**
	 * 名称
	 */
	private String name;

	/**
	 * 备注
	 */
	private String remark;

	/**
	 * 排序
	 */
	private Integer sort;

}
