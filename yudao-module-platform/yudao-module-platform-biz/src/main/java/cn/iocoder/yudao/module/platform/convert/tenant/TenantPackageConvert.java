package cn.iocoder.yudao.module.platform.convert.tenant;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantPackageDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * 租户套餐 Convert
 *
 * @author 芋道源码
 */
@Mapper
public interface TenantPackageConvert {

    TenantPackageConvert INSTANCE = Mappers.getMapper(TenantPackageConvert.class);

    PlatformTenantPackageDO convert(TenantPackageCreateReqVO bean);

    PlatformTenantPackageDO convert(TenantPackageUpdateReqVO bean);

    TenantPackageRespVO convert(PlatformTenantPackageDO bean);

    List<TenantPackageRespVO> convertList(List<PlatformTenantPackageDO> list);

    PageResult<TenantPackageRespVO> convertPage(PageResult<PlatformTenantPackageDO> page);

    List<TenantPackageSimpleRespVO> convertList02(List<PlatformTenantPackageDO> list);

}
