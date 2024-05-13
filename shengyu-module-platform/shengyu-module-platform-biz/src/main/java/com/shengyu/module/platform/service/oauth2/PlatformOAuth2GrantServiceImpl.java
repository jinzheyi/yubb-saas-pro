package com.shengyu.module.platform.service.oauth2;

import cn.hutool.core.lang.Assert;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2CodeDO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import com.shengyu.module.system.enums.ErrorCodeConstants;
import com.shengyu.module.platform.service.auth.PlatformAuthService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;

/**
 * OAuth2 授予 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
public class PlatformOAuth2GrantServiceImpl implements PlatformOAuth2GrantService {

    @Resource
    private PlatformOAuth2TokenService oauth2TokenServicePlatform;
    @Resource
    private PlatformOAuth2CodeService oauth2CodeServicePlatform;
    @Resource
    private PlatformAuthService platformAuthService;

    @Override
    public PlatformOAuth2AccessTokenDO grantImplicit(Long userId, Integer userType,
                                                     String clientId, List<String> scopes) {
        return oauth2TokenServicePlatform.createAccessToken(userId, userType, clientId, scopes);
    }

    @Override
    public String grantAuthorizationCodeForCode(Long userId, Integer userType,
                                                String clientId, List<String> scopes,
                                                String redirectUri, String state) {
        return oauth2CodeServicePlatform.createAuthorizationCode(userId, userType, clientId, scopes,
                redirectUri, state).getCode();
    }

    @Override
    public PlatformOAuth2AccessTokenDO grantAuthorizationCodeForAccessToken(String clientId, String code,
                                                                            String redirectUri, String state) {
        PlatformOAuth2CodeDO codeDO = oauth2CodeServicePlatform.consumeAuthorizationCode(code);
        Assert.notNull(codeDO, "授权码不能为空"); // 防御性编程
        // 校验 clientId 是否匹配
        if (!StrUtil.equals(clientId, codeDO.getClientId())) {
            throw exception(ErrorCodeConstants.OAUTH2_GRANT_CLIENT_ID_MISMATCH);
        }
        // 校验 redirectUri 是否匹配
        if (!StrUtil.equals(redirectUri, codeDO.getRedirectUri())) {
            throw exception(ErrorCodeConstants.OAUTH2_GRANT_REDIRECT_URI_MISMATCH);
        }
        // 校验 state 是否匹配
        state = StrUtil.nullToDefault(state, ""); // 数据库 state 为 null 时，会设置为 "" 空串
        if (!StrUtil.equals(state, codeDO.getState())) {
            throw exception(ErrorCodeConstants.OAUTH2_GRANT_STATE_MISMATCH);
        }

        // 创建访问令牌
        return oauth2TokenServicePlatform.createAccessToken(codeDO.getUserId(), codeDO.getUserType(),
                codeDO.getClientId(), codeDO.getScopes());
    }

    @Override
    public PlatformOAuth2AccessTokenDO grantPassword(String username, String password, String clientId, List<String> scopes) {
        // 使用账号 + 密码进行登录
        PlatformUserDO user = platformAuthService.authenticate(username, password);
        Assert.notNull(user, "用户不能为空！"); // 防御性编程

        // 创建访问令牌
        return oauth2TokenServicePlatform.createAccessToken(user.getId(), UserTypeEnum.PLATFORM.getValue(), clientId, scopes);
    }

    @Override
    public PlatformOAuth2AccessTokenDO grantRefreshToken(String refreshToken, String clientId) {
        return oauth2TokenServicePlatform.refreshAccessToken(refreshToken, clientId);
    }

    @Override
    public PlatformOAuth2AccessTokenDO grantClientCredentials(String clientId, List<String> scopes) {
        // TODO 芋艿：项目中使用 OAuth2 解决的是三方应用的授权，内部的 SSO 等问题，所以暂时不考虑 client_credentials 这个场景
        throw new UnsupportedOperationException("暂时不支持 client_credentials 授权模式");
    }

    @Override
    public boolean revokeToken(String clientId, String accessToken) {
        // 先查询，保证 clientId 时匹配的
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2TokenServicePlatform.getAccessToken(accessToken);
        if (accessTokenDO == null || ObjectUtil.notEqual(clientId, accessTokenDO.getClientId())) {
            return false;
        }
        // 再删除
        return oauth2TokenServicePlatform.removeAccessToken(accessToken) != null;
    }

}
