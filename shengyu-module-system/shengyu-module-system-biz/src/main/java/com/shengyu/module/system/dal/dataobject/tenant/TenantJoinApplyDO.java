package com.shengyu.module.system.dal.dataobject.tenant;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

@TableName("system_tenant_join_apply")
@Data
@EqualsAndHashCode(callSuper = true)
public class TenantJoinApplyDO extends BaseDO {
    private Long id;
    private Long tenantId;
    private Long saasUserId;
    private Long inviteId;
    private String source;
    private Integer status;
    private String remark;
    private Long auditorId;
    private java.time.LocalDateTime auditTime;
}
