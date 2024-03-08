package cn.iocoder.yudao.framework.common.enums.permission;

import cn.iocoder.yudao.framework.common.util.object.ObjectUtils;
import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 角色标识枚举
 */
@Getter
@AllArgsConstructor
public enum RoleCodeEnum {

    SUPER_ADMIN("super_admin", "超级管理员"),
    TENANT_ADMIN("tenant_admin", "租户管理员"),
    ;

    /**
     * 角色编码
     */
    private final String code;
    /**
     * 名字
     */
    private final String name;

    /**
     * 租户超管
     * @param code
     * @return
     */
    public static boolean isTenantAdmin(String code) {
        return ObjectUtils.equalsAny(code, TENANT_ADMIN.getCode());
    }

    /**
     * 平台超管
     * @param code
     * @return
     */
    public static boolean isSuperAdmin(String code) {
        return ObjectUtils.equalsAny(code, SUPER_ADMIN.getCode());
    }

}
