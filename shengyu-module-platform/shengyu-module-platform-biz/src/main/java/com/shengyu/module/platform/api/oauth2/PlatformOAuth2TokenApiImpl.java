package com.shengyu.module.platform.api.oauth2;

import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.api.oauth2.dto.OAuth2AccessTokenCheckRespDTO;
import com.shengyu.module.platform.api.oauth2.dto.OAuth2AccessTokenCreateReqDTO;
import com.shengyu.module.platform.api.oauth2.dto.OAuth2AccessTokenRespDTO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import com.shengyu.module.platform.service.oauth2.PlatformOAuth2TokenService;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * OAuth2.0 Token API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class PlatformOAuth2TokenApiImpl implements PlatformOAuth2TokenApi {

    @Resource
    private PlatformOAuth2TokenService oauth2TokenServicePlatform;

    @Override
    public OAuth2AccessTokenRespDTO createAccessToken(OAuth2AccessTokenCreateReqDTO reqDTO) {
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2TokenServicePlatform.createAccessToken(
                reqDTO.getUserId(), reqDTO.getUserType(), reqDTO.getClientId(), reqDTO.getScopes());
        return BeanUtils.toBean(accessTokenDO, OAuth2AccessTokenRespDTO.class);
    }

    @Override
    public OAuth2AccessTokenCheckRespDTO checkAccessToken(String accessToken) {
        return BeanUtils.toBean(oauth2TokenServicePlatform.checkAccessToken(accessToken), OAuth2AccessTokenCheckRespDTO.class);
    }

    @Override
    public OAuth2AccessTokenRespDTO removeAccessToken(String accessToken) {
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2TokenServicePlatform.removeAccessToken(accessToken);
        return BeanUtils.toBean(accessTokenDO, OAuth2AccessTokenRespDTO.class);
    }

    @Override
    public OAuth2AccessTokenRespDTO refreshAccessToken(String refreshToken, String clientId) {
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2TokenServicePlatform.refreshAccessToken(refreshToken, clientId);
        return BeanUtils.toBean(accessTokenDO, OAuth2AccessTokenRespDTO.class);
    }

}
