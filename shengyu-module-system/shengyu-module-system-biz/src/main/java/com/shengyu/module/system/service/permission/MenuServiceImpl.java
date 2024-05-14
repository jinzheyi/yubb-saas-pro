package com.shengyu.module.system.service.permission;

import com.shengyu.module.platform.api.tenant.TenantMenuApi;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuListReqDTO;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import java.util.List;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 菜单 Service 实现
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class MenuServiceImpl implements MenuService {

    @Resource
    private TenantMenuApi tenantMenuApi;

    @Override
    public List<TenantMenuRespDTO> getMenuListSimpleByTenant(TenantMenuListReqDTO reqDTO) {
        return tenantMenuApi.getTenantMenuList(reqDTO);
    }

}
