package com.shengyu.module.platform.api.tenant;

import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import com.shengyu.module.platform.service.tenant.PlatformTenantService;

import java.util.Collection;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * 多租户的 API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class TenantApiImpl implements TenantApi {

    @Resource
    private PlatformTenantService platformTenantService;

    @Override
    public List<Long> getTenantIdList() {
        return platformTenantService.getTenantIdList();
    }

    @Override
    public void validateTenant(Long id) {
        platformTenantService.validTenant(id);
    }

    @Override
    public TenantRespDTO getTenant(Long id) {
        return BeanUtils.toBean(platformTenantService.getTenant(id), TenantRespDTO.class);
    }

    @Override
    public List<TenantRespDTO> getTenantList(Collection<Long> ids) {
        return BeanUtils.toBean(platformTenantService.getTenantList(ids), TenantRespDTO.class);
    }

    @Override
    public TenantRespDTO getTenantByName(String name) {
        return BeanUtils.toBean(platformTenantService.getTenantByName(name), TenantRespDTO.class);
    }

    @Override
    public TenantRespDTO getTenantByWebsite(String website) {
        return BeanUtils.toBean(platformTenantService.getTenantByWebsite(website), TenantRespDTO.class);
    }

}
