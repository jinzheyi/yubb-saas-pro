package cn.iocoder.yudao.module.platform.service.tenant;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantDO;

import javax.validation.Valid;
import java.util.List;
import java.util.Set;

/**
 * 租户 Service 接口
 *
 * @author 芋道源码
 */
//TODO 这里为了能启动，暂时注释掉，后期需要把租户端去掉
public interface PlatformTenantService /*extends TenantFrameworkService*/ {

    /**
     * 初始化租户的本地缓存
     */
    void initLocalCache();

    /**
     * 创建租户
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createTenant(@Valid TenantCreateReqVO createReqVO);

    /**
     * 更新租户
     *
     * @param updateReqVO 更新信息
     */
    void updateTenant(@Valid TenantUpdateReqVO updateReqVO);

    /**
     * 更新租户的角色菜单
     *
     * @param tenantId 租户编号
     * @param menuIds 调整后的菜单编号数组
     */
    void updateTenantRoleMenu(Long tenantId, Set<Long> menuIds);

    /**
     * 删除租户
     *
     * @param id 编号
     */
    void deleteTenant(Long id);

    /**
     * 获得租户
     *
     * @param id 编号
     * @return 租户
     */
    PlatformTenantDO getTenant(Long id);

    /**
     * 获得租户分页
     *
     * @param pageReqVO 分页查询
     * @return 租户分页
     */
    PageResult<PlatformTenantDO> getTenantPage(TenantPageReqVO pageReqVO);

    /**
     * 获得租户列表, 用于 Excel 导出
     *
     * @param exportReqVO 查询条件
     * @return 租户列表
     */
    List<PlatformTenantDO> getTenantList(TenantExportReqVO exportReqVO);

    /**
     * 获得名字对应的租户
     *
     * @param name 组户名
     * @return 租户
     */
    PlatformTenantDO getTenantByName(String name);

    /**
     * 获得使用指定套餐的租户数量
     *
     * @param packageId 租户套餐编号
     * @return 租户数量
     */
    Long getTenantCountByPackageId(Long packageId);

    /**
     * 获得使用指定套餐的租户数组
     *
     * @param packageId 租户套餐编号
     * @return 租户数组
     */
    List<PlatformTenantDO> getTenantListByPackageId(Long packageId);

}
