package cn.iocoder.yudao.module.platform.service.tenant;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackagePageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantPackageDO;

import javax.validation.Valid;
import java.util.List;

/**
 * 租户套餐 Service 接口
 *
 * @author 芋道源码
 */
public interface PlatformTenantPackageService {

    /**
     * 创建租户套餐
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createTenantPackage(@Valid TenantPackageCreateReqVO createReqVO);

    /**
     * 更新租户套餐
     *
     * @param updateReqVO 更新信息
     */
    void updateTenantPackage(@Valid TenantPackageUpdateReqVO updateReqVO);

    /**
     * 删除租户套餐
     *
     * @param id 编号
     */
    void deleteTenantPackage(Long id);

    /**
     * 获得租户套餐
     *
     * @param id 编号
     * @return 租户套餐
     */
    PlatformTenantPackageDO getTenantPackage(Long id);

    /**
     * 获得租户套餐分页
     *
     * @param pageReqVO 分页查询
     * @return 租户套餐分页
     */
    PageResult<PlatformTenantPackageDO> getTenantPackagePage(TenantPackagePageReqVO pageReqVO);

    /**
     * 校验租户套餐
     *
     * @param id 编号
     * @return 租户套餐
     */
    PlatformTenantPackageDO validTenantPackage(Long id);

    /**
     * 获得指定状态的租户套餐列表
     *
     * @param status 状态
     * @return 租户套餐
     */
    List<PlatformTenantPackageDO> getTenantPackageListByStatus(Integer status);

}
