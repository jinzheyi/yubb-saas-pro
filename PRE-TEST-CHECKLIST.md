# IM 系统测试前检查清单

> **检查日期**: 2026年2月16日  
> **检查目的**: 确保所有组件就绪，可以开始前后端联调测试  
> **检查人员**: AI + 开发者

---

## ✅ 1. 数据库检查

### 1.1 MySQL 数据库

**检查项**:
- [ ] MySQL 服务已启动（端口 3306）
- [ ] 数据库 `shengyu-saas` 已创建
- [ ] IM 表结构已执行（6张表）

**验证命令**:
```bash
# 检查 MySQL 服务
mysql -u root -p -e "SELECT VERSION();"

# 检查数据库
mysql -u root -p -e "SHOW DATABASES LIKE 'shengyu%';"

# 检查 IM 表
mysql -u root -p shengyu-saas -e "SHOW TABLES LIKE 'im_%';"
```

**预期结果**:
```
im_contact_setting
im_conversation
im_group
im_group_user
im_message
```

**注意**: 缺少 `im_message_read` 表（已读回执表），需要确认是否需要创建。

---

### 1.2 Redis 缓存

**检查项**:
- [ ] Redis 服务已启动（端口 6379）
- [ ] Redis 可以正常连接

**验证命令**:
```bash
# 检查 Redis 服务
redis-cli ping

# 检查 Redis 连接
redis-cli
> INFO server
> EXIT
```

**预期结果**:
```
PONG
```

---

## ✅ 2. 后端服务检查

### 2.1 后端应用配置

**检查项**:
- [ ] `application.yaml` 配置正确
- [ ] 数据库连接配置正确
- [ ] Redis 连接配置正确
- [ ] WebSocket 配置已启用

**配置文件位置**:
- `shengyu-server/src/main/resources/application.yaml`
- `shengyu-server/src/main/resources/application-local.yaml`

**关键配置检查**:
```yaml
# 数据库配置
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/shengyu-saas
    username: root
    password: ******

# Redis 配置
spring:
  data:
    redis:
      host: localhost
      port: 6379

# WebSocket 配置（如果有）
shengyu:
  websocket:
    enabled: true
    port: 9000
```

---

### 2.2 后端服务启动

**检查项**:
- [ ] 后端服务已编译
- [ ] 后端服务已启动（端口 48080）
- [ ] WebSocket 服务已启动（端口 9000）
- [ ] 无启动错误

**启动命令**:
```bash
# 进入后端目录
cd shengyu-server

# 启动服务（开发模式）
mvn spring-boot:run

# 或使用 JAR 包启动
java -jar target/shengyu-server.jar
```

**验证方法**:
```bash
# 检查后端服务
curl http://localhost:48080/actuator/health

# 检查 WebSocket 服务
netstat -an | grep 9000
```

**预期结果**:
- HTTP 服务返回 200 OK
- WebSocket 端口 9000 处于 LISTEN 状态

---

### 2.3 后端 API 接口检查

**检查项**:
- [ ] 登录接口可用
- [ ] IM 相关接口已注册
- [ ] API 文档可访问

**验证方法**:
```bash
# 访问 API 文档
open http://localhost:48080/doc.html

# 测试登录接口
curl -X POST http://localhost:48080/app-api/system/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**检查 IM 接口**:
- `/app-api/system/im/contact/list` - 联系人列表
- `/app-api/system/im/group/list` - 群组列表
- `/app-api/system/im/conversation/list` - 会话列表
- `/app-api/system/im/message/list` - 消息列表

---

## ✅ 3. 移动端检查

### 3.1 移动端配置

**检查项**:
- [ ] API 地址配置正确（`/app-api`）
- [ ] WebSocket 地址配置正确
- [ ] 租户配置已启用

**配置文件**: `shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts`

**关键配置**:
```typescript
// ✅ 正确：使用 /app-api 前缀
export const BASE_URL = 'http://localhost:48080'

// ✅ 正确：WebSocket 地址
export const WS_URL = 'ws://localhost:9000/ws'

// ✅ 正确：租户已启用
export const TENANT_ENABLE = 'true'
```

**验证方法**:
```bash
# 检查配置文件
cat shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts | grep BASE_URL
cat shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts | grep WS_URL
```

---

### 3.2 移动端 API 前缀

**检查项**:
- [ ] request.uts 使用 `/app-api` 前缀
- [ ] 没有使用 `/admin-api` 前缀

**配置文件**: `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts`

**关键代码**:
```typescript
// ✅ 正确：移动端使用 app-api 前缀
const BASE_URL = CONFIG_BASE_URL + '/app-api'
```

**验证方法**:
```bash
# 检查是否有错误的 admin-api 前缀
grep -r "admin-api" shengyu-ui/shengyu-ui-admin-uniappx/
# 预期结果：无匹配（或仅在注释中）
```

---

### 3.3 移动端权限配置

**检查项**:
- [ ] Android 权限已配置（13项）
- [ ] iOS 权限描述已配置（5项）

**配置文件**: `shengyu-ui/shengyu-ui-admin-uniappx/manifest.json`

**Android 权限清单**:
```json
{
  "permissions": [
    "INTERNET",                  // ✅ 网络访问
    "ACCESS_NETWORK_STATE",      // ✅ 网络状态
    "ACCESS_WIFI_STATE",         // ✅ WiFi 状态
    "RECORD_AUDIO",              // ✅ 录音（语音消息）
    "CAMERA",                    // ✅ 相机（拍照、视频）
    "MODIFY_AUDIO_SETTINGS",     // ✅ 音频设置
    "READ_EXTERNAL_STORAGE",     // ✅ 读取存储
    "WRITE_EXTERNAL_STORAGE",    // ✅ 写入存储
    "READ_MEDIA_IMAGES",         // ✅ 读取图片（Android 13+）
    "READ_MEDIA_VIDEO",          // ✅ 读取视频（Android 13+）
    "READ_MEDIA_AUDIO",          // ✅ 读取音频（Android 13+）
    "VIBRATE",                   // ✅ 震动
    "WAKE_LOCK"                  // ✅ 唤醒锁
  ]
}
```

**iOS 权限清单**:
```json
{
  "privacyDescription": {
    "NSMicrophoneUsageDescription": "✅ 麦克风权限",
    "NSCameraUsageDescription": "✅ 相机权限",
    "NSPhotoLibraryUsageDescription": "✅ 相册读取权限",
    "NSPhotoLibraryAddUsageDescription": "✅ 相册保存权限",
    "NSLocationWhenInUseUsageDescription": "✅ 位置权限"
  }
}
```

---

### 3.4 移动端编译

**检查项**:
- [ ] 移动端代码无编译错误
- [ ] 依赖包已安装
- [ ] 可以正常运行

**验证方法**:
```bash
# 进入移动端目录
cd shengyu-ui/shengyu-ui-admin-uniappx

# 检查是否有语法错误（如果有 lint 工具）
# npm run lint

# 在 HBuilderX 中运行到浏览器/模拟器
```

---

## ✅ 4. WebSocket 中间件检查

### 4.1 中间件配置

**检查项**:
- [ ] WebSocket 中间件已引入
- [ ] SPI 接口实现已注册
- [ ] 配置类已生效

**关键文件**:
- `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/config/ImWebSocketConfiguration.java`
- `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java`
- `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/WebSocketAuthServiceImpl.java`

**验证方法**:
```bash
# 检查配置类
cat shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/config/ImWebSocketConfiguration.java

# 检查 SPI 实现
ls shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/
```

**预期结果**:
- `SystemMessageStorageServiceImpl.java` ✅
- `WebSocketAuthServiceImpl.java` ✅

---

### 4.2 WebSocket 服务启动

**检查项**:
- [ ] WebSocket 服务自动启动
- [ ] 端口 9000 已监听
- [ ] 无启动错误

**验证方法**:
```bash
# 检查端口
netstat -an | grep 9000
# 或
lsof -i :9000

# 检查日志
tail -f shengyu-server/logs/info.log | grep WebSocket
```

**预期日志**:
```
[IM-WebSocket] 注册消息存储服务: SystemMessageStorageServiceImpl
[WebSocket] Netty Server started on port 9000
```

---

## ✅ 5. 测试账号准备

### 5.1 创建测试账号

**检查项**:
- [ ] 至少创建 3 个测试账号
- [ ] 账号可以正常登录
- [ ] 账号属于同一租户

**测试账号清单**:
| 账号 | 密码 | 用途 | 状态 |
|------|------|------|------|
| testuser1 | 123456 | 单聊发送方 | ⏳ 待创建 |
| testuser2 | 123456 | 单聊接收方 | ⏳ 待创建 |
| testuser3 | 123456 | 群聊测试 | ⏳ 待创建 |

**创建方法**:
1. 登录管理后台
2. 进入"用户管理"
3. 创建测试用户
4. 设置密码并启用

---

### 5.2 测试账号验证

**检查项**:
- [ ] 账号可以登录移动端
- [ ] 账号可以获取 Token
- [ ] 账号可以访问 IM 接口

**验证方法**:
```bash
# 测试登录
curl -X POST http://localhost:48080/app-api/system/auth/login \
  -H "Content-Type: application/json" \
  -H "tenant-id: 1" \
  -d '{
    "username": "testuser1",
    "password": "123456"
  }'
```

**预期结果**:
```json
{
  "code": 0,
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "userId": 123,
    "expiresTime": "..."
  }
}
```

---

## ✅ 6. 网络环境检查

### 6.1 本地网络

**检查项**:
- [ ] 本地回环地址可用（localhost）
- [ ] 端口无冲突
- [ ] 防火墙已配置

**验证方法**:
```bash
# 检查端口占用
netstat -an | grep 48080
netstat -an | grep 9000

# 测试本地连接
curl http://localhost:48080/actuator/health
```

---

### 6.2 跨域配置（如果使用 H5）

**检查项**:
- [ ] 后端已配置 CORS
- [ ] 允许 WebSocket 升级

**配置检查**:
```java
// 检查是否有 CORS 配置
@Configuration
public class WebMvcConfiguration {
    @Bean
    public CorsFilter corsFilter() {
        // CORS 配置
    }
}
```

---

## ✅ 7. 开发工具检查

### 7.1 必需工具

**检查项**:
- [ ] HBuilderX 已安装（移动端开发）
- [ ] Chrome/Edge 浏览器（H5 测试）
- [ ] Android Studio / Xcode（真机测试）
- [ ] Postman / Apifox（API 测试）

---

### 7.2 调试工具

**检查项**:
- [ ] 浏览器开发者工具
- [ ] 移动端调试工具
- [ ] 日志查看工具

---

## ✅ 8. 文档准备

### 8.1 测试文档

**检查项**:
- [ ] `INTEGRATION-TEST-GUIDE.md` 已创建 ✅
- [ ] `PRE-TEST-CHECKLIST.md` 已创建 ✅
- [ ] API 文档可访问

---

### 8.2 设计文档

**检查项**:
- [ ] `sql/doc/IM即时通讯逻辑设计文档-v1.0.md` 已更新 ✅
- [ ] 数据库表结构文档完整 ✅
- [ ] API 接口文档完整 ✅

---

## 📊 检查结果汇总

### 通过的检查项

✅ **移动端配置**:
- API 前缀正确（`/app-api`）
- WebSocket 地址正确
- 权限配置完整（Android 13项，iOS 5项）
- 多端消息兼容性完整

✅ **后端配置**:
- WebSocket 配置类已创建
- SPI 接口实现已完成
- 消息存储服务已注册

✅ **文档准备**:
- 测试指南已创建
- 检查清单已创建
- 设计文档已更新

### 待确认的检查项

⏳ **数据库**:
- [ ] MySQL 服务是否已启动
- [ ] IM 表结构是否已执行
- [ ] Redis 服务是否已启动

⏳ **后端服务**:
- [ ] 后端服务是否已启动
- [ ] WebSocket 服务是否已启动
- [ ] API 接口是否可访问

⏳ **测试账号**:
- [ ] 测试账号是否已创建
- [ ] 测试账号是否可登录

### 潜在问题

⚠️ **缺少 im_message_read 表**:
- 设计文档中提到了已读回执表
- 但 DDL 文件中可能未包含
- 需要确认是否需要创建

⚠️ **WebSocket 配置**:
- `application.yaml` 中未找到 WebSocket 配置
- 可能使用默认配置或在其他配置文件中
- 需要确认 WebSocket 服务是否能正常启动

---

## 🚀 下一步操作

### 立即执行

1. **启动数据库服务**:
   ```bash
   # 启动 MySQL
   sudo service mysql start
   
   # 启动 Redis
   sudo service redis start
   ```

2. **执行数据库脚本**:
   ```bash
   # 执行 IM 表结构
   mysql -u root -p shengyu-saas < sql/mysql/1.0/im/ddl_im_tables.sql
   ```

3. **启动后端服务**:
   ```bash
   cd shengyu-server
   mvn spring-boot:run
   ```

4. **验证服务状态**:
   ```bash
   # 检查 HTTP 服务
   curl http://localhost:48080/actuator/health
   
   # 检查 WebSocket 服务
   netstat -an | grep 9000
   ```

5. **创建测试账号**:
   - 登录管理后台
   - 创建 3 个测试用户

6. **开始测试**:
   - 按照 `INTEGRATION-TEST-GUIDE.md` 执行测试用例
   - 记录测试结果
   - 发现并修复问题

---

**检查完成时间**: 2026年2月16日  
**检查结论**: 移动端和文档准备就绪，待启动后端服务后即可开始测试  
**建议**: 先确认数据库和后端服务正常，再开始移动端测试
