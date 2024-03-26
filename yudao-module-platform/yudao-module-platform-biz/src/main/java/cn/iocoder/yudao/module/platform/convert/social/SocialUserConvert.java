package cn.iocoder.yudao.module.platform.convert.social;

import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserBindReqDTO;
import cn.iocoder.yudao.module.platform.controller.platform.socail.vo.user.SocialUserBindReqVO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

@Mapper
public interface SocialUserConvert {

    SocialUserConvert INSTANCE = Mappers.getMapper(SocialUserConvert.class);

    @Mapping(source = "reqVO.type", target = "socialType")
    SocialUserBindReqDTO convert(Long userId, Integer userType, SocialUserBindReqVO reqVO);

}
