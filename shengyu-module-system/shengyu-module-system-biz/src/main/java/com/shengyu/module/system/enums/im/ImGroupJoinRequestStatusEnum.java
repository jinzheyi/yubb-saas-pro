package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ImGroupJoinRequestStatusEnum {

    PENDING(1, "待审批"),
    APPROVED(2, "已通过"),
    REJECTED(3, "已拒绝");

    private final Integer status;
    private final String desc;

    public static boolean isPending(Integer status) {
        return status != null && status.equals(PENDING.status);
    }
}
