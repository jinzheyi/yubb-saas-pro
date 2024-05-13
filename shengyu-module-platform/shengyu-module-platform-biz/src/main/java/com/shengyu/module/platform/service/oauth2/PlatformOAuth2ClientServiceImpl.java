package com.shengyu.module.platform.service.oauth2;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.OAUTH2_CLIENT_AUTHORIZED_GRANT_TYPE_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.OAUTH2_CLIENT_CLIENT_SECRET_ERROR;
import static com.shengyu.module.system.enums.ErrorCodeConstants.OAUTH2_CLIENT_DISABLE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.OAUTH2_CLIENT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.OAUTH2_CLIENT_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.OAUTH2_CLIENT_REDIRECT_URI_NOT_MATCH;
import static com.shengyu.module.system.enums.ErrorCodeConstants.OAUTH2_CLIENT_SCOPE_OVER;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.extra.spring.SpringUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.common.util.string.StrUtils;
import com.shengyu.module.platform.controller.platform.oauth2.vo.client.OAuth2ClientCreateReqVO;
import com.shengyu.module.platform.controller.platform.oauth2.vo.client.OAuth2ClientPageReqVO;
import com.shengyu.module.platform.controller.platform.oauth2.vo.client.OAuth2ClientUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import com.shengyu.module.platform.dal.mysql.oauth2.OAuth2ClientMapper;
import com.shengyu.module.platform.dal.redis.RedisKeyConstants;
import com.google.common.annotations.VisibleForTesting;
import java.util.Collection;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * OAuth2.0 Client Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
@Slf4j
public class PlatformOAuth2ClientServiceImpl implements PlatformOAuth2ClientService {

    @Resource
    private OAuth2ClientMapper oauth2ClientMapper;

    @Override
    public Long createOAuth2Client(OAuth2ClientCreateReqVO createReqVO) {
        validateClientIdExists(null, createReqVO.getClientId());
        // 插入
        PlatformOAuth2ClientDO oauth2Client = BeanUtils.toBean(createReqVO, PlatformOAuth2ClientDO.class);
        oauth2ClientMapper.insert(oauth2Client);
        return oauth2Client.getId();
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.OAUTH_CLIENT,
        allEntries = true) // allEntries 清空所有缓存，因为可能修改到 clientId 字段，不好清理
    public void updateOAuth2Client(OAuth2ClientUpdateReqVO updateReqVO) {
        // 校验存在
        validateOAuth2ClientExists(updateReqVO.getId());
        // 校验 Client 未被占用
        validateClientIdExists(updateReqVO.getId(), updateReqVO.getClientId());

        // 更新
        PlatformOAuth2ClientDO updateObj = BeanUtils.toBean(updateReqVO, PlatformOAuth2ClientDO.class);
        oauth2ClientMapper.updateById(updateObj);
    }

    @Override
    @CacheEvict(cacheNames = RedisKeyConstants.OAUTH_CLIENT,
        allEntries = true) // allEntries 清空所有缓存，因为 id 不是直接的缓存 key，不好清理
    public void deleteOAuth2Client(Long id) {
        // 校验存在
        validateOAuth2ClientExists(id);
        // 删除
        oauth2ClientMapper.deleteById(id);
    }

    private void validateOAuth2ClientExists(Long id) {
        if (oauth2ClientMapper.selectById(id) == null) {
            throw exception(OAUTH2_CLIENT_NOT_EXISTS);
        }
    }

    @VisibleForTesting
    void validateClientIdExists(Long id, String clientId) {
        PlatformOAuth2ClientDO client = oauth2ClientMapper.selectByClientId(clientId);
        if (client == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的客户端
        if (id == null) {
            throw exception(OAUTH2_CLIENT_EXISTS);
        }
        if (!client.getId().equals(id)) {
            throw exception(OAUTH2_CLIENT_EXISTS);
        }
    }

    @Override
    public PlatformOAuth2ClientDO getOAuth2Client(Long id) {
        return oauth2ClientMapper.selectById(id);
    }

    @Override
    @Cacheable(cacheNames = RedisKeyConstants.OAUTH_CLIENT, key = "#clientId",
        unless = "#result == null")
    public PlatformOAuth2ClientDO getOAuth2ClientFromCache(String clientId) {
        return oauth2ClientMapper.selectByClientId(clientId);
    }

    @Override
    public PageResult<PlatformOAuth2ClientDO> getOAuth2ClientPage(OAuth2ClientPageReqVO pageReqVO) {
        return oauth2ClientMapper.selectPage(pageReqVO);
    }

    @Override
    public PlatformOAuth2ClientDO validOAuthClientFromCache(String clientId, String clientSecret,
        String authorizedGrantType, Collection<String> scopes, String redirectUri) {
        // 校验客户端存在、且开启
        PlatformOAuth2ClientDO client = getSelf().getOAuth2ClientFromCache(clientId);
        if (client == null) {
            throw exception(OAUTH2_CLIENT_NOT_EXISTS);
        }
        if (ObjectUtil.notEqual(client.getStatus(), CommonStatusEnum.ENABLE.getStatus())) {
            throw exception(OAUTH2_CLIENT_DISABLE);
        }

        // 校验客户端密钥
        if (StrUtil.isNotEmpty(clientSecret) && ObjectUtil.notEqual(client.getSecret(),
            clientSecret)) {
            throw exception(OAUTH2_CLIENT_CLIENT_SECRET_ERROR);
        }
        // 校验授权方式
        if (StrUtil.isNotEmpty(authorizedGrantType) && !CollUtil.contains(
            client.getAuthorizedGrantTypes(), authorizedGrantType)) {
            throw exception(OAUTH2_CLIENT_AUTHORIZED_GRANT_TYPE_NOT_EXISTS);
        }
        // 校验授权范围
        if (CollUtil.isNotEmpty(scopes) && !CollUtil.containsAll(client.getScopes(), scopes)) {
            throw exception(OAUTH2_CLIENT_SCOPE_OVER);
        }
        // 校验回调地址
        if (StrUtil.isNotEmpty(redirectUri) && !StrUtils.startWithAny(redirectUri,
            client.getRedirectUris())) {
            throw exception(OAUTH2_CLIENT_REDIRECT_URI_NOT_MATCH, redirectUri);
        }
        return client;
    }

    /**
     * 获得自身的代理对象，解决 AOP 生效问题
     *
     * @return 自己
     */
    private PlatformOAuth2ClientServiceImpl getSelf() {
        return SpringUtil.getBean(getClass());
    }

}
