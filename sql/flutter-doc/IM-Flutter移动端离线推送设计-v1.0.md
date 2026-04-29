# IM Flutter 移动端离线推送设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 移动端离线推送主方案、抽象层、降级策略  

---

## 1. 目标

在个人开发者成本可控的前提下，为 Flutter IM 定义一套“够稳定、可售卖、可替换”的移动端离线推送方案。

本设计接受一定失败兜底，不追求超大厂级别的极限覆盖率。

---

## 2. 结论

### 2.1 不自研离线推送主通道

离线推送无法完全通过自建应用长连接替代。

原因：

- iOS 必须依赖 APNs
- Android 后台、锁屏、被杀场景高度依赖厂商系统通道或聚合推送

### 2.2 首期实现策略

- 只实现一个主推送方案
- 其他厂商通道只保留抽象和空实现
- 服务端负责统一推送编排

---

## 3. 主方案

### 3.1 iOS

- 主通道：APNs
- 由自有服务端直连 APNs

### 3.2 Android 国内

- 主通道：聚合推送供应商
- 当前建议作为首期主方案接入个推

### 3.3 Android 其他环境

- 预留：
  - FCM adapter
  - 厂商直连接口 adapter

首期不强制落地。

---

## 4. 架构设计

### 4.1 Flutter 侧

```text
core/platform/push/
  push_facade.dart
  push_provider.dart
  push_message.dart
  push_token.dart
  push_open_router.dart
  adapters/
    getui_push_adapter.dart
    apns_token_adapter.dart
    noop_vendor_push_adapter.dart
```

### 4.2 服务端侧

- `PushDispatchService`
- `PushProviderSelector`
- `PushTokenRegistry`
- `PushAuditService`

---

## 5. Flutter 客户端职责

1. 初始化 push facade
2. 获取并上报 push token / clientId
3. 接收通知点击或透传
4. 统一路由回应用内页面
5. 与登录态、用户态绑定和解绑

---

## 6. 服务端职责

1. 保存设备推送标识
2. 按平台选择推送供应商
3. 下发通知类消息
4. 下发透传类消息
5. 记录推送审计日志
6. 支持重试与降级

---

## 7. 推送消息分类

### 7.1 IM 普通消息提醒

- 标题
- 摘要
- 会话跳转参数

### 7.2 音视频来电提醒

- 来电类型
- `callSessionId`
- 主叫信息
- 超时信息

### 7.3 系统通知

- 审批
- 风险
- 业务提醒

---

## 8. 应用内打开协议

统一使用抽象路由载荷：

- `targetType`
- `chatId`
- `messageId`
- `callSessionId`
- `bizId`
- `extra`

禁止客户端直接透出供应商自定义字段格式到业务层。

---

## 9. 失败与降级

### 9.1 允许失败的场景

- 厂商通道被限额
- 用户关闭通知权限
- 被杀透传未拉起
- 某些 ROM 自启策略严格

### 9.2 兜底策略

1. App 冷启动后补拉未读
2. WebSocket 重连后做增量同步
3. 通话场景允许未收到离线来电通知
4. 会话列表最终态以服务端同步为准

---

## 10. 抽象接口建议

### 10.1 `PushFacade`

- `initialize()`
- `bindUser()`
- `unbindUser()`
- `registerToken()`
- `consumeLaunchPayload()`

### 10.2 `PushProviderAdapter`

- `initSdk()`
- `requestPermission()`
- `getRegistration()`
- `setAlias()`
- `clearAlias()`
- `onMessage()`
- `onNotificationTap()`

---

## 11. 首期实现边界

只实现：

- 一条 Android 主推送链路
- iOS APNs token 注册与服务端下发
- App 内通知点击统一打开

先不实现：

- 多供应商自动切换
- 推送效果精细分析
- 厂商直连多通道并行

---

## 12. 验收标准

1. 用户登录后设备标识能上报
2. 普通消息通知可唤起指定会话
3. 来电通知可唤起通话页
4. 推送失败不破坏会话最终一致性
5. 供应商 SDK 不泄漏到业务页面层

