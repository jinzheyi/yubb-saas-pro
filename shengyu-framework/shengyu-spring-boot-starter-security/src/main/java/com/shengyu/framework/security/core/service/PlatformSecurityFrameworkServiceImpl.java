package com.shengyu.framework.security.core.service;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.framework.security.core.PlatformLoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.platform.api.permission.PlatformPermissionApi;
import lombok.AllArgsConstructor;

import java.util.Arrays;

import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getPlatformLoginUserId;

/**
 * 平台的 {@link SecurityFrameworkService} 实现类
 *
 * @author 圣钰科技
 */
@AllArgsConstructor
public class PlatformSecurityFrameworkServiceImpl implements SecurityFrameworkService {

    private final PlatformPermissionApi permissionApi;

    @Override
    public boolean hasPermission(String permission) {
        return hasAnyPermissions(permission);
    }

    @Override
    public boolean hasAnyPermissions(String... permissions) {
        return permissionApi.hasAnyPermissions(getPlatformLoginUserId(), permissions);
    }

    @Override
    public boolean hasRole(String role) {
        return hasAnyRoles(role);
    }

    @Override
    public boolean hasAnyRoles(String... roles) {
        return permissionApi.hasAnyRoles(getPlatformLoginUserId(), roles);
    }

    @Override
    public boolean hasScope(String scope) {
        return hasAnyScopes(scope);
    }

    @Override
    public boolean hasAnyScopes(String... scope) {
        PlatformLoginUser user = SecurityFrameworkUtils.getPlatformLoginUser();
        if (user == null) {
            return false;
        }
        return CollUtil.containsAny(user.getScopes(), Arrays.asList(scope));
    }

    /**
     * 平台端对于插件权限判断空实现,默认都有权限
     * @param plugAppSns 支持多个插件编码
     * @return 平台默认true
     */
    @Override
    public boolean hasAllPlugApp(String... plugAppSns) {
        return true;
    }

}
