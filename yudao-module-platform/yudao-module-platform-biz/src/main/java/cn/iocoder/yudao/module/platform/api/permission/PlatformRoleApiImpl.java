package cn.iocoder.yudao.module.platform.api.permission;

import cn.iocoder.yudao.module.platform.service.permission.PlatformRoleService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;

/**
 * 角色 API 实现类
 *
 * @author 芋道源码
 */
@Service
public class PlatformRoleApiImpl implements RoleApi {

    @Resource
    private PlatformRoleService platformRoleService;

    @Override
    public void validRoles(Collection<Long> ids) {
        platformRoleService.validRoles(ids);
    }
}
