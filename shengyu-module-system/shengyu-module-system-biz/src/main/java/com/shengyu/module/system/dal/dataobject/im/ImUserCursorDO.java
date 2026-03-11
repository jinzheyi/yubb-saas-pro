package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@TableName(value = "im_user_cursor", autoResultMap = true)
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImUserCursorDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Long userId;

    private Long nextCursorVersion;
}
