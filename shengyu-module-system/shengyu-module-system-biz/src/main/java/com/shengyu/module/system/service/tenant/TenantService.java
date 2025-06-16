package com.shengyu.module.system.service.tenant;

import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import com.shengyu.module.system.service.tenant.handler.TenantInfoHandler;
import com.shengyu.module.system.service.tenant.handler.TenantMenuHandler;

import java.util.Collection;
import java.util.List;
import java.util.Set;

/**
 * 租户 Service 接口
 *
 * @author 圣钰科技
 */
public interface TenantService {

    /**
     * 获得名字对应的租户
     *
     * @param name 组户名
     * @return 租户
     */
    TenantRespDTO getTenantByName(String name);

    /**
     * 获得id对应的租户
     *
     * @param id 租户id
     * @return 租户
     */
    TenantRespDTO getTenantById(Long id);

    /**
     * 获得租户列表
     *
     * @param ids 租户编号数组
     * @return 租户列表
     */
    List<TenantRespDTO> getTenantList(Collection<Long> ids);

    /**
     * 获得域名对应的租户
     *
     * @param website 域名
     * @return 租户
     */
    TenantRespDTO getTenantByWebsite(String website);

    /**
     * 进行租户的信息处理逻辑
     * 其中，租户编号从 {@link TenantContextHolder} 上下文中获取
     *
     * @param handler 处理器
     */
    void handleTenantInfo(TenantInfoHandler handler);

    /**
     * 查询当前租户已开启的套餐菜单+已上架且平台正常启用的拥有的插件菜单
     * @return 租户已开启的套餐菜单+已上架且平台正常启用的拥有的插件菜单
     */
    Set<Long> getMentIdList();

    /**
     * 进行租户的菜单处理逻辑
     * 其中，租户编号从 {@link TenantContextHolder} 上下文中获取
     *
     * @param handler 处理器
     */
    void handleTenantMenu(TenantMenuHandler handler);

}
