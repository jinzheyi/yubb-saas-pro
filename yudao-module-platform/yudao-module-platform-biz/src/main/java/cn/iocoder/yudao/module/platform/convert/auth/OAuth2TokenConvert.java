package cn.iocoder.yudao.module.platform.convert.auth;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.PlatformOAuth2AccessTokenCheckRespDTO;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.PlatformOAuth2AccessTokenRespDTO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.token.OAuth2AccessTokenRespVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface OAuth2TokenConvert {

    OAuth2TokenConvert INSTANCE = Mappers.getMapper(OAuth2TokenConvert.class);

    PlatformOAuth2AccessTokenCheckRespDTO convert(PlatformOAuth2AccessTokenDO bean);

    PageResult<OAuth2AccessTokenRespVO> convert(PageResult<PlatformOAuth2AccessTokenDO> page);

    PlatformOAuth2AccessTokenRespDTO convert2(PlatformOAuth2AccessTokenDO bean);

}
