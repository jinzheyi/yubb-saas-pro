package com.shengyu.framework.datapermission.core.rule.dept;

import com.shengyu.framework.datapermission.core.rule.dept.dto.DeptDataPermissionRespDTO;

/**
 * 部门数据权限提供者接口
 * 用于抽象平台端和租户端的数据权限获取逻辑
 *
 * @author 圣钰科技
 */
public interface DeptDataPermissionProvider {

    /**
     * 获得登陆用户的部门数据权限
     *
     * @param userId 用户编号
     * @return 部门数据权限
     */
    DeptDataPermissionRespDTO getDeptDataPermission(Long userId);

    /**
     * 判断当前提供者是否支持当前用户类型
     *
     * @param userType 用户类型
     * @return 是否支持
     */
    boolean supports(Integer userType);

}
