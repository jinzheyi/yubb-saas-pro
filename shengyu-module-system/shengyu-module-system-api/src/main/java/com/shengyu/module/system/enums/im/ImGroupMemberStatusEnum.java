package com.shengyu.module.system.enums.im;

import cn.hutool.core.util.ObjUtil;
import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 群成员状态枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImGroupMemberStatusEnum {

    NORMAL(0, "正常（在群内）"),
    LEFT(1, "已退出（主动退群）"),
    KICKED(2, "已被踢（被群主/管理员踢出）"),
    DISSOLVED(3, "群已解散");

    /**
     * 状态值
     */
    private final Integer status;

    /**
     * 状态名
     */
    private final String name;

    public static boolean isNormal(Integer status) {
        return ObjUtil.equal(NORMAL.status, status);
    }

    public static boolean isLeft(Integer status) {
        return ObjUtil.equal(LEFT.status, status);
    }

    public static boolean isKicked(Integer status) {
        return ObjUtil.equal(KICKED.status, status);
    }

    public static boolean isDissolved(Integer status) {
        return ObjUtil.equal(DISSOLVED.status, status);
    }

    /**
     * 判断是否已离群（退出/被踢/解散）
     */
    public static boolean hasLeft(Integer status) {
        return status != null && !isNormal(status);
    }
}
