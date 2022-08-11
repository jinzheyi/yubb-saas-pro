package cn.iocoder.yudao.module.platform.convert.permission;

import cn.iocoder.yudao.module.platform.controller.center.permission.vo.role.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleDO;
import cn.iocoder.yudao.module.platform.service.permission.bo.RoleCreateReqBO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface RoleConvert {

    RoleConvert INSTANCE = Mappers.getMapper(RoleConvert.class);

    PlatformRoleDO convert(RoleUpdateReqVO bean);

    RoleRespVO convert(PlatformRoleDO bean);

    PlatformRoleDO convert(RoleCreateReqVO bean);

    List<RoleSimpleRespVO> convertList02(List<PlatformRoleDO> list);

    List<RoleExcelVO> convertList03(List<PlatformRoleDO> list);

    PlatformRoleDO convert(RoleCreateReqBO bean);

}
