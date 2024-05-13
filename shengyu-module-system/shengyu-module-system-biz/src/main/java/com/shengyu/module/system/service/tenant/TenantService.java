package com.shengyu.module.system.service.tenant;

import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import com.shengyu.module.system.service.tenant.handler.TenantInfoHandler;
import com.shengyu.module.system.service.tenant.handler.TenantMenuHandler;

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
     * 进行租户的菜单处理逻辑
     * 其中，租户编号从 {@link TenantContextHolder} 上下文中获取
     *
     * @param handler 处理器
     */
    void handleTenantMenu(TenantMenuHandler handler);

}
