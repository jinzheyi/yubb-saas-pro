package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 通话状态枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImCallStatusEnum {

    MISSED(1, "未接听"),
    ANSWERED(2, "已接听"),
    REJECTED(3, "已拒绝"),
    BUSY(4, "忙线"),
    CANCELLED(5, "已取消");

    /**
     * 状态
     */
    private final Integer status;

    /**
     * 描述
     */
    private final String description;

}
