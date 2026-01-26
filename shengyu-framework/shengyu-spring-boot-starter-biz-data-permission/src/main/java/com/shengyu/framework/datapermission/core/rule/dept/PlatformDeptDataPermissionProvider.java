package com.shengyu.framework.datapermission.core.rule.dept;

import cn.hutool.core.bean.BeanUtil;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.datapermission.core.rule.dept.dto.DeptDataPermissionRespDTO;
import com.shengyu.module.platform.api.permission.PlatformPermissionApi;
import lombok.RequiredArgsConstructor;

/**
 * 平台端（Platform）部门数据权限提供者
 *
 * @author 圣钰科技
 */
@RequiredArgsConstructor
public class PlatformDeptDataPermissionProvider implements DeptDataPermissionProvider {

    private final PlatformPermissionApi platformPermissionApi;

    @Override
    public DeptDataPermissionRespDTO getDeptDataPermission(Long userId) {
        com.shengyu.module.platform.api.permission.dto.DeptDataPermissionRespDTO platformDto = 
                platformPermissionApi.getDeptDataPermission(userId);
        
        // 转换为统一的DTO
        DeptDataPermissionRespDTO result = new DeptDataPermissionRespDTO();
        BeanUtil.copyProperties(platformDto, result);
        return result;
    }

    @Override
    public boolean supports(Integer userType) {
        // 支持平台端管理员类型
        return UserTypeEnum.PLATFORM.getValue().equals(userType);
    }

}
