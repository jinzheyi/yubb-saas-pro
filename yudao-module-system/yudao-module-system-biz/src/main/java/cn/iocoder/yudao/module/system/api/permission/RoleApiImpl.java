package cn.iocoder.yudao.module.system.api.permission;

import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.system.api.permission.dto.RoleCreateReqDTO;
import cn.iocoder.yudao.module.system.api.permission.dto.RoleSimpleRespDTO;
import cn.iocoder.yudao.module.system.controller.admin.permission.vo.role.RoleSaveReqVO;
import cn.iocoder.yudao.module.system.service.permission.RoleService;
import java.util.Collection;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * 角色 API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class RoleApiImpl implements RoleApi {

    @Resource
    private RoleService roleService;

    @Override
    public void validRoleList(Collection<Long> ids) {
        roleService.validateRoleList(ids);
    }

    @Override
    public Long createRole(RoleCreateReqDTO reqDTO) {
        return roleService.createRole(BeanUtils.toBean(reqDTO, RoleSaveReqVO.class), reqDTO.getType());
    }

    @Override
    public List<RoleSimpleRespDTO> getRoleListByStatus(Collection<Integer> statuses) {
        return BeanUtils.toBean(roleService.getRoleListByStatus(statuses), RoleSimpleRespDTO.class);
    }
}
