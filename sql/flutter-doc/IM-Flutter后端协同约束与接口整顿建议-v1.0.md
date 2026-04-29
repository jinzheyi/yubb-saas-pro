# IM Flutter 后端协同约束与接口整顿建议 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 重构所需的后端协同约束、接口整顿策略、协议出口规则  

---

## 1. 目标

本文件用于在 Flutter 开工前，把后端需要配合的关键约束一次性定义清楚，减少后续返工。

原则：

1. 不要求大面积重写后端业务逻辑
2. 优先通过统一出口规则解决多端精度与协议一致性问题
3. 保持 `shengyu-spring-boot-starter-websocket` 的中间件定位
4. 多租户 SaaS 体系下，底层 IM 能力应保持可复用、可扩展到租户端和平台端

---

## 2. 当前已反推的主链路

### 2.1 认证链路

- `/system/auth/login`
- `/system/auth/sms-login`
- `/system/auth/logout`
- `/system/auth/refresh-token`
- `/system/auth/get-permission-info`

### 2.2 会话链路

- `/system/im/conversation/list`
- `/system/im/conversation/search`
- `/system/im/conversation/sync`
- `/system/im/conversation/list-by-type`
- `/system/im/conversation/create`
- `/system/im/conversation/update`
- `/system/im/conversation/delete`
- `/system/im/conversation/mark-read-seq`
- `/system/im/conversation/unread-count`
- `/system/im/conversation/get-by-target`

### 2.3 消息链路

- `/system/im/message/page`
- `/system/im/message/send`
- `/system/im/message/list-by-chat`
- `/system/im/message/window`
- `/system/im/message/history`
- `/system/im/message/recall`
- `/system/im/message/delete`
- `/system/im/message/clear`
- `/system/im/message/search`
- `/system/im/message/media`
- `/system/im/message/location-search`
- `/system/im/message/pull`
- `/system/im/message/detail`
- `/system/im/message/mark-read`
- `/system/im/message/mark-voice-played`
- `/system/im/message/mark-voice-played-batch`
- `/system/im/message/voice-played-status`
- `/system/im/message/forward`

### 2.4 角标链路

- `/system/im/badge/get`

### 2.5 用户链路

- `/system/user/get`
- `/system/user/get-profile`
- `/system/user/theme`
- `/system/user/chat-bubble`

---

## 3. 当前后端结构可直接复用的部分

### 3.1 App 接口收口

`controller.app` 分层已经比较清晰，适合 Flutter 继续复用。

### 3.2 会话同步模型

已有：

- conversation list
- conversation sync
- message window
- history
- pull
- badge

这条链路已经满足 Flutter 目标态的主流程。

### 3.3 WebSocket 中间件总体方向

`shengyu-spring-boot-starter-websocket` 当前具备：

- AUTH_REQ / AUTH_RESP
- heartbeat
- protobuf 协议
- processor 分发
- session manager
- 多端互踢
- accessToken / deviceId 维度索引

这套中间件保留“底层能力层”定位是正确的，不应下沉具体 IM 业务规则。

---

## 4. 最需要前置整顿的点

### 4.1 ID / version / sequence 出口统一规则

这是第一优先级。

问题：

- HTTP VO、WebSocket protobuf、数据库层目前大量使用 `Long/int64`
- Flutter 多端目标态统一按 `String` 处理
- 如果继续让客户端逐字段兜底，后续极易漏改

### 4.2 推荐解法：统一出口字符串化策略

不要求后端数据库、Mapper、查询条件改成字符串。

只要求在“对客户端出口层”统一处理：

1. HTTP Response VO 层统一字符串化
2. WebSocket 对客户端事件统一字符串化
3. Flutter 文档中冻结为全部按 `String` 接收

### 4.3 推荐实现方式

#### HTTP 层

- 所有面向 Flutter 的 Response VO 中，关键标识字段统一声明为 `String`
- Service / DO / Query 层仍可使用 `Long`
- 通过 convert 层统一 `Long -> String`

这样不会影响数据库索引和查询性能，也避免零碎修补。

#### WebSocket 层

分两阶段：

1. 现阶段保留 protobuf `int64`，不大改底层 starter
2. 在 Flutter 客户端 codec / mapper 层统一即时转换为 `String`

中期再考虑更清晰的 app-level event envelope。

### 4.4 适用字段

- `messageId`
- `chatId`
- `groupId`
- `userId`
- `tenantId`
- `sequence`
- `cursorVersion`
- `conversationVersion`
- `lastReadSequence`
- `lastMessageSequence`

### 4.5 明确不推荐

- 一个字段一个字段手工补 `ToStringSerializer`
- 前端每个页面各自做 `String(value)`
- 让 starter 直接侵入具体业务 VO

---

## 5. WebSocket 中间件边界建议

### 5.1 starter 应继续只负责

- 连接管理
- 鉴权
- 心跳
- session 生命周期
- 多端会话治理
- 消息编解码
- processor 分发
- MQ / 广播 / 精确投递底座

### 5.2 不应下沉的内容

- 会话业务状态机
- 消息存储业务规则
- IM 通话业务状态
- 群治理规则
- 平台端 / 租户端专属页面语义

### 5.3 推荐对外 SPI

- `AuthService`
- `MessageStorageService`
- `OfflinePushService`
- `SessionLifecycleListener`
- `BusinessEventPublisher`

这样后续租户端和平台端都能复用同一底层能力。

---

## 6. Session / 鉴权协议整顿建议

### 6.1 现状

当前 `AuthHandler` 已支持：

- PROBE
- AUTH_REQ
- renew 式 reauth
- 租约过期关闭

但仍有过渡性设计：

- `REAUTH_REQUIRED` 仍借助 `CLOSE + extra.action`
- kicked / invalidated / revoke 的表达不够正式

### 6.2 建议

补充标准 session 级事件语义：

- `session.reauth-required`
- `session.kicked`
- `session.invalidated`
- `session.revoked`

可以先通过统一 envelope 表达，不必立刻演进为复杂业务消息类型。

---

## 7. 会话与消息最终态规则

### 7.1 会话最终态

- WebSocket `conversationHint` 只做提示
- 最终会话状态以 `/conversation/sync` 为准

### 7.2 消息最终态

- socket 实时到达负责实时性
- `/message/pull` 负责断线补偿
- `/message/window` / `/history` 负责聊天页窗口正确性

### 7.3 读水位规则

- `/conversation/mark-read-seq` 是主链路
- `/message/mark-read` 保留为明细补充链路

---

## 8. 用户偏好协同策略调整

### 8.1 冻结结论

跨端统一只保留：

- 聊天气泡偏好

其余偏好跟随设备本身：

- theme mode
- language mode

### 8.2 对后端的建议

保留：

- `/system/user/chat-bubble`

可降级为非核心：

- `/system/user/theme`

不建议新增：

- 语言偏好服务端同步接口

---

## 9. 位置服务边界建议

当前 `location-search` 已带供应商耦合痕迹。

建议后端层后续逐步改成 provider-neutral 表达：

- `LocationSearchService`
- `LocationProviderAdapter`

首期可以不改接口路径，只改服务内抽象边界。

---

## 10. 文件上传协同建议

### 10.1 当前判断

- `/infra/file/upload-and-return-id` 已能支撑 Flutter 首期聊天上传
- `/infra/file/presigned-url` + `/infra/file/create` 已具备直传扩展基础
- 现有聊天媒体流程已经具备 `fileId` 化趋势

### 10.2 建议

1. Flutter 首期统一走 `upload-and-return-id`
2. 聊天媒体消息不再接受只传 `url` 不传 `fileId`
3. 上传目录规则逐步标准化为会话作用域目录
4. 群文件列表不要通过重复上传生成，改为基于已上传 `fileId` 建索引

### 10.3 后续优化

1. 增加上传用途字段，如 `purpose/chatId/groupId`
2. 服务端按用途和会话归属校验目录
3. 为大文件直传和分片上传预留正式协议

---

## 11. 音视频后端协同建议

### 11.1 当前判断

- `CALL_SIGNAL` 已在 protobuf 中存在
- 底层中间件具备信令投递基础
- 但 app 业务层尚未形成完整 call 业务闭环

### 11.2 建议

音视频应落在业务模块中，而非 starter 中。

推荐新增业务层能力：

- `AppImCallController`
- `ImCallService`
- `ImCallSession`
- `ImCallStateMachine`
- `ImCallPushService`

starter 只负责：

- 通道
- 会话
- 投递
- 基础协议

---

## 12. 调整优先级

### P0

1. 出口层统一字符串化策略
2. 明确用户偏好只同步聊天气泡
3. 明确 starter 中间件边界，不承载 IM 业务状态机
4. 聊天上传统一 `fileId` 权威，不重复上传生成群文件

### P1

1. session 级系统事件正式化
2. 位置 provider 抽象化
3. 音视频业务层正式建模
4. 上传用途字段与目录校验标准化

### P2

1. 更统一的 app-level socket event envelope
2. 更细的 token / revoke / kicked 语义细化
