package cn.iocoder.yudao.module.platform.convert.tenant;

import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.PlatformTenantMenuDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface TenantMenuConvert {

    TenantMenuConvert INSTANCE = Mappers.getMapper(TenantMenuConvert.class);

    List<TenantMenuRespVO> convertList(List<PlatformTenantMenuDO> list);

    PlatformTenantMenuDO convert(TenantMenuCreateReqVO bean);

    PlatformTenantMenuDO convert(TenantMenuUpdateReqVO bean);

    TenantMenuRespVO convert(PlatformTenantMenuDO bean);

    List<TenantMenuSimpleRespVO> convertList02(List<PlatformTenantMenuDO> list);

}
