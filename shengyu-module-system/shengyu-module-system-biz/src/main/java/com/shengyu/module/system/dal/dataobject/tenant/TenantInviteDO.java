package com.shengyu.module.system.dal.dataobject.tenant;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

@TableName("system_tenant_invite")
@Data
@EqualsAndHashCode(callSuper = true)
public class TenantInviteDO extends BaseDO {
    private Long id;
    private Long tenantId;
    private String inviteCode;
    private String name;
    private Integer status;
    private java.time.LocalDateTime expireTime;
    private Integer maxUseCount;
    private Integer usedCount;
    private Long defaultDeptId;
    private Long defaultRoleId;
    private Boolean autoApprove;
}
