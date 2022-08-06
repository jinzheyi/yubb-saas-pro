package cn.iocoder.yudao.module.system.service.permission;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.module.platform.api.tenant.TenantMenuApi;
import cn.iocoder.yudao.module.platform.api.tenant.dto.menu.TenantMenuListReqDTO;
import cn.iocoder.yudao.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import cn.iocoder.yudao.module.system.service.tenant.TenantService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 菜单 Service 实现
 *
 * @author 芋道源码
 */
@Service
@Slf4j
public class MenuServiceImpl implements MenuService {

    @Resource
    private TenantMenuApi tenantMenuApi;

    @Resource
    private TenantService tenantService;

    @Override
    public List<TenantMenuRespDTO> getTenantMenus(TenantMenuListReqDTO reqDTO) {
        List<TenantMenuRespDTO> menus = tenantMenuApi.getTenantMenuList(reqDTO);
        // 开启多租户的情况下，需要过滤掉未开通的菜单
        tenantService.handleTenantMenu(menuIds -> menus.removeIf(menu -> !CollUtil.contains(menuIds, menu.getId())));
        return menus;
    }

}
