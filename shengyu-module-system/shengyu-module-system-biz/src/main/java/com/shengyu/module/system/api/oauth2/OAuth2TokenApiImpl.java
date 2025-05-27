package com.shengyu.module.system.api.oauth2;

import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.api.oauth2.dto.OAuth2AccessTokenCheckRespDTO;
import com.shengyu.module.system.api.oauth2.dto.OAuth2AccessTokenCreateReqDTO;
import com.shengyu.module.system.api.oauth2.dto.OAuth2AccessTokenRespDTO;
import com.shengyu.module.system.dal.dataobject.oauth2.OAuth2AccessTokenDO;
import com.shengyu.module.system.service.oauth2.OAuth2TokenService;
import com.shengyu.module.system.service.user.AdminUserService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Optional;

/**
 * OAuth2.0 Token API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class OAuth2TokenApiImpl implements OAuth2TokenApi {

    @Resource
    private OAuth2TokenService oauth2TokenService;
    @Resource
    private AdminUserService adminUserService;

    @Override
    public OAuth2AccessTokenRespDTO createAccessToken(OAuth2AccessTokenCreateReqDTO reqDTO) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.createAccessToken(
                reqDTO.getUserId(), reqDTO.getUserType(), reqDTO.getClientId(), reqDTO.getScopes());
        return BeanUtils.toBean(accessTokenDO, OAuth2AccessTokenRespDTO.class);
    }

    @Override
    public OAuth2AccessTokenCheckRespDTO checkAccessToken(String accessToken) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.checkAccessToken(accessToken);
        OAuth2AccessTokenCheckRespDTO accessTokenCheckRespDTO = BeanUtils.toBean(accessTokenDO, OAuth2AccessTokenCheckRespDTO.class);
        if (accessTokenCheckRespDTO != null) {
            Optional.ofNullable(adminUserService.getUser(accessTokenCheckRespDTO.getUserId()))
                    .ifPresent(user -> accessTokenCheckRespDTO.setNickname(user.getNickname()));
        }
        return accessTokenCheckRespDTO;
    }

    @Override
    public OAuth2AccessTokenRespDTO removeAccessToken(String accessToken) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.removeAccessToken(accessToken);
        return BeanUtils.toBean(accessTokenDO, OAuth2AccessTokenRespDTO.class);
    }

    @Override
    public OAuth2AccessTokenRespDTO refreshAccessToken(String refreshToken, String clientId) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.refreshAccessToken(refreshToken, clientId);
        return BeanUtils.toBean(accessTokenDO, OAuth2AccessTokenRespDTO.class);
    }

}
