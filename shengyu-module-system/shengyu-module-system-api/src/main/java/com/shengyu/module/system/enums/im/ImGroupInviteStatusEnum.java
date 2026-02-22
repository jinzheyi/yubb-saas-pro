package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 群邀请码状态枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImGroupInviteStatusEnum {

    VALID(1, "有效"),
    EXPIRED(2, "已过期"),
    DISABLED(3, "已禁用");

    /**
     * 状态值
     */
    private final Integer status;

    /**
     * 状态名
     */
    private final String name;

    /**
     * 判断是否有效
     */
    public static boolean isValid(Integer status) {
        return VALID.getStatus().equals(status);
    }

    /**
     * 判断是否过期
     */
    public static boolean isExpired(Integer status) {
        return EXPIRED.getStatus().equals(status);
    }

    /**
     * 判断是否禁用
     */
    public static boolean isDisabled(Integer status) {
        return DISABLED.getStatus().equals(status);
    }

}
