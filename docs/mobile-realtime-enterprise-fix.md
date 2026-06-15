# 真机实时通信企业级修复方案

> 文档版本：v1.0  
> 创建时间：2026-06-15  
> 目标：彻底解决真机环境下消息发送"发送中"卡死、消息不实时、角标不联动等问题

---

## 一、问题诊断

### 1.1 核心问题现象

| 问题 | 现象描述 | 影响范围 |
|------|----------|----------|
| P0-1 | 真机发送消息后一直显示"发送中"，重新进入对话页才正常 | 所有真机用户 |
| P0-2 | Web 端给真机发消息，真机无法实时收到，需重新进入对话页 | 跨端通信 |
| P0-3 | 会话列表最后一条消息不实时显示，切换 Tab 后才更新 | 会话列表页 |
| P0-4 | Tab 栏角标数字经常无效不显示，与下方会话列表角标不一致 | 全局角标体系 |

### 1.2 根本原因分析

#### 根因 1：WebSocket 在移动端后台被系统杀死

**发生机制：**
```
用户切到后台/锁屏 
  → iOS 几秒内挂起应用 / Android 省电策略切断连接
  → Timer 被系统暂停 → 心跳停止
  → 服务端检测到心跳超时 → 断开连接
  → 客户端不知道连接已断开 → 状态仍显示 connected
  → 用户回到前台 → 发消息发不出去（显示"发送中"）
  → 收不到对方消息推送（显示不实时）
```

**与 Web 端的差异：**

| 维度 | Web 端 | 真机端 |
|------|--------|--------|
| 后台运行 | 标签页保持连接 | iOS 几秒挂起，Android 可能被杀 |
| 心跳保活 | Timer 正常执行 | 后台 Timer 被系统暂停 |
| 网络切换 | 较少发生 | WiFi ↔ 4G/5G 频繁切换 |
| 连接恢复 | 浏览器自动处理 | 需要手动重连 |
| 消息到达 | 实时推送 | 后台期间推送丢失 |

#### 根因 2：缺乏应用生命周期管理

当前代码检查：
- ✅ 会话列表页有 `didChangeAppLifecycleState`，但只触发会话 sync，未检查 WebSocket
- ❌ 聊天页面**没有**实现 `didChangeAppLifecycleState`（虽然有 `WidgetsBindingObserver` mixin）
- ❌ 全局**没有**网络状态监听

#### 根因 3：角标更新完全依赖 WebSocket 实时推送

```
badgeUpdated 事件
  → 需要 WebSocket 连接正常
  → 如果断连，事件丢失
  → 重连后只在 authSucceeded 时初始化（有10秒冷却期）
  → 冷却期内角标不更新 → 显示过期数据
```

#### 根因 4：消息发送无连接检查

```
用户点击发送
  → 直接调用 sendEnvelope
  → 不检查 WebSocket 状态
  → 如果已断连，消息发不出去
  → 本地标记为 sending → 永远等不到回执
```

---

## 二、企业级修复方案

### 2.1 P0 级修复（必须立即实施）

#### 方案 1：完善应用生命周期管理

**目标：** 应用从后台恢复时，立即检测并修复连接状态

**实施点：**
1. 聊天页 `chat_page.dart`：
   - 实现 `didChangeAppLifecycleState`
   - `resumed` 时检查 WebSocket 连接
   - 如果断连，触发重连
   - 重试发送中的消息

2. 会话列表页 `conversation_list_page.dart`：
   - 现有生命周期处理增强
   - `resumed` 时检查 WebSocket 连接并强制刷新角标

**修改文件：**
- `lib/features/im/chat/presentation/pages/chat_page.dart`
- `lib/features/im/conversation/presentation/pages/conversation_list_page.dart`

#### 方案 2：消息发送前连接检查

**目标：** 确保消息发送时 WebSocket 处于连接状态，断连时自动重连

**实施点：**
1. `chat_controller.dart` 的所有 submit 方法：
   - 发送前检查 `canSendBusinessMessage`
   - 如果不可发送，触发重连并等待连接建立
   - 添加发送超时机制（10 秒）

**修改文件：**
- `lib/features/im/chat/presentation/controllers/chat_controller.dart`
- `lib/core/websocket/socket_outbound_sender.dart`

#### 方案 3：角标数据补偿机制

**目标：** WebSocket 重连或应用恢复时，强制拉取最新角标数据

**实施点：**
1. `global_badge_socket_binding.dart`：
   - `authSucceeded` 时忽略冷却期，强制刷新
   - 新增 `resumeFromBackground` 事件处理

2. `badge_service.dart`：
   - 新增 `forceRefresh` 方法，绕过冷却期

**修改文件：**
- `lib/app/shell/global_badge_socket_binding.dart`
- `lib/features/im/badge/badge_service.dart`

### 2.2 P1 级修复（短期完善）

#### 方案 4：网络状态监听

**目标：** 检测网络切换，主动处理连接失效

**实施点：**
1. 新增 `network_connectivity_service.dart`：
   - 监听网络状态变化（WiFi ↔ 4G/5G ↔ 离线）
   - 网络恢复时触发 WebSocket 重连

2. `im_socket_client.dart` 增强：
   - 暴露连接健康检查方法
   - 网络变化时自动触发检查

**新增文件：**
- `lib/core/network/network_connectivity_service.dart`

**修改文件：**
- `lib/core/websocket/im_socket_client.dart`
- `lib/app/shell/app_bootstrap.dart`（注册全局监听）

#### 方案 5：本地消息队列优化

**目标：** 断网时消息加入本地队列，网络恢复后自动重试

**实施点：**
1. 发送失败时标记为 `failed` 而非永久失败
2. 网络恢复时自动重试 failed 消息
3. 用户可手动重试

**修改文件：**
- `lib/features/im/chat/presentation/controllers/chat_controller.dart`
- `lib/features/im/chat/presentation/controllers/chat_timeline_controller.dart`

### 2.3 P2 级修复（长期架构优化，后续迭代）

#### 方案 6：集成推送通知（FCM + APNs）

**目标：** 应用后台时通过推送通知触达用户

**架构设计：**
```
服务端发送消息
  → 检查接收方 WebSocket 是否在线
  → 如果离线：发送 FCM/APNs 推送
  → 用户点击推送 → 唤醒应用 → 恢复 WebSocket 连接
  → 拉取离线消息
```

**依赖：**
- `firebase_messaging`（Android）
- APNs 配置（iOS）
- 后端推送服务适配

#### 方案 7：后台保活策略（Android）

**目标：** Android 端使用前台服务保持 WebSocket 连接

**架构设计：**
- 使用 `flutter_background_service`
- 前台 Notification 显示"IM 服务运行中"
- 适配各厂商保活策略（小米、华为、OPPO、vivo）

---

## 三、实施计划

### 第一阶段：P0 修复（本次）

| 序号 | 任务 | 预估工作量 | 依赖 |
|------|------|------------|------|
| 1 | 聊天页生命周期处理 | 15 分钟 | 无 |
| 2 | 消息发送前连接检查 | 20 分钟 | 无 |
| 3 | 角标数据补偿机制 | 15 分钟 | 无 |
| 4 | 会话列表页增强 | 10 分钟 | 1 |

### 第二阶段：P1 修复（本次）

| 序号 | 任务 | 预估工作量 | 依赖 |
|------|------|------------|------|
| 5 | 网络状态监听 | 30 分钟 | 无 |
| 6 | 本地消息队列优化 | 20 分钟 | 2 |

### 第三阶段：P2 修复（后续迭代）

| 序号 | 任务 | 预估工作量 | 依赖 |
|------|------|------------|------|
| 7 | FCM/APNs 推送集成 | 3-5 天 | 后端适配 |
| 8 | Android 后台保活 | 2-3 天 | 各厂商适配 |

---

## 四、风险与回滚

### 4.1 风险评估

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 重连频繁触发 | 耗电增加 | 添加重连冷却期，指数退避 |
| 角标频繁刷新 | 请求过多 | 合并请求，节流处理 |
| 网络监听不稳定 | 误触发 | 多重校验，日志记录 |

### 4.2 回滚策略

- 所有修改都有 git 记录，可快速回滚
- 关键功能通过 feature flag 控制（如需）

---

## 五、验证方案

### 5.1 真机测试场景

| 场景 | 预期结果 |
|------|----------|
| 真机发消息后立即切后台，再回前台 | 消息状态正常更新，不卡"发送中" |
| Web 端发消息给真机（真机在后台） | 真机回前台后能实时收到消息 |
| 真机在会话列表，收到新消息 | 会话列表实时更新，角标正确 |
| 真机网络切换（WiFi → 4G） | WebSocket 自动重连，消息不丢失 |
| 真机锁屏 1 分钟后解锁 | WebSocket 自动恢复，角标刷新 |

### 5.2 调试日志

所有关键操作添加 `[MobileResume]` 前缀的 debugPrint：
- WebSocket 状态检查
- 重连触发
- 角标刷新
- 消息重试

---

## 六、参考文档

- [WebSocket RFC 6455](https://datatracker.ietf.org/doc/html/rfc6455)
- [Flutter App Lifecycle](https://docs.flutter.dev/release/breaking-changes/app-lifecycle-restrictions)
- [iOS Background Execution](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background)
- [Android Background Services](https://developer.android.com/guide/background)
- 微信 IM 架构公开分享（参考）
