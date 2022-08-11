package cn.iocoder.yudao.module.platform.convert.oauth2;

import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.user.OAuth2UserInfoRespVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.user.OAuth2UserUpdateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface OAuth2UserConvert {

    OAuth2UserConvert INSTANCE = Mappers.getMapper(OAuth2UserConvert.class);

    OAuth2UserInfoRespVO convert(PlatformUserDO bean);
    OAuth2UserInfoRespVO.Dept convert(PlatformDeptDO dept);
    List<OAuth2UserInfoRespVO.Post> convertList(List<PlatformPostDO> list);

    UserProfileUpdateReqVO convert(OAuth2UserUpdateReqVO bean);

}
