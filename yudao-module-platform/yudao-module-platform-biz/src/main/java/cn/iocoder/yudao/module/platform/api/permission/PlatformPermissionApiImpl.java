package cn.iocoder.yudao.module.platform.api.permission;

import cn.iocoder.yudao.module.platform.api.permission.dto.DeptDataPermissionRespDTO;
import cn.iocoder.yudao.module.platform.service.permission.PlatformPermissionService;
import java.util.Collection;
import java.util.Set;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * 权限 API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class PlatformPermissionApiImpl implements PlatformPermissionApi {

    @Resource
    private PlatformPermissionService platformPermissionService;

    @Override
    public Set<Long> getUserRoleIdListByRoleIds(Collection<Long> roleIds) {
        return platformPermissionService.getUserRoleIdListByRoleId(roleIds);
    }

    @Override
    public boolean hasAnyPermissions(Long userId, String... permissions) {
        return platformPermissionService.hasAnyPermissions(userId, permissions);
    }

    @Override
    public boolean hasAnyRoles(Long userId, String... roles) {
        return platformPermissionService.hasAnyRoles(userId, roles);
    }

    @Override
    public DeptDataPermissionRespDTO getDeptDataPermission(Long userId) {
        return platformPermissionService.getDeptDataPermission(userId);
    }

}
