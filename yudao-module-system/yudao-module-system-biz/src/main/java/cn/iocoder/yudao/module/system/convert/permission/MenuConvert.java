package cn.iocoder.yudao.module.system.convert.permission;

import cn.iocoder.yudao.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import cn.iocoder.yudao.module.system.controller.admin.permission.vo.menu.MenuSimpleRespVO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface MenuConvert {

    MenuConvert INSTANCE = Mappers.getMapper(MenuConvert.class);

    List<MenuSimpleRespVO> convertList02(List<TenantMenuRespDTO> list);

}
