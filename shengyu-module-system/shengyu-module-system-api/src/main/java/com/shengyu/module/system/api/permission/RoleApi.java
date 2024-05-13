package com.shengyu.module.system.api.permission;

import com.shengyu.module.system.api.permission.dto.RoleCreateReqDTO;
import com.shengyu.module.system.api.permission.dto.RoleSimpleRespDTO;
import org.springframework.lang.Nullable;

import javax.validation.Valid;
import java.util.Collection;
import java.util.List;

/**
 * 角色 API 接口
 *
 * @author 圣钰科技
 */
public interface RoleApi {

    /**
     * 校验角色们是否有效。如下情况，视为无效：
     * 1. 角色编号不存在
     * 2. 角色被禁用
     *
     * @param ids 角色编号数组
     */
    void validRoleList(Collection<Long> ids);

    /**
     * 外部创建租户角色
     * @param reqDTO
     * @return
     */
    Long createRole(@Valid RoleCreateReqDTO reqDTO);

    /**
     * 获得角色列表
     *
     * @param statuses 筛选的状态。允许空，空时不筛选
     * @return 角色列表
     */
    List<RoleSimpleRespDTO> getRoleListByStatus(@Nullable Collection<Integer> statuses);

}
