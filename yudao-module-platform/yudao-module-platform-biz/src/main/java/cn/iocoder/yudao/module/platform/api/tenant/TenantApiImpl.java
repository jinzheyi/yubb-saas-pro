package cn.iocoder.yudao.module.platform.api.tenant;

import cn.iocoder.yudao.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import cn.iocoder.yudao.module.platform.convert.tenant.TenantConvert;
import cn.iocoder.yudao.module.platform.service.tenant.PlatformTenantService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 多租户的 API 实现类
 *
 * @author 芋道源码
 */
@Service
public class TenantApiImpl implements TenantApi {

    @Resource
    private PlatformTenantService platformTenantService;

    @Override
    public List<Long> getTenantIds() {
        return platformTenantService.getTenantIds();
    }

    @Override
    public void validTenant(Long id) {
        platformTenantService.validTenant(id);
    }

    @Override
    public TenantRespDTO getTenant(Long id) {
        return TenantConvert.INSTANCE.convertDTO(platformTenantService.getTenant(id));
    }

    @Override
    public TenantRespDTO getTenantByName(String name) {
        return TenantConvert.INSTANCE.convertDTO(platformTenantService.getTenantByName(name));
    }

}
