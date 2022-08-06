package cn.iocoder.yudao.module.system.service.permission;

import cn.iocoder.yudao.module.platform.api.tenant.dto.menu.TenantMenuListReqDTO;
import cn.iocoder.yudao.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;

import java.util.List;

/**
 * 菜单 Service 接口
 *
 * @author 芋道源码
 */
public interface MenuService {

    /**
     * 基于租户，筛选菜单列表
     * 注意，如果是系统租户，返回的还是全菜单
     *
     * @param reqDTO 筛选条件请求 DTO
     * @return 菜单列表
     */
    List<TenantMenuRespDTO> getTenantMenus(TenantMenuListReqDTO reqDTO);

}
