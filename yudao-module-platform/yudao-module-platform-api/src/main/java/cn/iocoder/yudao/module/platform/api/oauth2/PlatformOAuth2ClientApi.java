package cn.iocoder.yudao.module.platform.api.oauth2;

import cn.iocoder.yudao.module.platform.api.oauth2.dto.client.OAuth2ClientRespDTO;

import java.util.Collection;

/**
 * @Description OAuth2Clien api 接口
 * @Author zhusy
 * @Date 2023/4/25 11:14
 * @Version 1.0
 **/
public interface PlatformOAuth2ClientApi {

    /**
     * 根据客户端类型查询客户端信息
     * @param clientId 客户端类型
     * @return 客户端信息
     */
    OAuth2ClientRespDTO validOAuthClientFromCache(String clientId);

    /**
     * 从缓存中，校验客户端是否合法
     *
     * 非空时，进行校验
     *
     * @param clientId 客户端编号
     * @param clientSecret 客户端密钥
     * @param authorizedGrantType 授权方式
     * @param scopes 授权范围
     * @param redirectUri 重定向地址
     * @return 客户端
     */
    OAuth2ClientRespDTO validOAuthClientFromCache(String clientId, String clientSecret,
                                                     String authorizedGrantType, Collection<String> scopes, String redirectUri);

}
