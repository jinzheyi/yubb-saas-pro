package cn.iocoder.yudao.module.platform.api.oauth2;

import cn.iocoder.yudao.module.platform.api.oauth2.dto.client.OAuth2ClientRespDTO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import cn.iocoder.yudao.module.platform.service.oauth2.PlatformOAuth2ClientService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;

/**
 * @Description OAuth2Clien api 接口实现
 * @Author zhusy
 * @Date 2023/4/25 11:15
 * @Version 1.0
 **/
@Service
public class PlatformOAuth2ClientApiImpl implements PlatformOAuth2ClientApi {

    @Resource
    private PlatformOAuth2ClientService auth2ClientService;

    @Override
    public OAuth2ClientRespDTO validOAuthClientFromCache(String clientId) {
        PlatformOAuth2ClientDO auth2ClientDO = auth2ClientService.validOAuthClientFromCache(clientId);
        return getRespDTO(auth2ClientDO);
    }

    @Override
    public OAuth2ClientRespDTO validOAuthClientFromCache(String clientId, String clientSecret, String authorizedGrantType, Collection<String> scopes, String redirectUri) {
        PlatformOAuth2ClientDO auth2ClientDO = auth2ClientService.validOAuthClientFromCache(clientId, clientSecret, authorizedGrantType, scopes, redirectUri);
        return getRespDTO(auth2ClientDO);
    }

    private OAuth2ClientRespDTO getRespDTO(PlatformOAuth2ClientDO auth2ClientDO) {
        OAuth2ClientRespDTO oAuth2ClientRespDTO = new OAuth2ClientRespDTO();
        oAuth2ClientRespDTO.setId(auth2ClientDO.getId());
        oAuth2ClientRespDTO.setClientId(auth2ClientDO.getClientId());
        oAuth2ClientRespDTO.setSecret(auth2ClientDO.getSecret());
        oAuth2ClientRespDTO.setName(auth2ClientDO.getName());
        oAuth2ClientRespDTO.setLogo(auth2ClientDO.getLogo());
        oAuth2ClientRespDTO.setDescription(auth2ClientDO.getDescription());
        oAuth2ClientRespDTO.setStatus(auth2ClientDO.getStatus());
        oAuth2ClientRespDTO.setAccessTokenValiditySeconds(auth2ClientDO.getAccessTokenValiditySeconds());
        oAuth2ClientRespDTO.setRefreshTokenValiditySeconds(auth2ClientDO.getRefreshTokenValiditySeconds());
        oAuth2ClientRespDTO.setRedirectUris(auth2ClientDO.getRedirectUris());
        oAuth2ClientRespDTO.setAuthorizedGrantTypes(auth2ClientDO.getAuthorizedGrantTypes());
        oAuth2ClientRespDTO.setScopes(auth2ClientDO.getScopes());
        oAuth2ClientRespDTO.setAutoApproveScopes(auth2ClientDO.getAutoApproveScopes());
        oAuth2ClientRespDTO.setAuthorities(auth2ClientDO.getAuthorities());
        oAuth2ClientRespDTO.setResourceIds(auth2ClientDO.getResourceIds());
        oAuth2ClientRespDTO.setAdditionalInformation(auth2ClientDO.getAdditionalInformation());
        return oAuth2ClientRespDTO;
    }

}
