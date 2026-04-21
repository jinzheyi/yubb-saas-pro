package com.shengyu.module.platform.service.oauth2;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.ObjectUtil;
import com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.date.DateUtils;
import com.shengyu.module.platform.controller.platform.oauth2.vo.token.OAuth2AccessTokenPageReqVO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2RefreshTokenDO;
import com.shengyu.module.platform.dal.mysql.oauth2.PlatformOAuth2AccessTokenMapper;
import com.shengyu.module.platform.dal.mysql.oauth2.PlatformOAuth2RefreshTokenMapper;
import com.shengyu.module.platform.dal.redis.oauth2.PlatformOAuth2AccessTokenRedisDAO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.List;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception0;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * OAuth2.0 Token Service 实现类
 *
 * @author 圣钰科技
 */
@Service
public class PlatformOAuth2TokenServiceImpl implements PlatformOAuth2TokenService {

    @Resource
    private PlatformOAuth2AccessTokenMapper oauth2AccessTokenMapperPlatform;
    @Resource
    private PlatformOAuth2RefreshTokenMapper oauth2RefreshTokenMapperPlatform;

    @Resource
    private PlatformOAuth2AccessTokenRedisDAO oauth2AccessTokenRedisDAOPlatform;

    @Resource
    private PlatformOAuth2ClientService oauth2ClientServicePlatform;

    @Override
    @Transactional
    public PlatformOAuth2AccessTokenDO createAccessToken(Long userId, Integer userType, String clientId, List<String> scopes) {
        PlatformOAuth2ClientDO clientDO = oauth2ClientServicePlatform.validOAuthClientFromCache(clientId);
        // 创建刷新令牌
        PlatformOAuth2RefreshTokenDO refreshTokenDO = createOAuth2RefreshToken(userId, userType, clientDO, scopes);
        // 创建访问令牌
        return createOAuth2AccessToken(refreshTokenDO, clientDO);
    }

    @Override
    public PlatformOAuth2AccessTokenDO refreshAccessToken(String refreshToken, String clientId) {
        // 查询访问令牌
        PlatformOAuth2RefreshTokenDO refreshTokenDO = oauth2RefreshTokenMapperPlatform.selectByRefreshToken(refreshToken);
        if (refreshTokenDO == null) {
            throw exception0(GlobalErrorCodeConstants.BAD_REQUEST.getCode(),
                ServiceExceptionUtil.getOrDefault("oauth.refresh_token.invalid", "Invalid refresh token"));
        }

        // 校验 Client 匹配
        PlatformOAuth2ClientDO clientDO = oauth2ClientServicePlatform.validOAuthClientFromCache(clientId);
        if (ObjectUtil.notEqual(clientId, refreshTokenDO.getClientId())) {
            throw exception0(GlobalErrorCodeConstants.BAD_REQUEST.getCode(),
                ServiceExceptionUtil.getOrDefault("oauth.refresh_token.client_mismatch", "Refresh token client ID is invalid"));
        }

        // 移除相关的访问令牌
        List<PlatformOAuth2AccessTokenDO> accessTokenDOs = oauth2AccessTokenMapperPlatform.selectListByRefreshToken(refreshToken);
        if (CollUtil.isNotEmpty(accessTokenDOs)) {
            oauth2AccessTokenMapperPlatform.deleteBatchIds(convertSet(accessTokenDOs, PlatformOAuth2AccessTokenDO::getId));
            oauth2AccessTokenRedisDAOPlatform.deleteList(convertSet(accessTokenDOs, PlatformOAuth2AccessTokenDO::getAccessToken));
        }

        // 已过期的情况下，删除刷新令牌
        if (DateUtils.isExpired(refreshTokenDO.getExpiresTime())) {
            oauth2RefreshTokenMapperPlatform.deleteById(refreshTokenDO.getId());
            throw exception0(GlobalErrorCodeConstants.UNAUTHORIZED.getCode(),
                ServiceExceptionUtil.getOrDefault("oauth.refresh_token.expired", "Refresh token expired"));
        }

        // 创建访问令牌
        return createOAuth2AccessToken(refreshTokenDO, clientDO);
    }

    @Override
    public PlatformOAuth2AccessTokenDO getAccessToken(String accessToken) {
        // 优先从 Redis 中获取
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2AccessTokenRedisDAOPlatform.get(accessToken);
        if (accessTokenDO != null) {
            return accessTokenDO;
        }

        // 获取不到，从 MySQL 中获取
        accessTokenDO = oauth2AccessTokenMapperPlatform.selectByAccessToken(accessToken);
        // 如果在 MySQL 存在，则往 Redis 中写入
        if (accessTokenDO != null && !DateUtils.isExpired(accessTokenDO.getExpiresTime())) {
            oauth2AccessTokenRedisDAOPlatform.set(accessTokenDO);
        }
        return accessTokenDO;
    }

    @Override
    public PlatformOAuth2AccessTokenDO checkAccessToken(String accessToken) {
        PlatformOAuth2AccessTokenDO accessTokenDO = getAccessToken(accessToken);
        if (accessTokenDO == null) {
            throw exception0(GlobalErrorCodeConstants.UNAUTHORIZED.getCode(),
                ServiceExceptionUtil.getOrDefault("oauth.access_token.not_found", "Access token not found"));
        }
        if (DateUtils.isExpired(accessTokenDO.getExpiresTime())) {
            throw exception0(GlobalErrorCodeConstants.UNAUTHORIZED.getCode(),
                ServiceExceptionUtil.getOrDefault("oauth.access_token.expired", "Access token expired"));
        }
        return accessTokenDO;
    }

    @Override
    public PlatformOAuth2AccessTokenDO removeAccessToken(String accessToken) {
        // 删除访问令牌
        PlatformOAuth2AccessTokenDO accessTokenDO = oauth2AccessTokenMapperPlatform.selectByAccessToken(accessToken);
        if (accessTokenDO == null) {
            return null;
        }
        oauth2AccessTokenMapperPlatform.deleteById(accessTokenDO.getId());
        oauth2AccessTokenRedisDAOPlatform.delete(accessToken);
        // 删除刷新令牌
        oauth2RefreshTokenMapperPlatform.deleteByRefreshToken(accessTokenDO.getRefreshToken());
        return accessTokenDO;
    }

    @Override
    public PageResult<PlatformOAuth2AccessTokenDO> getAccessTokenPage(OAuth2AccessTokenPageReqVO reqVO) {
        return oauth2AccessTokenMapperPlatform.selectPage(reqVO);
    }

    private PlatformOAuth2AccessTokenDO createOAuth2AccessToken(PlatformOAuth2RefreshTokenDO refreshTokenDO, PlatformOAuth2ClientDO clientDO) {
        PlatformOAuth2AccessTokenDO accessTokenDO = new PlatformOAuth2AccessTokenDO().setAccessToken(generateAccessToken())
                .setUserId(refreshTokenDO.getUserId()).setUserType(refreshTokenDO.getUserType())
                .setClientId(clientDO.getClientId()).setScopes(refreshTokenDO.getScopes())
                .setRefreshToken(refreshTokenDO.getRefreshToken())
                .setExpiresTime(LocalDateTime.now().plusSeconds(clientDO.getAccessTokenValiditySeconds()));
        oauth2AccessTokenMapperPlatform.insert(accessTokenDO);
        // 记录到 Redis 中
        oauth2AccessTokenRedisDAOPlatform.set(accessTokenDO);
        return accessTokenDO;
    }

    private PlatformOAuth2RefreshTokenDO createOAuth2RefreshToken(Long userId, Integer userType, PlatformOAuth2ClientDO clientDO, List<String> scopes) {
        PlatformOAuth2RefreshTokenDO refreshToken = new PlatformOAuth2RefreshTokenDO().setRefreshToken(generateRefreshToken())
                .setUserId(userId).setUserType(userType)
                .setClientId(clientDO.getClientId()).setScopes(scopes)
                .setExpiresTime(LocalDateTime.now().plusSeconds(clientDO.getRefreshTokenValiditySeconds()));
        oauth2RefreshTokenMapperPlatform.insert(refreshToken);
        return refreshToken;
    }

    private static String generateAccessToken() {
        return IdUtil.fastSimpleUUID();
    }

    private static String generateRefreshToken() {
        return IdUtil.fastSimpleUUID();
    }

}
