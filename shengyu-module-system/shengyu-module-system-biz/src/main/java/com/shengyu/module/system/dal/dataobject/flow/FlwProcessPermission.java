package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableId;
import com.shengyu.framework.common.validation.group.Create;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import javax.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.util.Objects;

/**
 * 流程定义权限
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
@Schema(name = "FlwProcessPermission", description = "流程定义权限")
public class FlwProcessPermission extends TenantBaseDO {

    @TableId
    private Long id;

    @Schema(description = "流程定义ID")
    @NotNull(groups = Create.class)
    @PositiveOrZero
    private Long processId;

    @Schema(description = "用户ID")
    @NotNull(groups = Create.class)
    @PositiveOrZero
    private Long userId;

    @Schema(description = "用户名")
    @Size(max = 50)
    private String userName;

    @Schema(description = "允许编辑/停用/删除审批 0，否 1，是")
    @NotNull(groups = Create.class)
    @PositiveOrZero
    private Integer operateApproval;

    @Schema(description = "允许添加/移除审批负责人 0，否 1，是")
    @NotNull(groups = Create.class)
    @PositiveOrZero
    private Integer operateOwner;

    @Schema(description = "允许审批数据查询与操作 0，否 1，是")
    @NotNull(groups = Create.class)
    @PositiveOrZero
    private Integer operateData;

    /**
     * 是否允许操作审批
     */
    public boolean allowOperateApproval() {
        return Objects.equals(1, operateApproval);
    }

}
