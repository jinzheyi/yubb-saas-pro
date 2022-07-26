package cn.iocoder.yudao.module.platform.api.oauth2;

import cn.iocoder.yudao.module.platform.api.oauth2.dto.PlatformOAuth2AccessTokenCheckRespDTO;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.PlatformOAuth2AccessTokenCreateReqDTO;
import cn.iocoder.yudao.module.platform.api.oauth2.dto.PlatformOAuth2AccessTokenRespDTO;

import javax.validation.Valid;

/**
 * OAuth2.0 Token API 接口
 *
 * @author 芋道源码
 */
public interface PlatformOAuth2TokenApi {

    /**
     * 创建访问令牌
     *
     * @param reqDTO 访问令牌的创建信息
     * @return 访问令牌的信息
     */
    PlatformOAuth2AccessTokenRespDTO createAccessToken(@Valid PlatformOAuth2AccessTokenCreateReqDTO reqDTO);

    /**
     * 校验访问令牌
     *
     * @param accessToken 访问令牌
     * @return 访问令牌的信息
     */
    PlatformOAuth2AccessTokenCheckRespDTO checkAccessToken(String accessToken);

    /**
     * 移除访问令牌
     *
     * @param accessToken 访问令牌
     * @return 访问令牌的信息
     */
    PlatformOAuth2AccessTokenRespDTO removeAccessToken(String accessToken);

    /**
     * 刷新访问令牌
     *
     * @param refreshToken 刷新令牌
     * @param clientId 客户端编号
     * @return 访问令牌的信息
     */
    PlatformOAuth2AccessTokenRespDTO refreshAccessToken(String refreshToken, String clientId);

}
