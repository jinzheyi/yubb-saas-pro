package cn.iocoder.yudao.module.platform.service.oauth2;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.iocoder.yudao.framework.common.exception.enums.GlobalErrorCodeConstants;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.date.DateUtils;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.token.OAuth2AccessTokenPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2RefreshTokenDO;
import cn.iocoder.yudao.module.platform.dal.mapper.oauth2.PlatformOAuth2AccessTokenMapper;
import cn.iocoder.yudao.module.platform.dal.mapper.oauth2.PlatformOAuth2RefreshTokenMapper;
import cn.iocoder.yudao.module.platform.dal.redis.oauth2.PlatformOAuth2AccessTokenRedisDAO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.Calendar;
import java.util.List;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception0;
import static cn.iocoder.yudao.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * OAuth2.0 Token Service 实现类
 *
 * @author 芋道源码
 */
@Service
public class PlatformOAuth2TokenServiceImpl implements PlatformOAuth2TokenService {

    @Resource
    private PlatformOAuth2AccessTokenMapper platformOAuth2AccessTokenMapper;
    @Resource
    private PlatformOAuth2RefreshTokenMapper platformOAuth2RefreshTokenMapper;

    @Resource
    private PlatformOAuth2AccessTokenRedisDAO platformOAuth2AccessTokenRedisDAO;

    @Resource
    private PlatformOAuth2ClientService platformOAuth2ClientService;

    @Override
    @Transactional
    public PlatformOAuth2AccessTokenDO createAccessToken(Long userId, Integer userType, String clientId, List<String> scopes) {
        PlatformOAuth2ClientDO clientDO = platformOAuth2ClientService.validOAuthClientFromCache(clientId);
        // 创建刷新令牌
        PlatformOAuth2RefreshTokenDO refreshTokenDO = createOAuth2RefreshToken(userId, userType, clientDO, scopes);
        // 创建访问令牌
        return createOAuth2AccessToken(refreshTokenDO, clientDO);
    }

    @Override
    public PlatformOAuth2AccessTokenDO refreshAccessToken(String refreshToken, String clientId) {
        // 查询访问令牌
        PlatformOAuth2RefreshTokenDO refreshTokenDO = platformOAuth2RefreshTokenMapper.selectByRefreshToken(refreshToken);
        if (refreshTokenDO == null) {
            throw exception0(GlobalErrorCodeConstants.BAD_REQUEST.getCode(), "无效的刷新令牌");
        }

        // 校验 Client 匹配
        PlatformOAuth2ClientDO clientDO = platformOAuth2ClientService.validOAuthClientFromCache(clientId);
        if (ObjectUtil.notEqual(clientId, refreshTokenDO.getClientId())) {
            throw exception0(GlobalErrorCodeConstants.BAD_REQUEST.getCode(), "刷新令牌的客户端编号不正确");
        }

        // 移除相关的访问令牌
        List<PlatformOAuth2AccessTokenDO> accessTokenDOs = platformOAuth2AccessTokenMapper.selectListByRefreshToken(refreshToken);
        if (CollUtil.isNotEmpty(accessTokenDOs)) {
            platformOAuth2AccessTokenMapper.deleteBatchIds(convertSet(accessTokenDOs, PlatformOAuth2AccessTokenDO::getId));
            platformOAuth2AccessTokenRedisDAO.deleteList(convertSet(accessTokenDOs, PlatformOAuth2AccessTokenDO::getAccessToken));
        }

        // 已过期的情况下，删除刷新令牌
        if (DateUtils.isExpired(refreshTokenDO.getExpiresTime())) {
            platformOAuth2RefreshTokenMapper.deleteById(refreshTokenDO.getId());
            throw exception0(GlobalErrorCodeConstants.UNAUTHORIZED.getCode(), "刷新令牌已过期");
        }

        // 创建访问令牌
        return createOAuth2AccessToken(refreshTokenDO, clientDO);
    }

    @Override
    public PlatformOAuth2AccessTokenDO getAccessToken(String accessToken) {
        // 优先从 Redis 中获取
        PlatformOAuth2AccessTokenDO accessTokenDO = platformOAuth2AccessTokenRedisDAO.get(accessToken);
        if (accessTokenDO != null) {
            return accessTokenDO;
        }

        // 获取不到，从 MySQL 中获取
        accessTokenDO = platformOAuth2AccessTokenMapper.selectByAccessToken(accessToken);
        // 如果在 MySQL 存在，则往 Redis 中写入
        if (accessTokenDO != null && !DateUtils.isExpired(accessTokenDO.getExpiresTime())) {
            platformOAuth2AccessTokenRedisDAO.set(accessTokenDO);
        }
        return accessTokenDO;
    }

    @Override
    public PlatformOAuth2AccessTokenDO checkAccessToken(String accessToken) {
        PlatformOAuth2AccessTokenDO accessTokenDO = getAccessToken(accessToken);
        if (accessTokenDO == null) {
            throw exception0(GlobalErrorCodeConstants.UNAUTHORIZED.getCode(), "访问令牌不存在");
        }
        if (DateUtils.isExpired(accessTokenDO.getExpiresTime())) {
            throw exception0(GlobalErrorCodeConstants.UNAUTHORIZED.getCode(), "访问令牌已过期");
        }
        return accessTokenDO;
    }

    @Override
    public PlatformOAuth2AccessTokenDO removeAccessToken(String accessToken) {
        // 删除访问令牌
        PlatformOAuth2AccessTokenDO accessTokenDO = platformOAuth2AccessTokenMapper.selectByAccessToken(accessToken);
        if (accessTokenDO == null) {
            return null;
        }
        platformOAuth2AccessTokenMapper.deleteById(accessTokenDO.getId());
        platformOAuth2AccessTokenRedisDAO.delete(accessToken);
        // 删除刷新令牌
        platformOAuth2RefreshTokenMapper.deleteByRefreshToken(accessTokenDO.getRefreshToken());
        return accessTokenDO;
    }

    @Override
    public PageResult<PlatformOAuth2AccessTokenDO> getAccessTokenPage(OAuth2AccessTokenPageReqVO reqVO) {
        return platformOAuth2AccessTokenMapper.selectPage(reqVO);
    }

    private PlatformOAuth2AccessTokenDO createOAuth2AccessToken(PlatformOAuth2RefreshTokenDO refreshTokenDO, PlatformOAuth2ClientDO clientDO) {
        PlatformOAuth2AccessTokenDO accessTokenDO = new PlatformOAuth2AccessTokenDO().setAccessToken(generateAccessToken())
                .setUserId(refreshTokenDO.getUserId()).setUserType(refreshTokenDO.getUserType())
                .setClientId(clientDO.getClientId()).setScopes(refreshTokenDO.getScopes())
                .setRefreshToken(refreshTokenDO.getRefreshToken())
                .setExpiresTime(DateUtils.addDate(Calendar.SECOND, clientDO.getAccessTokenValiditySeconds()));
        platformOAuth2AccessTokenMapper.insert(accessTokenDO);
        // 记录到 Redis 中
        platformOAuth2AccessTokenRedisDAO.set(accessTokenDO);
        return accessTokenDO;
    }

    private PlatformOAuth2RefreshTokenDO createOAuth2RefreshToken(Long userId, Integer userType, PlatformOAuth2ClientDO clientDO, List<String> scopes) {
        PlatformOAuth2RefreshTokenDO refreshToken = new PlatformOAuth2RefreshTokenDO().setRefreshToken(generateRefreshToken())
                .setUserId(userId).setUserType(userType)
                .setClientId(clientDO.getClientId()).setScopes(scopes)
                .setExpiresTime(DateUtils.addDate(Calendar.SECOND, clientDO.getRefreshTokenValiditySeconds()));
        platformOAuth2RefreshTokenMapper.insert(refreshToken);
        return refreshToken;
    }

    private static String generateAccessToken() {
        return IdUtil.fastSimpleUUID();
    }

    private static String generateRefreshToken() {
        return IdUtil.fastSimpleUUID();
    }

}
