package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@TableName(value = "im_group_join_request", autoResultMap = true)
@KeySequence("im_group_join_request_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImGroupJoinRequestDO extends TenantBaseDO {

    @TableId
    private Long id;

    private Long groupId;

    private Long applicantUserId;

    private String inviteCode;

    private Integer status;

    private String rejectReason;

    private Long handledBy;

    private LocalDateTime handledTime;
}
