package com.shengyu.module.platform.service.tenant;

import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuCreateReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuListReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.tenant.TenantMenuDO;
import java.util.List;

/**
 * 菜单 Service 接口
 *
 * @author 圣钰科技
 */
public interface TenantMenuService {

    /**
     * 创建菜单
     *
     * @param reqVO 菜单信息
     * @return 创建出来的菜单编号
     */
    Long createMenu(TenantMenuCreateReqVO reqVO);

    /**
     * 更新菜单
     *
     * @param reqVO 菜单信息
     */
    void updateMenu(TenantMenuUpdateReqVO reqVO);

    /**
     * 删除菜单
     *
     * @param id 菜单编号
     */
    void deleteMenu(Long id);

    /**
     * 筛选菜单列表
     *
     * @param reqVO 筛选条件请求 VO
     * @return 菜单列表
     */
    List<TenantMenuDO> getMenuList(TenantMenuListReqVO reqVO);

    /**
     * 获得权限对应的菜单数组
     *
     * @param permission 权限标识
     * @return 数组
     */
    List<Long> getMenuIdListByPermissionFromCache(String permission);

    /**
     * 获得菜单
     *
     * @param id 菜单编号
     * @return 菜单
     */
    TenantMenuDO getMenu(Long id);

}
