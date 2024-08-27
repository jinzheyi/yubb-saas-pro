package com.shengyu.module.system.service.permission;

import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuListReqDTO;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import java.util.List;

/**
 * 菜单 Service 接口
 *
 * @author 圣钰科技
 */
public interface MenuService {

    /**
     * 筛选菜单列表
     *
     * @param reqDTO 筛选条件请求 DTO
     * @return 菜单列表
     */
    List<TenantMenuRespDTO> getMenuListSimpleByTenant(TenantMenuListReqDTO reqDTO);

}
