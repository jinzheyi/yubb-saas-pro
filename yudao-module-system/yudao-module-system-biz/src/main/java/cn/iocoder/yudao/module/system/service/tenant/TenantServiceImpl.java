package cn.iocoder.yudao.module.system.service.tenant;

import cn.iocoder.yudao.framework.tenant.core.context.TenantContextHolder;
import cn.iocoder.yudao.module.platform.api.tenant.TenantApi;
import cn.iocoder.yudao.module.platform.api.tenant.TenantPackageApi;
import cn.iocoder.yudao.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import cn.iocoder.yudao.module.system.service.tenant.handler.TenantInfoHandler;
import cn.iocoder.yudao.module.system.service.tenant.handler.TenantMenuHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.Set;

/**
 * 租户 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
@Slf4j
public class TenantServiceImpl implements TenantService {

    @Resource
    private TenantApi tenantApi;

    @Resource
    private TenantPackageApi tenantPackageApi;

    @Override
    public TenantRespDTO getTenantByName(String name) {
        return tenantApi.getTenantByName(name);
    }

    @Override
    public TenantRespDTO getTenantByWebsite(String website) {
        return tenantApi.getTenantByWebsite(website);
    }

    @Override
    public void handleTenantInfo(TenantInfoHandler handler) {
        // 获得租户
        TenantRespDTO tenant = tenantApi.getTenant(TenantContextHolder.getRequiredTenantId());
        // 执行处理器
        handler.handle(tenant);
    }

    @Override
    public void handleTenantMenu(TenantMenuHandler handler) {
        // 获得租户，然后获得菜单
        TenantRespDTO tenant = tenantApi.getTenant(TenantContextHolder.getRequiredTenantId());
        Set<Long> menuIds = tenantPackageApi.getTenantPackage(tenant.getPackageId()).getMenuIds();
        // 执行处理器
        handler.handle(menuIds);
    }

}
