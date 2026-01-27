package com.shengyu.framework.websocket.core.service.impl;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.security.core.util.LoginBase;
import com.shengyu.framework.websocket.core.service.AuthService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Service;

/**
 * 认证服务默认实现
 * <p>
 * 这是一个默认的空实现，业务模块应该提供自己的实现来集成项目的 OAuth2 认证体系
 * <p>
 * 实现建议：
 * 1. 在 system 或 platform 模块中创建 AuthService 的实现类
 * 2. 注入对应的 OAuth2TokenService
 * 3. 实现 Token 验证逻辑
 * 4. 返回 LoginUser 或 PlatformLoginUser 对象
 *
 * @author 圣钰科技
 */
@Slf4j
@Service
@ConditionalOnMissingBean(AuthService.class)
public class AuthServiceImpl implements AuthService {

    @Override
    public LoginBase validateToken(String accessToken) {
        if (StrUtil.isBlank(accessToken)) {
            log.warn("[AuthService] Token 为空");
            return null;
        }

        // 默认实现：不进行实际验证
        // 业务模块应该提供自己的实现
        log.warn("[AuthService] 使用默认实现，Token 验证未执行: {}", accessToken);
        log.warn("[AuthService] 请在业务模块中实现 AuthService 接口以集成 OAuth2 认证");
        
        return null;
    }

    @Override
    public Long getTenantId(LoginBase loginUser) {
        // 默认实现：返回 null
        // 业务模块应该提供自己的实现
        return null;
    }
}
