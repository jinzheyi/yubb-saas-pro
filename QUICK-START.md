# IM 即时通讯系统 - 快速开始指南

## 🚀 快速启动

### 1. 启动后端服务

```bash
# 进入服务端目录
cd shengyu-server

# 启动服务(使用 local 配置)
mvn spring-boot:run -Dspring-boot.run.profiles=local

# 或者使用 IDEA 直接运行 ShengyuServerApplication
```

**验证服务启动成功**:
```bash
curl http://localhost:48080/actuator/health
# 返回: {"status":"UP"}
```

### 2. 测试 REST API

#### 方式 1: 使用 Postman (推荐)

1. 打开 Postman
2. 导入 `IM-API.postman_collection.json`
3. 先执行"认证 > 登录"获取 Token
4. Token 会自动保存,然后测试其他接口

#### 方式 2: 使用自动化脚本

```bash
# 给脚本添加执行权限
chmod +x test-api.sh

# 运行测试
./test-api.sh
```

#### 方式 3: 手动测试

```bash
# 1. 登录获取 Token
curl -X POST http://localhost:48080/app-api/system/auth/login \
  -H "Content-Type: application/json" \
  -H "tenant-id: 1" \
  -d '{"username":"admin","password":"admin123"}'

# 2. 获取会话列表(替换 YOUR_TOKEN)
curl -X GET http://localhost:48080/app-api/system/im/conversation/list \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "tenant-id: 1"
```

### 3. 启动移动端

```bash
# 进入移动端目录
cd shengyu-ui/shengyu-ui-admin-uniappx

# 使用 HBuilderX 打开项目
# 或者使用命令行运行
```

**配置 WebSocket 地址**:

编辑 `config/app.config.uts`:
```typescript
// 开发环境
export const WS_URL = 'ws://localhost:9000/ws'

// 生产环境
// export const WS_URL = 'wss://api.example.com:9000/ws'
```

### 4. 测试 WebSocket 连接

1. 在移动端登录
2. 查看控制台日志,确认 WebSocket 连接成功
3. 发送测试消息
4. 验证消息收发是否正常

## 📋 测试检查清单

### 后端 API 测试

- [ ] 登录接口 - 获取 Token
- [ ] 会话列表 - 返回空数组或已有会话
- [ ] 创建会话 - 返回会话ID
- [ ] 消息列表 - 返回空数组或已有消息
- [ ] 联系人列表 - 返回同租户用户
- [ ] 群组列表 - 返回空数组或已有群组
- [ ] 创建群组 - 返回群组ID

### WebSocket 测试

- [ ] 连接建立 - 控制台显示"连接已建立"
- [ ] 认证成功 - 控制台显示"认证成功"
- [ ] 心跳正常 - 每30秒发送心跳
- [ ] 消息发送 - 消息成功发送到服务器
- [ ] 消息接收 - 能够接收其他用户的消息
- [ ] 断线重连 - 网络断开后自动重连

### 移动端功能测试

- [ ] 登录功能 - 账号密码登录成功
- [ ] 消息列表 - 显示会话列表
- [ ] 聊天页面 - 能够发送文本消息
- [ ] 图片上传 - 能够选择并上传图片
- [ ] 通讯录 - 显示联系人列表
- [ ] 群组管理 - 能够创建群组

## 🔧 常见问题

### 1. 后端服务启动失败

**问题**: 端口被占用
```
Port 48080 is already in use
```

**解决**:
```bash
# 查找占用端口的进程
lsof -i:48080

# 杀死进程
kill -9 PID
```

### 2. WebSocket 连接失败

**问题**: 连接被拒绝
```
WebSocket connection failed
```

**检查**:
1. 确认后端服务已启动
2. 确认 WebSocket 端口(9000)未被占用
3. 检查防火墙设置
4. 查看后端日志

### 3. Token 过期

**问题**: 401 Unauthorized

**解决**:
重新登录获取新的 Token

### 4. 数据库连接失败

**问题**: 无法连接到数据库

**检查**:
1. MySQL 服务是否启动
2. 数据库配置是否正确
3. 用户名密码是否正确
4. 数据库是否已创建

## 📊 性能指标

### 预期性能

- API 响应时间: < 500ms
- WebSocket 连接时间: < 1s
- 消息发送延迟: < 100ms
- 心跳间隔: 30s
- 重连间隔: 1s, 2s, 4s, 8s, 16s

### 并发能力

- 单机 WebSocket 连接数: 10w+
- 消息吞吐量: 10w+ msg/s
- API 并发请求: 1000+ req/s

## 🎯 下一步

测试通过后,继续以下工作:

1. **前后端联调** (2-3小时)
   - 消息列表页面对接实际 API
   - 聊天页面集成 WebSocket 消息服务
   - 测试消息发送和接收

2. **完善功能** (1-2天)
   - 实现图片/语音/视频消息
   - 实现文件上传和预览
   - 实现消息撤回和删除

3. **测试优化** (1-2天)
   - 端到端测试
   - 性能测试
   - Bug 修复

## 📞 技术支持

如遇到问题,请查看:
- `API-TEST.md` - 详细的 API 测试文档
- `IMPLEMENTATION-SUMMARY.md` - 功能实现总结
- `NEXT-STEPS.md` - 下一步工作指南
- 后端日志: `shengyu-server/logs/`
- 移动端控制台日志

## 🎉 开始测试

现在你可以开始测试 IM 即时通讯系统了!

建议按照以下顺序进行:
1. 启动后端服务
2. 测试 REST API
3. 启动移动端
4. 测试 WebSocket 连接
5. 测试消息收发

祝测试顺利! 🚀
