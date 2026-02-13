# IM 认证机制与 Web 端认证机制对比分析

> **文档版本**: v1.0  
> **创建日期**: 2026年2月13日  
> **目的**: 系统性学习 Web 端鉴权逻辑，确保 IM 认证完全对齐

---

## 1. Web 端认证流程（完整分析）

### 1.1 认证架构

```
客户端                    Spring Security Filter                OAuth2TokenService
  │                              │                                      │
  │  1. HTTP 请求 + Token        │                                      │
  │─────────────────────────────>│                                      │
  │                              │  2. 提取 Token                        │
  │                              │     (Header/Parameter)                │
  │                              │                                      │
  │                              │  3. 验证 Token                        │
  │                              │────────────────────────────────────>│
  │                              │                                      │
  │                              │  4. checkAccessToken()                │
  │                              │     - 优先从 Redis 获取               │
  │                              │     - 缓存未命中查 MySQL              │
  │                              │     - DateUtils.isExpired() 检查过期  │
  │                              │<────────────────────────────────────│
  │                              │                                      │
  │                              │  5. 构建 LoginUser                    │
  │                              │     - userId, tenantId, userType     │
  │                              │     - username, nickname, deptId     │
  │                              │     - roleIds, permissions           │
  │                              │                                      │
  │                              │  6. 设置到 SecurityContext            │
  │                              │     SecurityContextHolder.setContext()│
  │                              │                                      │
  │  7. 返回响应                  │                                      │
  │<─────────────────────────────│                                      │
```

### 1.2 核心代码分析

#### 1.2.1 Token 验证（OAuth2TokenServiceImpl.java）

```java
@Override
public OAuth2AccessTokenDO checkAccessToken(String accessToken) {
    // 1. 获取 Token（优先从 Redis）
    OAuth2AccessTokenDO accessTokenDO = getAccessToken(accessToken);
    
    // 2. 检查 Token 是否存在
    if (accessTokenDO == null) {
        throw exception0(GlobalErrorCodeConstants.UNAUTHORIZED.getCode(), 
                        "访问令牌不存在");
    }
    
    // 3. 检查 Token 是否过期（使用 DateUtils.isExpired）
    if (DateUtils.isExpired(accessTokenDO.getExpiresTime())) {
        throw exception0(GlobalErrorCodeConstants.UNAUTHORIZED.getCode(), 
                        "访问令牌已过期");
    }
    
    return accessTokenDO;
}

@Override
public OAuth2AccessTokenDO getAccessToken(String accessToken) {
    // 优先从 Redis 中获取（性能优化）
    OAuth2AccessTokenDO accessTokenDO = oauth2AccessTokenRedisDAO.get(accessToken);
    if (accessTokenDO != null) {
        return accessTokenDO;
    }

    // 获取不到，从 MySQL 中获取
    accessTokenDO = oauth2AccessTokenMapper.selectByAccessToken(accessToken);
    
    // 如果在 MySQL 存在，则往 Redis 中写入
    if (accessTokenDO != null && !DateUtils.isExpired(accessTokenDO.getExpiresTime())) {
        oauth2AccessTokenRedisDAO.set(accessTokenDO);
    }
    
    return accessTokenDO;
}
```

**关键点**:
1. ✅ 优先从 Redis 获取（性能优化）
2. ✅ 使用 `DateUtils.isExpired()` 统一判断过期
3. ✅ Token 不存在或已过期会抛出 `ServiceException`
4. ✅ 自动将 MySQL 数据同步到 Redis

#### 1.2.2 登录流程（AdminAuthServiceImpl.java）

```java
@Override
public AuthLoginRespVO login(AuthLoginReqVO reqVO) {
    // 1. 校验验证码
    validateCaptcha(reqVO);

    // 2. 使用账号密码，进行登录
    AdminUserDO user = authenticate(reqVO.getUsername(), reqVO.getPassword());

    // 3. 创建 Token 令牌，记录登录日志
    return createTokenAfterLoginSuccess(user, reqVO.getUsername(), 
                                       LoginLogTypeEnum.LOGIN_USERNAME);
}

@Override
public AdminUserDO authenticate(String username, String password) {
    // 1. 校验账号是否存在
    SaasUserDO saasUserDO = saasUserService.getUserByUsername(username);
    if (saasUserDO == null) {
        throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
    }
    
    // 2. 校验密码
    if (!saasUserService.isPasswordMatch(password, saasUserDO.getPassword())) {
        throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
    }
    
    // 3. 获取租户用户信息
    return getLoginAdminUser(saasUserDO, LoginLogTypeEnum.LOGIN_USERNAME);
}

private AuthLoginRespVO createTokenAfterLoginSuccess(AdminUserDO user, 
                                                     String username, 
                                                     LoginLogTypeEnum logType) {
    // 1. 插入登录日志
    createLoginLog(user.getId(), username, logType, LoginResultEnum.SUCCESS);
    
    // 2. 创建访问令牌
    OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.createAccessToken(
        user.getId(), 
        getUserType().getValue(),
        OAuth2ClientConstants.CLIENT_ID_TENANT, 
        null
    );
    
    // 3. 构建返回结果
    AuthLoginRespVO loginRespVO = BeanUtils.toBean(accessTokenDO, AuthLoginRespVO.class);
    loginRespVO.setDeptId(user.getDeptId());
    return loginRespVO;
}
```

**关键点**:
1. ✅ 验证码校验（可选）
2. ✅ 账号密码验证
3. ✅ 多租户支持（SaaS 用户 → 租户用户）
4. ✅ 创建 Token 并记录登录日志
5. ✅ 返回 Token 和用户基本信息

#### 1.2.3 Token 提取（SecurityFrameworkUtils.java）

```java
public static String obtainAuthorization(HttpServletRequest request,
                                        String headerName, 
                                        String parameterName) {
    // 1. 获得 Token。优先级：Header > Parameter
    String token = request.getHeader(headerName);
    if (StrUtil.isEmpty(token)) {
        token = request.getParameter(parameterName);
    }
    if (!StringUtils.hasText(token)) {
        return null;
    }
    
    // 2. 去除 Token 中带的 Bearer
    int index = token.indexOf(AUTHORIZATION_BEARER + " ");
    return index >= 0 ? token.substring(index + 7).trim() : token;
}
```

**关键点**:
1. ✅ 支持 Header 和 Parameter 两种方式传递 Token
2. ✅ 自动去除 "Bearer " 前缀
3. ✅ 优先级：Header > Parameter

---

## 2. IM 认证流程（完整分析）

### 2.1 认证架构

```
移动端                    WebSocket 握手                    SystemAuthServiceImpl
  │                              │                                      │
  │  1. WebSocket 连接 + Token   │                                      │
  │─────────────────────────────>│                                      │
  │                              │  2. 提取 Token                        │
  │                              │     (AuthRequest)                     │
  │                              │                                      │
  │                              │  3. 验证 Token                        │
  │                              │────────────────────────────────────>│
  │                              │                                      │
  │                              │  4. validateToken()                   │
  │                              │     - OAuth2TokenService.checkAccessToken()│
  │                              │     - 内部逻辑与 Web 端完全一致       │
  │                              │<────────────────────────────────────│
  │                              │                                      │
  │                              │  5. 构建 LoginUser                    │
  │                              │     - userId, tenantId, userType     │
  │                              │     - 不查询完整用户信息（性能优化）   │
  │                              │                                      │
  │                              │  6. 保存到 NettySession               │
  │                              │     sessionManager.addSession()       │
  │                              │                                      │
  │  7. 返回认证成功              │                                      │
  │<─────────────────────────────│                                      │
```

### 2.2 核心代码分析

#### 2.2.1 Token 验证（SystemAuthServiceImpl.java）

```java
@Override
public LoginBase validateToken(String accessToken) {
    // 1. 参数校验
    if (StrUtil.isBlank(accessToken)) {
        log.warn("[IM-WebSocketAuth] Token 为空");
        return null;
    }

    try {
        // 2. 验证 Token 有效性（完全对齐 Web 端逻辑）
        // 调用 OAuth2TokenService.checkAccessToken()
        // 内部会：
        // - 优先从 Redis 获取
        // - 使用 DateUtils.isExpired() 检查过期
        // - Token 不存在或已过期会抛出 ServiceException
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.checkAccessToken(accessToken);
        
        // 3. 构建 LoginUser 对象
        LoginUser loginUser = buildLoginUser(accessTokenDO);
        
        log.info("[IM-WebSocketAuth] Token 验证成功, userId: {}, tenantId: {}, userType: {}", 
                loginUser.getId(), loginUser.getTenantId(), loginUser.getUserType());
        
        return loginUser;
        
    } catch (Exception e) {
        // 4. 异常处理
        log.warn("[IM-WebSocketAuth] Token 验证失败: {}", e.getMessage());
        return null;
    }
}

private LoginUser buildLoginUser(OAuth2AccessTokenDO accessTokenDO) {
    LoginUser loginUser = new LoginUser();
    loginUser.setId(accessTokenDO.getUserId());
    loginUser.setUserType(accessTokenDO.getUserType());
    loginUser.setTenantId(accessTokenDO.getTenantId());
    
    // 注意：不设置其他字段（性能优化）
    // - 不查询 username、nickname、deptId
    // - 不查询 roleIds、permissions
    // - 如果业务需要，在消息处理时再查询
    
    return loginUser;
}
```

**关键点**:
1. ✅ 使用 `OAuth2TokenService.checkAccessToken()` 验证（与 Web 端一致）
2. ✅ Token 验证逻辑完全对齐（Redis 缓存、过期检查、异常处理）
3. ✅ 只构建基本身份信息（性能优化）
4. ✅ 异常处理返回 null（WebSocket 会关闭连接）

---

## 3. Web 端 vs IM 端对比

### 3.1 相同点

| 对比项 | Web 端 | IM 端 | 说明 |
|-------|--------|-------|------|
| Token 验证服务 | `OAuth2TokenService.checkAccessToken()` | `OAuth2TokenService.checkAccessToken()` | ✅ 完全一致 |
| 过期时间判断 | `DateUtils.isExpired()` | `DateUtils.isExpired()` | ✅ 完全一致 |
| Redis 缓存 | 优先从 Redis 获取 | 优先从 Redis 获取 | ✅ 完全一致 |
| 异常处理 | 抛出 `ServiceException` | 抛出 `ServiceException` | ✅ 完全一致 |
| 租户隔离 | 支持 `tenantId` | 支持 `tenantId` | ✅ 完全一致 |
| 用户类型 | 支持 `userType` | 支持 `userType` | ✅ 完全一致 |

### 3.2 差异点

| 对比项 | Web 端 | IM 端 | 原因 |
|-------|--------|-------|------|
| **传输协议** | HTTP/HTTPS | WebSocket | 协议不同 |
| **Token 传递** | Header/Parameter | Protobuf AuthRequest | 协议不同 |
| **认证时机** | 每次 HTTP 请求 | WebSocket 握手时 | 连接方式不同 |
| **用户信息** | 完整（username、roles、permissions） | 基本（userId、tenantId、userType） | 性能优化 |
| **权限控制** | 需要（基于角色和权限） | 不需要（消息路由不需要权限） | 业务需求不同 |
| **上下文存储** | SecurityContext（ThreadLocal） | NettySession（Channel Attribute） | 框架不同 |
| **异常处理** | 返回 401 HTTP 状态码 | 关闭 WebSocket 连接 | 协议不同 |

### 3.3 为什么 IM 端不查询完整用户信息？

#### 3.3.1 Web 端需要完整用户信息

```java
// Web 端：需要权限控制
@PreAuthorize("@ss.hasPermission('system:user:query')")
public CommonResult<UserRespVO> getUser(@RequestParam("id") Long id) {
    // 需要检查用户是否有 'system:user:query' 权限
    // 因此需要完整的 roleIds 和 permissions
}
```

#### 3.3.2 IM 端不需要权限控制

```java
// IM 端：只需要身份验证
public void handleMessage(ImMessage message) {
    // 只需要知道：
    // 1. 消息来自哪个用户（userId）
    // 2. 用户属于哪个租户（tenantId）
    // 3. 用户类型（userType）
    
    // 不需要检查权限：
    // - 发送消息不需要权限
    // - 接收消息不需要权限
    // - 消息路由只需要 userId 和 tenantId
}
```

#### 3.3.3 性能对比

| 操作 | Web 端 | IM 端 | 性能差异 |
|------|--------|-------|---------|
| Token 验证 | 1 次数据库查询（Token） | 1 次数据库查询（Token） | 相同 |
| 用户信息查询 | 1 次数据库查询（User） | 0 次 | IM 端快 |
| 角色查询 | 1 次数据库查询（Roles） | 0 次 | IM 端快 |
| 权限查询 | 1 次数据库查询（Permissions） | 0 次 | IM 端快 |
| **总计** | 4 次数据库查询 | 1 次数据库查询 | **IM 端快 75%** |

---

## 4. 最佳实践总结

### 4.1 IM 认证必须遵循的原则

1. ✅ **使用 OAuth2TokenService.checkAccessToken()**
   - 不要自己实现 Token 验证逻辑
   - 不要手动检查过期时间
   - 不要直接查询数据库

2. ✅ **使用 DateUtils.isExpired()**
   - 统一的过期时间判断
   - 与 Web 端保持一致

3. ✅ **利用 Redis 缓存**
   - OAuth2TokenService 内部已经实现
   - 不需要额外的缓存逻辑

4. ✅ **异常处理返回 null**
   - WebSocket 中间件会自动关闭连接
   - 不要向上抛出异常

5. ✅ **只构建基本身份信息**
   - 不查询完整用户信息
   - 性能优化

### 4.2 如果业务需要完整用户信息怎么办？

```java
// 方案 1：在消息处理时查询（推荐）
public void handleMessage(ImMessage message, NettySession session) {
    Long userId = session.getUserId();
    
    // 只在需要时查询
    if (needUserInfo) {
        UserRespVO user = adminUserService.getUser(userId);
        // 使用用户信息
    }
}

// 方案 2：在认证时查询并缓存到 Session（不推荐）
private LoginUser buildLoginUser(OAuth2AccessTokenDO accessTokenDO) {
    LoginUser loginUser = new LoginUser();
    loginUser.setId(accessTokenDO.getUserId());
    loginUser.setUserType(accessTokenDO.getUserType());
    loginUser.setTenantId(accessTokenDO.getTenantId());
    
    // ❌ 不推荐：每次认证都查询，影响性能
    UserRespVO user = adminUserService.getUser(accessTokenDO.getUserId());
    loginUser.setUsername(user.getUsername());
    loginUser.setNickname(user.getNickname());
    
    return loginUser;
}
```

**推荐方案 1 的原因**:
1. 认证时不查询，性能更好
2. 只在需要时查询，按需加载
3. 避免不必要的数据库查询
4. 符合单一职责原则（认证只负责验证身份）

---

## 5. 验证清单

### 5.1 代码验证

- [x] IM 认证使用 `OAuth2TokenService.checkAccessToken()`
- [x] 不手动检查 Token 过期时间
- [x] 不直接查询数据库验证 Token
- [x] 异常处理返回 null
- [x] 只构建基本身份信息（userId、tenantId、userType）
- [x] 不查询完整用户信息（username、roles、permissions）

### 5.2 功能验证

- [ ] Token 验证成功，WebSocket 连接建立
- [ ] Token 不存在，WebSocket 连接关闭
- [ ] Token 已过期，WebSocket 连接关闭
- [ ] 租户隔离正常工作
- [ ] 多设备登录互踢正常工作

### 5.3 性能验证

- [ ] 认证时只查询 1 次数据库（Token）
- [ ] Redis 缓存命中率 > 90%
- [ ] 认证耗时 < 50ms（Redis 命中）
- [ ] 认证耗时 < 200ms（MySQL 查询）

---

## 6. 总结

### 6.1 核心结论

1. **IM 认证已完全对齐 Web 端**
   - 使用相同的 `OAuth2TokenService.checkAccessToken()`
   - 使用相同的 `DateUtils.isExpired()`
   - 使用相同的 Redis 缓存机制
   - 使用相同的异常处理逻辑

2. **IM 认证的优化点**
   - 不查询完整用户信息（性能提升 75%）
   - 只在需要时查询（按需加载）
   - 符合 WebSocket 长连接的特点

3. **IM 认证的差异点**
   - 传输协议不同（WebSocket vs HTTP）
   - 认证时机不同（握手时 vs 每次请求）
   - 用户信息不同（基本 vs 完整）
   - 但核心验证逻辑完全一致

### 6.2 下一步工作

1. 前后端联调测试
2. 验证 Token 过期处理
3. 验证租户隔离
4. 性能压力测试

---

**文档维护**: shengyu 开发团队  
**最后更新**: 2026年2月13日
