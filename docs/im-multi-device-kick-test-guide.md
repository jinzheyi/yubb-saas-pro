# 企业级 IM 多端登录互踢机制 - 集成测试指南

> **版本**: v1.0  
> **日期**: 2026-07-19  
> **状态**: 待执行  
> **作者**: 圣钰科技  

---

## 一、测试环境准备

### 1.1 后端环境

1. **启动 Redis**（用于跨节点互踢）
   ```bash
   redis-server
   ```

2. **启动后端服务**（单节点或多节点）
   ```bash
   # 单节点测试
   mvn spring-boot:run -pl shengyu-module-system/shengyu-module-system-biz
   
   # 多节点测试（需修改端口）
   # 节点1: 默认端口 48080
   # 节点2: 修改 server.port=48081, 启动另一个实例
   ```

3. **验证 Redis Pub/Sub 配置**
   ```bash
   redis-cli
   > PING
   PONG
   ```

### 1.2 前端环境

1. **准备多台测试设备**（或模拟器）
   - 2 台 Android 设备（或模拟器）
   - 1 台 iOS 设备（或模拟器）
   - 1 台 Web 浏览器

2. **修改 API 地址**（如需要）
   ```dart
   // lib/core/config/api_config.dart
   const String baseUrl = 'http://192.168.1.100:48080'; // 后端地址
   ```

3. **编译 Flutter 应用**
   ```bash
   cd shengyu-ui/shengyu-ui-admin-flutter
   flutter build apk --debug  # Android
   flutter build ios --debug  # iOS
   flutter build web          # Web
   ```

### 1.3 测试账号

创建测试账号：
```sql
INSERT INTO system_users (username, password, nickname, status) 
VALUES ('test_user', '$2a$10$...', '测试用户', 0);
```

---

## 二、测试用例

### T1: 同类型设备互踢测试

**测试目标**: 验证两个 Android 设备登录同一账号时，旧设备被踢出

**测试步骤**:

1. **设备 A（Android 1）登录**
   ```
   1. 打开 App
   2. 输入账号: test_user
   3. 输入密码: ******
   4. 点击登录
   5. 验证: 登录成功，进入主界面
   ```

2. **设备 B（Android 2）登录**
   ```
   1. 打开 App
   2. 输入账号: test_user
   3. 输入密码: ******
   4. 点击登录
   5. 验证: 登录成功，进入主界面
   ```

3. **验证设备 A 被踢出**
   ```
   1. 观察设备 A 屏幕
   2. 预期: 弹出被踢弹窗
      - 标题: "账号异常"
      - 内容: "你的账号于 2026-07-19 14:30:00 在 Android 设备 上登录，你已被迫下线。"
      - 提示: "如非本人操作，请及时修改密码。"
      - 按钮: "确定"
   3. 点击"确定"
   4. 验证: 跳转到登录页
   ```

4. **验证设备 B 在线**
   ```
   1. 观察设备 B 屏幕
   2. 预期: 正常使用，无异常提示
   3. 发送消息测试
   4. 验证: 消息发送成功
   ```

**预期结果**:
- ✅ 设备 A 收到 KICKED 通知
- ✅ 设备 A 弹窗显示踢人设备信息（Android 设备）
- ✅ 设备 A 弹窗显示踢人时间
- ✅ 设备 A 点击确定后跳转到登录页
- ✅ 设备 B 正常使用

**后端日志验证**:
```bash
# 查看后端日志
tail -f logs/websocket.log | grep "踢掉设备"

# 预期日志:
[SessionManager] 踢掉设备, userId: 100, deviceType: 3, reason: 当前账号于2026-07-19 14:30:00在Android 设备设备上登录。此客户端已退出登录。
```

---

### T2: 不同类型设备共存测试

**测试目标**: 验证 Web + iOS + Android 同时登录，不互踢

**测试步骤**:

1. **设备 A（Web）登录**
   ```
   1. 打开浏览器访问 Web 端
   2. 输入账号: test_user
   3. 输入密码: ******
   4. 点击登录
   5. 验证: 登录成功
   ```

2. **设备 B（iOS）登录**
   ```
   1. 打开 iOS App
   2. 输入账号: test_user
   3. 输入密码: ******
   4. 点击登录
   5. 验证: 登录成功，Web 端未被踢出
   ```

3. **设备 C（Android）登录**
   ```
   1. 打开 Android App
   2. 输入账号: test_user
   3. 输入密码: ******
   4. 点击登录
   5. 验证: 登录成功，Web 和 iOS 端未被踢出
   ```

4. **验证三端同时在线**
   ```
   1. 在 Web 端发送消息
   2. 验证: iOS 和 Android 端收到消息
   3. 在 iOS 端发送消息
   4. 验证: Web 和 Android 端收到消息
   5. 在 Android 端发送消息
   6. 验证: Web 和 iOS 端收到消息
   ```

5. **验证设备列表 API**
   ```bash
   # 调用设备列表接口
   curl -X GET "http://localhost:48080/system/im/device/list" \
     -H "Authorization: Bearer {access_token}"
   
   # 预期返回:
   {
     "code": 0,
     "data": [
       {"deviceType": 1, "deviceName": "Web 浏览器", "online": true},
       {"deviceType": 2, "deviceName": "iPhone 15", "online": true},
       {"deviceType": 3, "deviceName": "Android 设备", "online": true}
     ]
   }
   ```

**预期结果**:
- ✅ 三端同时登录成功
- ✅ 无任何设备被踢出
- ✅ 三端消息同步正常
- ✅ 设备列表显示三个在线设备

---

### T3: 被踢弹窗交互测试

**测试目标**: 验证被踢弹窗展示、确认、登出、跳转流程

**测试步骤**:

1. **触发被踢事件**（参考 T1）

2. **验证弹窗 UI**
   ```
   1. 弹窗样式:
      - 圆角矩形（12px）
      - 白色背景
      - 宽度: 320px
      - 内边距: 24px
   
   2. 弹窗内容:
      - 图标: 警告图标（橙色 #FF9800）
      - 标题: "账号异常"（18px, 粗体）
      - 内容: 踢人原因（14px, 灰色 #666666）
      - 提示: "如非本人操作，请及时修改密码。"（13px, 浅灰 #999999）
      - 按钮: "确定"（蓝色 #1890FF）
   
   3. 弹窗行为:
      - 点击外部不关闭（barrierDismissible: false）
      - 只能点击"确定"关闭
   ```

3. **验证点击确定后流程**
   ```
   1. 点击"确定"按钮
   2. 验证: WebSocket 连接断开
   3. 验证: 本地会话清理（Token、用户信息）
   4. 验证: 缓存清理（消息、会话等）
   5. 验证: 跳转到登录页
   6. 验证: 无法通过返回键回到主界面
   ```

4. **验证重连控制**
   ```
   1. 等待 10 秒
   2. 验证: App 不自动重连 WebSocket
   3. 验证: 仍然停留在登录页
   ```

**预期结果**:
- ✅ 弹窗 UI 符合微信级别设计
- ✅ 弹窗不可外部关闭
- ✅ 点击确定后完整登出流程
- ✅ 跳转到登录页
- ✅ 不自动重连

---

### T4: 跨节点互踢测试

**测试目标**: 验证多节点部署下，Redis Pub/Sub 跨节点互踢生效

**环境准备**:
```bash
# 启动两个后端节点
# 节点1: 端口 48080
java -jar app.jar --server.port=48080

# 节点2: 端口 48081
java -jar app.jar --server.port=48081

# 配置负载均衡（Nginx）
upstream backend {
    server 127.0.0.1:48080;
    server 127.0.0.1:48081;
}
```

**测试步骤**:

1. **设备 A 连接到节点 1**
   ```
   1. 配置设备 A 直接连接节点 1（http://192.168.1.100:48080）
   2. 登录账号: test_user
   3. 验证: 登录成功
   4. 记录: 设备 A 的 WebSocket 连接在节点 1
   ```

2. **设备 B 连接到节点 2**
   ```
   1. 配置设备 B 直接连接节点 2（http://192.168.1.100:48081）
   2. 登录账号: test_user（同类型设备 Android）
   3. 验证: 登录成功
   4. 记录: 设备 B 的 WebSocket 连接在节点 2
   ```

3. **验证跨节点互踢**
   ```
   1. 观察设备 A 屏幕
   2. 预期: 弹出被踢弹窗
      - 内容: "你的账号于 2026-07-19 14:30:00 在 Android 设备 上登录，你已被迫下线。"
   3. 点击"确定"
   4. 验证: 跳转到登录页
   ```

4. **验证 Redis Pub/Sub 消息**
   ```bash
   # 监听 Redis 频道
   redis-cli
   > SUBSCRIBE *
   
   # 预期消息:
   1) "pmessage"
   2) "*"
   3) "cross-node-kick"
   4) "{\"userId\":100,\"deviceType\":3,\"byDevice\":\"Android 设备\"}"
   ```

5. **验证节点日志**
   ```bash
   # 节点 2 日志（新设备登录）
   tail -f node2.log | grep "跨节点互踢"
   # 预期: [CrossNodeKickProducer] 发送跨节点互踢消息, userId: 100, deviceType: 3, byDevice: Android 设备
   
   # 节点 1 日志（旧设备被踢）
   tail -f node1.log | grep "跨节点互踢"
   # 预期: [CrossNodeKickConsumer] 收到跨节点互踢消息, userId: 100, deviceType: 3, byDevice: Android 设备
   # 预期: [SessionManager] 踢掉设备, userId: 100, deviceType: 3
   ```

**预期结果**:
- ✅ 设备 A 被跨节点踢出
- ✅ Redis Pub/Sub 消息正确广播
- ✅ 节点 1 收到消息并踢出旧设备
- ✅ 节点 2 正常处理新设备登录

---

### T5: Protobuf 协议认证测试

**测试目标**: 验证 Protobuf 认证时 deviceName 正确传递

**测试步骤**:

1. **启用 Protobuf 协议**
   ```dart
   // lib/core/websocket/im_socket_client.dart
   // 确保使用 Protobuf 协议认证
   final authRequest = AuthRequest(
     accessToken: accessToken,
     deviceType: 3,
     deviceId: 'test-device-123',
     deviceName: 'Test Android Device',
     clientVersion: '1.0.0',
   );
   ```

2. **建立 WebSocket 连接**
   ```
   1. 打开 App
   2. 登录账号: test_user
   3. 验证: 登录成功
   ```

3. **验证后端接收到的 deviceName**
   ```bash
   # 查看后端日志
   tail -f logs/websocket.log | grep "认证成功"
   
   # 预期日志:
   [AuthHandler] Protobuf 认证成功, userId: 100, deviceType: 3, deviceId: test-device-123, deviceName: Test Android Device
   ```

4. **验证 NettySession 字段**
   ```bash
   # 调用在线状态接口
   curl -X GET "http://localhost:48080/system/im/device/online-status" \
     -H "Authorization: Bearer {access_token}"
   
   # 预期返回:
   {
     "code": 0,
     "data": {
       "online": true,
       "deviceType": 3,
       "deviceName": "Test Android Device",
       "deviceId": "test-device-123"
     }
   }
   ```

5. **验证踢人通知中的 byDevice**
   ```
   1. 在另一台 Android 设备登录同一账号
   2. 观察当前设备被踢弹窗
   3. 预期: byDevice 显示 "Test Android Device"
   ```

**预期结果**:
- ✅ Protobuf 认证包含 deviceName 字段
- ✅ 后端正确接收 deviceName
- ✅ NettySession 存储 deviceName
- ✅ 踢人通知显示正确的 byDevice

---

## 三、测试报告模板

### 测试执行记录

| 测试用例 | 执行时间 | 执行人 | 结果 | 备注 |
|---------|---------|-------|------|------|
| T1: 同类型设备互踢 | 2026-07-19 | 张三 | ✅ 通过 | - |
| T2: 不同类型设备共存 | 2026-07-19 | 张三 | ✅ 通过 | - |
| T3: 被踢弹窗交互 | 2026-07-19 | 张三 | ✅ 通过 | - |
| T4: 跨节点互踢 | 2026-07-19 | 张三 | ✅ 通过 | - |
| T5: Protobuf 认证 | 2026-07-19 | 张三 | ✅ 通过 | - |

### 问题记录

| 问题编号 | 严重程度 | 问题描述 | 影响范围 | 解决方案 | 状态 |
|---------|---------|---------|---------|---------|------|
| BUG-001 | P0 | 示例问题 | 核心功能 | 示例解决方案 | 已解决 |

---

## 四、性能测试

### 4.1 并发登录测试

**测试目标**: 验证大量设备同时登录时的互踢性能

**测试工具**: JMeter / Gatling

**测试场景**:
- 1000 个用户同时登录
- 每个用户 3 台设备（Web + iOS + Android）
- 验证互踢延迟 < 100ms

**预期结果**:
- ✅ 互踢延迟 < 100ms
- ✅ CPU 使用率 < 70%
- ✅ 内存使用率 < 80%
- ✅ 无死锁或异常

### 4.2 跨节点延迟测试

**测试目标**: 验证跨节点互踢消息延迟

**测试场景**:
- 2 个节点，物理距离 100km
- 验证跨节点互踢延迟 < 200ms

**预期结果**:
- ✅ Redis Pub/Sub 延迟 < 50ms
- ✅ 跨节点互踢总延迟 < 200ms

---

## 五、安全测试

### 5.1 设备伪造测试

**测试目标**: 验证防止设备信息伪造

**测试步骤**:
1. 修改客户端代码，伪造 deviceType
2. 验证后端是否检测到异常
3. 验证是否有审计日志

**预期结果**:
- ✅ 后端记录审计日志
- ✅ 可选：风控系统介入

### 5.2 重放攻击测试

**测试目标**: 验证防止认证消息重放

**测试步骤**:
1. 抓取 WebSocket 认证消息
2. 重放认证消息
3. 验证是否被拒绝

**预期结果**:
- ✅ 重放消息被拒绝
- ✅ 记录安全审计日志

---

## 六、附录

### 6.1 设备类型枚举对照表

| 设备类型 | 枚举值 | 说明 |
|---------|-------|------|
| Web | 1 | 浏览器访问 |
| iOS | 2 | iPhone/iPad |
| Android | 3 | Android 手机/平板 |
| 小程序 | 4 | 微信/支付宝小程序 |

### 6.2 关键接口列表

| 接口 | 方法 | 路径 | 说明 |
|-----|------|------|------|
| 设备列表 | GET | /system/im/device/list | 获取当前用户登录设备列表 |
| 踢出设备 | POST | /system/im/device/kick | 踢出指定设备 |
| 在线状态 | GET | /system/im/device/online-status | 查询用户在线状态 |

### 6.3 关键日志关键字

```bash
# 互踢相关
grep "踢掉设备" logs/websocket.log
grep "跨节点互踢" logs/websocket.log

# 认证相关
grep "认证成功" logs/websocket.log
grep "deviceName" logs/websocket.log

# 错误相关
grep "ERROR" logs/websocket.log
grep "Exception" logs/websocket.log
```

---

**文档结束**
