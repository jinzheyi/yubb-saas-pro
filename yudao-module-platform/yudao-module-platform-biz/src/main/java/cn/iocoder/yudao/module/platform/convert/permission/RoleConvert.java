package cn.iocoder.yudao.module.platform.convert.permission;

import cn.iocoder.yudao.module.platform.controller.center.permission.vo.role.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.RoleDO;
import cn.iocoder.yudao.module.platform.service.permission.bo.RoleCreateReqBO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface RoleConvert {

    RoleConvert INSTANCE = Mappers.getMapper(RoleConvert.class);

    RoleDO convert(RoleUpdateReqVO bean);

    RoleRespVO convert(RoleDO bean);

    RoleDO convert(RoleCreateReqVO bean);

    List<RoleSimpleRespVO> convertList02(List<RoleDO> list);

    List<RoleExcelVO> convertList03(List<RoleDO> list);

    RoleDO convert(RoleCreateReqBO bean);

}
