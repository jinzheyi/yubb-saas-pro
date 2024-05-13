package com.shengyu.module.system.api.permission;

import com.shengyu.module.system.api.permission.dto.DeptDataPermissionRespDTO;
import com.shengyu.module.system.service.permission.PermissionService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;
import java.util.Set;

/**
 * 权限 API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class PermissionApiImpl implements PermissionApi {

    @Resource
    private PermissionService permissionService;

    @Override
    public Set<Long> getUserRoleIdListByRoleIds(Collection<Long> roleIds) {
        return permissionService.getUserRoleIdListByRoleId(roleIds);
    }

    @Override
    public boolean hasAnyPermissions(Long userId, String... permissions) {
        return permissionService.hasAnyPermissions(userId, permissions);
    }

    @Override
    public boolean hasAnyRoles(Long userId, String... roles) {
        return permissionService.hasAnyRoles(userId, roles);
    }

    @Override
    public DeptDataPermissionRespDTO getDeptDataPermission(Long userId) {
        return permissionService.getDeptDataPermission(userId);
    }

    @Override
    public void assignUserRole(Long userId, Set<Long> roleIds) {
        permissionService.assignUserRole(userId, roleIds);
    }

    @Override
    public Set<Long> getRoleMenuListByRoleId(Long roleId) {
        return permissionService.getRoleMenuListByRoleId(roleId);
    }

    @Override
    public void processMenuDeleted(Long menuId) {
        permissionService.processMenuDeleted(menuId);
    }

    @Override
    public boolean hasAnyRoleMenu(Long menuId) {
        return permissionService.hasAnyRoleMenu(menuId);
    }

    @Override
    public void assignRoleMenu(Long roleId, Set<Long> menuIds) {
        permissionService.assignRoleMenu(roleId, menuIds);
    }

}
