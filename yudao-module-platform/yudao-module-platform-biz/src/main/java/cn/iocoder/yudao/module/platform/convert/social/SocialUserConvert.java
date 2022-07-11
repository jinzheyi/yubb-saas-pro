package cn.iocoder.yudao.module.platform.convert.social;

import cn.iocoder.yudao.module.platform.api.social.dto.PlatformSocialUserBindReqDTO;
import cn.iocoder.yudao.module.platform.api.social.dto.PlatformSocialUserUnbindReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.socail.vo.SocialUserBindReqVO;
import cn.iocoder.yudao.module.platform.controller.center.socail.vo.SocialUserUnbindReqVO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface SocialUserConvert {

    SocialUserConvert INSTANCE = Mappers.getMapper(SocialUserConvert.class);

    PlatformSocialUserBindReqDTO convert(Long userId, Integer userType, SocialUserBindReqVO reqVO);

    PlatformSocialUserUnbindReqDTO convert(Long userId, Integer userType, SocialUserUnbindReqVO reqVO);

}
