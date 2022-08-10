package cn.iocoder.yudao.module.platform.convert.tenant;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.api.tenant.dto.packages.TenantPackageRespDTO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.packages.TenantPackageUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantPackageDO;
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

    TenantPackageDO convert(TenantPackageCreateReqVO bean);

    TenantPackageDO convert(TenantPackageUpdateReqVO bean);

    TenantPackageRespVO convert(TenantPackageDO bean);

    List<TenantPackageRespVO> convertList(List<TenantPackageDO> list);

    PageResult<TenantPackageRespVO> convertPage(PageResult<TenantPackageDO> page);

    List<TenantPackageSimpleRespVO> convertList02(List<TenantPackageDO> list);

    TenantPackageRespDTO convertDTO(TenantPackageDO bean);

}
