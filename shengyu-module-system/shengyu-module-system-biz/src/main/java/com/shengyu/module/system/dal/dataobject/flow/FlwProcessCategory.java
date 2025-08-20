package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableId;
import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.flowlong.engine.core.FlowBaseDO;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.PositiveOrZero;
import javax.validation.constraints.Size;

/**
 * 流程分类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Schema(name = "FlwProcessCategory", description = "流程分类")
public class FlwProcessCategory extends FlowBaseDO {

	/**
	 * id
	 */
	@TableId
	private Long id;

	@Schema(description = "名称")
	@NotBlank(groups = Create.class)
	@Size(max = 50)
	private String name;

	@Schema(description = "备注")
	@Size(max = 255)
	private String remark;

	@Schema(description = "排序")
	@PositiveOrZero
	private Integer sort;

}
