package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.SqlCondition;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.flowlong.engine.core.FlowBaseDO;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import javax.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程表单分类
 *
 * @author hubin
 * @since 2024-05-19
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(name = "FlwFormCategory", description = "流程表单分类")
@TableName("flw_form_category")
public class FlwFormCategory extends FlowBaseDO {

	/**
	 * id
	 */
	@TableId
	private Long id;

	@Schema(description = "父ID")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Long pid;

	@Schema(description = "名称")
	@NotBlank(groups = Create.class)
	@Size(max = 50)
	@TableField(condition = SqlCondition.LIKE)
	private String name;

	@Schema(description = "备注")
	@Size(max = 255)
	private String remark;

	@Schema(description = "状态 0、禁用 1、正常")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Short status;

	@Schema(description = "排序")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Short sort;

}
