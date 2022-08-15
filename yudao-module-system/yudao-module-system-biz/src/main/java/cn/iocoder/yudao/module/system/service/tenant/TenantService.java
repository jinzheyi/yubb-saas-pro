package cn.iocoder.yudao.module.system.service.tenant;

import cn.iocoder.yudao.framework.tenant.core.context.TenantContextHolder;
import cn.iocoder.yudao.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import cn.iocoder.yudao.module.system.service.tenant.handler.TenantInfoHandler;
import cn.iocoder.yudao.module.system.service.tenant.handler.TenantMenuHandler;

/**
 * 租户 Service 接口
 *
 * @author 芋道源码
 */
public interface TenantService {

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

    /**
     * 获得名字对应的租户
     *
     * @param name 组户名
     * @return 租户
     */
    TenantRespDTO getTenantByName(String name);

}
