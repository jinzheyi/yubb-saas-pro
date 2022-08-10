package cn.iocoder.yudao.module.platform.convert.social;

import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserBindReqDTO;
import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserUnbindReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.socail.vo.SocialUserBindReqVO;
import cn.iocoder.yudao.module.platform.controller.center.socail.vo.SocialUserUnbindReqVO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface SocialUserConvert {

    SocialUserConvert INSTANCE = Mappers.getMapper(SocialUserConvert.class);

    SocialUserBindReqDTO convert(Long userId, Integer userType, SocialUserBindReqVO reqVO);

    SocialUserUnbindReqDTO convert(Long userId, Integer userType, SocialUserUnbindReqVO reqVO);

}
