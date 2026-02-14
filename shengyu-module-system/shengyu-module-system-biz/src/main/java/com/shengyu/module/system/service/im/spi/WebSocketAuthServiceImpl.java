package com.shengyu.module.system.service.im.spi;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.LoginBase;
import com.shengyu.framework.websocket.core.service.AuthService;
import com.shengyu.module.system.dal.dataobject.oauth2.OAuth2AccessTokenDO;
import com.shengyu.module.system.service.oauth2.OAuth2TokenService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * System 模块 - WebSocket 认证服务实现
 * 
 * 实现 WebSocket 中间件的 AuthService SPI 接口
 * 负责验证 WebSocket 连接的 Token，支持租户端认证
 * 
 * 认证流程（完全对齐 Web 端）：
 * 1. 调用 OAuth2TokenService.checkAccessToken() 验证 Token
 * 2. checkAccessToken() 内部会：
 *    - 优先从 Redis 缓存获取 Token（性能优化）
 *    - 缓存未命中则从 MySQL 查询
 *    - 使用 DateUtils.isExpired() 检查是否过期
 *    - Token 不存在或已过期会抛出 ServiceException
 * 3. 验证成功后，构建 LoginUser 对象返回
 * 4. WebSocket 中间件将 LoginUser 保存到 Session 中
 * 
 * 与 Web 端认证的对比：
 * - Web 端：通过 Spring Security Filter 拦截 HTTP 请求，验证 Token 后设置到 SecurityContext
 * - IM 端：通过 WebSocket 握手时验证 Token，验证后保存到 NettySession
 * - 共同点：都使用 OAuth2TokenService.checkAccessToken() 验证 Token
 * - 差异点：Web 端需要完整用户信息（权限、角色等），IM 端只需要基本身份信息
 *
 * Bean 命名说明：
 * - 类名：WebSocketAuthServiceImpl
 * - Bean名称：webSocketAuthServiceImpl（Spring自动生成）
 * - 实现接口：com.shengyu.framework.websocket.core.service.AuthService
 * - 不会与 AdminAuthService（不同接口）冲突
 * 
 * 注意：
 * - 不使用 @Primary，因为 AdminAuthService 和 AuthService 是不同的接口
 * - WebSocket 中间件会通过类型自动注入此实现
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class WebSocketAuthServiceImpl implements AuthService {

    @Resource
    private OAuth2TokenService oauth2TokenService;

    @Override
    public LoginBase validateToken(String accessToken) {
        // 1. 参数校验
        if (StrUtil.isBlank(accessToken)) {
            log.warn("[IM-WebSocketAuth] Token 为空");
            return null;
        }

        try {
            // 2. 验证 Token 有效性（完全对齐 Web 端逻辑）
            // 参考：
            // - OAuth2TokenServiceImpl.checkAccessToken() - Token 验证核心逻辑
            // - OAuth2TokenServiceImpl.getAccessToken() - 优先从 Redis 获取，提升性能
            // - DateUtils.isExpired() - 统一的过期时间判断
            // 
            // 如果 Token 不存在或已过期，会抛出 ServiceException：
            // - "访问令牌不存在" (GlobalErrorCodeConstants.UNAUTHORIZED)
            // - "访问令牌已过期" (GlobalErrorCodeConstants.UNAUTHORIZED)
            OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.checkAccessToken(accessToken);
            
            // 3. 构建 LoginUser 对象
            LoginUser loginUser = buildLoginUser(accessTokenDO);
            
            log.info("[IM-WebSocketAuth] Token 验证成功, userId: {}, tenantId: {}, userType: {}", 
                    loginUser.getId(), loginUser.getTenantId(), loginUser.getUserType());
            
            return loginUser;
            
        } catch (Exception e) {
            // 4. 异常处理
            // 捕获所有异常，返回 null 表示认证失败
            // WebSocket 中间件会关闭连接并返回认证失败响应
            log.warn("[IM-WebSocketAuth] Token 验证失败: {}", e.getMessage());
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
     * 
     * 设计说明：
     * 1. IM 认证只需要基本身份信息（userId、userType、tenantId）
     * 2. 不查询完整用户信息（username、nickname、权限、角色等）
     * 3. 性能优化：避免额外的数据库查询
     * 4. 如果业务需要完整用户信息，可以在消息处理时通过 userId 查询
     * 
     * 与 Web 端的差异：
     * - Web 端：需要完整用户信息，包括权限、角色、部门等（用于权限控制）
     * - IM 端：只需要基本身份信息（用于消息路由和租户隔离）
     * 
     * 参考：
     * - AdminAuthServiceImpl.createTokenAfterLoginSuccess() - Web 端创建 Token 后的处理
     * - SecurityFrameworkUtils.setLoginUser() - Web 端设置登录用户到 SecurityContext
     */
    private LoginUser buildLoginUser(OAuth2AccessTokenDO accessTokenDO) {
        LoginUser loginUser = new LoginUser();
        loginUser.setId(accessTokenDO.getUserId());
        loginUser.setUserType(accessTokenDO.getUserType());
        loginUser.setTenantId(accessTokenDO.getTenantId());
        
        // 注意：这里不设置其他字段（如 username、nickname、deptId、roleIds 等）
        // 原因：
        // 1. WebSocket 认证只需要验证身份，不需要完整用户信息
        // 2. 避免额外的数据库查询（AdminUserService.getUser()），提升性能
        // 3. IM 消息处理不需要权限控制（与 Web 端不同）
        // 4. 如果业务需要，可以在消息处理时通过 userId 查询：
        //    - AdminUserService.getUser(userId) - 获取用户详细信息
        //    - PermissionService.getUserRoleIdListByUserId(userId) - 获取用户角色
        
        return loginUser;
    }

}
