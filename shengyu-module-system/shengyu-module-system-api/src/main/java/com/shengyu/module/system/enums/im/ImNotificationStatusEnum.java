package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 通知状态枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImNotificationStatusEnum {

    NORMAL(1, "正常"),
    EXPIRED(2, "已过期"),
    RECALLED(3, "已撤回");

    /**
     * 状态
     */
    private final Integer status;

    /**
     * 状态名称
     */
    private final String name;

    public static boolean isNormal(Integer status) {
        return NORMAL.status.equals(status);
    }

}
