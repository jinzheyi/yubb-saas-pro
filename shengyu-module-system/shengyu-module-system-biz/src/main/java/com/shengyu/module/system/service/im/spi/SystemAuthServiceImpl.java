package com.shengyu.module.system.service.im.spi;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.LoginBase;
import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.module.system.api.oauth2.OAuth2TokenApi;
import com.shengyu.module.system.api.oauth2.dto.OAuth2AccessTokenCheckRespDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.time.LocalDateTime;

/**
 * System 模块 - 认证服务实现
 * 
 * 实现 WebSocket 中间件的 AuthService SPI 接口
 * 负责验证 WebSocket 连接的 Token，支持租户端认证
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class SystemAuthServiceImpl implements AuthService {

    @Resource
    private OAuth2TokenApi oauth2TokenApi;

    @Override
    public LoginBase validateToken(String accessToken) {
        if (StrUtil.isBlank(accessToken)) {
            log.warn("[WebSocketAuth] Token 为空");
            return null;
        }

        try {
            // 1. 验证 Token 有效性
            OAuth2AccessTokenCheckRespDTO tokenInfo = oauth2TokenApi.checkAccessToken(accessToken);
            
            if (tokenInfo == null) {
                log.warn("[WebSocketAuth] Token 验证失败，Token 不存在: {}", accessToken);
                return null;
            }

            // 2. 检查 Token 是否过期
            if (tokenInfo.getExpiresTime() != null && 
                tokenInfo.getExpiresTime().isBefore(LocalDateTime.now())) {
                log.warn("[WebSocketAuth] Token 已过期, userId: {}, expiresTime: {}", 
                        tokenInfo.getUserId(), tokenInfo.getExpiresTime());
                return null;
            }

            // 3. 构建 LoginUser 对象
            LoginUser loginUser = buildLoginUser(tokenInfo);
            
            log.info("[WebSocketAuth] Token 验证成功, userId: {}, tenantId: {}", 
                    loginUser.getId(), loginUser.getTenantId());
            
            return loginUser;
            
        } catch (Exception e) {
            log.error("[WebSocketAuth] Token 验证异常", e);
            return null;
        }
    }

    @Override
    public Long getTenantId(LoginBase loginUser) {
        if (loginUser instanceof LoginUser) {
            return ((LoginUser) loginUser).getTenantId();
        }
        // 平台端用户无租户ID
        return null;
    }

    /**
     * 构建 LoginUser 对象
     */
    private LoginUser buildLoginUser(OAuth2AccessTokenCheckRespDTO tokenInfo) {
        LoginUser loginUser = new LoginUser();
        loginUser.setId(tokenInfo.getUserId());
        loginUser.setUserType(tokenInfo.getUserType());
        loginUser.setTenantId(tokenInfo.getTenantId());
        
        // 设置其他必要字段
        // 注意：这里可能需要查询用户详细信息
        // 为了性能考虑，WebSocket 认证只验证 Token，不查询完整用户信息
        
        return loginUser;
    }

}
