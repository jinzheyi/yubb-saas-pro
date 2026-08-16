# IM 最小可售卖音视频通话模块（LiveKit 私有化）需求与实施任务书

**版本**：v1.0  
**日期**：2026-08-16  
**状态**：待实施；本文件是后续 AI/研发的唯一 P0 实施依据  
**适用端**：Flutter Android、iOS；Web 仅保留加入房间与基础通话能力，不承诺系统级来电唤醒  
**目标客户**：需要在自有网络、私有云或客户现场部署企业 IM 的购买方

---

## 1. 执行结论与强制边界

本项目不再修补现有 `Janus + flutter_webrtc + 自研 Janus 信令/订阅` 通话链路。P0 采用：

```text
Flutter Call Module  ── WSS/WebRTC ──> LiveKit Server（客户自托管）
          │                                  │
          ├─ HTTPS ──> IM 后端（鉴权、Token、记录、裁决）
          └─ Push ──> APNs VoIP / FCM（系统来电唤醒）
```

媒体协商、SDP、ICE、TURN 选择、发布/订阅、媒体重连全部由 LiveKit SDK/Server 负责；业务后端不得再直接操作 WebRTC 或模拟媒体信令。业务后端只负责用户权限、通话业务状态、Token 签发、通话记录和系统推送。

**技术选择**：LiveKit Server、LiveKit Flutter SDK、LiveKit Flutter Components（均 Apache-2.0）；`flutter_callkit_incoming`（MIT）用于系统来电 UI。所有第三方 Flutter 源码须以明确版本锁定，并建议镜像/供应商化到本仓库或企业制品库。

**本期只交付 1v1 语音与 1v1 视频。** 任何群通话、录制、屏幕共享、视频美颜、呼叫等待、多端同时接听、通话转接均不在 P0 范围内。

---

## 2. P0 目标、非目标与验收红线

### 2.1 P0 必须具备

1. 单聊页可发起 1v1 语音或视频通话。
2. 被叫 App 前台显示完整 Flutter 来电页；后台/锁屏时 Android 显示通话通知，iOS 通过 VoIP Push 显示 CallKit 来电页。
3. 接听后双方进入统一的通话中页面，并正常传输语音/视频。
4. 支持：接听、拒绝、取消、挂断、30 秒无应答、忙线、静音、扬声器开关、摄像头开关、前后摄切换、通话时长。
5. 网络短暂切换或抖动时，SDK 自动恢复媒体；超过 15 秒未恢复则安全结束通话并记录原因。
6. 每次通话在双方会话中落一条可查询的通话记录；不会因失败留下“用户通话中”的脏状态。
7. 可使用 Docker Compose 在客户局域网部署；生产环境提供 VM/Kubernetes 部署说明、TLS 和 TURN 配置。

### 2.2 明确不做

- 不实现 Janus Client、手工 `RTCPeerConnection`、SDP/ICE trickle、VideoRoom handle。
- 不把 `SYSTEM_NOTIFY` 当作 RTC 传输协议；它只能传递业务邀请/状态。
- 不要求浏览器关闭后仍可像原生 App 一样被可靠唤醒。
- 不实施端到端加密、录制、转写、多人会议、屏幕共享、悬浮窗、呼叫等待。
- 不允许客户端自签 RTC Token、指定任意 room、篡改被叫用户。

### 2.3 不可妥协的验收红线

- 接听/拒绝/挂断接口必须幂等；重复回调不得产生异常或重复记录。
- 通话业务状态只由后端原子裁决；客户端 UI 状态不是事实来源。
- 每个 1v1 会话只允许一台被叫设备接听。P0 若同一账号多设备在线，后端选择**最近活跃设备**推送；其余设备仅显示“已在其他设备接听”。
- Token 仅对指定用户、指定房间、最短有效期有效；不得把 API secret 或 token 签名密钥打包进 App。
- 所有音视频服务地址必须使用可访问的 DNS 域名和 TLS（`wss://` / `https://`）；生产禁止依赖 `.local`、固定 LAN IP、`ws://`。

---

## 3. 产品交互与状态定义

### 3.1 页面

| 页面 | 触发 | P0 元素 | 离开条件 |
|---|---|---|---|
| 去电页 | 主叫创建成功 | 对方头像/昵称、语音或视频标识、取消、30 秒倒计时 | 接听、拒绝、忙线、超时、取消 |
| 来电页 | 前台业务邀请 | 头像/昵称、来电类型、拒绝、接听、铃声 | 接听、拒绝、取消、超时、其他设备接听 |
| 系统来电 | 后台/锁屏推送 | iOS CallKit / Android 高优先级全屏通知 | 原生接听或拒绝后回到 Flutter |
| 通话中页 | 后端确认接听且 LiveKit 已连接 | 本地/远端画面；语音时头像；时长；静音、扬声器、摄像头、翻转、挂断 | 本地/远端结束或重连超时 |
| 结束页 | 结束后 | 不单独停留；返回原会话，展示记录消息 | 自动返回 |

### 3.2 业务状态机（后端权威）

```text
CREATED -> RINGING -> ACCEPTED -> CONNECTED -> ENDED
                  \-> REJECTED
                  \-> CANCELLED
                  \-> TIMEOUT
                  \-> BUSY
                  \-> FAILED
```

- `CREATED`：创建记录但尚未发送邀请；只允许极短事务内存在。
- `RINGING`：邀请已持久化并尝试投递；主叫可取消、被叫可接听/拒绝。
- `ACCEPTED`：后端已原子选定被叫设备、签发双方短期 LiveKit Token。
- `CONNECTED`：至少双方都已报告加入 LiveKit 房间；仅用于记录时长，不影响媒体本身。
- 终态：`REJECTED/CANCELLED/TIMEOUT/BUSY/FAILED/ENDED`，一旦进入不可逆。

客户端只使用以下 UI 状态：`idle`、`outgoingRinging`、`incomingRinging`、`connectingMedia`、`inCall`、`ending`。客户端收到任何与当前 `callId` 不匹配的事件必须忽略。

### 3.3 关键时序

1. 主叫请求创建；后端校验单聊成员、租户、黑名单、双方忙线。
2. 后端原子插入 `RINGING` 记录，选择目标设备，发送业务邀请和离线推送。
3. 被叫接听；后端用条件更新 `RINGING -> ACCEPTED` 裁决唯一接听者。
4. 后端为双方签发同一 LiveKit room 的短期 Token，分别发送 `call.accepted`。
5. 双方收到 Token 后才连接 LiveKit；连接成功后报告 `media-connected`。不得在 `RINGING` 时预连房间。
6. 任意一方挂断，后端原子进入终态，广播结束；客户端立即离开房间并释放相机、麦克风、音频会话。

---

## 4. 服务端设计

### 4.1 数据模型

现有 `im_call_record` 可迁移；必须新增/确认以下字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `call_id` | varchar(64), unique | UUID，业务通话唯一标识 |
| `tenant_id` | bigint | 租户隔离键 |
| `chat_id` | bigint | 单聊会话 ID |
| `caller_id` / `callee_id` | bigint | 发起与被叫用户 |
| `call_type` | tinyint | `1=audio,2=video` |
| `state` | varchar(24) | 本文状态机值 |
| `accepted_device_id` | varchar(128) nullable | 唯一接听设备 |
| `livekit_room` | varchar(128) unique | `t_{tenantId}_c_{callId}`，不可由客户端传入 |
| `started_at` / `connected_at` / `ended_at` | datetime | 生命周期时间 |
| `end_reason` | varchar(32) | 用户行为/系统失败原因 |
| `version` | int | 乐观锁版本 |

建立索引：`(tenant_id, caller_id, state)`、`(tenant_id, callee_id, state)`、`(call_id)` unique、`(livekit_room)` unique。忙线查询只认 `RINGING/ACCEPTED/CONNECTED`，事务内用条件更新或行锁保证并发安全；禁止“先查再插”。

### 4.2 HTTP API

所有接口要求现有登录态、租户上下文和 `X-Device-Id`。响应使用现有统一 `CommonResult`。

| 方法 | 路径 | 请求 | 结果 |
|---|---|---|---|
| POST | `/app-api/im/call/create` | `chatId,calleeId,callType` | `callId,state=RINGING` |
| POST | `/app-api/im/call/{callId}/accept` | 无 | `room,url,token,expiresAt` |
| POST | `/app-api/im/call/{callId}/reject` | `reason=declined` | 204/成功 |
| POST | `/app-api/im/call/{callId}/cancel` | 无 | 204/成功 |
| POST | `/app-api/im/call/{callId}/hangup` | 无 | 204/成功 |
| POST | `/app-api/im/call/{callId}/media-connected` | 无 | 204/成功 |
| GET | `/app-api/im/call/{callId}` | 无 | 当前权威状态；用于冷启动恢复 |

错误码：`CALL_NOT_FOUND`、`CALL_PERMISSION_DENIED`、`CALL_BUSY`、`CALL_NOT_RINGING`、`CALL_ALREADY_ANSWERED`、`CALL_TERMINAL`、`RTC_UNAVAILABLE`。终态的 reject/cancel/hangup 返回成功并附当前状态，确保客户端可安全重试。

### 4.3 业务事件

沿用 IM WebSocket `SYSTEM_NOTIFY`，但事件只承载业务数据，统一 envelope：

```json
{
  "type": "call.invite|call.accepted|call.ended|call.timeout|call.busy",
  "callId": "uuid",
  "version": 3,
  "occurredAt": 1780000000000,
  "payload": {}
}
```

- `call.invite`：`callerId,callerName,callerAvatar,chatId,callType,expireAt`；**不含 RTC Token**。
- `call.accepted`：`acceptedDeviceId,room,url,token,expiresAt,callType`；只发送给主叫和被裁决接听设备。
- `call.ended`：`reason,endedAt,durationSeconds`。
- 客户端应按 `version` 去重；每个 callId 只接受版本更大的事件。

### 4.4 Token 服务与 LiveKit 权限

新增 `LiveKitTokenService`，使用 LiveKit 官方 Java Server SDK，密钥只存服务端配置/密钥管理服务。Token 必须：

- identity = `tenantId:userId:deviceId`；metadata 写入 `callId`。
- roomJoin=true，room=当前 `livekit_room`，有效期 10 分钟。
- P0 不授予 roomAdmin、录制、数据消息管理等额外权限。
- 仅在 `ACCEPTED` 之后签发；Token 刷新只允许未终态且当前接听设备。

后端可通过 LiveKit Webhook 验签补偿 `participant_joined/participant_left/room_finished`，但 webhook 是补偿源，不替代显式挂断 API。

---

## 5. Flutter 模块设计

### 5.1 代码边界

新模块路径：`lib/features/im/call_v2/`。禁止在旧 `features/im/call/` 内继续新增功能；旧模块只保留到迁移开关删除。

```text
call_v2/
  domain/          CallSession, CallState, CallRepository
  application/     CallOrchestrator（唯一业务协调入口）
  infrastructure/  CallApi, CallSocketGateway, LiveKitGateway, CallPushGateway
  presentation/    IncomingCallPage, OutgoingCallPage, InCallPage, widgets/
  platform/        NativeCallUiGateway（CallKit/Android 通知）
```

`CallOrchestrator` 是唯一可改变 UI 状态的对象；不得再拆分多个互相写状态的 Controller。其依赖仅包括 API、Socket、LiveKit、NativeCallUi、Clock、DeviceIdentity。所有依赖必须可 mock。

### 5.2 LiveKit 使用规则

- 使用 `livekit_client` 连接、发布和离开房间，使用 `livekit_components` 作为通话中页面控件/渲染基础。
- 禁止调用 `createPeerConnection`、`RTCSessionDescription`、手工 ICE 发送、手工 WebSocket 连接媒体服务器。
- Token 到达后创建一个 `Room`；通话结束必须按顺序 `disconnect -> dispose -> stop native audio/call UI`。
- `RoomEventConnected` 后调用 `media-connected`；`RoomEventDisconnected` 若非用户主动挂断，进入 `connectingMedia`，15 秒内由 SDK 重连，否则调用 hangup(reason=media_failed)。
- 语音通话默认不开摄像头；视频通话默认开前摄。仅在用户授权后启用轨道。

### 5.3 原生来电与推送

| 场景 | Android | iOS |
|---|---|---|
| 前台 | Flutter `IncomingCallPage` | Flutter `IncomingCallPage` |
| 后台/锁屏 | FCM 高优先级 data message + 全屏通话通知/ConnectionService | APNs VoIP Push + CallKit |
| 点击接听 | 拉起 App，调用 accept API，再进入通话页 | CallKit action 回调，调用 accept API，再进入通话页 |
| 点击拒绝 | 调用 reject API | 调用 reject API |

使用 `flutter_callkit_incoming` 但须封装为 `NativeCallUiGateway`，业务层不得直接调用插件。iOS 必须配置 PushKit、CallKit、后台 `voip` 能力；Android 必须配置通知权限、前台服务、Android 13+ 通知权限及厂商推送策略。Push payload 只含 `callId`、显示信息和过期时间，绝不能含 LiveKit Token。

### 5.4 UI 最小规范

- 来电/去电：深色渐变背景、头像、昵称、类型文案、清晰的红/绿操作按钮；支持无头像兜底。
- 通话中：视频为远端全屏+本地右上角小窗；语音为头像+昵称+时长；底部固定五项：静音、扬声器、摄像头、翻转（视频时）、挂断。
- 每个按钮必须有 loading/disabled 状态，避免连续点击产生多个 API 请求。
- 结束时先关闭页面/系统 UI，再释放媒体；不会遗留铃声、前台服务、相机或音频焦点。

---

## 6. 私有化部署要求

### 6.1 最小部署单元

```text
customer-im-backend + customer-im-db + redis
livekit-server + coturn + reverse-proxy(Caddy/Nginx)
```

- 开发：Docker Compose；生产：单 VM 起步，规模化使用 Kubernetes/Helm。
- 每个客户独立 LiveKit API key/secret、Redis、域名、TURN 凭证；严禁多客户共享密钥。
- 外网部署必须有 `rtc.customer-domain`、`turn.customer-domain` 两个 DNS 名称及有效 TLS 证书。
- 防火墙至少放行 HTTPS/WSS、UDP RTP 端口范围、TURN UDP/TCP/TLS；具体端口来自该客户的 LiveKit 配置，文档必须随部署包交付。
- 内网部署必须由客户网络管理员确认 NAT、DNS、移动终端访问和 UDP 策略；不能用开发机 `.local` 名称作为产品方案。

### 6.2 交付物

1. `deploy/livekit/docker-compose.yml`、`.env.example`、`livekit.yaml`、Coturn 配置模板。
2. Helm chart 或 values 示例、升级与回滚手册。
3. 部署前检查脚本：DNS、TLS、TCP/WSS、UDP/TURN、Token、房间连通性。
4. 客户侧密钥清单、备份恢复和日志脱敏说明。
5. 版本兼容矩阵：App、后端、LiveKit、Redis、Coturn 的已验证版本。

---

## 7. 实施任务分解（按顺序，不得跳步）

### Phase 0：冻结与基线

- [ ] 在配置中新增 `im.call.provider=janus|livekit`；默认 `janus`，所有新代码只在 `livekit` 下启用。
- [ ] 停止向旧 CallController 新增功能；记录旧模块可删除文件清单。
- [ ] 创建两台真实 Android/iOS 测试设备、两个测试账号、可观测日志会话。
- [ ] 建立 P0 冒烟脚本和 10 次连续呼叫基线。

**完成条件**：不影响现网 IM；可随时切回 Janus。

### Phase 1：基础设施与服务端

- [ ] 在本地 Docker 与测试环境部署 LiveKit、Redis、Coturn、TLS 反向代理。
- [ ] 完成 Java `LiveKitTokenService`、配置属性、健康检查与 webhook 验签。
- [ ] 实现数据迁移、原子忙线裁决、六个 HTTP API、业务 WebSocket 事件。
- [ ] 实现 30 秒超时任务作为兜底；同时在 create 前同步回收过期 `RINGING/ACCEPTED`。

**完成条件**：通过 Postman/API 测试覆盖 create/accept/reject/cancel/hangup 的幂等和并发。

### Phase 2：Flutter 前台最小通话

- [ ] 创建 `call_v2`，实现 API/Socket 映射和 `CallOrchestrator`。
- [ ] 集成 LiveKit SDK/Components，完成 Android ↔ Android、iOS ↔ iOS、Android ↔ iOS 的语音/视频。
- [ ] 实现前台来电、去电、通话中页面及所有 P0 控件。
- [ ] 实现断网、媒体失败、路由返回、应用前后台切换的清理逻辑。

**完成条件**：每种方向连续 10 次通话，无卡死、无忙线残留、无相机/麦克风占用。

### Phase 3：后台来电与生产化

- [ ] 接入 Android FCM/厂商推送和 iOS APNs VoIP/CallKit。
- [ ] 封装 NativeCallUiGateway，完成锁屏接听/拒绝与冷启动恢复。
- [ ] 接入通话记录消息、监控指标、结构化日志与故障诊断页。
- [ ] 完成客户部署包、环境检查、升级/回滚、运维手册。

**完成条件**：真实设备后台、锁屏、冷启动均可完成接听或拒绝；部署文档可由非研发运维独立复现。

### Phase 4：灰度与删除旧实现

- [ ] 仅内部租户开启 `livekit`，观察至少 7 天。
- [ ] 指标达标后，默认切到 LiveKit。
- [ ] 保留旧 Janus 只读回滚窗口 30 天；之后删除旧 RTC 客户端和 Janus 配置，不允许双链路长期并存。

---

## 8. 测试矩阵与发布门禁

### 8.1 必测用例

| 类别 | 用例 | 预期 |
|---|---|---|
| 基础 | A 呼叫 B，语音/视频 | 双方页面正确、双向媒体正常 |
| 状态 | 取消、拒绝、忙线、30 秒超时 | 双方退出，记录与原因正确 |
| 并发 | A 与 C 同时呼叫 B | 仅一条会话可响铃；另一条忙线 |
| 多设备 | B 手机与平板在线 | 仅目标设备可接听；其他端正确结束 |
| 网络 | Wi-Fi↔蜂窝切换、断网 5 秒/20 秒 | 5 秒自动恢复；20 秒安全结束 |
| 权限 | 拒绝麦克风/相机 | 给出可操作提示，不进入假连接状态 |
| 生命周期 | 前台、后台、锁屏、冷启动 | 按平台能力正确接听/拒绝 |
| 资源 | 连续 10 次语音和 10 次视频 | 无残留铃声、前台服务、相机占用、忙线记录 |
| 隔离 | 不同租户、伪造 callId/token | 无越权查询、接听或进房 |

### 8.2 发布门禁

- P0 用例 100% 通过；阻塞级缺陷为 0。
- 连续 20 次 Android↔iOS 视频通话成功率 100%；50 次 API 并发裁决无重复接听。
- 失败通话后 60 秒内两位用户均可再次发起新通话。
- 日志可通过 `callId` 串起 create、push、accept、token、connect、end 全链路；日志不得打印 Token、secret、完整推送凭证。
- 客户私有化环境不依赖开发机 IP、局域网 mDNS 或外部 RTC 云域名。

---

## 9. AI 实施约束

1. 先完成 Phase 0/1 的 API、并发测试和 LiveKit 可观测性，再写 Flutter UI。
2. 每次修改只完成一个 Phase 中可独立验证的任务；必须附自动化测试、手工真机验证步骤和回滚说明。
3. 不得删除旧 Janus 代码，直到 Phase 4 灰度门禁通过；不得让两套 RTC 同时处理同一 `callId`。
4. 不得使用临时硬编码的 API key、API secret、Token、LAN IP 或 `.local` 域名。
5. 每个网络/推送/媒体异常必须映射为有限的 `CallEndReason`，禁止吞异常后保持“通话中”。
6. 遇到平台限制必须明确报告并停止扩大范围；禁止以“再加一个定时器”掩盖状态不一致。

---

## 10. 决策记录

- LiveKit 的核心服务、Flutter SDK 与官方组件均采用 Apache-2.0，允许商业分发、修改和私有化部署。
- 选择 LiveKit 不是为了得到零代码“微信 UI”；它的价值是把最易出错的媒体链路交给有版本化 SDK 的开源系统，同时把可销售的业务 UI、权限与部署控制留在本产品。
- 系统级来电仍依赖 Apple PushKit/CallKit 与 Android 推送/系统通知，这是操作系统能力，任何私有化 RTC 方案都无法绕开。
- 旧设计文档 `docs/im-rtc-call-system-design.md` 和 `sql/flutter-doc/IM-Flutter音视频通话企业级设计-v1.0.md` 中的 Janus 方案不再作为 P0 实施依据；保留仅供历史追溯。
