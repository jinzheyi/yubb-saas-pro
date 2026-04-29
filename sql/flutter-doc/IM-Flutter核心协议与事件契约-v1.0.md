# IM Flutter 核心协议与事件契约 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 最核心的 HTTP、WebSocket、增量同步、消息、通话事件契约总纲  

---

## 1. 目标

本文件用于冻结 Flutter IM 的核心协议层规则，避免后续开发在多份文档之间分裂。

本文件优先级高于页面说明、模板文档与任务清单。

---

## 2. 全局冻结规则

1. 所有 ID、游标、序列、版本统一使用 `String`
2. 会话主键统一为 `chatId`
3. 群消息历史统一按 `chatId` 查询
4. `lastReadSequence` 只升不降
5. `cursorVersion` 只前进
6. `conversationVersion` 用于会话幂等合并
7. 消息最终态以更大 `rev` 为准
8. 文件访问必须通过服务端 `open-strategy`
9. HTTP refresh 成功后必须触发 WebSocket 同连接 reauth

---

## 3. HTTP 协议契约

### 3.1 鉴权

- `accessToken` 用于业务接口
- `refreshToken` 用于续期
- 401 刷新必须单飞
- 单飞刷新成功后，等待中的请求统一重放

### 3.2 租户与多端

每个请求在基础拦截层必须具备：

- `Authorization`
- `tenantId`
- `deviceId`
- `locale`
- `requestId`

### 3.3 响应处理

- DTO 只停留在 `infrastructure`
- 页面层不接触 raw response
- API 错误统一映射到领域异常

---

## 4. WebSocket 总线契约

### 4.1 客户端职责

`ImSocketClient` 只负责：

- connect
- disconnect
- auth
- reauth
- heartbeat
- reconnect
- codec
- event dispatch

### 4.2 明确禁止

- 不允许在 socket 客户端持有 UI 状态
- 不允许在 socket 客户端维护消息列表
- 不允许在 socket 客户端做页面恢复逻辑

### 4.3 状态机

- `disconnected`
- `connecting`
- `probing`
- `authenticating`
- `connected`
- `reauthenticating`
- `reconnectWaiting`
- `invalidated`

### 4.4 关键事件

- `connectRequested`
- `authSucceeded`
- `heartbeatTimeout`
- `closeByServer`
- `tokenRefreshed`

---

## 5. Socket 事件分层

### 5.1 session 级

- `connected`
- `authSucceeded`
- `authFailed`
- `reauthSucceeded`
- `invalidated`
- `reconnecting`

### 5.2 conversation 级

- `conversationHint`
- `conversationUpdated`
- `conversationDeleted`

### 5.3 message 级

- `messageReceived`
- `messageRecalled`
- `readReceiptChanged`
- `voicePlayedChanged`

### 5.4 badge 级

- `badgeUpdated`

### 5.5 call 级

- `callInvite`
- `callAccepted`
- `callRejected`
- `callBusy`
- `callCancelled`
- `callEnded`
- `callStateSync`
- `callDeviceTerminated`

---

## 6. 会话增量同步契约

### 6.1 基本规则

1. socket 只负责提示，不负责最终态
2. 最终会话状态以增量同步结果为准
3. `cursorVersion` 只前进
4. 允许在本地异常时做 reset sync

### 6.2 合并规则

- 本地 `conversationVersion` 更新于远端时丢弃远端旧数据
- unread 展示先可即时更新，最终态由 sync 修正
- 置顶排序只能由 controller/reducer 统一收敛

### 6.3 reconnect 后动作

1. socket reconnect
2. socket reauth
3. conversation incremental sync
4. chat pull after reconnect

---

## 7. 聊天消息契约

### 7.1 消息主键

- `messageId`
- `sequence`
- `chatId`

### 7.2 发送阶段

- 本地先创建临时发送态消息
- 服务端确认后进行 `messageId / sequence` 归并
- 最终展示态受 `rev` 保护

### 7.3 消息类型

必须支持：

- text
- image
- video
- file
- voice
- location
- contactCard
- emoji
- customEmoji
- quoteReply
- mergedForward
- system
- callRecord

### 7.4 引用定位

- 优先本地查找
- 失败后按 `anchorSequence` 或 `anchorMessageId` 请求锚点窗口
- 禁止分页穷举

---

## 8. 已读与未听契约

### 8.1 已读

- `readSequence` 只升不降
- 页面离开时必须 flush

### 8.2 语音未听

- 与 read watermark 完全分离
- 单独维护 `VoicePlayedState`

---

## 9. 文件打开协议契约

服务端不可只返回下载地址，必须返回打开策略对象。

建议字段：

- `renderStrategy`
- `contentType`
- `previewUrl`
- `downloadUrl`
- `viewerUrl`
- `convertedPdfUrl`
- `expiresAt`
- `unstable`
- `message`

客户端只消费 `FilePreviewDescriptor`，不直连临时下载协议细节。

---

## 10. 音视频通话契约

### 10.1 设计原则

- 业务信令与媒体信令分离
- IM 后端负责业务状态
- WebRTC 层负责媒体连接
- 页面只消费 `CallState`

### 10.2 业务事件

建议冻结为：

- `call.invite`
- `call.ringing`
- `call.accepted`
- `call.rejected`
- `call.busy`
- `call.cancelled`
- `call.ended`
- `call.timeout`
- `call.media-token-issued`
- `call.device-terminated`
- `call.state-sync`

### 10.3 业务状态

- `idle`
- `outgoing`
- `incoming`
- `accepting`
- `connecting`
- `connected`
- `reconnecting`
- `ended`

### 10.4 关键规则

1. 一个 `callSessionId` 对应一条通话业务链路
2. 多端只允许一个设备正式接听
3. 媒体异常不直接改写业务最终态
4. 页面恢复依赖 `call.state-sync`
5. 通话结束后必须产生 `callRecord` 类型消息

---

## 11. 第三方基础设施接入契约

### 11.1 总规则

- 必须通过 `adapter / facade`
- feature 层只依赖抽象接口
- 页面层不可感知供应商 SDK

### 11.2 当前主方案

- RTC：`flutter_webrtc`
- SFU：Janus
- TURN：coturn
- Push：单主方案聚合通道
- Map：单主方案地图供应商

### 11.3 备选方案策略

- 备选通道允许空实现
- 但抽象接口和替换边界必须先定义

---

## 12. 协议冲突处理

若后续文档与本文件冲突，按以下顺序处理：

1. 以本文件为准修正专题文档
2. 不在页面文档中临时改协议
3. 不在模板代码中发明新事件名

