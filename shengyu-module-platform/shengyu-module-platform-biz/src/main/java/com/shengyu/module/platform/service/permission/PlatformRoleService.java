package com.shengyu.module.platform.service.permission;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RoleCreateReqVO;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RoleExportReqVO;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RolePageReqVO;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RoleUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.permission.PlatformRoleDO;
import java.util.Collection;
import java.util.List;
import java.util.Set;
import javax.validation.Valid;

/**
 * 角色 Service 接口
 *
 * @author 圣钰科技
 */
public interface PlatformRoleService {

    /**
     * 创建角色
     *
     * @param reqVO 创建角色信息
     * @param type 角色类型
     * @return 角色编号
     */
    Long createRole(@Valid RoleCreateReqVO reqVO, Integer type);

    /**
     * 更新角色
     *
     * @param reqVO 更新角色信息
     */
    void updateRole(@Valid RoleUpdateReqVO reqVO);

    /**
     * 删除角色
     *
     * @param id 角色编号
     */
    void deleteRole(Long id);

    /**
     * 更新角色状态
     *
     * @param id 角色编号
     * @param status 状态
     */
    void updateRoleStatus(Long id, Integer status);

    /**
     * 设置角色的数据权限
     *
     * @param id 角色编号
     * @param dataScope 数据范围
     * @param dataScopeDeptIds 部门编号数组
     */
    void updateRoleDataScope(Long id, Integer dataScope, Set<Long> dataScopeDeptIds);

    /**
     * 获得角色
     *
     * @param id 角色编号
     * @return 角色
     */
    PlatformRoleDO getRole(Long id);

    /**
     * 获得角色，从缓存中
     *
     * @param id 角色编号
     * @return 角色
     */
    PlatformRoleDO getRoleFromCache(Long id);

    /**
     * 获得角色列表
     *
     * @param ids 角色编号数组
     * @return 角色列表
     */
    List<PlatformRoleDO> getRoleList(Collection<Long> ids);

    /**
     * 获得角色数组，从缓存中
     *
     * @param ids 角色编号数组
     * @return 角色数组
     */
    List<PlatformRoleDO> getRoleListFromCache(Collection<Long> ids);

    /**
     * 获得角色列表
     *
     * @param statuses 筛选的状态
     * @return 角色列表
     */
    List<PlatformRoleDO> getRoleListByStatus(Collection<Integer> statuses);

    /**
     * 获得所有角色列表
     *
     * @return 角色列表
     */
    List<PlatformRoleDO> getRoleList();

    /**
     * 获得角色分页
     *
     * @param reqVO 角色分页查询
     * @return 角色分页结果
     */
    PageResult<PlatformRoleDO> getRolePage(RolePageReqVO reqVO);

    /**
     * 获得角色列表
     *
     * @param reqVO 列表查询
     * @return 角色列表
     */
    List<PlatformRoleDO> getRoleList(RoleExportReqVO reqVO);

    /**
     * 判断角色编号数组中，是否有管理员
     *
     * @param ids 角色编号数组
     * @return 是否有管理员
     */
    boolean hasAnySuperAdmin(Collection<Long> ids);

    /**
     * 校验角色们是否有效。如下情况，视为无效：
     * 1. 角色编号不存在
     * 2. 角色被禁用
     *
     * @param ids 角色编号数组
     */
    void validateRoleList(Collection<Long> ids);

}
