package cn.iocoder.yudao.module.platform.convert.tenant;

import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantMenuDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface TenantMenuConvert {

    TenantMenuConvert INSTANCE = Mappers.getMapper(TenantMenuConvert.class);

    List<TenantMenuRespVO> convertList(List<TenantMenuDO> list);

    TenantMenuDO convert(TenantMenuCreateReqVO bean);

    TenantMenuDO convert(TenantMenuUpdateReqVO bean);

    TenantMenuRespVO convert(TenantMenuDO bean);

    List<TenantMenuSimpleRespVO> convertList02(List<TenantMenuDO> list);

}
