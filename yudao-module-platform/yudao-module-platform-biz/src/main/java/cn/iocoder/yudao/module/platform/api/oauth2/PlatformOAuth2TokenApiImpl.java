package cn.iocoder.yudao.module.platform.api.oauth2;

import cn.iocoder.yudao.module.platform.api.oauth2.dto.OAuth2AccessTokenCheckRespDTO;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.OAuth2AccessTokenCreateReqDTO;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.OAuth2AccessTokenRespDTO;
import cn.iocoder.yudao.module.platform.convert.auth.OAuth2TokenConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.OAuth2AccessTokenDO;
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
    private PlatformOAuth2TokenService oauth2TokenServicePlatform;

    @Override
    public OAuth2AccessTokenRespDTO createAccessToken(OAuth2AccessTokenCreateReqDTO reqDTO) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenServicePlatform.createAccessToken(
                reqDTO.getUserId(), reqDTO.getUserType(), reqDTO.getClientId(), reqDTO.getScopes());
        return OAuth2TokenConvert.INSTANCE.convert2(accessTokenDO);
    }

    @Override
    public OAuth2AccessTokenCheckRespDTO checkAccessToken(String accessToken) {
        return OAuth2TokenConvert.INSTANCE.convert(oauth2TokenServicePlatform.checkAccessToken(accessToken));
    }

    @Override
    public OAuth2AccessTokenRespDTO removeAccessToken(String accessToken) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenServicePlatform.removeAccessToken(accessToken);
        return OAuth2TokenConvert.INSTANCE.convert2(accessTokenDO);
    }

    @Override
    public OAuth2AccessTokenRespDTO refreshAccessToken(String refreshToken, String clientId) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenServicePlatform.refreshAccessToken(refreshToken, clientId);
        return OAuth2TokenConvert.INSTANCE.convert2(accessTokenDO);
    }

}
