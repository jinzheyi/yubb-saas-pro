package com.shengyu.framework.security.core.service;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.api.permission.PermissionApi;
import com.shengyu.module.system.api.plug.PlugTenantApi;
import lombok.AllArgsConstructor;

import java.util.Arrays;

import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

/**
 * 默认的 {@link SecurityFrameworkService} 实现类
 *
 * @author 圣钰科技
 */
@AllArgsConstructor
public class SecurityFrameworkServiceImpl implements SecurityFrameworkService {

    private final PermissionApi permissionApi;

    private final PlugTenantApi plugTenantApi;

    @Override
    public boolean hasPermission(String permission) {
        return hasAnyPermissions(permission);
    }

    @Override
    public boolean hasAnyPermissions(String... permissions) {
        return permissionApi.hasAnyPermissions(getLoginUserId(), permissions);
    }

    @Override
    public boolean hasRole(String role) {
        return hasAnyRoles(role);
    }

    @Override
    public boolean hasAnyRoles(String... roles) {
        return permissionApi.hasAnyRoles(getLoginUserId(), roles);
    }

    @Override
    public boolean hasScope(String scope) {
        return hasAnyScopes(scope);
    }

    @Override
    public boolean hasAnyScopes(String... scope) {
        LoginUser user = SecurityFrameworkUtils.getLoginUser();
        if (user == null) {
            return false;
        }
        return CollUtil.containsAny(user.getScopes(), Arrays.asList(scope));
    }

    /**
     * 租户端对于插件权限判断
     * @param plugAppSns 支持多个插件编码
     * @return true 通过  false 不通过
     */
    @Override
    public boolean hasAllPlugApp(String... plugAppSns) {
        return plugTenantApi.hasAllPlugApp(getLoginUserId(), plugAppSns);
    }

}
