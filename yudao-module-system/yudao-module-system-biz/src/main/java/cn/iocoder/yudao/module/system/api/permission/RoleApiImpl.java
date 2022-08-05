package cn.iocoder.yudao.module.system.api.permission;

import cn.iocoder.yudao.module.system.api.permission.dto.RoleCreateReqDTO;
import cn.iocoder.yudao.module.system.api.permission.dto.RoleSimpleRespDTO;
import cn.iocoder.yudao.module.system.convert.permission.RoleConvert;
import cn.iocoder.yudao.module.system.service.permission.RoleService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;
import java.util.List;

/**
 * 角色 API 实现类
 *
 * @author 芋道源码
 */
@Service
public class RoleApiImpl implements RoleApi {

    @Resource
    private RoleService roleService;

    @Override
    public void validRoles(Collection<Long> ids) {
        roleService.validRoles(ids);
    }

    @Override
    public Long createRole(RoleCreateReqDTO reqDTO) {
        return roleService.createRole(RoleConvert.INSTANCE.convert(reqDTO), reqDTO.getType());
    }

    @Override
    public List<RoleSimpleRespDTO> getRoles(Collection<Integer> statuses) {
        return RoleConvert.INSTANCE.convert1(roleService.getRoles(statuses));
    }

}
