# IM 单聊/群聊音视频通话：LiveKit 私有化替换式重构任务书

> **版本**：v2.0｜**日期**：2026-08-16｜**状态**：待实施  
> **优先级**：P0｜**唯一实施依据**：是  
> **适用**：Android、iOS；Flutter Web 只保证前台加入/通话，不保证浏览器关闭后的系统来电  
> **替代关系**：本文件取代 `docs/im-rtc-call-system-design.md` 和 `sql/flutter-doc/IM-Flutter音视频通话企业级设计-v1.0.md` 中所有 Janus 实施结论。

## 1. 目标与不可变原则

把当前已实现但职责混杂的 Janus 通话系统，**整体替换**为可交付给购买方私有部署的 LiveKit 通话模块。保留 IM 的用户、单聊/群聊、权限、WebSocket 会话、通话记录和消息气泡；删除所有手写 WebRTC/Janus 媒体协议代码。

P0 只支持以下闭环：

| 场景 | 必须支持 |
|---|---|
| 单聊 | 1v1 语音、1v1 视频；发起、来电、接听、拒绝、取消、挂断、超时、忙线、记录 |
| 群聊 | 群成员选择后发起群语音/视频；被邀成员接听加入/拒绝；成员主动离开；发起人结束全体；实时成员列表 |
| 通话内控件 | 静音、扬声器、摄像头开关、前后摄切换、时长、挂断 |
| 生命周期 | 前台来电；Android/iOS 后台/锁屏来电；短暂网络恢复；通话记录；多端唯一接听 |

**P0 明确排除**：屏幕共享、录制、转接、呼叫等待、悬浮窗、通话中追加邀请、视频美颜、字幕、E2EE、会议管理、旁路直播、质量面板。它们不得预埋半成品状态机或 API。

### 1.1 绝对技术边界

```text
IM 后端：业务权限、状态裁决、LiveKit Token、推送、记录、审计
WebSocket 中间层：可靠投递业务事件，不传媒体 SDP/ICE
LiveKit：房间、WebRTC 信令、发布订阅、ICE、TURN、媒体重连
Flutter：调用业务 API、展示 UI、调用 LiveKit SDK、调用系统来电能力
```

禁止：`JanusClient`、`JanusVideoRoomPlugin`、裸 `RTCPeerConnection`、自行处理 SDP/JSEP/ICE trickle、以定时器弥补状态不一致、把 Token 放入 IM 推送。

## 2. 基于当前代码的重构范围

### 2.1 Flutter：替换而非叠加

当前目录 `shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/call/` 中的领域模型、页面、Controller、Socket/API mapper、记录气泡可以评估复用；以下必须删除或不再引用：

```text
infrastructure/rtc/janus_client.dart
infrastructure/rtc/janus_video_room_plugin.dart
infrastructure/rtc/adaptive_bitrate_controller.dart
infrastructure/rtc/audio_level_monitor.dart
infrastructure/rtc/network_quality_monitor.dart
presentation/controllers/call_media_controller.dart
presentation/controllers/call_conflict_manager.dart
presentation/controllers/call_floating_window_manager.dart
presentation/widgets/call_floating_window.dart
presentation/widgets/call_waiting_banner.dart
presentation/widgets/call_waiting_dialog.dart
```

创建新根目录 `lib/features/im/call_v2/`；旧 `call/` 在灰度完成前只允许保留，不允许继续修改。新目录固定如下：

```text
call_v2/
  domain/{call_session,call_participant,call_enums,call_repository}.dart
  application/call_orchestrator.dart
  infrastructure/{call_api,call_socket_gateway,livekit_gateway,native_call_ui_gateway}.dart
  presentation/{call_router,incoming_call_page,outgoing_call_page,in_call_page,widgets/}
  providers/call_v2_providers.dart
```

`CallOrchestrator` 是唯一状态写入者，状态只有 `idle/outgoingRinging/incomingRinging/connecting/inCall/ending`。页面、LiveKit 回调、Socket 回调都只能向它发送命令；不得再存在 `CallController + CallCoordinator + CallMediaController` 三方同时改状态。

复用并迁移：`CallRecord`、`CallRecordMessage`、`call_history_page.dart`、`call_record_message_bubble.dart`、单聊/群聊入口及现有权限/设备 ID 服务。重做：`incoming_call_page.dart`、`outgoing_call_page.dart`、`call_session_page.dart`、所有 group call 页面与 provider。

### 2.2 业务层：重构 AppCallController 与服务

当前 `AppCallController` 同时校验、调用 `ImCallService/GroupCallService`、组装事件、签发 Janus token、处理群行为；这是状态分散的根因。重构为：

```text
AppCallController（只做鉴权、VO、调用）
  -> ImCallApplicationService（唯一业务编排与事务）
  -> CallStateMachine / CallRepository / LiveKitTokenService / CallEventPublisher
```

删除 `@Value("${janus.url:}")`、`CallTokenService` 的 Janus 语义、`JanusRoomManager` 及一切 `janus.*` 配置。`CallSignalProcessor` 不再处理任何呼叫生命周期入口；生命周期只通过 REST API 进入。

保留现有路径前缀 `/system/im/call`，但替换内部实现与 VO。群通话不再把“先建 1v1，再转换 roster”作为实现方式，必须直接创建群通话会话。

### 2.3 WebSocket 中间层：收敛为事件总线

当前 proto 已有 `SYSTEM_NOTIFY=200` 与 `CALL_SIGNAL=206`。P0 统一采用 `SYSTEM_NOTIFY` 承载**后端下发的只读业务事件**；不新增客户端上行 Call Signal，也不让 Flutter 对媒体服务器使用本系统 WebSocket。

`shengyu-spring-boot-starter-websocket/src/main` 必须完成：

- 保留 `MessageHeader` 的 tenantId、senderId、receiverId、groupId、extra；`extra` 统一放 JSON event envelope。
- 新增框架无关的 `CallEventPublisher` 接口/默认实现，封装 `NettyMessageSender.sendToUserWithExtra`；业务层不允许直接拼 `TextMessage` 或直接发 sender。
- 多节点时沿用现有 Redis/Kafka/RabbitMQ sender 路径；必须验证 call event 跨节点送达。
- `CALL_SIGNAL=206` 和 `CallSignalMessage` 不纳入 P0；若没有其他模块使用，在 Phase 5 删除 proto 定义、生成代码和处理入口；否则标记 deprecated，禁止通话模块使用。

## 3. 领域模型、状态机与并发规则

### 3.1 会话模型

`ImCallRecordDO` 作为会话主表，补齐或统一字段：

| 字段 | 规则 |
|---|---|
| `call_id` | UUID，唯一，不暴露递增 ID |
| `tenant_id` | 所有查询必须带租户 |
| `chat_id`、`group_id` | 二选一；单聊仅 chatId，群聊 chatId+groupId |
| `mode` | `DIRECT/GROUP` |
| `call_type` | `AUDIO/VIDEO` |
| `state` | 下表枚举 |
| `owner_id` | 单聊=caller；群聊=发起人，拥有结束全体权限 |
| `livekit_room` | `t_{tenantId}_call_{callId}`，只由服务端生成 |
| `accepted_device_id` | 仅单聊使用 |
| `connected_at/ended_at/end_reason/version` | 审计、时长、乐观锁 |

群成员表 `ImCallParticipantDO` 必须是群通话唯一成员事实源：`call_id,user_id,invite_state,join_state,joined_at,left_at,device_id`；唯一索引 `(call_id,user_id)`。单聊不使用群成员表。

### 3.2 状态机

```text
DIRECT: CREATED -> RINGING -> ACCEPTED -> CONNECTED -> ENDED
                            \-> REJECTED/CANCELLED/TIMEOUT/BUSY/FAILED
GROUP : CREATED -> RINGING -> ACTIVE -> ENDED
                            \-> CANCELLED/TIMEOUT/FAILED
```

- 单聊 `accept` 必须执行 `UPDATE ... WHERE state=RINGING AND accepted_device_id IS NULL`；受影响行数为 1 才是胜者。其他端返回 `CALL_ALREADY_ANSWERED` 并收到 ended。
- 群聊首次任意成员成功 join 时，`RINGING -> ACTIVE`；发起人未入房且所有成员拒绝/超时，才 `TIMEOUT`。群内至少一人时不因某成员拒绝而结束会话。
- 同一用户任一活跃状态（`RINGING/ACCEPTED/CONNECTED/ACTIVE`）只能属于一个 call。群聊邀请时，忙线成员写为 `BUSY` participant，不影响其他成员。
- 所有状态变化都必须在同一数据库事务内：条件更新 → 写事件 outbox → 写审计/记录。事件由事务提交后异步投递；不得先发 WebSocket 再落库。

## 4. API、事件与 Token 契约

### 4.1 API

| Method | URL | 请求 | 权限/结果 |
|---|---|---|---|
| POST | `/system/im/call/direct` | `chatId,calleeId,callType` | 校验单聊双方成员，创建 RINGING |
| POST | `/system/im/call/group` | `chatId,groupId,inviteeIds,callType` | 发起人必须群成员；被邀 1~8 人，总人数上限 9 |
| POST | `/system/im/call/{callId}/accept` | `deviceId` | 单聊唯一接听；群聊加入 |
| POST | `/system/im/call/{callId}/reject` | `deviceId` | 单聊终态；群聊仅本成员拒绝 |
| POST | `/system/im/call/{callId}/cancel` | 空 | 仅 RINGING 的 owner 可取消 |
| POST | `/system/im/call/{callId}/leave` | `deviceId` | 群成员离开；单聊等同 hangup |
| POST | `/system/im/call/{callId}/end` | 空 | 单聊任意参与方；群聊仅 owner 结束全体 |
| POST | `/system/im/call/{callId}/connected` | `deviceId` | 报告 LiveKit 已连接，幂等 |
| GET | `/system/im/call/{callId}` | 空 | 授权用户获取状态与当前 roster |

`accept` 成功响应仅此时返回：`callId,roomName,serverUrl,accessToken,expiresAt,participants`。Token 有效期 10 分钟；Token 仅包含此 room 的 join/publish/subscribe 权限，identity=`tenant:user:device`。任何 invite/push/socket 事件均不得包含 RTC Token。

### 4.2 系统事件

所有事件经 `CallEventPublisher` 发到 `SYSTEM_NOTIFY`，格式固定：

```json
{"type":"call.invite","callId":"uuid","version":1,"occurredAt":0,"payload":{}}
```

| type | 接收者 | payload 最小字段 |
|---|---|---|
| `call.invite` | 被叫/被邀成员 | `mode,callType,chatId,groupId,owner{id,name,avatar},expireAt` |
| `call.accepted` | 单聊主叫+胜出被叫 | `acceptedDeviceId` |
| `call.group-active` | 所有群成员 | `participantId,userId,joinedAt` |
| `call.participant-left` | 当前群成员 | `userId,leftAt` |
| `call.ended` | 所有相关用户 | `reason,endedAt,durationSeconds` |
| `call.busy` | 主叫或群发起人 | `userId` |

客户端按 `(callId,version)` 去重。收到版本跳跃、冷启动、网络恢复时调用 GET state 对账；对账结果覆盖本地 UI。

## 5. LiveKit 与部署设计

### 5.1 组件

每个客户环境部署 `livekit-server + redis + coturn + reverse-proxy`；可选 Egress 不进入 P0。必须使用官方 Apache-2.0 LiveKit Server、`livekit_client` 和 `livekit_components`，版本写入客户交付兼容矩阵。

- 开发环境可 Docker Compose；生产单机 VM 起步，容量/高可用另行通过 Kubernetes/Helm 扩展。
- 客户必须提供可由移动端访问的 DNS、TLS 证书、UDP 端口段及 TURN/TLS；禁止开发机 `.local`、`localhost`、硬编码内网 IP。
- 每个客户独立 API key/secret、Redis、TURN 长期密钥；密钥存部署环境变量或密钥管理服务，App 永不持有。
- Java 后端使用 LiveKit 官方 Server SDK 签发 Token，并验证 LiveKit webhook 签名；webhook 只做离线补偿和审计，不改变用户已显式结束的终态。

### 5.2 Flutter 媒体适配

`LiveKitGateway` 封装且只封装：`connect(token)`、`setMicrophoneEnabled`、`setCameraEnabled`、`switchCamera`、`setSpeakerphone`、`disconnect`、`events`。页面使用 LiveKit Components 进行视频渲染和控制栏基础实现，但最终 UI 由本项目 widget 统一封装，保证可换肤并可出售。

短网断时 SDK 自身重连；`CallOrchestrator` 显示“网络恢复中”。持续 15 秒未连接，调用 `/end`（群聊调用 `/leave`），进入正常终态并释放设备。不得自己重新建 WebSocket、重发 SDP 或重建不同 room。

## 6. 来电、推送、页面规则

### 6.1 系统来电

- 前台：Socket `call.invite` → `IncomingCallPage`，铃声只由 `NativeCallUiGateway` 单例管理。
- Android 后台/锁屏：FCM 高优先级 data push + 原生全屏通话通知/ConnectionService；接听/拒绝回调到同一 Orchestrator。
- iOS 后台/锁屏：APNs VoIP Push + CallKit；PushKit 收到 callId 后必须先向后端 GET state，确认仍 RINGING 才报告来电。
- 采用 `flutter_callkit_incoming`，封装在 `NativeCallUiGateway`；插件不可散落在 page/controller。
- 推送只携带 `callId`、昵称、头像 URL、通话类型和过期时间；接听前必须再请求服务端，防止过期或伪造邀请。

### 6.2 最小 UI

单聊来电/去电页：头像、昵称、语音/视频文案、红色拒绝/取消、绿色接听、30 秒倒计时。单聊视频通话中：远端全屏、本地小窗、静音/扬声器/摄像头/翻转/挂断。语音：头像、时长和四项控制。

群聊：发起页只允许从群成员选择 1~8 位被邀成员；来电页显示发起人和群名；通话中以最多 9 格显示已加入参与者，未加入用户不占媒体格。所有成员可 leave，只有 owner 显示“结束全体”。不做通话中邀请。

## 7. 详细任务、文件动作与完成条件

### 阶段 A：替换准备

1. 新建 feature flag `im.call.provider=janus|livekit`，默认 janus；一个 `callId` 只能绑定一种 provider。
2. 新建 `docs/` 中的 LiveKit Compose、环境变量模板、网络验证脚本；在两台真机完成 LiveKit SDK 原生示例通话。
3. 添加依赖 `livekit_client`、`livekit_components`、`flutter_callkit_incoming`；锁定版本和许可清单。

**门禁**：不改现网通话；本地和测试环境 LiveKit HTTPS/WSS/UDP/TURN 全通过。

### 阶段 B：后端替换

1. 新建 `ImCallApplicationService`、`LiveKitTokenService`、`CallEventPublisher`、outbox 表/消费者和 LiveKit webhook controller。
2. 重写 `AppCallController` 的上述 API，删除 controller 中 `publishInvite/publishStateEvent/publishMediaTokenEvents` 这类拼装逻辑。
3. 重写 `ImCallServiceImpl/GroupCallService` 的生命周期为本文状态机；删除 `JanusRoomManager` 和 Janus token/room 代码。
4. 在 websocket starter 新增 `CallEventPublisher`，业务层不再直接调用 `NettyMessageSender`。
5. 增加数据库迁移、MyBatis 原子条件更新、单元/集成并发测试。

**门禁**：并发双 accept 仅一人成功；单聊/群聊所有终态幂等；服务端不再产生 Janus URL、room 或 token。

### 阶段 C：Flutter 替换

1. 完整新建 `call_v2`，从聊天页和群聊天页接入新入口；禁止调用旧 use case。
2. 实现 API/Socket 对账、单一 Orchestrator、单聊和群聊三种页面（来电、去电、通话中）。
3. 实现 `LiveKitGateway` 与音频/视频控制，接入真实设备权限；实现所有资源释放和恢复。
4. 实现 NativeCallUiGateway、FCM/APNs VoIP/CallKit；冷启动必须通过 GET state 恢复。
5. 迁移通话记录气泡和历史页到 v2 DTO/API。

**门禁**：Android↔Android、iOS↔iOS、Android↔iOS 的单聊音频和视频连续各 10 次通过；群 3 人音频、群 3 人视频各 10 次通过。

### 阶段 D：灰度与清理

1. 内部租户灰度 7 天；监控 create、push、accept、LiveKit connect、end 和失败原因。
2. 达到发布门禁后默认 livekit；保留 Janus 回滚 30 天。
3. 删除第 2.1 列出的旧 Flutter Janus 文件、`JanusRoomManager`、Janus Docker 配置、`janus.*` 属性、Janus 测试与文档；清理不再使用的 `CALL_SIGNAL`。

## 8. 测试、观测与发布门禁

必须覆盖：单聊/群聊语音视频、取消/拒绝/超时/忙线、双端同时接听、多设备接听、权限拒绝、前台后台锁屏、Wi-Fi/蜂窝切换、断网 5 秒与 20 秒、连续 20 次、服务端重启后的 state 对账、跨租户/伪造 callId/过期 Token。

发布门禁：

1. Android/iOS 真实设备 P0 用例 100% 通过，阻塞缺陷为 0。
2. 单聊双向与群 3 人通话成功率：连续 20 次均成功；失败后 60 秒内所有相关用户可再次发起。
3. 双 accept 并发 100 次无双赢家；所有终态 API 重复调用均成功返回当前事实状态。
4. 日志可按 `tenantId + callId` 关联 API、outbox、WebSocket、Push、LiveKit webhook；不得记录 access token、API secret、VoIP 凭证。
5. 一键部署到全新客户环境后，不依赖开发机、外部 Janus 或 RTC 云域名。

## 9. AI 实施约束

1. 严格按阶段实施，阶段门禁未通过不得开始下一阶段。
2. 任何无法确认的现有行为先用代码/测试验证；不能依据旧设计文档推测。
3. 每一个 PR 必须列出新增/删除文件、数据库迁移、接口兼容性、自动化测试、真机验证、回滚步骤。
4. 不得为了兼容而在 LiveKit 链路继续保留 Janus media client；只允许 feature flag 层面短期二选一。
5. 遇到 iOS/Android 系统限制要明确报告，不得把失败隐藏为“连接中”或用无上限定时器重试。

## 10. 源码审计结论与精确迁移映射

本节基于以下实际源码完成，AI 实施前必须再次执行编译级引用搜索确认：

| 当前位置 | 审计结论 | 重构动作 |
|---|---|---|
| `AppCallController#createInvite/accept/reject/cancel/hangup` | Controller 既发业务事件又签发媒体凭证，accept 后还同时发布 state/group/token 三类事件 | 保留 REST 职责；所有编排迁入 `ImCallApplicationService`；Controller 只返回 service VO |
| `AppCallController#getCallToken` | 按 Janus `roomId` 直接签 Token，生命周期边界错误 | 删除；LiveKit Token 只由 accept/join 成功响应返回 |
| `AppCallController#createGroupInvite/group/invite/group/leave` | 存在“原子创建群通话”和“既有通话追加邀请”两种群模型 | 保留一次性创建群通话与 leave；删除通话中追加邀请 API 与页面功能 |
| `publishInvite/publishStateEvent/publishMediaTokenEvents/publishGroup*` | Controller 私有方法直接拼 JSON、直调 `CallPushService`，事件可能与 DB 事务脱节 | 全部删除，替换为 outbox + `CallEventPublisher` |
| `ImCallServiceImpl`、`GroupCallService`、`CallSignalProcessor` | 业务状态与 Janus 房间/Token/Socket 发信交织 | 保留通话记录与成员权限规则；拆出 application service；删除 Janus 和上行 Call Signal 生命周期 |
| Flutter `call_controller.dart/call_coordinator.dart/call_media_controller.dart` | 多个对象共同维护页面、媒体和恢复状态，是当前状态错乱根源 | 不迁移实现；以单一 `CallOrchestrator` 替换 |
| Flutter `call_socket_data_source.dart` | 已能从 `SYSTEM_NOTIFY` 解析 `call.` 事件 | 可复用解析思路，但迁入 v2，按固定 envelope/version 对账 |
| Flutter `rtc_room_bundle.dart` | Janus URL/TURN/JWT 领域模型 | 删除；以 `LiveKitConnectionInfo(roomName,serverUrl,accessToken,expiresAt)` 替代 |
| WebSocket `NettyMessageSender` | 已支持 tenant、receiver、group、extra 和全设备投递 | 不改其基础发送语义；新增上层 `CallEventPublisher` 防止业务层直接调用 |
| `im_message.proto` | `SYSTEM_NOTIFY=200` 可复用；`CALL_SIGNAL=206` 已定义但不是 P0 必需 | 保留前者；后者先引用审计，再删除/弃用，变更 proto 必须重新生成并验证 JSON/PB 双 codec |

### 10.1 旧 API 兼容与下线

旧 API `/create-invite`、`/token`、`/group/create-invite`、`/group/invite`、`/group/leave` 不得静默改变语义。灰度期以 provider 路由适配：旧客户端仅走 Janus，版本达到 `minLiveKitCallVersion` 的新客户端仅走新 API；服务端依据客户端版本和 feature flag 拒绝跨 provider 接听。灰度结束后先返回明确 `CALL_PROVIDER_RETIRED`，观察 30 天再删除旧 endpoint/VO/use case。不得让一个 room 同时被 Janus 和 LiveKit 消费。

### 10.2 数据库、Outbox 与清理任务

新增 `im_call_event_outbox`：`id,tenant_id,call_id,event_type,event_version,payload,status,retry_count,next_retry_at,created_at,published_at`，唯一键 `(call_id,event_version)`。事务内更新会话/成员/记录并插入 outbox；提交后消费者发送 WebSocket、离线 Push，失败按指数退避，最终告警而非回滚已完成业务状态。

新增或调整枚举而非继续复用模糊的页面状态：`CallMode`、`CallState`、`CallEndReason`、`ParticipantInviteState`、`ParticipantJoinState`。数据库迁移必须为历史 Janus 记录写 `provider=JANUS_LEGACY`，新记录写 `provider=LIVEKIT`；历史记录只读可查，禁止用新 LiveKit API 操作。

后台任务每分钟处理：RINGING 到期、ACCEPTED 长时间未连接、群通话无人加入、终态 room 数据清理。任务是兜底而非唯一正确性来源；create 与 accept 仍必须同步检查并回收过期会话。

### 10.3 安全、审计和运维体系

- 所有 call API 限流：同用户 create 每分钟 5 次、accept/reject/end 每 callId 每 5 秒 3 次；超限返回明确业务码。
- 创建单聊必须验证双方均是 chat 成员；创建群聊和每个 invitee 必须验证群成员身份、租户一致、群未解散；不信任请求中的 userId、groupId、roomName。
- LiveKit API secret、TURN long-term secret、APNs key、FCM 服务账号只允许部署侧密钥管理；日志、数据库 event payload、客户端 analytics 均需脱敏。
- 记录 `CALL_CREATED/CALL_ACCEPTED/CALL_CONNECTED/CALL_ENDED` 审计事件，字段含 tenantId、callId、actorId、deviceId、reason、traceId，不记录媒体内容。
- 健康检查至少暴露：后端 Token 签发、Redis/outbox backlog、LiveKit HTTPS、TURN UDP/TLS；监控 create→invite、invite→accept、accept→connected、connected→end 的耗时与失败率。

### 10.4 交付文档体系

实施完成必须同时提交以下文件，缺一不可：架构图与端口表、Docker Compose、Kubernetes values、环境变量说明、证书/TURN/防火墙检查、容量估算、监控告警、升级回滚、密钥轮换、故障排查、API/OpenAPI、数据库迁移、Flutter Android/iOS 推送配置、测试报告和第三方许可证清单。客户交付包不得引用开发电脑路径、个人域名、测试账号或共享密钥。
