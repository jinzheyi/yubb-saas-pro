package com.shengyu.module.system.enums.im;

import cn.hutool.core.util.ObjUtil;
import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * IM 群成员角色枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImGroupMemberRoleEnum implements ArrayValuable<Integer> {

    MEMBER(0, "普通成员"),
    ADMIN(1, "管理员"),
    OWNER(2, "群主");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(ImGroupMemberRoleEnum::getRole).toArray(Integer[]::new);

    /**
     * 角色值
     */
    private final Integer role;
    /**
     * 角色名
     */
    private final String name;

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

    public static boolean isMember(Integer role) {
        return ObjUtil.equal(MEMBER.role, role);
    }

    public static boolean isAdmin(Integer role) {
        return ObjUtil.equal(ADMIN.role, role);
    }

    public static boolean isOwner(Integer role) {
        return ObjUtil.equal(OWNER.role, role);
    }

}
