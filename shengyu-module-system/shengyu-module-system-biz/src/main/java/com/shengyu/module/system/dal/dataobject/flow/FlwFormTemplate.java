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
 * 流程表单模板
 *
 * @author hubin
 * @since 2024-05-19
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(name = "FlwFormTemplate", description = "流程表单模板")
@TableName("flw_form_template")
public class FlwFormTemplate extends FlowBaseDO {

	@TableId
	private Long id;

	@Schema(description = "表单分类ID")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Long formCategoryId;

	@Schema(description = "名称")
	@NotBlank(groups = Create.class)
	@Size(max = 100)
	@TableField(condition = SqlCondition.LIKE)
	private String name;

	@Schema(description = "唯一编号")
	@NotBlank(groups = Create.class)
	@Size(max = 100)
	private String code;

	@Schema(description = "类型 0，设计表单 1，系统表单")
	@PositiveOrZero
	private Integer type;

	@Schema(description = "PC端地址")
	@Size(max = 255)
	private String pcUrl;

	@Schema(description = "APP端地址")
	@Size(max = 255)
	private String appUrl;

	@Schema(description = "内容")
	@Size(max = 10000)
	private String content;

	@Schema(description = "备注")
	@Size(max = 255)
	private String remark;

	@Schema(description = "状态 0、禁用 1、正常 3，绑定")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Integer status;

	@Schema(description = "排序")
	@NotNull(groups = Create.class)
	@PositiveOrZero
	private Integer sort;

}
