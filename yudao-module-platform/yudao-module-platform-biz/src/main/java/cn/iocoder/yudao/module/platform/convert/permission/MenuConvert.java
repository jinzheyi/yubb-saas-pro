package cn.iocoder.yudao.module.platform.convert.permission;

import cn.iocoder.yudao.module.platform.controller.center.permission.vo.menu.MenuCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.menu.MenuRespVO;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.menu.MenuSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.permission.vo.menu.MenuUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformMenuDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface MenuConvert {

    MenuConvert INSTANCE = Mappers.getMapper(MenuConvert.class);

    List<MenuRespVO> convertList(List<PlatformMenuDO> list);

    PlatformMenuDO convert(MenuCreateReqVO bean);

    PlatformMenuDO convert(MenuUpdateReqVO bean);

    MenuRespVO convert(PlatformMenuDO bean);

    List<MenuSimpleRespVO> convertList02(List<PlatformMenuDO> list);

}
