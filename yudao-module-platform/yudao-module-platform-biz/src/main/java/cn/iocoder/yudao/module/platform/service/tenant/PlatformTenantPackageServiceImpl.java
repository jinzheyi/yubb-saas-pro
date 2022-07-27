package cn.iocoder.yudao.module.platform.service.tenant;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackagePageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.tenant.TenantPackageConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantPackageDO;
import cn.iocoder.yudao.module.platform.dal.mapper.tenant.PlatformTenantPackageMapper;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.List;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.platform.enums.PlatformErrorCodeConstants.*;

/**
 * 租户套餐 Service 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PlatformTenantPackageServiceImpl implements PlatformTenantPackageService {

    @Resource
    private PlatformTenantPackageMapper platformTenantPackageMapper;

    @Resource
    @Lazy // 避免循环依赖的报错
    private PlatformTenantService platformTenantService;

    @Override
    public Long createTenantPackage(TenantPackageCreateReqVO createReqVO) {
        // 插入
        PlatformTenantPackageDO tenantPackage = TenantPackageConvert.INSTANCE.convert(createReqVO);
        platformTenantPackageMapper.insert(tenantPackage);
        // 返回
        return tenantPackage.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateTenantPackage(TenantPackageUpdateReqVO updateReqVO) {
        // 校验存在
        PlatformTenantPackageDO tenantPackage = validateTenantPackageExists(updateReqVO.getId());
        // 更新
        PlatformTenantPackageDO updateObj = TenantPackageConvert.INSTANCE.convert(updateReqVO);
        platformTenantPackageMapper.updateById(updateObj);
        // 如果菜单发生变化，则修改每个租户的菜单
        if (!CollUtil.isEqualList(tenantPackage.getMenuIds(), updateReqVO.getMenuIds())) {
            //根据套餐编号查出使用了这个套餐的租户
            List<PlatformTenantDO> tenants = platformTenantService.getTenantListByPackageId(tenantPackage.getId());
            //updateReqVO.getMenuIds()调整的菜单id
            tenants.forEach(tenant -> platformTenantService.updateTenantRoleMenu(tenant.getId(), updateReqVO.getMenuIds()));
        }
    }

    @Override
    public void deleteTenantPackage(Long id) {
        // 校验存在
        this.validateTenantPackageExists(id);
        // 校验正在使用
        this.validateTenantUsed(id);
        // 删除
        platformTenantPackageMapper.deleteById(id);
    }

    private PlatformTenantPackageDO validateTenantPackageExists(Long id) {
        PlatformTenantPackageDO tenantPackage = platformTenantPackageMapper.selectById(id);
        if (tenantPackage == null) {
            throw exception(TENANT_PACKAGE_NOT_EXISTS);
        }
        return tenantPackage;
    }

    private void validateTenantUsed(Long id) {
        if (platformTenantService.getTenantCountByPackageId(id) > 0) {
            throw exception(TENANT_PACKAGE_USED);
        }
    }

    @Override
    public PlatformTenantPackageDO getTenantPackage(Long id) {
        return platformTenantPackageMapper.selectById(id);
    }

    @Override
    public PageResult<PlatformTenantPackageDO> getTenantPackagePage(TenantPackagePageReqVO pageReqVO) {
        return platformTenantPackageMapper.selectPage(pageReqVO);
    }

    @Override
    public PlatformTenantPackageDO validTenantPackage(Long id) {
        PlatformTenantPackageDO tenantPackage = platformTenantPackageMapper.selectById(id);
        if (tenantPackage == null) {
            throw exception(TENANT_PACKAGE_NOT_EXISTS);
        }
        if (tenantPackage.getStatus().equals(CommonStatusEnum.DISABLE.getStatus())) {
            throw exception(TENANT_PACKAGE_DISABLE, tenantPackage.getName());
        }
        return tenantPackage;
    }

    @Override
    public List<PlatformTenantPackageDO> getTenantPackageListByStatus(Integer status) {
        return platformTenantPackageMapper.selectListByStatus(status);
    }

}
