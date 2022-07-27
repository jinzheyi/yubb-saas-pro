package cn.iocoder.yudao.module.platform.api.oauth2;

import cn.iocoder.yudao.module.platform.api.oauth2.dto.PlatformOAuth2AccessTokenCheckRespDTO;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.PlatformOAuth2AccessTokenCreateReqDTO;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.PlatformOAuth2AccessTokenRespDTO;
import cn.iocoder.yudao.module.platform.convert.auth.OAuth2TokenConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import cn.iocoder.yudao.module.platform.service.oauth2.PlatformOAuth2TokenService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * OAuth2.0 Token API 实现类
 *
 * @author 芋道源码
 */
@Service
public class PlatformOAuth2TokenApiImpl implements PlatformOAuth2TokenApi {

    @Resource
    private PlatformOAuth2TokenService oauth2TokenService;

    @Override
    public PlatformOAuth2AccessTokenRespDTO createAccessToken(PlatformOAuth2AccessTokenCreateReqDTO reqDTO) {
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2TokenService.createAccessToken(
                reqDTO.getUserId(), reqDTO.getUserType(), reqDTO.getClientId(), reqDTO.getScopes());
        return OAuth2TokenConvert.INSTANCE.convert2(accessTokenDO);
    }

    @Override
    public PlatformOAuth2AccessTokenCheckRespDTO checkAccessToken(String accessToken) {
        return OAuth2TokenConvert.INSTANCE.convert(oauth2TokenService.checkAccessToken(accessToken));
    }

    @Override
    public PlatformOAuth2AccessTokenRespDTO removeAccessToken(String accessToken) {
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2TokenService.removeAccessToken(accessToken);
        return OAuth2TokenConvert.INSTANCE.convert2(accessTokenDO);
    }

    @Override
    public PlatformOAuth2AccessTokenRespDTO refreshAccessToken(String refreshToken, String clientId) {
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2TokenService.refreshAccessToken(refreshToken, clientId);
        return OAuth2TokenConvert.INSTANCE.convert2(accessTokenDO);
    }

}
