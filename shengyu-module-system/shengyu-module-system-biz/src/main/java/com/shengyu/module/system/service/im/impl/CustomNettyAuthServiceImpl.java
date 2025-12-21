package com.shengyu.module.system.service.im.impl;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.oauth2.OAuth2ClientConstants;
import com.shengyu.framework.netty.core.Attributes;
import com.shengyu.framework.netty.core.auth.AuthInfo;
import com.shengyu.framework.netty.service.NettyAuthService;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.module.system.dal.dataobject.oauth2.OAuth2AccessTokenDO;
import com.shengyu.module.system.service.oauth2.OAuth2TokenService;
import io.netty.channel.Channel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 自定义Netty认证服务实现
 * 用于处理WebSocket连接的认证逻辑
 *
 * @author zhusy
 * @since 2024/12/21
 */
@Service
public class CustomNettyAuthServiceImpl implements NettyAuthService {

    private static final Logger log = LoggerFactory.getLogger(CustomNettyAuthServiceImpl.class);

    @Autowired
    private OAuth2TokenService oauth2TokenService;

    @Override
    public boolean authenticate(AuthInfo authInfo, Channel channel) {
        if (authInfo == null || authInfo.getToken() == null) {
            log.warn("认证失败：token为空");
            return false;
        }
        return TenantUtils.execute(Long.valueOf(authInfo.getTenantId()), () -> auth(authInfo));
    }

    @Override
    public AuthInfo getAuthInfo(Channel channel) {
        return channel.attr(Attributes.AUTH_INFO).get();
    }

    @Override
    public void saveAuthInfo(Channel channel, AuthInfo authInfo) {
        channel.attr(Attributes.AUTH_INFO).set(authInfo);
        log.debug("保存认证信息：用户ID={}", authInfo.getUserId());
    }

    @Override
    public void clearAuthInfo(Channel channel) {
        channel.attr(Attributes.AUTH_INFO).remove();
        log.debug("清除认证信息：通道ID={}", channel.id());
    }

    @Override
    public boolean isAuthenticated(Channel channel) {
        return channel.attr(Attributes.AUTH_INFO).get() != null;
    }

    private boolean auth(AuthInfo authInfo) {
        // 调用业务服务的token验证逻辑
        OAuth2AccessTokenDO accessTokenDO = null;
        try {
            accessTokenDO = oauth2TokenService.checkAccessToken(authInfo.getToken());
        } catch (Exception e) {
            log.warn("token验证异常：{}", e.getMessage());
        }
        if (accessTokenDO != null) {
            // 如果token有效，设置userId和tenantId
            Long userId = accessTokenDO.getUserId();
            Long tenantId = accessTokenDO.getTenantId();
            authInfo.setUserId(userId.toString());
            authInfo.setTenantId(tenantId != null ? tenantId.toString() : authInfo.getTenantId());
            log.info("认证成功：用户ID={}, 租户ID={}", userId, authInfo.getTenantId());
            return true;
        } else {
            log.warn("accessToken无效，尝试使用refreshToken刷新：token={}", authInfo.getToken());
            // accessToken无效，尝试使用refreshToken刷新
            if (StrUtil.isNotBlank(authInfo.getRefreshToken())) {
                OAuth2AccessTokenDO newAccessTokenDO = null;
                try {
                    // 使用refreshToken获取新的accessToken
                    newAccessTokenDO = oauth2TokenService.refreshAccessToken(authInfo.getRefreshToken(), OAuth2ClientConstants.CLIENT_ID_TENANT);
                } catch (Exception e) {
                    log.warn("refreshToken验证异常：{}", e.getMessage());
                }
                if (newAccessTokenDO != null) {
                    // 刷新成功，更新token
                    authInfo.setToken(newAccessTokenDO.getAccessToken());
                    authInfo.setRefreshToken(newAccessTokenDO.getRefreshToken());
                    // 设置userId和tenantId
                    Long userId = newAccessTokenDO.getUserId();
                    Long tenantId = newAccessTokenDO.getTenantId();
                    authInfo.setUserId(userId.toString());
                    authInfo.setTenantId(tenantId != null ? tenantId.toString() : authInfo.getTenantId());
                    log.info("token刷新成功：用户ID={}, 租户ID={}", userId, authInfo.getTenantId());
                    return true;
                }
            }
            log.warn("认证失败：无效的token和refreshToken");
            return false;
        }
    }
}
