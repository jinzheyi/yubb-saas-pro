package com.shengyu.framework.datapermission.core.rule.dept;

import cn.hutool.core.bean.BeanUtil;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.datapermission.core.rule.dept.dto.DeptDataPermissionRespDTO;
import com.shengyu.module.system.api.permission.PermissionApi;
import lombok.RequiredArgsConstructor;

/**
 * 租户端（System）部门数据权限提供者
 *
 * @author 圣钰科技
 */
@RequiredArgsConstructor
public class SystemDeptDataPermissionProvider implements DeptDataPermissionProvider {

    private final PermissionApi permissionApi;

    @Override
    public DeptDataPermissionRespDTO getDeptDataPermission(Long userId) {
        com.shengyu.module.system.api.permission.dto.DeptDataPermissionRespDTO systemDto = 
                permissionApi.getDeptDataPermission(userId);
        
        // 转换为统一的DTO
        DeptDataPermissionRespDTO result = new DeptDataPermissionRespDTO();
        BeanUtil.copyProperties(systemDto, result);
        return result;
    }

    @Override
    public boolean supports(Integer userType) {
        // 支持租户端管理员类型
        return UserTypeEnum.ADMIN.getValue().equals(userType);
    }

}
