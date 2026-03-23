---
description: IM 音视频通话（WebRTC 自研）设计文档
owner: IM
status: draft
---

# IM 即时通讯音视频通话设计文档（纯自研 WebRTC 路线）

## 0. 背景与目标

### 0.1 背景
当前 IM 已具备：
- WebSocket 双栈（JSON/PB）协议与鉴权
- 会话增量同步（cursorVersion/conversationVersion）
- 消息存储与断线补偿（sequence）

希望新增音视频通话能力，并且：
- 尽可能纯自研（优先 WebRTC）
- 保持企业级规模、可观测、可灰度、可长期维护

### 0.2 目标（必须满足）
- 通话信令：在现有 IM WS 上闭环（JSON/PB 双栈）
- 媒体传输：基于 WebRTC（端侧）
- 服务端：维护权威状态机，处理多端/乱序/重试/超时
- 可观测：可按 tenantId/userId/callId 串起链路，具备基础指标与日志
- 灰度开关：按 tenant/user/deviceType 可控启用

### 0.3 非目标（本期不做/可后续迭代）
- 群通话（多人会议）
- 录制/转写/同声传译
- 运营侧复杂策略（如强制主端接听、并发策略可配置）

## 1. 总体架构

### 1.1 模块拆分
- **IM 信令层（自研）**
  - 复用现有 WS 连接与认证
  - 定义 `CALL_*` 业务消息类型（JSON/PB）
  - 负责状态同步、重试、幂等、离线补偿

- **RTC 媒体层（WebRTC）**
  - iOS/Android 端集成 WebRTC 栈
  - 负责采集/编解码/回声消除/弱网自适应（由 WebRTC 提供基础能力）

- **服务端 Call State 服务（自研）**
  - callId 维度权威状态机
  - 负责：多端一致、超时、并发控制、幂等
  - 保存通话最终态，产生通话记录消息（R5）

### 1.2 数据流
1) A 发起通话：`CALL_INVITE`（携带 callId）
2) 服务端校验/落库/推进状态：INVITED
3) 服务端 fanout 到 B（以及 B 多端）：`CALL_RINGING`
4) B 任一端接受：`CALL_ACCEPT`
5) 服务端做并发裁决：只允许一个端 ACCEPT 成功
6) 服务端通知其他端：`CALL_END`/`CALL_BUSY`
7) 双方开始 WebRTC SDP/ICE 协商（通过 `CALL_SDP`/`CALL_ICE` 信令消息交换）
8) 结束：任一方 `CALL_END`，服务端落最终态并广播

## 2. 关键约束与原则（企业级）

- **2.1 幂等性**
  - 所有 `CALL_*` 事件必须带 `callId` + `eventId`（或 `seq`）
  - 服务端必须按 `eventId` 幂等处理，重复事件不导致状态倒退

- **2.2 状态机权威性**
  - 服务端是权威：端侧仅是 UI + 媒体控制
  - 状态只允许单向推进，不允许回滚

- **2.3 多端一致**
  - 同账号多端可同时响铃
  - 只能一个端 ACCEPT 成功，其余端必须收到结束/忙线

- **2.4 超时治理**
  - INVITED/RINGING 必须有超时（如 30s）自动 TIMEOUT
  - CONNECTING（SDP/ICE）也应有超时（如 60s）

- **2.5 可灰度/可降级**
  - FeatureFlag：关闭时不展示入口、不处理媒体
  - 允许“仅信令联调”模式（媒体不启用）用于灰度排障

## 3. 信令协议设计（WS JSON/PB 双栈）

### 3.1 消息类型（建议最小闭环）
- `CALL_INVITE`
- `CALL_RINGING`
- `CALL_ACCEPT`
- `CALL_REJECT`
- `CALL_END`
- `CALL_BUSY`
- `CALL_TIMEOUT`
- `CALL_SDP`（携带 offer/answer）
- `CALL_ICE`（携带 candidate）
- `CALL_STATE_SYNC`（断线重连/多端同步）

### 3.2 Header 约定
复用现有 IM header：
- `tenantId`
- `senderId`
- `receiverId`（单聊）
- `messageId`（可选，用于幂等/落库）
- `sequence/chatId/cursorVersion`（如需对齐会话模型）

### 3.3 Body 字段（建议）
- `callId: string/int64`
- `eventId: string`（UUID）
- `callType: audio|video`
- `sdp: string`（CALL_SDP）
- `ice: { sdpMid, sdpMLineIndex, candidate }`（CALL_ICE）
- `reason: enum`（END/BUSY/TIMEOUT/REJECT）
- `timestamp`

### 3.4 事件幂等与顺序
- 端侧每次发事件生成 `eventId`
- 服务端保存 `processed_event_ids(callId, eventId)`（或缓存）
- 状态机只允许：
  - INIT -> INVITED -> RINGING -> CONNECTING -> CONNECTED -> ENDED

## 4. 服务端状态机与数据模型

### 4.1 核心表（建议）
- `im_call_session`
  - `call_id`（主键）
  - `tenant_id`
  - `caller_id`
  - `callee_id`
  - `call_type`
  - `state`
  - `accepted_device_id`（可选）
  - `start_time/end_time`
  - `end_reason`

- `im_call_event`
  - `call_id`
  - `event_id`
  - `event_type`
  - `sender_id`
  - `payload_json`
  - `create_time`

### 4.2 并发裁决（多端 accept）
- `CALL_ACCEPT` 到达：
  - 若 state 已 CONNECTED/ENDED：返回当前最终态
  - 若 state 在 RINGING/CONNECTING 且未设置 accepted_device：
    - CAS 成功写入 accepted_device + state=CONNECTING
  - 否则：对其他设备返回 BUSY/ENDED

### 4.3 超时任务
- INVITED/RINGING 超时：
  - 若未 ACCEPT：置 TIMEOUT 并广播 `CALL_TIMEOUT`

## 5. WebRTC 媒体层（端侧）

### 5.1 端侧职责
- 管理 PeerConnection 生命周期
- 采集（音频/视频）与轨道管理
- SDP offer/answer 生成与处理
- ICE candidate 收集与上报

### 5.2 NAT/穿透与 TURN
- 需要配置：STUN/TURN
- 企业级建议：自建 coturn 或云服务

## 6. 可观测性与排障

### 6.1 日志
- 服务端每条事件日志必须带：`tenantId/userId/callId/eventId/state`

### 6.2 指标（建议）
- `call_invite_total`
- `call_accept_total`
- `call_connect_success_total`
- `call_end_total`
- `call_timeout_total`
- `call_busy_total`

### 6.3 Trace
- 按 `callId` 聚合事件流

## 7. 灰度与开关

- tenant 级开关：`rtc_enabled`
- user 白名单/黑名单
- deviceType 策略

## 8. 验收用例（建议最小集合）

- A 呼叫 B：B 接听成功，双方建立媒体
- B 拒绝：A 收到 reject 并结束
- 超时：B 不操作 30s，A 收到 timeout
- 多端：B 两台设备同时响铃，仅一台可接听成功
- 断线：通话中 B 断网 10s 恢复，能通过 state_sync 恢复最终态

## 9. 实施计划（阶段化）

- Phase 0：仅信令（不启用媒体），验证状态机/多端/幂等/超时
- Phase 1：接入 WebRTC，打通 SDP/ICE，完成 1v1 音频
- Phase 2：视频、弱网优化、质量统计与可观测增强

