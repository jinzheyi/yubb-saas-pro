package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.module.system.framework.engine.core.TenantFlowBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.Objects;

/**
 * 流程定义权限
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("flw_process_permission")
public class FlwProcessPermission extends TenantFlowBaseDO {

    /**
     * 流程定义ID
     */
    private Long processId;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 用户名
     */
    private String userName;

    /**
     * 允许编辑/停用/删除审批 0，否 1，是
     */
    private Integer operateApproval;

    /**
     * 允许添加/移除审批负责人 0，否 1，是
     */
    private Integer operateOwner;

    /**
     * 允许审批数据查询与操作 0，否 1，是
     */
    private Integer operateData;

    /**
     * 是否允许操作审批
     */
    public boolean allowOperateApproval() {
        return Objects.equals(1, operateApproval);
    }

}
