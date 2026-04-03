# IM 即时通讯架构设计文档 v2.0

> **文档版本**: v2.0.0  \
> **创建日期**: 2026-03-05  \
> **项目**: 圣钰 SaaS Pro - IM 即时通讯系统  \
> **定位**: 企业内部 IM（组织架构即通讯录，无需社交链）  \
> **目标体验**: 对齐企业微信/钉钉（统一鉴权、不断链续期、后台 presence 收敛、多端互踢友好提示、离线补偿与可靠性）  \
> **协议策略**: **App Protobuf + H5 JSON（双栈）**  \
> **关联文档**: `sql/doc/IM+HTTP统一鉴权技术设计文档-v2.0.md`

---

## 1. 范围与非目标

### 1.1 范围（In Scope）

- 企业内 IM：单聊、群聊、已读回执、撤回、角标、会话列表、群文件、聊天记录搜索
- 组织架构通讯录：联系人直接来源于同租户的用户与部门数据
- 多端登录：同 deviceType 互踢，不同 deviceType 共存（具体规则以“统一鉴权文档”为准）
- 统一鉴权：HTTP + IM 共享 token 生命周期，支持不断链续期与精确撤销
- 离线与补偿：离线消息拉取、断线补偿、会话未读一致
- 离线推送：优先 DCloud 厂商推送组件；备份方案极光推送

---

## 2. 总体架构

### 2.1 分层与模块

- **客户端（uniappx）**
  - UI：消息列表/聊天页/通讯录/个人中心
  - HTTP：统一请求封装（token/tenant-id 注入、401 刷新、队列重放）
  - IM：WebSocket 长连接（认证、续期、互踢、断线重连、presence gating）
  - 推送：DCloud 推送 SDK（备选极光）

- **系统业务模块（shengyu-module-system）**
  - REST API：会话/消息/群/联系人等
  - IM 业务：SPI 实现（消息存储、认证、缓存、离线推送等）

- **WebSocket 中间件（shengyu-spring-boot-starter-websocket）**
  - Netty Server + SessionManager + MessageProcessor
  - 多设备会话管理、消息路由、心跳与 idle 管控
  - 消息总线：Local/Redis/RocketMQ/Kafka/RabbitMQ

### 2.2 核心设计原则

- **一致性优先**：HTTP 与 IM 共享鉴权与撤销语义，避免“HTTP 刷新导致 IM 断链/被踢”
- **体验优先**：前台无感续期，后台逐步收敛并提示重登（企微/钉钉风格）
- **可靠性优先**：序列号/ACK/幂等/重投/断线补偿闭环
- **可演进**：协议双栈，H5 JSON 便于调试，App Protobuf 优化流量与性能

### 2.3 强制规范：Long 精度（前端 / JSON）

- 所有涉及 ID / 序列号的 `Long` 字段（包含但不限于：`messageId`、`sequence`、`chatId`、`groupId`、`userId`、`targetId`、`tenantId` 等），在 **前端与 JSON 传输层必须按 `string` 处理**，禁止按 JS `number` 持久化或参与去重/索引。
- App/uniapp 对应的后端 **Response VO** 中，所有 `Long` 字段必须使用 `@JsonSerialize(using = ToStringSerializer.class)` 输出为字符串，避免超过 `2^53-1` 时前端精度丢失导致的去重/ACK/排序错误。
- 前端消息/会话模型中，上述字段必须定义为 `string`，仅在排序/比较需要时临时转换（例如 `BigInt`），且不得把转换后的 `number` 写回缓存。

---

## 2.3.1 文档维护规则（必须遵循）

- 本文档与 `IM即时通讯开发任务清单-v2.0.md` 必须以“当前工程代码”为准，不为兼容旧业务保留历史契约。
- **权威来源优先级**（从高到低）：
  - module-system 的 Controller 路由（`AppIm*Controller`）
  - uniappx 的 `api/*.uts`（端侧权威调用口径）
  - uniappx 的 `services/*.uts`（只允许做缓存/聚合，不允许自维护 URL）
- 任一接口/字段在文档中出现时，必须同时给出：
  - 后端路由（URL + Method + 入参形态）
  - 端侧唯一调用点（`api/*.uts` 的函数名）
  - 关键不变式（例如“水位只升不降”、“只以 chatId 作为主键”）

## 2.4 当前工程落地情况（关键落点）

说明：本节用于把“对标企微/钉钉的设计”与“当前工程已落地实现”对齐，便于回归与后续迭代。

### 2.4.1 会话增量同步（cursorVersion）

- **后端**：`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImConversationServiceImpl.java#syncConversations`
  - 数据源：`im_conversation_user_state`
  - 过滤：`cursor_version > cursorVersion`
  - 返回：`nextCursorVersion/hasMore/items`（items 含 `cursorVersion/conversationVersion/lastMessageSequence/lastReadSequence/unreadCount`）

- **前端**：`shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts#syncConversationsIncrementally`
  - 本地存储：按 `tenantId+userId` 维度持久化 cursorVersion
  - reset 策略：本地列表为空但 cursor>0 时强制 reset（避免“刷新后列表为空”）

### 2.4.2 会话幂等/乱序保护（conversationVersion）

- **前端**：`shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts#upsertFromSnapshot`
  - 合并规则：incoming `conversationVersion` 不大于 current 时丢弃，避免旧快照覆盖新状态

### 2.4.3 WebSocket 推送版本透传与补偿

- **后端 WS Sender**：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/sender/NettyMessageSender.java#sendToUser`
  - payload root 透传：`cursorVersion/conversationVersion`
  - cursorVersion 非空时可跳过 snapshot 构建（避免额外查询）

- **前端 WS**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`：AUTH 成功后触发节流补偿 sync（对标企微/钉钉的断线恢复）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts#handleRealtimeCursorVersion`：支持从 WS root 读取 `cursorVersion` 做 gap 检测（snapshot 为空也可补偿）

### 2.4.4 已读水位/角标一致性（对标企微/钉钉）

- **权威接口**：`PUT /system/im/conversation/mark-read-seq?chatId=&readSequence=`
  - **后端**：`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImConversationServiceImpl.java#markConversationReadBySequence` + `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/dal/mysql/im/ImChatUserMapper.java#markReadToSequence`
  - 规则：水位只升不降（GREATEST），并把 `unread_count` 清零

- **短期补充接口（仅用于端到端状态闭环；长期以水位为准）**：`PUT /system/im/message/mark-read?messageIds=...`
  - 说明：用于端侧按 messageIds 快速落“已读”状态（例如已读回执可视化），但未读数/跨端一致仍以 `lastReadSequence` 为权威。

- **角标刷新**：`GET /system/im/badge/get`
  - **后端**：`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImBadgeServiceImpl.java#getBadgeData` -> `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImConversationServiceImpl.java#getConversationBadges`
  - 口径：`unread = lastMessageSequence - lastReadSequence`（与会话列表一致）

- **前端**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/badge-service.uts#clearConversationBadge`：进入会话始终推进服务端已读水位（幂等），避免“本地 badge 未加载导致服务端未清”
  - `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat.uvue`：进入会话上报 readSequence 使用权威 `lastMessageSequence`（并兜底页面消息最大 seq），避免上报 0 导致未清

多端同步（企业级推荐：推送触发 sync，最终态以 sync 为准）：

- 服务端：已读水位推进成功后，写入 `im_conversation_user_state` 并推进 `cursorVersion`
- WS：
  - 推送 `SYSTEM_NOTIFY` 透传 `cursorVersion`（允许不携带 `conversationSnapshot`）用于触发端侧增量 `syncConversations(cursor)`
  - 推送 `BADGE_UPDATE` 用于即时刷新 tab 红点（最终态仍以 sync 为准）
- 端侧：收到 `SYSTEM_NOTIFY` 且无 snapshot 时，触发 `syncConversationsIncrementally(false)` 拉取增量会话状态

端侧交互规则（对标企微/钉钉的“看见即已读/离开即落水位”）：

- **进入会话页**：立即按“当前可见的最大 `sequence`”推进 `lastReadSequence`（服务端幂等），并清空本地角标。
- **会话页停留中**：若收到该会话新消息（WS 实时），视为用户已读：
  - 不增加会话角标
  - 直接推进本地读水位（`applyReadWatermark`）
- **离开会话页（onHide/onUnload/onUnmounted）**：再次按“当前可见最大 `sequence`”推进服务端读水位，确保：
  - 返回会话列表页未读角标立即消失
  - 刷新/重启后从 `GET /badge/get` 或会话列表刷新时仍保持一致

### 2.4.5 群聊摘要一致性（对标企微/钉钉）

- **后端写入**：`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#updateChatUserAsync`
  - 群聊 `last_message_content` 按成员写入 `"我: {摘要}"/"昵称: {摘要}"`（示例文案；兜底 senderId），保证刷新后仍可展示发送者

- **后端读取**：`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImConversationServiceImpl.java#buildPreviewByType`
  - raw 非空优先返回 raw（截断），避免类型占位文案覆盖发送者前缀

- **前端渲染**：`shengyu-ui/shengyu-ui-admin-uniappx/pages/message/message.uvue#buildConversationPreview`
  - raw 非空优先展示 raw（截断），保证推送与刷新一致

### 2.4.6 群消息分页查询口径（对标企微/钉钉）

- **唯一消息分页接口**：`GET /system/im/message/list-by-chat?chatId=&pageNo=&pageSize=`
- **不提供** `list-by-group` 作为长期契约（避免双标准与误用）。
- 端侧若仅持有 `groupId`：必须先通过会话接口映射到 `chatId`（`GET /system/im/conversation/get-by-target?targetId={groupId}&conversationType=2`），再按 `chatId` 拉消息。

### 2.4.7 撤回最终态一致（rev 版，对标企微/钉钉）

说明：本节固化“当前工程已落地”的撤回一致性闭环，目标是确保撤回在 **实时 WS + 断线补偿拉取** 两条链路下均不被旧数据覆盖。

- 服务端数据模型：`im_chat_message.rev`
  - 初始：新消息 `rev = 1`
  - 状态变更：撤回/编辑/删除等“最终态变更”执行 `rev = rev + 1`（原子递增）
  - 输出：REST 查询（`list-by-chat/pull/page`）返回 `rev`，用于端侧合并

- WS 撤回事件（MessageType.RECALL）：
  - 事件体：`RecallMessage{ messageId }`
  - `header.extra`（JSON）最少包含：
    - `rev`
    - `recallBy`
    - `recallTime`
  - 端侧合并规则：同一 `messageId` 以 `rev` 更大者覆盖，保证“撤回最终态不回滚”

- WS 普通业务消息（TEXT/IMAGE/FILE/...）：
  - `header.extra`（JSON）携带 `rev`（默认 1），并与文件元数据等扩展字段合并（同一个 JSON）

说明：此处的 `...` 表示“其它业务消息类型”，非协议字段。

- 撤回时间窗配置：
  - 配置键：`im.recall.window-seconds`
  - 默认值：`120`（秒）
  - 语义：超过窗口期返回 `MESSAGE_RECALL_TIMEOUT`（提示文案不硬编码具体分钟数）

- 会话列表预览一致性（撤回最后一条消息）：
  - 服务端仅当 `last_message_id == messageId` 时才更新会话预览（避免竞态回退）
  - 更新后写入 `im_conversation_user_state` 并推进 `cursorVersion`，确保换端/重登/增量 sync 不回滚

### 2.4.8 引用消息一致性（发送态与刷新态）

- 字段分层（强制）：
  - `quoteMessageId`：引用关系主键（权威字段，必须按 `string` 处理）
  - `extra.quoteContent/quoteSenderName`：引用预览快照（仅用于刷新恢复与兜底展示）
- 后端落库（已落地）：
  - `QUOTE_REPLY` 持久化时，`extra.quoteMessageId` 必须字符串化；并同步写入 `quoteContent/quoteSenderName/quoteSenderId`
  - 目的：避免 JS Number 精度污染导致刷新后引用错位或点击定位失败
- 前端渲染（已落地）：
  - 预览构建：优先使用当前列表内的被引用原消息（对齐发送前 UI）
  - 仅在原消息不在当前列表时回退到快照字段
  - 点击引用：本地定位失败后自动分页补拉历史，再执行定位与高亮
- 解析优先级（强制）：
  - 顶层 `quoteMessageId` 为最高优先级；raw/content/extra 仅可补全，不得覆盖已存在有效主键

### 2.4.9 消息持久化可靠性护栏（先持久化后投递）

- 存储 SPI fail-fast（已落地）：
  - 默认禁止 NoOp 存储兜底；未注入业务 `MessageStorageService` 时启动失败
  - 仅开发联调可显式开启 `shengyu.websocket.allow-no-op-storage=true`
- 处理器统一门禁（已落地）：
  - `TEXT/IMAGE/VOICE/VIDEO/FILE/LOCATION/QUOTE_REPLY` 统一要求 `saveResult.messageId/chatId` 有效后才允许回推与 fanout
  - 不满足门禁时直接中断投递，避免“端侧看起来发送成功但 DB 无记录”

### 2.4.10 语音消息发送基线（开发版）

- **前端录音入口**：`shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat.uvue`
  - `toggleInputMode` 在文字/语音输入之间切换；语音模式下显示“按住说话”按钮
  - `handleVoiceStart` 使用单例 `recorderManager`，录音参数固定为 `duration=60000 / sampleRate=16000 / numberOfChannels=1 / encodeBitRate=48000 / format='mp3'`
  - `handleVoiceMove` 以上滑 `60px` 作为取消阈值；`handleVoiceEnd` 只负责停止录音，上传与发消息统一由 `onStop` 后续状态机处理
- **前端上传与发送**：
  - 录音完成后先生成本地占位消息，再上传到 `im/chat/{chatId}/voice` 或 `im/group/{groupId}/voice`
  - 上传统一使用 `uploadFileAndReturnId(...)`，发送统一使用 `messageService.sendVoiceMessageV2(receiverId, groupId, fileId, url, duration, size, durationMs, format, md5?)`
  - 语音发送失败只允许复用已上传结果重发，不再重复上传
- **消息体与协议现状**：
  - uniappx `VoiceMessageBody = { fileId?: string, url: string, duration: number, size: number, durationMs?: number, format?: string, md5?: string }`
  - Protobuf `VoiceMessage` 当前字段为 `url:string + duration:int32(秒) + size:int64`
  - `header.extra` / DB `extra` 为语音权威元数据：`fileId + duration + durationMs + size + format + md5?`
  - DB `content` 固定摘要为 `[语音]`，播放时统一按 `fileId -> presigned-get-url`
- **现状缺口（后续任务必须补齐）**：
  - 端到端真机回归与弱网回归仍需补跑

### 2.4.11 语音未听红点链路优化（2026-04-02）

- **当前已落地能力**：
  - 后端：`mark-voice-played`（单条）+ `mark-voice-played-batch`（批量）+ `voice-played-status`（补偿查询）
  - 前端：语音播放后本地立即消点；`300ms` 聚合上报；`onHide/onUnload/onUnmounted` 强制 flush
  - 多端：`SYSTEM_NOTIFY(action=voice_played)` 实时通知；推送丢失时通过 `voice-played-status` 周期补偿
- **性能与容量控制**：
  - 存储增长：`im_message_voice_play` 由 `ImVoicePlayCleanupJob` 按保留期分批清理
  - 请求频率：连续播放场景采用批量上报替代逐条上报，减少高频小请求
  - 索引：`idx_played_time(played_time, tenant_id, deleted)` 支撑清理任务与时间维度查询
- **口径边界（强约束）**：
  - 群聊“已读/未读xx”继续完全依赖会话阅读水位（`lastReadSequence`）
  - 语音红点继续完全依赖 `voicePlayed`，两条链路禁止互相反推

---

## 3. 统一鉴权体系（HTTP + IM）

本章以本文档的 **附录 16（统一鉴权详细版）** 为权威来源，本章只做归纳与 IM 侧补充。

### 3.1 Token 与租户

- `Authorization: Bearer <accessToken>`

### 3.2 HTTP 刷新与队列重放（关键不变式）

- 401 触发 refresh **单飞**，并发请求进入队列
- refresh 成功后：
  - 原请求 retry 前重新注入 `Authorization/tenant-id`
  - 队列请求 replay 前重新注入 `Authorization/tenant-id`

### 3.3 IM 不断链续期（对齐企微/钉钉）

- 当 HTTP refresh 成功后，IM 在**同一条连接**上发起“续期/重认证”，避免断链
- 系统通知：
  - `RENEW_SUGGEST`：建议续期（客户端尽量无感处理）
  - `REAUTH_REQUIRED`：必须重登（客户端停止重连并引导登录）

---

## 4. Presence / Lease 设计（企微/钉钉体验核心）

### 4.1 目标

- 前台活跃：连接稳定、续租及时、消息实时
- 后台闲置：减少 presence 与续租

### 4.2 客户端 gating 策略

- `appForeground=true` 且（`realtimeBizActive=true` 或在聊天页）时：
  - 发送 PRESENCE + 正常心跳
  - 必要时无感续期（AUTH_RENEW/AUTH_REQ）
- `appForeground=false` 且非实时业务页时：
  - presence 频率降低或停止
  - 服务端租约到期后推送 `REAUTH_REQUIRED`

### 4.3 服务端租约状态机（摘要）

- ACTIVE：租约有效
- SOFT_EXPIRE：建议续期（`RENEW_SUGGEST`）
- HARD_EXPIRE：强制重登（`REAUTH_REQUIRED`）

---

## 5. 多端登录与互踢

### 5.1 策略

- 维度：`userId + deviceType`
- 同 deviceType 新登录互踢旧会话，不同 deviceType 允许共存

### 5.2 用户提示（必须友好）

- `KICKED` 携带：
  - `kickedAt`
  - `byDevice`（优先 `deviceName`，避免展示 deviceId）

---

## 6. 协议双栈（App Protobuf + H5 JSON）

### 6.1 设计目标

- App：Protobuf 降流量、提升吞吐与序列化性能
- H5：JSON 便于调试、兼容性更好
- 服务端：同一套业务处理链路，前置编解码层适配

### 6.2 传输与编解码分层（强制统一）

- **Transport**：WebSocket
- **Encoding**：
  - App：Protobuf（二进制）
  - H5：JSON（文本）
- **Business**：服务端业务处理链路不关心编码，仅消费“统一的领域消息对象”

> 关键原则：**编码与业务完全解耦**。即：Decoder 把输入统一成内存对象，Encoder 把输出统一成网络字节。

### 6.3 连接层协商（SubProtocol 优先，首帧探测兜底）

#### 6.3.1 协商优先级

1. **WebSocket SubProtocol（首选）**：`Sec-WebSocket-Protocol`
2. **PROBE（必须）**：连接建立后客户端发送 `PROBE` 完成版本/能力协商，同时固化本连接的 codec

协商输出（必须落到连接会话上下文）：

- `codec`：`PB` / `JSON`
- `protoVersion`：如 `v1`
- `negotiationMode`：`subprotocol` / `probe`

不变式：

- **一个连接只绑定一个 codec**，绑定后不得切换（切换必须重新建链）
- 协商必须在 AUTH 之前完成，否则无法正确解码 AUTH
- **严格模式（当前工程已启用）**：即使已通过 SubProtocol 协商出 codec，客户端仍必须先发送 `PROBE`，再发送 `AUTH_REQ`（用于能力/版本对账与回归定位）。

#### 6.3.2 SubProtocol 约定（建议）

- Protobuf：`im.pb.v1`
- JSON：`im.json.v1`

客户端：

- App：`protocols: ['im.pb.v1']`
- H5：`protocols: ['im.json.v1']`（或不传，默认 JSON）

服务端策略：

- 若请求声明 SubProtocol：按声明绑定 decoder/encoder
- 若未声明：进入首帧探测

#### 6.3.3 首帧探测（必须具备）

当前工程实现说明（以代码为准）：

- 本项目的“首帧探测/协商”统一通过 **TextFrame 的 `PROBE` 消息**完成。
- `Sec-WebSocket-Protocol` 仅用于在握手阶段提前绑定 `codec`（便于立刻启用载体约束与编解码），但不会替代 `PROBE`。

`PROBE` 参考格式（JSON TextFrame）：

```json
{
  "header": {
    "messageId": "<string>",
    "messageType": 6,
    "timestamp": "<string>"
  },
  "body": {
    "codec": "json | pb",
    "features": {
      "ack": true
    }
  }
}
```

服务端响应 `PROBE_RESP(7)`，并在连接上下文固化：

- `codec`：`json` / `pb`
- `negotiationMode`：`subprotocol` / `probe`
- `subprotocol`：握手选中的 subprotocol（若有）

严格模式超时（当前工程已落地）：

- 连接建立后必须在 `shengyu.netty.probeTimeoutMs`（默认 `3000ms`）内完成 `PROBE`，否则服务端发送 `CLOSE(PROBE_TIMEOUT)` 并断开连接。

协商状态机（服务端）：

- `UPGRADED`（WebSocket Upgrade 完成）
- `NEGOTIATING`（等待 SubProtocol 或首帧探测）
- `CODEC_BOUND`（已绑定 PB/JSON，进入正常 decode）
- `AUTH_PENDING`（等待 AUTH_REQ）
- `AUTHED`（鉴权成功，允许业务消息）
- `CLOSED`（关闭）



### 6.4 统一消息 Envelope（跨编码一致语义）

#### 6.4.1 统一 Header 语义（必须一致）

无论 JSON/Protobuf，以下字段语义必须一致：

- `messageId`：客户端生成，用于幂等/ACK/重投
- `messageType`：枚举（以 proto 为权威）
- `timestamp`：客户端时间（服务端可回填 serverTime）
- `tenantId/userId`：服务端认证后补齐/校验；客户端只可读不可写

补充约束（企业级落地口径，以当前工程为准）：

- `messageId` 必须为 **可被服务端 int64 解析的纯数字字符串**（long-safe），用于：
  - 服务端落库主键（`im_chat_message.id`）
  - 服务端幂等去重（重投复用同一 `messageId`，`DuplicateKey` 命中后返回既有记录）
  - 已读回执聚合/撤回等按 `messageId` 查询的业务接口
- 前端不得再使用“时间戳+随机字符串”作为 `messageId`（否则服务端 `Long.parseLong` 失败或查库不命中）。

实现锚点：

- **前端**：`shengyu-ui/shengyu-ui-admin-uniappx/utils/message-utils.uts#generateMessageId`（snowflake-like）
  - `utils/message-handler.uts#MessageBuilder.generateMessageId` 统一复用该实现
- **后端**：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/JsonBusinessMessageHandler.java#readLong` 兼容 `header.messageId` 为 string/number
  - `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageStorageServiceImpl.java#saveMessageWithId`：`messageDO.setId(header.getMessageId())`
- `sequence`：服务端生成（建议会话维度递增），用于排序与断线补偿
- `extra`：扩展 JSON（存放 subType / debug 等）

#### 6.4.4 消息体（body）Schema 冻结

说明：本节冻结各 `messageType` 的 body 最小字段集（minimum viable schema）。各端必须遵守：

- 新增字段只能“可选追加”，不得改名/改语义
- 端侧必须忽略未知字段
- 大体积内容禁止走 WS（见 6.5.2 MaxFrameSize），附件/媒体必须走 HTTP 上传，消息仅携带引用

媒体上传能力复用（与现有系统框架对齐）：

- 服务端统一复用 `shengyu-module-infra` 的文件能力（`/infra/file/*`、`FileApi`），IM 不再重复造轮子
- 推荐主路径（模式一）：`POST /infra/file/upload` 上传文件，返回“可访问引用”（建议演进为 `fileId`，见下）
- 推荐主路径（模式二）：`GET /infra/file/presigned-url` + `POST /infra/file/create`（前端直传对象存储）

推荐补齐的企业级接口契约（用于 IM 媒体消息的 `fileId` 化）：

- `POST /infra/file/upload-and-return-id`
  - form-data：
    - `file`：binary
    - `directory`：string（例如 `im/chat/{conversationId}`、`im/group/{groupId}`）
  - 响应（`CommonResult<T>`，客户端 `request()` 成功时返回 `data`）：
    - `data = { fileId: string, url?: string, name: string, size: number, mimeType?: string, md5?: string, thumbFileId?: string }`
  - 约束：
    - `fileId` 为权威引用；`url` 仅用于兼容与临时预览
    - 对于图片/视频：如能生成缩略图，返回 `thumbFileId`

错误码与限制建议：

端侧处理建议：

- 上传成功后立即本地预览：使用 `tempFilePath` 直接预览；`fileId->url` 解析可异步
- 下载/预览失败（403/过期）：重新换取短期 URL（expirationSeconds）

缩略图（thumbFileId）生成策略建议：

- 适用范围：`IMAGE`、`VIDEO`
- 生成时机：
  - 推荐：上传成功后异步生成缩略图（不阻塞主上传响应）；生成完成后可通过后续查询/同步补齐 `thumbFileId`
  - 可选：小图/小视频可同步生成（以耗时阈值控制，例如 <=200ms）
- 推荐规格（示例值，最终按端侧展示与带宽调优）：
  - 图片缩略图：短边 240~360px，JPEG/WebP，质量 60~75
  - 视频封面：抽帧 + 同图片规格
- 失败降级：
  - thumb 生成失败不影响主消息投递；端侧可回退显示原图/原视频封面（或默认占位）
- 回收策略（建议）：
  - thumb 与原文件生命周期绑定；支持按租户策略定期清理孤儿文件

兼容方案（可选）：

- 若短期无法新增上传返回 `fileId`：可新增 `POST /infra/file/resolve`，实现 `url -> fileId` 的映射，用于渐进迁移。

建议：IM 消息体中优先使用 `fileId`，而不是直接携带裸 `url`：

- `fileId` 可用于：过期 URL 生成（`presignGetUrl`）、撤回一致性
- 若现有上传接口仅返回 `url string`，属于“可用但不够企业级”的阶段性形态，建议在 infra 层补齐“上传返回 fileId”（或提供 url->fileId 映射），再让 IM 消息体全部切换为 `fileId`

兼容迁移建议：

- 灰度期允许 body 同时包含：`fileId` + `url`（`url` 仅临时兼容）
- 渲染优先级：能通过 `fileId` 换取可访问 URL -> 优先使用；否则 fallback 到 `url`
- url 退场策略：当存量端均升级后，移除 body.url（或仅服务端返回，端侧不再发送）

下载/预览建议：

- 端侧不直接持久化长期可访问 URL，而是在需要预览/下载时通过服务端换取短期地址
- 推荐接口形态（与 infra/FileApi 对齐）：`fileId -> presigned get url (expirationSeconds)`

推荐契约（用于端侧渲染/预览/下载时解析 `fileId`）：

- `GET /infra/file/presigned-get-url?fileId=...&expirationSeconds=...`
  - 鉴权：需登录
  - 响应：`{ url: string, expiresAt: number }`
  - 说明：
    - `expirationSeconds` 建议有上限（例如 60~600s），避免生成长期可访问 URL
    - 如对象存储不支持 presign，可退化为服务端代理下载（但需注意带宽成本）

端侧缓存策略建议：

- URL 仅做短 TTL 内存缓存（不落永久存储），到期前可提前刷新
- 渲染优先：列表/缩略图优先拿 `thumbFileId` 的 url；点击查看再解析 `fileId`

#### 6.4.4.1 文件在线预览体系（kkFileView）

背景：移动端（uniappx）与 H5 对 `openDocument` 的支持存在显著差异，且依赖用户是否安装第三方 Office 应用（WPS/Office）。企业级体验要求“**绝大多数常见 Office/PDF 文件可直接预览**”，而不是“下载后无法打开/提示异常”。

本节给出一套与现有 `fileId + presigned-get-url` 体系兼容的“在线预览”方案：**kkFileView 私有化部署 + WebView 打开预览链接**。

##### 6.4.4.1.1 目标体验（对齐企微/钉钉的可接受程度）

- 优先目标：Word/Excel/PPT/PDF/图片/文本类文件可预览（无需安装 WPS）
- 体验要求：点击文件 -> 进入预览页（loading）-> 可查看/可下载/可分享
- 权限要求：无权限不可预览（403）；URL 过期自动换取
- 可靠性要求：预览失败可降级为“仅下载”；弱网/中断可提示重试

##### 6.4.4.1.2 范围与非目标

- In Scope：IM 聊天消息 FILE；群文件列表；聊天记录搜索结果中的文件
- Out of Scope（阶段性）：在线编辑、协作编辑（OnlyOffice/Collabora 属于更重方案）

##### 6.4.4.1.3 总体架构

- IM 客户端（uniappx/H5）新增统一预览入口：`file-preview` 页面（WebView）
- kkFileView：独立服务私有化部署（同环境同网络、同租户体系的“基础组件”）
- 文件服务：复用现有 infra 文件能力（`fileId`、`presigned-get-url`）

关键原则：

- 客户端只拿 **短期 URL**（presigned）
- kkFileView 只消费短期 URL；URL 过期由客户端重新换取

##### 6.4.4.1.4 端到端链路（推荐时序）

1. 用户点击文件（chat / chat-files / search 结果）
2. 客户端判断类型：
   - 图片：`previewImage`
   - 视频：`video-player`
   - 其它：进入 `file-preview`（WebView）
3. `file-preview` 启动后：
   - 若已有 `fileId`：调用 `GET /infra/file/presigned-get-url?fileId=...&expirationSeconds=...` 获得短期 `url`
   - 若仅有历史 `url`（兼容期）：可直接使用（但建议尽快迁移为 fileId）
4. `file-preview` 拼接 kkFileView 预览地址并加载 WebView：
   - `KK_URL/onlinePreview?url=${encodeURIComponent(presignedUrl)}`
5. 预览页提供按钮：下载/复制链接/用其它应用打开（端能力允许时）

失败与兜底：

- presigned 获取失败（401/403/过期）：提示“无权限或登录失效”，允许重新登录/重试
- kkFileView 加载失败/转换失败：提示“预览失败”，提供“仅下载”兜底

##### 6.4.4.1.5 接口契约（与现有 infra 对齐）

- 必选：`GET /infra/file/presigned-get-url?fileId=...&expirationSeconds=...` -> `{ url, expiresAt }`
- 可选增强（企业级建议，后续迭代）：
  - `POST /system/im/file/preview-url`（服务端聚合接口）
    - 输入：`fileId` + `scene(chat|groupFile|search)`
    - 输出：`{ previewUrl, expiresAt }`（直接返回 kkFileView 的 onlinePreview 完整 URL）
    - 作用：在服务端集中处理：URL 生成策略与域名统一

##### 6.4.4.1.7 多端策略（uniappx/H5 一致）

- App（uniappx）：默认走在线预览（WebView），并提供“用其它应用打开/下载到本地”按钮作为增强
- H5：默认走在线预览（新标签/内嵌 iframe/WebView），避免 XHR 下载触发 CORS；下载走浏览器原生行为

统一约束（所有消息类型通用）：

- `messageId` 由 header 承载（幂等键），body 不重复
- `conversationId` 建议在持久化后由服务端关联，端侧可在 body 中携带用于路由，但服务端必须校验

最小字段集建议（示例，不含可选扩展字段）：

- `TEXT`：
  - `text: string`
  - `mentions?: { userIds: string[], all?: boolean }`

- `IMAGE`：
  - `fileId: string`（或 `urlKey`，由服务端换取可访问 URL）
  - `width: number` / `height: number`
  - `sizeBytes: number`
  - `thumbFileId?: string`
  - `md5?: string`

- `VOICE`：
  - **当前工程兼容字段**：`url: string`、`duration: number`（秒）、`size: number`、`fileId?: string`
  - **目标冻结字段**：`fileId: string`、`durationMs: number`、`format: string`（amr/aac/mp3 等）、`sizeBytes: number`
  - **兼容期要求**：`header.extra` / REST `extra` 至少补齐 `durationMs`、`format`、`md5?`

- `VIDEO`：
  - `fileId: string`
  - `durationMs: number`
  - `width: number` / `height: number`
  - `sizeBytes: number`
  - `thumbFileId?: string`

- `FILE`：
  - `fileId: string`
  - `fileName: string`
  - `sizeBytes: number`
  - `mimeType?: string`

- `LOCATION`：
  - `lat: number` / `lng: number`
  - `address: string`
  - `name?: string`（POI 名称）
  - `mapProvider?: string`

- `EMOJI`：
  - `emojiCode: string`（平台表情编码，跨端权威字段）
  - `emojiName?: string`
  - `version?: string`

- `STICKER`（自定义表情包 / 自定义贴纸）：
  - `stickerId: string`（用户表情库内的唯一 ID）
  - `fileId: string`（原图文件 ID，服务端权威）
  - `thumbFileId?: string`
  - `url?: string`（Phase 1 兼容字段；便于兼容当前 uniappx 直接渲染 URL 的实现）
  - `md5?: string`（去重与秒传依据）
  - `width?: number` / `height?: number`
  - `packageId?: string`（来源于系统表情包/企业表情包时可选）
  - `source?: string`（`CUSTOM` / `SYSTEM` / `STORE`）

- `CARD`（应用消息卡片/业务卡片）：
  - `cardType: string`
  - `title: string`
  - `summary?: string`
  - `actions: { type: string, label: string, url?: string, payload?: object }[]`
  - `data?: object`（必须白名单字段；禁止端侧渲染任意脚本）

- `CUSTOM`（统一扩展）：
  - `subType: string`
  - `data: object`
  - 约束：`subType` 受白名单控制；服务端必须做 schema 校验/降级

- `CALL_RECORD`（通话记录消息，见 10.5.5）：
  - `callId: string`
  - `callType: string`（AUDIO/VIDEO）
  - `durationMs?: number`
  - `endReason: string`（END/BUSY/TIMEOUT/REJECT 等）

#### 6.4.4.2 语音消息发送机制（对齐微信，单一新契约）

说明：本节结合微信用户可感知交互与当前工程现状，冻结语音消息的单一实现方案。当前处于开发阶段，语音链路**不兼容老数据**，目标是把“发送、播放、60 秒控制、失败恢复”这些基础能力做稳，同时避免改动握手、ACK、`sequence/rev` 等公共语义。

##### 6.4.4.2.1 微信机制提炼（公开资料 + 可观察交互）

- 发送交互以“**按住说话，松开发送，上滑取消**”为主，用户不需要先进入单独录音页
- 语音发送有明确时长边界：短语音直接取消并提示；长语音上限按 `60s` 控制
- 语音播放强调“进入会话不自动播放、同页单实例播放、未播放红点独立于已读态”

##### 6.4.4.2.2 当前工程契约（冻结）

- 当前 `chat.uvue` 录音参数固定为：
  - `duration = 60000`
  - `sampleRate = 16000`
  - `numberOfChannels = 1`
  - `encodeBitRate = 48000`
  - `format = 'mp3'`
- 当前 WS / Protobuf `VoiceMessage` 主体仍是：
  - `url: string`
  - `duration: int32`（秒）
  - `size: int64`
- 本期冻结如下实现约束：
  - **不修改** WebSocket 握手、`MessageType.VOICE`、ACK 语义、`sequence/rev` 不变式
  - `body` 继续沿用当前 protobuf 形态：`url + duration(秒) + size`
  - `fileId` 为权威媒资标识，必须进入 `header.extra` 与 DB `extra`
  - `header.extra` / DB `extra` 至少包含：
    - `fileId: string`
    - `duration: number`
    - `durationMs: number`
    - `size: number`
    - `format: string`
    - `md5?: string`
  - DB `content` 只存固定摘要 `[语音]`，不持久化长期可访问 URL
  - 不再保留 `IM_MEDIA_USE_FILE_ID` 之类的语音双轨开关；语音发送统一走单一新契约
- 后续若要把 `durationMs/format/fileId` 升格为 protobuf/JSON body 的权威字段，必须作为单独协议版本任务推进；本期不做协议版本升级

##### 6.4.4.2.3 发送状态机（企业级冻结）

- 主状态链：
  - `IDLE -> RECORDING -> CANCEL_READY -> RECORDED -> UPLOADING -> SENDING -> SENT`
- 异常分支：
  - `RECORDING -> CANCELED`：上滑进入取消态后松手
  - `RECORDING -> TOO_SHORT`：录音 `< 1000ms`，toast“说话时间太短”，不生成正式消息
  - `UPLOADING -> UPLOAD_FAILED`：允许重试上传，不要求重新录音
  - `SENDING -> SEND_FAILED`：允许复用已上传 `fileId/url` 重发，不重复上传
- 状态语义：
  - `RECORDING`：只显示录音浮层，不插入正式消息
  - `RECORDED / UPLOADING`：生成本地占位消息，展示“上传中/重试”
  - `SENDING`：仅表示 WS 已发出、等待服务端回推确认
  - `SENT`：必须以服务端回推的 `messageId/sequence` 为准

##### 6.4.4.2.4 交互与体验冻结

- 入口：
  - 输入栏提供语音/键盘切换
  - 语音模式下仅展示“按住说话”按钮，不与文本输入框并存
- 录音阈值：
  - 最短：`1000ms`
  - 最长：`60000ms`
  - 取消阈值：上滑 `>= 60px`
- 权限与平台降级：
  - 首次录音前先检查麦克风权限；拒绝时给出明确引导
  - H5 或不支持录音的平台：入口隐藏，或点击时提示“当前平台暂不支持语音发送”
- 文案冻结：
  - 录音中：`手指上滑，取消发送`
  - 取消态：`松开手指，取消发送`
  - 短语音：`说话时间太短`
  - 上传失败：`语音上传失败，点击重试`
  - 发送失败：`语音发送失败，点击重发`
- 非目标：
  - 本期不做跨应用重启的录音草稿恢复
  - 本期不做录音暂停/继续
  - 本期不做转文字、倍速播放、听筒/扬声器手动切换等附加能力

##### 6.4.4.2.5 播放与读态冻结

- 语音消息默认**不自动播放**
- 全页只允许一个 `InnerAudioContext`，切换消息、切页、切后台时必须停止
- 语音红点定义为：`voicePlayed = false && !isSelf`
  - `voicePlayed` 是端侧渲染状态（服务端返回 + 本地缓存合并）
  - `voicePlayed` **不得**复用 `isRead/已读回执`
- 成功开始播放后先清除本地红点并上报服务端；播放失败不清除
- 播放统一走当前平台默认音频路由；本期不新增听筒/扬声器切换能力

##### 6.4.4.2.6 上传、安全与合规

- 上传目录规范：
  - 单聊：`im/chat/{chatId}/voice`
  - 群聊：`im/group/{groupId}/voice`
- 新代码只按 chat/group 维度归档，不再新增 `im/voice` 这种无上下文目录
- 限制建议：
  - `sizeBytes <= MAX_VOICE_SIZE`（当前工程为 `10MB`）
  - `format` 白名单：`mp3 / aac / m4a / amr / wav`
- 安全要求：
  - 服务端必须校验 `fileId` 存在、格式白名单、大小、时长
  - 消息体不持久化长期可访问 URL
  - 播放/下载统一走 `fileId -> presigned-get-url`
  - `im_chat_message.extra` 必须持久化 `fileId / format / durationMs / md5`
- 审计要求：
  - 记录 `tenantId / chatId / messageId / fileId / uploaderId / durationMs / sizeBytes`

##### 6.4.4.2.7 可观测性与回归

- 指标建议：
  - `im_voice_record_start_total`
  - `im_voice_record_cancel_total`
  - `im_voice_too_short_total`
  - `im_voice_upload_fail_total`
  - `im_voice_send_fail_total`
  - `im_voice_play_fail_total`
- 回归门禁：
  - 单聊 / 群聊发送语音
  - 权限拒绝 / 录音失败 / 短语音 / 上传失败 / 发送失败 / 重试
  - 刷新恢复、断线补偿、会话预览、引用 / 撤回对语音无回归
  - `TEXT/IMAGE/VIDEO/FILE/LOCATION/QUOTE_REPLY/RECALL` 主链路无回归

##### 6.4.4.2.8（2026-04-01）语音 UI 动画、时长一致性与 60s 控制补充冻结

- 目标：在既有 `6.4.4.2` 闭环基础上，补齐“可感知录制反馈 + 播放动效 + 时长准确性 + 平台兼容兜底”的体验约束，避免出现假录音、时长失真、动效缺失。
- 微信对齐（公开资料与可观察交互，2026-04-01）：
  - 录制中实时显示时长，便于用户控制内容长度
  - 接近上限时出现倒计时强化反馈，到达上限自动结束录制
  - 播放中语音条/振幅存在动态反馈，结束后回到静态态
- 状态机补充：
  - 录制阶段扩展为 `IDLE -> RECORDING -> LIMIT_WARNING -> AUTO_STOP_PENDING -> RECORDED`
  - 当 `elapsedMs >= 60000` 时必须触发 `AUTO_STOP_PENDING` 并在单次回调中收敛到 `RECORDED`，禁止重复 stop
  - `RECORDING`、`PLAYING` 的动效状态必须与真实引擎状态同源，不允许仅依赖 UI 定时器伪造
- 数据与一致性约束：
  - 展示时长统一来源于 `durationMs`（毫秒），`duration` 仅用于兼容展示；严禁双口径并行驱动
  - 发送前必须校验 `tempFilePath`、`durationMs`、`sizeBytes`、`format`，任一缺失直接失败并提示重录
  - 回放进度与总时长统一使用毫秒精度，确保“1 秒语音不会播放成 5 秒”
- UI 约束：
  - 语音气泡宽度按时长分段线性增长：短语音保底宽度、长语音上限宽度；上限受消息行容器限制
  - 语音气泡时长文本固定单行，不允许因气泡拉长触发换行错位
  - 录制中显示 `mm:ss`，达到 `60s` 自动收口并给出明确提示文案
- 兼容与容错：
  - `uni.getRecorderManager` 不支持时必须走能力降级：隐藏/禁用录音入口并提示，不得抛运行时异常
  - 录制上下文请求 ID（如 `currentRecordingRequestId`）必须显式声明并在页面卸载时清理，防止 `ReferenceError`
  - 页面隐藏、路由切换、会话切换时，必须统一执行 `stopRecord + stopPlay + clearTimer + unbindCallback`
- 回归口径补充：
  - 动效回归：录制、取消、自动结束、播放完成四类场景动效状态准确
  - 时长回归：`displayDuration` 与 `actualPlayDuration` 偏差 `<= ±300ms`
  - 稳定性回归：连续 `30` 次按住说话/取消/重试，无未定义变量错误、无重复事件监听

##### 6.4.4.2.9（2026-04-01）语音播放进度条与暂停续播机制补充冻结

- 目标：在保持“单实例播放 + 不自动播放”前提下，提升语音播放可控性与可预期性，避免用户无法判断已播放进度。
- 微信机制对齐（公开资料与可观察交互，2026-04-01）：
  - 语音消息支持“暂停后继续播放”的基础能力
  - 语音气泡提供播放态动态反馈；官方公开信息未给出可拖拽 seek 进度条作为标准能力
  - 本项目采取“显示进度，不支持拖拽”的一致策略
- 状态机补充：
  - 播放状态扩展为 `IDLE -> PLAYING -> PAUSED -> PLAYING -> ENDED`
  - 点击语音气泡本体：统一执行 `RESTART_FROM_ZERO`（从头重播）
  - 点击“继续播放”按钮：执行 `RESUME_FROM_PAUSED_POSITION`
  - 开始播放新语音前，必须先执行 `STOP_CURRENT_CONTEXT` 清理旧上下文
- UI 约束：
  - 进度条仅在 `PLAYING/PAUSED` 显示，`IDLE/ENDED/FAILED` 隐藏
  - “暂停”按钮仅在 `PLAYING` 显示；“继续播放”按钮仅在 `PAUSED` 显示且位于语音气泡旁
  - 气泡内时长文本允许显示 `已播时长 / 总时长`；必须保持单行，不得挤压造成换行错位
- 数据与同步约束：
  - 进度计算统一使用 `currentTime(ms)` 与 `durationMs`，禁止秒毫秒混算
  - `onTimeUpdate` 为主、UI 定时器仅可作为兜底；禁止仅靠定时器伪造播放进度
  - `onPause/onStop/onEnded/onError` 必须回收对应状态，防止“按钮显示与真实播放态不一致”
- 回归口径补充：
  - “播放→暂停→继续→暂停→重播”链路连续执行 `30` 次无异常
  - 暂停态点击气泡会从 `0ms` 重播；点击“继续播放”从暂停点恢复
  - 切页面、切会话、退后台后无悬挂播放实例，无残留进度条/按钮

##### 6.4.4.2.10（2026-04-01）语音“已读/已听”双口径解耦冻结（企业微信对齐）

- 目标：消除“已读=已听”的语义混淆，保证发送者与接收者对语音状态理解一致。
- 口径定义：
  - `已读/未读xx`（发送者侧群聊统计）：
    - 基于 `im_conversation_user_state.last_read_sequence` 与消息 `sequence` 比较
    - 判定条件：`lastReadSequence >= message.sequence` 记为已读
    - 不依赖语音是否被点击播放
  - `未听点`（接收者侧语音气泡红点）：
    - 基于用户维度 `voicePlayed` 状态（端侧缓存 + 服务端返回）
    - 首次有效播放后置 `voicePlayed=true` 并清除未听点，同时上报服务端
    - 不参与群聊“已读/未读xx”统计
- UI 冻结：
  - 语音消息打开“已读详情”时，必须展示口径提示：`已读按会话阅读水位统计，不代表已听语音`
  - 不展示“已听xx/未听xx”群聊聚合统计，除非后端新增独立“已听回执”协议
- 接口契约冻结（`GET /system/im/read-receipt/summary`）：
  - 响应需包含 `messageType`，用于前端准确识别是否语音消息
  - 响应需包含 `readBasis`，当前固定为 `conversation_read_watermark`
  - 前端优先以 `readBasis + messageType` 进行口径提示，不依赖本地消息列表兜底
- 一致性约束：
  - 任何代码路径不得用 `msg.status/isRead` 推导 `voicePlayed`
  - 任何代码路径不得用 `voicePlayed` 反推群聊已读统计
- 回归口径补充：
  - 接收者“进入会话未播放语音”场景：发送者侧已读统计可变化，接收侧未听点不应消失
  - 接收者“播放语音”场景：仅接收侧未听点变化，发送者侧已读统计不因播放动作额外变化

##### 6.4.4.2.11（2026-04-02）语音未听红点多端同步机制冻结

- 目标：把语音未听红点从“单端本地态”升级为“用户维度多端一致态”，在不引入“已听回执统计”前提下实现实时同步。
- 服务端数据模型：
  - 新增表 `im_message_voice_play`
  - 推荐唯一键：`(tenant_id, user_id, message_id)`
  - 语义：记录“当前用户首次播放该语音”的事实，不记录播放进度
- 接口与事件：
  - `PUT /system/im/message/mark-voice-played?messageId=...`
  - `PUT /system/im/message/mark-voice-played-batch?messageIds=...`（端侧 300ms 聚合上报）
  - `GET /system/im/message/voice-played-status?chatId=...&messageIds=...`（推送丢失补偿校准）
  - 幂等写入后推送 `SYSTEM_NOTIFY`，`header.extra.action = voice_played`，并携带 `chatId/messageId` 或 `chatId/messageIds`
  - 历史/分页/窗口消息查询需返回 `voicePlayed` 字段（当前用户视角）
- 端侧上报与补偿策略：
  - 初始渲染：`voicePlayed = serverVoicePlayed || localVoicePlayed`
  - 播放开始后：先本地消点，再进入 `300ms` 聚合队列上报（单条/批量自动切换）
  - 页面 `onHide/onUnload/onUnmounted` 必须执行语音已播队列 flush，降低切页丢上报
  - 收到 `voice_played` 事件：同会话同消息立即消点（跨端实时）
  - 定时调用 `voice-played-status` 对未听语音做补偿校准（用于推送偶发丢失场景）
- 数据增长与运维策略：
  - `im_message_voice_play` 增长由保留期任务控制：`im.voice-play.cleanup.*`（按天保留、分批删除）
  - 建议索引：`idx_played_time(played_time, tenant_id, deleted)`，保障清理任务与时间范围扫描效率
- 一致性约束：
  - 重复上报必须幂等，禁止重复广播导致 UI 抖动
  - 推送链路按 IM 常见“最终一致”模型：通知丢失由下次 HTTP 补偿拉取修正
  - 离线端重进后以服务端 `voicePlayed` 为最终态，确保跨端最终一致
  - 该机制仅作用于“未听红点”，不得改变群聊 `已读/未读xx` 统计口径

#### 6.4.2 Protobuf Envelope（现有形态）

- `ImMessage{ header: MessageHeader, body: bytes }`
- `body` 为具体消息体的 protobuf bytes（如 `AuthRequest/TextMessage`）

#### 6.4.3 JSON Envelope（H5 形态）

```json
{
  "header": {
    "messageId": "1710000000000",
    "messageType": 3,
    "timestamp": "1710000000000",
    "traceId": "t-1710000000000",
    "extra": "{}"
  },
  "body": {
    "text": "hello"
  }
}
```

JSON 兼容建议：

- `header.messageId` 建议使用 string（端侧统一使用 string，服务端需兼容 string/number）
- `header.timestamp` 建议使用 string（端侧 long-safe），服务端可兼容 string/number
- `body` 允许按 `messageType` 的不同结构变化，但必须可被服务端映射到统一领域对象

### 6.5 Netty Pipeline 设计（同端口双栈）

#### 6.5.1 Pipeline 分层

推荐处理顺序（概念层）：

1. **HTTP 握手 / WebSocket Upgrade**（`WebSocketServerProtocolHandler`）
2. **握手协商结果固化**（`Sec-WebSocket-Protocol` -> `codec` 绑定到 channel attr）
3. **WebSocket 帧入口与载体约束**（`WebSocketFrameHandler`）
  - `codec` 未绑定：仅允许 `PROBE/CLOSE` 走 TextFrame
  - `codec=pb`：除 `PROBE/PROBE_RESP/CLOSE` 外，业务消息必须走 BinaryFrame
  - `codec=json`：业务消息走 TextFrame，BinaryFrame 直接拒绝
4. **Decoder**
  - JSON：TextFrame -> `String` -> `AuthHandler` / `JsonBusinessMessageHandler`
  - Protobuf：BinaryFrame -> `ByteBuf` -> `ProtobufVarint32FrameDecoder + ProtobufDecoder(ImMessage)`
5. **AuthHandler**（鉴权前置；严格模式下未 PROBE 不允许 AUTH_REQ）
6. **Business Processor**（`MessageProcessorFactory` 分发）
7. **Encoder**
  - Protobuf 出站：`WebSocketProtobufOutboundHandler` 将 `ImMessage` 包装成 `BinaryWebSocketFrame`（varint32 length-prefix）

---

## 7. 消息可靠性模型

### 7.1 核心字段

- `messageId`：全局唯一（雪花/分布式 ID）
- `sequence`：会话维度或全局递增，用于排序与断线补偿
- `timestamp`：客户端/服务端时间戳（用于展示与冲突处理）

### 7.2 ACK / 重投 / 幂等

- 发送方本地先落 UI（pending），发送后等待“服务端确认/补偿闭环”。

当前工程 ACK 说明（以代码为准，phase1）：

- `ACK(8)` 是“投递回执/客户端接收回执”的协议控制消息，**当前阶段主要用于日志/指标 + 去重**，尚未作为“发送成功”的强一致依据。
- `ACK_RESP(9)` 为可选响应（便于联调与打点）。

实现要点：

- JSON ACK：由 `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/AuthHandler.java#handleJsonAck` 接收并记录日志，随后返回 `ACK_RESP(9)`（TextFrame）。
- Protobuf ACK：进入 `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/processor/impl/AckMessageProcessor.java`，使用 `(tenantId:userId:ackType:messageId)` 作为 key 做 10min 去重，并记录日志。

重投/幂等建议（后续迭代）：

- 若未来将 ACK 作为强一致的“送达确认”，必须补齐：服务端落库投递状态、可对账离线队列、以及与消息幂等键（`messageId`）的强绑定。

重投建议：

- 发送后未收到 ACK：可按退避策略重投
- 重投必须复用同一 `messageId`

### 7.4 断线补偿与离线/漫游消息

- reconnect + auth 成功后：
  - 客户端携带 `lastSequence` 拉取增量
  - 服务端按会话/用户维度返回缺失消息
  - 客户端按 `sequence` 归并并补齐本地会话未读

推荐补偿接口语义（HTTP 或 IM 都可）：

- `syncConversations(cursor)`：同步会话列表、未读与会话级游标
- `syncMessages(conversationId, afterSequence, limit)`：按序列补齐消息

客户端重连后的推荐流程（先会话，再消息）：

1. `syncConversations(cursor)` 拉取“会话变更 + 水位”
2. 对每个会话若 `lastPulledSequence < lastMessageSequence`：调用 `syncMessages(conversationId, afterSequence=lastPulledSequence)` 拉取缺失消息
3. 客户端把消息按 `sequence` 归并，更新本地 `lastPulledSequence`
4. 若用户停留在某会话，触发已读上报（推进 `lastReadSequence`，只升不降）

### 7.5 去重与顺序策略（客户端侧必须实现）

- 去重 key：`conversationId + messageId`
- 顺序 key：`conversationId + sequence`
- 乱序处理：
  - 允许临时乱序到达，但渲染必须按 `sequence` 排序
  - 对“缺洞”可短暂等待补齐，超时仍缺则触发补偿拉取

### 7.6 sequence 分配模型（服务端必须冻结）

建议采用“会话维度 sequence”（而非全局），原因：

- 客户端渲染/分页/补偿天然按会话维度进行
- 大租户/大并发下，全局 sequence 更容易成为热点

推荐实现方式（可选其一）：

- **方案 S1：DB 自增（每会话一行水位表）**
  - `im_conversation_seq(conversation_id, max_sequence, updated_at)`
  - 更新（示意）：`UPDATE im_conversation_seq SET max_sequence = max_sequence + 1 WHERE conversation_id=?`（需事务/行锁）
* **方案 S2：Redis INCR（会话 key）**
  - key：`im:seq:{conversationId}`

不变式：

- 同一 `conversationId` 的 `sequence` 严格递增且唯一
- `sequence` 只由服务端分配，客户端不可指定/不可篡改

### 7.7 服务端状态机（发送链路）

发送链路建议最少包含以下状态（便于对账与运维）：

- `RECEIVED`：服务端收到客户端请求
- `PERSISTED`：已落库（可返回 SendAck）
- `FANOUT_DONE`：已完成投递尝试（在线投递或入离线队列）
- `RECALLED`：被撤回（状态更新，不物理删除）

---

## 8. 会话模型与数据一致性

### 8.1 会话（Conversation）与未读

企业 IM 的关键体验是“会话列表稳定、未读准确、跨端一致”。建议会话核心状态统一由服务端维护：

- `conversationId`：单聊/群聊统一 ID
- `lastMessageSequence`：会话最新消息序号
- `lastReadSequence`：用户在该会话的已读水位
- `unreadCount = lastMessageSequence - lastReadSequence`

客户端原则：

- 会话列表来自服务端同步（避免纯客户端计算导致跨端不一致）
- 已读上报必须幂等（上报 `lastReadSequence`，只升不降）

补充：会话“变更同步”必须明确字段含义（企业级必须可回归）：

- `conversationVersion`：会话级版本号（设置变更/成员变更/禁言/免打扰等变更时递增）
- `cursor`：会话列表增量同步游标（全局游标或按用户游标）
- `deleted`：会话删除语义（对我删除 vs 解散群/被移出群）

### 8.2 多端一致（同账号不同端）

- 同一用户多端在线：
  - 服务端 fanout 同时投递（或按策略只投递“主端”）
  - 已读水位以服务端为准，任一端上报即可推进
- 被踢/登出/撤销：
  - 必须同时撤销 IM 与 HTTP 访问能力

### 8.4 已读水位上报模型（推荐演进）

当前端侧/服务端已有“按 messageIds 标记已读”的实现基础，但企业级建议演进为“水位上报”：

- 端侧上报：`reportReadWatermark(conversationId, lastReadSequence)`
- 服务端规则：只升不降（`max(old, new)`），并产生跨端同步事件（WS 或增量 sync 可见）

收益：

- 降低频繁上报 messageIds 的带宽与 CPU
- 群聊/大消息量下可控
- 易于断线补偿对齐

### 8.5 增量同步接口形态（HTTP 优先，WS 可选）

建议先以 HTTP 落地，保证可调试/可回归：

#### 8.5.1 完整版本号版（对标企微/钉钉）

本项目建议采用“完整版本号版”的增量同步：用服务端分配的 **单调递增游标版本号** 代替 `updatedAt` 时间戳做 cursor。

核心思想：

- **cursorVersion（会话同步游标）是用户维度的全局版本号**：同一 `tenantId + userId` 下，只要“会话列表态”发生变化（新会话出现、最后消息变更、已读水位推进、置顶/免打扰修改、对我删除等），服务端就为该用户分配一个新的 `cursorVersion`。
- 客户端只需要保存一个 `cursorVersion`，即可通过 `sync` 拉取“自上次游标之后的全部变更”。

与 `conversationVersion` 的区别：

- `conversationVersion`：会话级版本号（同一 chat 的设置/元信息变更递增），用于端侧合并同一会话的不同快照。
- `cursorVersion`：用户级同步游标（全量会话列表变更序列），用于增量同步与缺口检测。

##### （1）数据落点（建议）

推荐在“会话-用户态”表中增加以下字段（若沿用 `im_chat_user` 也同理）：

- `cursor_version BIGINT NOT NULL DEFAULT 0`：该行（userId+chatId）的最近一次变更游标
- `conversation_version BIGINT NOT NULL DEFAULT 0`：该会话用户态的版本号（仅该会话相关变更递增）

并增加索引：

- `(tenant_id, user_id, cursor_version)`：支持按游标增量扫描

同时维护一张“用户游标分配器”（可 DB/Redis）：

- `im_user_cursor`
  - 唯一键：`(tenant_id, user_id)`
  - 字段：`next_cursor_version BIGINT NOT NULL`
  - 分配规则：每次需要产生会话列表变更时做原子 `+1`（示意：`UPDATE im_user_cursor SET next_cursor_version = LAST_INSERT_ID(next_cursor_version + 1) WHERE tenant_id=? AND user_id=?`）

说明：

- 选择 `cursorVersion` 的收益是**天然可检测缺口**：端侧发现 push version 跳跃即可触发补偿 sync。
- 相比 `updatedAt`，`cursorVersion` 不受时钟漂移、精度、同毫秒多次更新的影响。

##### （2）服务端版本号分配触发点

以下场景必须分配新的 `cursorVersion`（对齐企微/钉钉“会话列表强一致体验”）：

- 新会话出现（createOrGet、创建群成员入群触发会话创建）
- 新消息入会话导致 `lastMessage*` 变化
- 已读水位推进导致 `lastReadSequence/unreadCount` 变化
- 置顶/免打扰/草稿 等会话设置变更
- 对我删除（delete-for-me）/会话恢复（可选）

##### （3）HTTP：会话增量同步接口（完整版契约）

- `GET /system/im/conversation/sync?cursorVersion=...&limit=...`
- 响应：
  - `nextCursorVersion`：本次返回的最大游标（客户端保存）
  - `hasMore`：是否还有更多
  - `items`：会话变更快照列表（按 cursor_version 升序）

建议返回字段（最小闭环）：

- `chatId, conversationType, targetId`
- `cursorVersion, conversationVersion`
- `lastMessageSequence, lastReadSequence, unreadCount`
- `lastMessageType, lastMessageContent, lastMessageTime`
- `isPinned, noDisturb, draft`
- `deletedByUser`（或 tombstone 语义）

服务端实现要求：

- 只返回 `cursor_version > cursorVersion` 的记录
- 排序必须按 `cursor_version ASC`
- `nextCursorVersion` = 本次 items 中最大 `cursorVersion`（若空则回传入参）

##### （4）WS：会话事件与缺口补偿

WS 推送必须携带 `cursorVersion`（或将其作为 envelope 字段），端侧策略：

- 收到 `CONVERSATION_UPSERT`（或 `CONVERSATION_WATERMARK_UPDATE`）：
  - 若 `cursorVersion == localCursor+1`：直接 apply，并推进 localCursor
  - 若 `cursorVersion > localCursor+1`：判定缺口，立刻调用 `sync(cursorVersion=localCursor)` 补齐，然后再推进
  - 若 `cursorVersion <= localCursor`：认为是重复/乱序，按 `conversationVersion` 去重合并

##### （5）一致性与性能目标（对标）

- **最终一致**：WS 丢包/断线后，通过 `sync(cursorVersion)` 100% 恢复
- **弱网体验**：单次 sync 请求只返回变更集合（增量），避免全量 list
- **性能目标**（建议验收口径）：
  - `sync` P95 < 200ms（limit=100）
  - 端侧会话合并 O(k log n)（k 为变更数）
  - WS 事件到达后会话列表 UI 刷新 < 300ms（端侧）

#### 8.5.2 时间戳版（过渡/不推荐作为企业级最终形态）

说明：时间戳 cursor 实现简单，但存在时钟漂移、同毫秒多次更新丢变更、无法天然检测缺口等问题。
如需过渡可保留，但企业级对标企微/钉钉建议最终以 **8.5.1 cursorVersion 版**为准。

- `GET /system/im/conversation/sync?cursor=...&limit=...`
  - 返回：会话变更列表 + `nextCursor`
  - 建议最小字段集（避免端侧各自推导口径导致不一致）：
    - `conversationId/targetId/conversationType`
    - `lastMessageSequence/lastMessageId/lastMessageTime`
    - `lastReadSequence/lastReadTime`
    - `unreadCount/isPinned/noDisturb`
    - `updatedAt`（cursor 基于该字段推进）
- `GET /system/im/message/sync?conversationId=...&afterSequence=...&limit=...`
  - 返回：消息增量列表（按 sequence 升序）+ `hasMore`

已读水位上报（推荐演进，替代 messageIds 批量已读）：

- `PUT /system/im/conversation/read-watermark`
  - body：`{ conversationId, lastReadSequence, clientTime?, deviceId? }`
  - 规则：只升不降（`max(old,new)`）；建议返回 `{ applied, lastReadSequence, serverTime }`

list vs sync 并存策略：

- `GET /system/im/conversation/list`：可作为“全量兜底/首屏快速加载”。
- `GET /system/im/conversation/sync`：作为企业级权威同步入口（多端一致、离线补偿、点击 push 拉起对齐）。
- 已读上报：统一使用 `PUT /system/im/conversation/mark-read-seq?chatId=&readSequence=`（按 sequence 水位推进，单调递增）。

群聊场景下的 groupId -> conversationId 映射建议：

- 消息查询统一按 `conversationId`（会话）维度。
- 若端侧仅持有 `groupId`：先通过 `GET /system/im/conversation/get-by-target?targetId={groupId}&conversationType=2` 获取会话，再使用 `GET /system/im/message/list-by-chat?chatId=...`（或等价分页接口）分页拉取。

WS 增强（后续）：

- 在线时由 WS 推送“会话水位变更/新消息”，离线/缺洞由 HTTP sync 补齐

### 8.5.3 对话页加载机制（对齐微信/企业微信）

背景：聊天页的加载目标不是“固定取第一页”，而是“根据进入场景恢复到用户预期的消息窗口”。对标微信/企业微信，聊天页至少要区分“普通进入最近消息窗口”“搜索/引用/未读锚点进入”“继续上滑加载更早历史”“WS/刷新后补齐更新”四种路径。

当前工程问题（已在 `pages/message/chat.uvue` 体现）：

- 聊天页首屏固定调用 `GET /system/im/message/list-by-chat?chatId=&pageNo=1&pageSize=20`
- H5/页面刷新后再次执行同样逻辑，因此渲染位置会回到固定首屏，而不是“最近阅读窗口”或“最新消息窗口”
- 搜索/引用定位目前通过 `pageNo=2..10` 逐页穷举补拉，无法稳定覆盖大群、大会话与业务会话
- 页面仅有“滚到底”检测，没有“向上翻历史”的标准加载闭环

对标产品行为归纳（用于约束本项目，不直接依赖对方内部实现）：

- 企业微信支持“在当前会话内查找聊天记录”，说明聊天页必须支持**会话内锚点定位**，而不是只能固定翻页
- 企业微信支持多选消息后**合并转发并预览**，说明聊天页入口模型必须能与转发详情、原消息定位联动
- 企业微信客服 API 公开了 `service_state` 等会话状态字段，说明后续业务会话不应另起一套消息时间线，而应复用聊天页窗口模型，只在头部元信息层区分状态

设计原则（必须冻结）：

- **聊天页首屏禁止再以固定 `pageNo=1` 作为标准入口**
- **聊天页标准查询主键统一为 `chatId`**；群聊仅允许 `groupId -> chatId` 映射后查询；后续业务会话仅允许 `bizSessionId -> chatId` 映射后查询
- **首屏/锚点/历史/补偿四条路径分离**：最近窗口、锚点窗口、更早历史、更新补偿分别建模，禁止一个分页接口硬扛全部场景
- **服务端返回给聊天页的消息列表必须按 `sequence ASC` 供渲染使用**；若内部查询为倒序，必须在服务端或端侧统一翻转后再渲染
- **分页与补偿统一使用 sequence/cursor 语义，不再依赖 offset pageNo 表达阅读位置**

进入场景与标准行为：

1. **从会话列表普通进入单聊/群聊**
   - 默认加载“最近消息窗口（latest window）”，而不是最早 20 条
   - 首屏建议返回最近 `20~50` 条可见消息（按终端性能可配，默认建议 `30`）
   - 页面初始滚动位置在底部
   - 若存在未读区间：
     - 首屏窗口内包含首条未读：展示“以下为新消息”分割线
     - 首屏窗口未覆盖首条未读：展示“跳转到首条未读”入口，点击后走锚点窗口

2. **从搜索结果/引用回复/@我/推送进入**
   - 必须按 `anchorSequence`（优先）或 `anchorMessageId` 进入“锚点窗口（anchor window）”
   - 锚点窗口建议：`beforeLimit=15`、`afterLimit=10`（可按端型调整）
   - 命中消息定位后允许高亮，并继续支持“向上加载更早历史/向下补齐较新消息”
   - 禁止再使用 `pageNo=2..10` 穷举翻页定位

3. **页面刷新/重建（尤其 H5）**
   - 若路由携带显式锚点（搜索/引用/推送）：
     - 仍按锚点窗口恢复
   - 若无显式锚点：
     - 优先恢复本地保存的“阅读视口锚点”（建议持久化 `topVisibleSequence/bottomVisibleSequence/enteredFrom/latestOrAnchor`）
     - 视口状态过期或不存在时，回退到最近消息窗口
   - 刷新后**禁止回到最老一页**

4. **后续业务对话（客服/审批/应用消息会话等）进入**
   - 仍按统一 `chatId` 打开聊天页，加载机制与单聊/群聊一致
   - 仅会话头部元信息不同：例如 `bizSessionId`、`bizType`、`serviceState`、`assigneeId`、`customerId`、`readOnly`
   - 若对接企业微信客服类业务会话，建议 `serviceState` 直接复用上游 `service_state` 语义做映射，避免同一状态在 IM 层再次命名漂移
   - 已结束/只读业务会话仍允许按最近窗口或锚点窗口查看历史，但输入区可按 `readOnly` 控制

推荐接口分层（聊天页标准）：

- **最近窗口（首屏）**
  - `GET /system/im/message/window?chatId=...&mode=latest&limit=30`
  - 响应建议：
    - `items[]`（按 `sequence ASC`）
    - `hasOlder`
    - `hasNewer`
    - `oldestSequence`
    - `newestSequence`
    - `firstUnreadSequence?`

- **锚点窗口（搜索/引用/未读定位）**
  - `GET /system/im/message/window?chatId=...&anchorSequence=...&beforeLimit=15&afterLimit=10`
  - 兼容：若端侧仅有 `anchorMessageId`，服务端先解析出对应 `sequence` 再返回窗口
  - 响应建议：
    - `items[]`（按 `sequence ASC`）
    - `anchorSequence`
    - `hasOlder`
    - `hasNewer`
    - `oldestSequence`
    - `newestSequence`

- **更早历史（向上翻页）**
  - `GET /system/im/message/history?chatId=...&beforeSequence=...&limit=30`
  - 语义：返回 `sequence < beforeSequence` 的消息窗口，响应按 `sequence ASC` 供端侧 prepend

- **较新消息补偿（保留现有）**
  - `GET /system/im/message/pull?chatId=...&lastSequence=...&limit=200`
  - 语义：返回 `sequence > lastSequence` 的增量消息，主要用于断线补偿、刷新校准、WS gap 修复

兼容与废弃策略：

- `GET /system/im/message/list-by-chat?chatId=&pageNo=&pageSize=` 可保留为：
  - 管理后台分页
  - 过渡期兼容接口
- 但 **聊天页首屏、锚点定位、向上翻历史** 不再以该接口作为长期标准

端侧聊天页状态机（必须遵循）：

- `entryMode`：`latest | anchor | restore`
- `viewportAnchorSequence`：当前视口锚点（建议取首个可见消息或中位可见消息）
- `oldestLoadedSequence`：当前已加载窗口最老 sequence
- `newestLoadedSequence`：当前已加载窗口最新 sequence
- `hasOlder/hasNewer`：是否仍有更老/更新消息可加载

端侧标准流程：

1. 进入聊天页先渲染本地缓存（若有）
2. 根据 `entryMode` 请求 `window(latest|anchor)`，用服务端结果覆盖/合并本地缓存
3. 页面滚动到顶部时触发 `history(beforeSequence=oldestLoadedSequence)`，prepend 后保持视口稳定
4. 页面停留时通过 WS + `pull(lastSequence=newestLoadedSequence)` 追平较新消息
5. 页面离开时持久化 `viewportAnchorSequence/topVisibleSequence/bottomVisibleSequence`

统一不变式：

- 单聊、群聊、业务会话都共享同一套“时间线窗口”模型，差异只体现在会话元信息与权限
- 查询消息列表时不得直接使用 `groupId`、`externalUserId`、`businessId` 作为主键代替 `chatId`
- 聊天页刷新后若无显式锚点，应恢复“最近窗口或上次阅读窗口”，而不是数据库最老页
- 搜索结果跳转、引用定位、首条未读定位三者统一走锚点窗口，不得各写一套分页逻辑
- 大群/大会话下，端侧永远只维护“当前窗口 + 必要缓存”，不全量拉取全历史

#### 8.5.3.1 多端兼容规则（Android / iOS / Web）

本节用于把“聊天页加载机制”冻结成跨端统一语义，避免 Android、iOS、Web 各自出现不同的加载与恢复口径。

基础兼容约束（结合当前 uni-app x 能力）：

- 聊天页滚动容器统一使用 `scroll-view` 语义，必须同时具备：
  - `scroll`
  - `scrolltoupper`
  - `scrolltolower`
  - `scroll-into-view`
- Android / iOS / Web 的聊天页都必须实现：
  - 最近窗口进入
  - 锚点窗口进入
  - 向上翻历史
  - 较新消息补偿
  - 阅读视口恢复
- 任一端不得因为“平台能力不足”回退为固定 `pageNo=1` 入口

平台差异与统一策略：

- **Web**
  - 页面刷新频繁，必须优先支持 `restore` 模式
  - 可使用“可见区域观察”能力（如 Intersection Observer 语义）辅助计算 `topVisibleSequence/bottomVisibleSequence`
  - 页面切后台/切标签页时，需基于可见性状态收敛自动已读、自动播放、重型预加载
- **Android**
  - 文件预览不得依赖系统 Office 是否安装；统一走 `file-preview + WebView/在线预览`
  - Android System WebView 存在碎片化，聊天页内嵌 WebView 仅用于统一预览入口，不得承载主时间线
- **iOS**
  - 文件预览同样统一走 `file-preview + WebView/在线预览`
  - iOS WebView（WKWebView）对跨域 cookie 与部分嵌入行为有限制，因此文件预览与业务 H5 页面不得依赖“跨域 cookie 才能拿到内容”；优先使用短期 URL 或服务端聚合预览 URL

媒体播放统一规则：

- `VOICE`、`VIDEO` 在 `latest/anchor/restore` 三种进入模式下都**禁止自动播放**
- Web 端必须假设浏览器可能阻止自动播放，所有音视频播放都以用户手势触发为准
- 聊天页切后台、路由离开、会话切换时：
  - 语音播放停止
  - 视频播放暂停或销毁播放器实例
- 锚点进入到语音/视频消息时：
  - 只滚动定位与高亮
  - 不自动展开播放器

媒体资源加载统一规则：

- `IMAGE/VIDEO/STICKER` 首屏与历史窗口优先使用缩略图、封面图、轻量预览图
- 原图/原视频地址仅在点击查看时解析，不在聊天页首屏批量解析
- `FILE` 消息首屏只展示元数据（名称/大小/类型图标），不预取长期 URL
- `LOCATION` 首屏只展示静态卡片/快照，不在聊天页首屏初始化地图 SDK

端侧实现建议（AI/开发执行口径）：

- 若平台支持可见区域观察：优先用“可见消息序列”维护 `viewportAnchorSequence`
- 若平台不稳定或观察能力成本高：退化为滚动事件 + DOM/节点测量，但输出语义必须仍是：
  - `topVisibleSequence`
  - `bottomVisibleSequence`
  - `viewportAnchorSequence`
- 同一套缓存字段名与路由入参必须在 Android / iOS / Web 保持一致，禁止端侧私有命名漂移

#### 8.5.3.2 聊天页入口参数契约（AI 可执行，必须冻结）

聊天页入口路由必须收敛到以下参数集合；业务侧、搜索页、收藏页、转发详情页都只能复用这套契约，不得各自私造跳转参数。

必选参数：

- `chatId: string`

可选参数：

- `entryMode: 'latest' | 'anchor' | 'restore'`
- `anchorSequence?: string`
- `anchorMessageId?: string`
- `highlight?: 'true' | 'false'`
- `source?: 'conversation-list' | 'search' | 'quote' | 'mention' | 'push' | 'favorite' | 'forward-detail' | 'biz-session'`
- `conversationBizType?: string`
- `bizSessionId?: string`
- `readOnly?: 'true' | 'false'`

入口优先级（强制）：

1. 若存在 `anchorSequence`：走 `entryMode=anchor`
2. 否则若存在 `anchorMessageId`：先解析 sequence，再走 `entryMode=anchor`
3. 否则若存在可用的本地阅读视口缓存：走 `entryMode=restore`
4. 否则：走 `entryMode=latest`

禁止项：

- 禁止仅传 `groupId` 直接进入聊天页后拉消息
- 禁止仅传 `bizSessionId` 直接查消息
- 禁止用 `pageNo/pageSize` 作为聊天页路由参数表达阅读位置
- 禁止让搜索页、收藏页、引用详情页分别定义不同的跳转字段

#### 8.5.3.3 与现有消息能力的融合规则（AI 可执行）

本节是“聊天页入口模型”与现有功能域的融合规范。原则：**所有消息能力都必须能在 `latest / anchor / history / pull` 四条路径下保持一致语义**。

1. `TEXT / QUOTE_REPLY`
   - 普通进入：参与最近窗口展示
   - 引用点击：若目标消息不在当前窗口，必须走锚点窗口，不得固定翻页穷举
   - 刷新恢复：引用链只恢复当前渲染所需快照，不要求一次性补全全链路历史

2. `RECALL / DELETE_FOR_ME / CLEAR_HISTORY`
   - `latest/history/pull/window` 四类接口都必须返回最终态
   - 锚点进入到已撤回消息：落到“撤回提示”而非原文
   - 收藏、搜索、转发详情再打开原消息时，如最终态已变化，仍以最终态渲染
   - “重新编辑”入口只受消息最终态与权限控制，不受进入模式影响

3. `FORWARD_SINGLE / FORWARD_COMBINE`
   - 转发消息本身是独立新消息，进入目标会话后按最近窗口处理
   - 合并转发详情中点击某条原消息：
     - 若有 `originalChatId + originalSequence`：直接走锚点窗口
     - 若只有 `originalMessageId`：先解析 sequence，再走锚点窗口
   - 原消息已撤回/删除时，详情页显示最终态占位，不得静默失败

4. `MENTION`
   - `@我`、群公告提及、业务提醒进入聊天页时统一走锚点窗口
   - `mentions[]` 必须在 `latest/history/pull` 三条链路中结构一致
   - 聊天页首屏不允许因为 mention 渲染而触发额外整页重排；mentions 解析应与消息体解析同批完成

5. `READ_RECEIPT`
   - 聊天页窗口加载不等于已读详情全量加载
   - 已读/未读人数明细只对“当前可见且需要展示入口的消息”懒加载
   - 大群场景禁止因为进入聊天页就批量拉所有消息的已读详情

6. `STICKER / EMOJI / 动画表情`
   - `latest/history/anchor` 统一按结构化贴纸载荷渲染
   - 动画表情首屏以轻量预览优先，避免一次性解码整屏 GIF 导致 Web/iOS/低端 Android 卡顿
   - “收藏到表情”与“消息收藏 Favorite”必须区分：前者写个人表情库，后者写消息收藏

7. `VOICE`
   - 语音消息进入窗口只渲染气泡、时长、读态，不自动播放
   - 锚点定位到语音消息时仅高亮，不自动播放
   - 语音播放实例全页唯一，切换消息或离页时停止

8. `IMAGE / VIDEO`
   - 窗口加载阶段优先封面/缩略图
   - 点击后再解析原图/视频播放地址
   - 视频消息在 Web 端必须假设浏览器会限制自动播放

9. `FILE`
   - 文件消息在聊天页、搜索页、收藏页、转发详情页的打开入口统一走 `file-preview`
   - 文件预览失败时必须有“下载/重试”兜底
   - 不允许在聊天页首屏批量换取所有 `fileId -> presigned-url`

10. `LOCATION`
   - 聊天页只展示位置快照与标题/地址
   - 点击后按平台能力打开地图；失败时至少允许复制地址或经纬度
   - 位置消息锚点进入只需要定位，不需要预初始化地图组件

11. `CARD / 名片 / 应用卡片`
   - 卡片消息作为不可变快照渲染，进入模式不改变其展示结构
   - 点击卡片打开详情页时：
     - 若目标实体仍存在：正常打开
     - 若目标实体已失效：展示卡片快照或失效占位，不得空白

12. `FAVORITE`
   - 收藏列表进入聊天页必须优先携带 `chatId + anchorSequence`
   - 若只有 `messageId`，必须补解析 sequence 后再进入
   - 原消息撤回/删除后，收藏记录仍存在，但会话内定位后显示最终态占位

13. `草稿 / 输入状态 / 业务会话只读`
   - `restore` 模式恢复阅读窗口时，不得覆盖当前草稿内容
   - 业务会话 `readOnly=true` 时：
     - 允许查看最近窗口/锚点窗口
     - 禁止展示发送、语音录制、@选择、上传入口
   - 输入状态同步只与“当前活跃会话 + 输入框焦点”绑定，不随历史窗口翻页重复发送

14. `搜索 / 推送 / 收藏 / 转发详情` 四类外部入口
   - 统一收敛到聊天页入口契约
   - 统一优先用 `anchorSequence`
   - 无法定位时必须给出显式提示，不得无提示落到会话底部

与现有工程的对应改造建议：

- `chat.uvue#loadMessages`：从“固定 `pageNo=1,pageSize=20`”改为“按 `entryMode` 选择 latest/anchor window”
- `chat.uvue#loadHistoryUntilFound`：移除 `pageNo=2..10` 穷举逻辑，改为基于 `anchorSequence/beforeSequence` 的窗口补拉
- 聊天滚动容器补充“向上加载更多”入口（建议 `scrolltoupper` 或等价观察器），形成 prepend 闭环
- `message-service.uts`：缓存不再只作为“已加载消息集合”，还要维护 `oldestLoadedSequence/newestLoadedSequence/viewportAnchorSequence`
- H5 刷新恢复：本地持久化最近一次阅读视口，默认 TTL 建议 `10~30` 分钟，超时回退到 latest window

对标体验结论（从产品行为抽象，不直接绑定厂商实现细节）：

- 微信/企业微信的聊天页核心体验不是“第一页”，而是“最近消息窗口 + 搜索/引用锚点窗口 + 上滑继续加载”
- 未来业务对话（客服/应用会话）也必须复用这套窗口模型，否则会在搜索定位、刷新恢复、只读历史查看上重复踩坑

### 8.6 缺洞（gap）处理标准

客户端必须可处理以下情况：

- 收到 `sequence=105`，但本地缺 `103/104`
- WS 短暂乱序
- 收到撤回/编辑事件，但原消息尚未拉取到

标准处理：

- 渲染层按 `sequence` 排序
- 缺洞超过阈值（例如 500ms~2s）仍未补齐：触发 `syncMessages(afterSequence=lastPulledSequence)`
- 若先收到“事件类消息（撤回/编辑）”：允许先落事件占位，待原消息补齐后再合并状态

### 8.7 多端一致性不变式（对齐企微/钉钉）

同一账号多端同时在线时，必须遵守以下不变式，否则会出现“看得到但对不上”的企业级体验问题：

- **会话未读以服务端为准**：端侧不得仅靠本地消息列表推导未读
- **已读水位只升不降**：任一端上报 `lastReadSequence`，服务端取 `max(old, new)`，并向其他端同步推进
- **撤回/编辑/删除是消息状态，不是消息是否存在**：服务端必须给出“最终状态”，端侧以最终状态渲染
- **幂等与去重全链路成立**：跨端同步同一消息/事件时，端侧去重键稳定（`conversationId + messageId`）

### 8.8 多端已读推进与同步策略

推荐策略（企业级）：

- 端侧上报：`reportReadWatermark(conversationId, lastReadSequence)`
- 服务端落库：更新 `im_conversation_user.last_read_sequence`
- 服务端同步：
  - WS 在线端：推送“会话水位变更事件”（包含 conversationId/lastReadSequence/unreadCount）
  - HTTP 增量：`syncConversations(cursor)` 返回最新水位

端侧处理：

- 收到“水位变更事件”时：
  - 若本端会话当前未打开：仅更新会话未读/角标
  - 若本端正在该会话：更新“对方已读”展示（单聊）或已读聚合（群聊）

### 8.9 撤回/编辑与补偿同步的冲突规则

企业级要求：无论事件先到还是消息先到，最终状态必须一致。

建议服务端输出统一的“消息最终态字段”（至少包括）：

- `status`：NORMAL / RECALLED / DELETED_FOR_ME（示例）
- `edited`：true/false
- `rev`：消息版本号（每次撤回/编辑递增）

端侧合并规则：

- **同一 messageId**：以 `rev` 更大者覆盖（或以 serverTime 更晚者覆盖），保证最终态一致
- 若先收到撤回/编辑事件但本地无原消息：
  - 先落“事件占位”到本地状态表（messageId -> {status, rev}）
  - 待补偿拉取到原消息后再合并渲染
- 补偿拉取返回的消息必须带最终态字段，避免“撤回后又被补偿拉回原文”

### 8.10 “对我删除”（Delete-for-me）跨端一致

企业级常见语义：删除仅影响当前用户的展示，但需跨端保持一致（同一账号在其他设备也不再显示）。

落地实现（当前工程，Route-A：全局消息单份存储）：

- 服务端为用户维度维护“删除墓碑（tombstone）”表：`im_chat_message_tombstone(tenantId, chatId, userId, messageId, deletedAt)`
- REST：`DELETE /system/im/message/delete?id={messageId}`（对我删除，幂等）
- 查询口径（必须过滤）：
  - `GET /system/im/message/list-by-chat?chatId=...`
  - `GET /system/im/message/pull?chatId=...&lastSequence=...`
  - `GET /system/im/message/page`
  - `getMessageDetail(messageId)`（若命中 tombstone：按不存在处理）
- 多端同步：删除成功后分配 `cursorVersion` 并推送 `SYSTEM_NOTIFY(cursorVersion)`，端侧触发增量 `syncConversations(cursor)`；同时推送 `BADGE_UPDATE` 作为即时角标刷新（最终态仍以 sync 为准）

端侧规则：

- tombstone 命中：本地不展示该 messageId
- tombstone 不得影响审计与管理员能力（服务端仍保留原消息）

回归用例（企业级必测）：

- A 端删除 messageId=M；B 端在线：收到 `SYSTEM_NOTIFY(cursorVersion)` 后增量 sync，会话/消息列表最终不再出现 M
- B 端离线：A 删除后，B 重连并 `pull/list-by-chat`，返回结果必须过滤 M（不允许“删除后又被补偿拉回”）

### 8.10.1 “清空聊天记录”（Clear-history，按水位）跨端一致

企业级常见语义：清空仅影响当前用户视图，服务端保留历史（审计/合规），并要求跨端一致。

落地实现（当前工程）：

- 服务端为用户维度维护“清空水位”表：`im_chat_clear_watermark(tenantId, chatId, userId, clearSequence, clearedAt)`
- clearSequence 规则：单调递增；对该用户 `sequence <= clearSequence` 的消息不可见
- REST：`DELETE /system/im/message/clear?chatId={chatId}`（对我清空，幂等）
- 查询口径（必须过滤）：`list-by-chat/pull/page/detail`
- 多端同步：同 delete-for-me，分配 `cursorVersion` 并推送 `SYSTEM_NOTIFY(cursorVersion)` + `BADGE_UPDATE`

回归用例（企业级必测）：

- A 端清空 chatId=C；B 端在线：增量 sync 后该会话消息列表不再展示清空前消息
- B 端离线：A 清空后，B 重连并 `pull/list-by-chat`，返回结果不得包含 `sequence <= clearSequence` 的消息

### 8.11 主端策略（可选，对齐企业产品的“多端体验一致”）

对齐企微/钉钉可选策略：同一账号多端在线时，可配置“主端优先”或“全端同步”。

- **全端同步**（默认推荐）：所有在线端都收到消息与水位变更
- **主端优先**（运营可配）：仅主端接收实时消息，其他端仅同步会话水位/角标，进入会话时再补偿拉取

无论采用哪种策略，必须保证：

- `syncConversations/syncMessages` 仍可把非主端补齐到最新状态
- 被踢/撤销/重登等系统 CLOSE 仍需所有端一致生效

### 8.12 全局搜索与聊天记录搜索（对齐 UI 方案）

目标：对齐企业微信/钉钉的“搜索入口”体验，形成可回归的页面流转与数据契约，并与本项目既有的“文件统一预览入口（file-preview）”保持一致。

后端接口权威入口：

- App 端 IM 相关接口以 `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im` 下的 Controller 为准。
- 任何端侧 API 封装、文档契约、联调口径，必须以该目录中 `@RequestMapping/@GetMapping/...` 的映射为最终依据。

#### 8.12.1 页面信息架构（按 UI 方案拆分）

1. **聚合搜索页**：`/pages/common/search`
    - 输入框：placeholder = “搜索联系人、群聊、消息”
    - 结果分区（可按产品需要启用/隐藏）：
      - 联系人（TopN）
      - 群聊（TopN，显示成员数）
      - 应用（可选，工作台/应用入口）
      - 详细搜索：
        - 搜我的群组：`keyword` 维度的群组搜索
        - 搜聊天记录：`keyword` 维度的消息全文搜索

2. **聊天记录搜索页**（独立结果页）：`/pages/common/search-chat-history`
    - 标题：`搜聊天记录:{keyword}`
    - 展示：命中的会话摘要（chatName/群名）+ 命中消息片段（高亮 keyword）+ 时间
    - 交互：点击某条结果 -> 进入对应会话并定位到命中消息
    - 列表：支持“上拉加载更多”（分页）

#### 8.12.2 页面流转（强制统一）

- 任意页面点击“搜索”入口 -> `navigateTo('/pages/common/search')`
- 聚合搜索页：
  - 点击联系人 -> 用户详情页（或发起单聊并进入会话）
  - 点击群聊 -> 进入群聊会话页
  - 点击“搜聊天记录” -> 进入 `search-chat-history`（携带 `keyword`）
- 聊天记录搜索页：
  - 点击结果 -> 进入 `pages/message/chat`，并携带 `chatId` + `anchorMessageId/anchorSequence`（用于定位）

#### 8.12.3 数据契约与索引（以现有工程为准）

本项目已存在后端接口与端侧调用口径：

- `GET /system/im/message/search`
- 端侧：`api/message.uts#searchMessages`；`services/message-search-service.uts`

当前缺口（需企业级补齐）：

- 会话/群聊维度的服务端搜索接口（端侧聚合搜索中“群聊”目前只能基于 `conversation/list` 本地过滤，数据量大时性能与实时性不可控）
- 热门搜索（热词）服务端配置接口（端侧目前为本地默认 + storage 缓存兜底）

建议补齐契约（示意）：

- `GET /system/im/conversation/search?keyword=...&conversationType=2&pageNo=...&pageSize=...`
  - 响应：`PageResult<AppImConversationRespVO>`（或精简 VO，至少含 chatId/targetName/groupMemberCount/conversationType）
- `GET /system/im/search/hot`（或 `GET /system/im/config/hot-search`）
  - 响应：`{ list: string[], version?: string, ttlSeconds?: number }`

建议冻结返回结构（示意，Long 全部按 string）：

- `items[]`：
  - `chatId: string`
  - `conversationType: number`（单聊/群聊）
  - `targetId: string`（对端 userId 或 groupId）
  - `chatName: string`
  - `messageId: string`
  - `sequence: string`
  - `senderId: string`
  - `sendTime: string|number`
  - `snippet: string`（命中片段，允许服务端生成高亮标记或纯文本）
- `pageNo/pageSize/hasMore` 或 `cursor/hasMore`

端侧合并规则：

- 点击跳转定位优先使用 `sequence`（会话维度单调递增）
- 若仅能拿到 `messageId`：进入会话后通过 pull/list-by-chat 定位 messageId 对应的 sequence 再定位

#### 8.12.4 与“文件统一预览入口”的耦合点（必须遵循）

搜索结果中若展示到 FILE/IMAGE/VIDEO 类型消息：

- 点击文件：必须走 `pages/common/file-preview`（端侧统一入口），禁止在搜索页单独实现下载/预览。
- 传参规则：
  - 能拿到 `fileId`：只传 `fileId`（优先），由后端 `getFileOpenStrategy` 决定 PREVIEW/DOWNLOAD。
  - 仅兼容期才传 `url`（fallback）。

### 8.3 大会话/大群优化（企业 IM 常见约束）

- 群聊已读回执：
  - 默认不对每条消息返回全量已读成员列表
  - 采用“已读人数/未读人数”聚合，必要时分页查询
- 消息同步：
  - `limit` 分页 + 游标
  - 支持按时间/sequence 断点续拉

---

## 9. 离线推送（DCloud 优先 + 极光备份）

### 9.1 目标

- 用户离线或后台被系统限制网络时仍可接收提醒
- 推送只做“唤醒/提醒”，消息内容以安全为先（敏感内容可只推摘要）

企业级要求：推送必须与“消息最终态 + 会话水位”一致，避免出现：

- 推送到了，但消息被撤回/删除后客户端仍展示原文
- 多次重投/补偿导致同一消息重复推送
- 免打扰开启仍推送，或推送不推但角标/未读不一致

### 9.2 推送通道策略

- 主：DCloud 厂商推送组件（统一集成）
- 备：极光推送（当 DCloud 在特定机型/渠道不可用时兜底）

建议输出统一通道抽象（仅作为标准，具体实现由 Backlog 落地）：

- `PushProvider`：DCloud/JPush
- `PushTarget`：设备 token（与 userId/deviceId 绑定）
- `PushPayload`：仅包含唤醒所需字段（见 9.5）

### 9.3 推送与 IM 的一致性

- 推送到达 -> 点击进入 -> 走 IM/HTTP 拉取最新会话与消息
- 推送仅触发“拉取/对齐”，不作为消息一致性的唯一来源

不变式：

- 客户端被拉起后必须走 `syncConversations(cursor)` 与 `syncMessages(...)` 对齐到最新状态
- 推送 payload 不应承载“权威消息内容”，最多承载摘要（且必须允许被服务端最终态覆盖）

### 9.4 推送闭环（企业级必须：去重、撤回、免打扰）

- 去重：同一条消息（messageId）对同一设备最多推送一次
- 撤回：若消息被撤回且推送已下发，客户端拉起后必须以“服务端最新状态”为准
- 免打扰：
  - 会话级免打扰、群免打扰、夜间免打扰
  - 服务端下发推送前需要查询用户通知策略

### 9.5 Push Payload（最小化，安全优先）

建议仅包含以下字段：

- `tenantId`
- `conversationId`
- `messageId`
- `messageType`
- `senderId`（可选）
- `pushTime`
- `title/summary`（可选，且必须可被撤回/敏感策略覆盖）

禁止把完整消息体、附件直链等敏感信息放入 payload。

### 9.6 推送 token 绑定模型（与多端一致对齐）

企业级要求：同一用户多端、多 token；换设备/重装/切账号必须解绑/重绑。

- 绑定维度：`tenantId + userId + deviceId + provider`
- token 更新：同一维度更新时覆盖旧 token，并记录更新时间
- 登出/被踢：应清理当前设备 token（或标记失效），避免继续推送

### 9.7 离线触发策略（何时推送）

推送触发必须满足：

- 接收方在该会话未读水位落后（`unreadCount > 0`）
- 接收方“当前无在线可达端”或端处于不可达状态（后台/系统限制网络等）
- 免打扰策略允许（见 9.8）

触发建议（可配置）：

- 在线但后台：可延迟推送（例如 30s 无前台活跃再推）
- 完全离线：立即推送

### 9.8 免打扰（DND）判定标准

判定输入：

- 会话级：`conversation.noDisturb`
- 群级：群禁言/群免打扰
- 用户级：夜间免打扰时间窗

判定输出：

- `ALLOW_PUSH`
- `SUPPRESS_PUSH_BUT_SYNC`（不推送，但未读/角标与 sync 必须正常推进）

### 9.9 推送去重（Dedup）标准

去重目标：同一条消息对同一设备最多推送一次。

- 去重键：`tenantId + userId + deviceId + messageId`
- 去重存储：Redis（TTL 建议 7~30 天，视消息漫游周期）
- 幂等要求：重投/补偿/重复入队不得重复推送

### 9.10 撤回与推送一致（对齐企微/钉钉）

场景：推送已下发，但消息随后撤回。

标准要求：客户端被拉起后以服务端最终态为准，不得展示原文。

- 服务端：
  - 撤回后消息最终态 `status=RECALLED` 必须可通过 sync/query 获取
  - 若 push payload 展示了摘要：撤回后不必“撤回推送通知”（多数平台不支持），但必须保证拉起后展示正确
- 客户端：
  - 点击推送进入会话后，必须先走 sync，再渲染落地页

### 9.11 点击拉起后的对齐流程（强制）

推荐流程（先会话、再消息）：

1. App 被 push 拉起 -> 获取当前登录态
2. 若未登录/需要重登：按 CLOSE/REAUTH_REQUIRED 流程走登录
3. 登录态有效：调用 `syncConversations(cursor)`
4. 定位到 `conversationId`：
  - 若本地 `lastPulledSequence < lastMessageSequence`：调用 `syncMessages(afterSequence=lastPulledSequence)`
5. 渲染会话页：以消息最终态字段渲染（撤回/编辑/tombstone 生效）

### 9.12 失败重试与可观测性（企业级必备）

推送链路必须可观测、可对账：

- 指标：
  - `push_send_total{provider,result}`
  - `push_dedup_suppressed_total`
  - `push_dnd_suppressed_total`
  - `push_click_open_total`
- 日志字段：`tenantId/userId/deviceId/provider/messageId/conversationId/dedupKey`

失败重试建议：

- provider 返回可重试错误：按退避重试（最大重试次数可配）
- token 失效：标记 token invalid 并触发客户端重新上报 token

---

## 10. 消息生命周期能力（企微/钉钉对齐）

### 10.1 已读回执

- 单聊：建议强一致（接收端上报 read，服务端转发给发送端并推进未读水位）
- 群聊：建议聚合（已读人数/未读人数），避免风暴

已读回执必须与“水位模型”（`lastReadSequence`）一致：

- 单聊：可展示“对方已读/未读”，但服务端权威仍以水位为准
- 群聊：默认只展示聚合人数，详情分页查询

建议 REST 契约（群聊聚合，避免风暴）：

- `GET /system/im/read-receipt/summary?messageId=...`：返回已读/未读聚合数字
- `GET /system/im/read-receipt/detail?messageId=...&status=read|unread&pageNo=...&pageSize=...`：按需分页查询成员列表

说明：推荐以会话维度 `lastReadSequence` 推导某 messageId 的 readCount（`lastReadSequence >= message.sequence`），避免逐条回执广播。

### 10.2 撤回/删除

- 撤回：
  - 触发方：发送端（受时限与权限控制）
  - 服务端：落库“撤回事件”，并向所有在线端广播撤回通知
  - 客户端：将原消息状态更新为“已撤回”（而非物理删除）

- 删除：
  - 企业 IM 语义通常为“对我删除”（本端不展示），服务端保留审计能力

#### 10.2.1 撤回（Recall）规则（企业级必须冻结）

权限模型建议：

- 普通用户：仅可撤回自己发送的消息
- 管理员/群主：可撤回群内任意消息（可配置开关）

时限策略建议：

- 单聊：默认 2 分钟（可配置）
- 群聊：默认 2 分钟；管理员撤回可放宽（可配置）

数据模型建议（与 8.9 最终态字段一致）：

- 消息记录不物理删除，更新 `status=RECALLED`
- `rev`：撤回事件使 `rev + 1`
- `recalledAt/recalledBy`：用于展示与审计

事件传播：

- WS：广播撤回事件（最少包含 conversationId/messageId/rev/status/recalledAt/recalledBy）
- HTTP sync：`syncMessages` 返回的消息必须带最终态字段，保证离线端补偿一致

不变式：

- 推送已下发也必须“拉起后不展示原文”（见 9.10）
- 撤回事件幂等：重复撤回同一 messageId 不应改变 `sequence`，只更新最终态（若已撤回则直接返回成功）

#### 10.2.2 删除（Delete-for-me）规则

企业 IM 推荐语义：

- “对我删除”：仅影响当前用户视图，但跨端保持一致（见 8.10）
- “对所有人删除”（不推荐，且需合规）：通常用撤回语义替代

实现建议：

- 服务端维护 tombstone（userId/conversationId/messageId/deletedAt）
- 查询与 sync 输出必须过滤/标记 tombstone

#### 10.2.3 撤回后的重新编辑（Re-edit after recall，对齐企微/钉钉）

- **撤回后的重新编辑（Re-edit after recall，对齐企微/钉钉）**
  - **语义（必须遵循）**：撤回后的“重新编辑”不是修改原消息，而是**回填原内容后发送一条新消息**；原撤回消息保持最终态不变。
  - **触发条件**：
    - 仅支持**普通文字消息**（引用消息/转发消息/图片/文件/位置/语音等不支持）
    - 仅当“撤回操作由发送者本人发起”时支持（群主/群管理员代撤回时：群主/群管理员/发送者均不允许重新编辑）
    - 仅在撤回后的 **5 分钟窗口** 内显示入口；超过窗口入口消失
  - **跨设备规则（2B）**：发送者账号的所有设备都应可看到“重新编辑”入口并可回填原文。
  - **实现要求**：
    - 服务端在撤回事件中，仅对“发送者本人”的所有在线设备下发 `originalContent/recallTime/recallBy`（不得广播给接收方）
    - 端侧点击“重新编辑”后，将 `originalContent` 回填到输入框，用户修改后走正常发送链路生成**新 messageId**
  - **禁止项（强制）**：未在本文档与 Backlog 明确设计/排期前，**禁止实现“编辑历史消息（Edit existing message）”**（即修改已发送消息内容并 `rev+1` 的能力）。

补充：表情回应（Reaction，可选）

- 建议受 feature-flag 控制，默认关闭。
- 建议独立路由：`/system/im/reaction/add`、`/system/im/reaction/remove`、`/system/im/reaction/list?messageId=...`
- 返回建议仅包含聚合结果（`emoji/count/isSelf`），避免返回全量 userId 列表导致大群风暴。

### 10.3 自定义表情包消息模型（Sticker/自定义贴纸，对齐微信）

自定义表情包采用“系统表情与自定义表情分层、用户个人表情库独立管理、发送链路轻量化”的设计，优先对齐微信“聊天输入区直接发送 + 个人收藏复用 + 低门槛添加”的思路，并兼容当前工程已存在的 `EMOJI(7)` / `STICKER(8)` 枚举与 uniappx 贴纸面板。

#### 10.3.1 设计目标

- **低门槛添加**：支持“从聊天中收藏”和“从相册导入”，不要求先创建完整表情专辑
- **发送轻量**：聊天发送只传 `stickerId/fileId` 等最小字段，避免每次发送重复上传
- **多端一致**：同账号下自定义表情库、排序、删除、最近使用记录保持一致
- **兼容现状**：Phase 1 允许继续携带 `url` 作为渲染兜底，逐步收敛到 `fileId + presigned` 体系

#### 10.3.2 类型分层

- `EMOJI(7)`：系统标准表情，强调编码稳定与跨端一致，正文/检索/输入框回填均以 `emojiCode` 为权威
- `STICKER(8)`：用户收藏或导入的图片/GIF 表情，强调个性化、快速发送与个人表情库管理
- 企业产品中不建议把两类能力混为同一种消息体：`EMOJI` 以编码为主，`STICKER` 以媒体资产为主

#### 10.3.3 STICKER 消息体

```json
{
  "stickerId": "stk_10001",
  "fileId": "1948392849201",
  "thumbFileId": "1948392849202",
  "url": "https://cdn.example.com/im/sticker/1948392849201.png",
  "md5": "e4d909c290d0fb1ca068ffaddf22cbd0",
  "width": 160,
  "height": 160,
  "source": "CUSTOM"
}
```

- `stickerId`：个人表情库主键；发送、删除、排序、最近使用都以此为锚点
- `fileId`：服务端权威媒体标识；用于鉴权下载、审计留痕、跨端恢复
- `url`：仅作兼容与缓存命中兜底，服务端不可只信任客户端 URL
- `md5`：用于防重复收藏、重复上传秒传与本地缓存复用
- `width/height`：端侧用于网格预览与消息气泡尺寸约束

#### 10.3.4 与当前工程的兼容策略

- 当前工程已具备：
  - 后端消息类型枚举：`EMOJI(7)`、`STICKER(8)`
  - 端侧输入区已有“emoji / sticker”双 Tab 结构
  - 本地贴纸管理仍为占位实现，当前主要以 `url` 直接渲染
- 因此推荐两阶段演进：
  - **Phase 1**：保留 `url` 渲染能力；补齐 `stickerId/fileId/md5` 等权威字段与个人表情库接口
  - **Phase 2**：统一切换为 `fileId -> presigned url` 拉取；最近使用、删除、排序改为服务端同步

#### 10.3.5 生命周期与最终态规则

- **发送**：发送自定义表情包生成新 `messageId/sequence`，原表情资产不复制，仅引用 `stickerId/fileId`
- **撤回**：撤回后消息最终态遵循 10.2；消息体不再展示原图，但个人表情库记录不受影响
- **转发**：
  - 逐条转发：允许转发 `STICKER`，目标会话收到独立新消息
  - 合并转发：列表摘要统一显示 `[表情]` 或 `[动画表情]`，详情中渲染静态快照，不展开二次编辑能力
- **收藏/删除**：
  - “收藏到表情”是写入个人表情库，不等于消息收藏（Favorite）
  - 删除个人表情只影响后续发送入口，不影响历史消息渲染与审计

### 10.4 自定义表情包管理与 UI 方案（对齐微信）

微信的核心思路不是让用户维护复杂的“专辑后台”，而是围绕聊天输入面板提供“最近可发、随手可加、集中可管”的轻量体验；本项目沿用该方向，并结合现有 uniappx 面板结构落地。

#### 10.4.1 输入面板信息架构

- 底部维持双 Tab：
  - `emoji`：系统 emoji
  - `sticker`：自定义表情包
- `sticker` 面板采用网格布局，首格固定为“添加”入口，其余格子展示最近/已收藏表情
- 默认优先展示最近使用，其次展示用户手动收藏的稳定表情
- 单张点击即发送，不再二次确认

#### 10.4.2 添加与管理入口

- **从聊天中添加**：长按图片/GIF/已收到的贴纸消息，显示“添加到表情”
- **从相册导入**：在 `sticker` 面板首格点击“+”，选择相册图片/GIF 上传
- **整理入口**：在表情管理页支持删除、排序，能力与微信“添加的单个表情 -> 整理”保持一致
- **容量限制**：默认建议每用户上限 150 张，可配置；与微信官方自定义表情上限口径保持一致，避免表情面板膨胀

#### 10.4.3 服务端数据模型

- `im_user_sticker`
  - `id`
  - `tenant_id`
  - `user_id`
  - `file_id`
  - `thumb_file_id`
  - `md5`
  - `sort_no`
  - `source_type`（`UPLOAD` / `CHAT_COLLECT` / `STORE`）
  - `status`（`ACTIVE` / `DELETED`）
  - `created_at` / `updated_at`
- `im_user_sticker_recent`
  - `user_id`
  - `sticker_id`
  - `last_used_at`
  - `use_count`

建议 DDL 草案（按当前 IM 表命名规范收口）：

```sql
CREATE TABLE `im_user_sticker` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `file_id` bigint NOT NULL COMMENT '原图文件ID',
  `thumb_file_id` bigint NULL DEFAULT NULL COMMENT '缩略图文件ID',
  `name` varchar(128) NULL DEFAULT NULL COMMENT '表情名称',
  `md5` varchar(64) NOT NULL COMMENT '文件MD5',
  `width` int NULL DEFAULT NULL COMMENT '宽度',
  `height` int NULL DEFAULT NULL COMMENT '高度',
  `mime_type` varchar(64) NULL DEFAULT NULL COMMENT '媒体类型',
  `source_type` tinyint NOT NULL DEFAULT 1 COMMENT '来源(1-上传 2-聊天收藏 3-商店)',
  `source_message_id` bigint NULL DEFAULT NULL COMMENT '来源消息ID',
  `sort_no` int NOT NULL DEFAULT 0 COMMENT '排序号',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态(1-正常 2-已移除)',
  `creator` varchar(64) NULL DEFAULT '',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updater` varchar(64) NULL DEFAULT '',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  `tenant_id` bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_md5`(`tenant_id`, `user_id`, `md5`, `deleted`) USING BTREE,
  INDEX `idx_user_sort`(`tenant_id`, `user_id`, `sort_no`, `deleted`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM用户自定义表情表';

CREATE TABLE `im_user_sticker_recent` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `sticker_id` bigint NOT NULL COMMENT '表情ID',
  `last_used_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最近使用时间',
  `use_count` int NOT NULL DEFAULT 1 COMMENT '使用次数',
  `creator` varchar(64) NULL DEFAULT '',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updater` varchar(64) NULL DEFAULT '',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  `tenant_id` bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_sticker`(`tenant_id`, `user_id`, `sticker_id`, `deleted`) USING BTREE,
  INDEX `idx_user_last_used`(`tenant_id`, `user_id`, `last_used_at`, `deleted`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM用户最近使用表情表';
```

#### 10.4.4 建议接口

- `POST /system/im/sticker/upload`：上传相册图片/GIF，返回 `stickerId/fileId/thumbFileId`
- `POST /system/im/sticker/collect`：从消息收藏到个人表情库，body：`{ messageId }`
- `GET /system/im/sticker/list`：获取个人表情库（含排序、最近使用信息）
- `PUT /system/im/sticker/sort`：提交排序结果
- `DELETE /system/im/sticker/remove?id=...`：从个人表情库移除
- `POST /system/im/sticker/recent/use`：记录最近使用

建议与现有工程契约对齐：

- 上传复用现有 App 文件接口：
  - `POST /infra/file/upload-and-return-id`
  - 入参：`multipart/form-data(file, directory)`
  - 建议目录：`im/sticker/{userId}`
  - 出参已具备：`fileId/url/name/size/mimeType`
- IM 发送暂不新增专用发送接口，继续复用现有：
  - `POST /system/im/message/send`
  - `messageType = 8`
  - `content` 建议写入轻量摘要：`[动画表情]`
  - `extra` 写入 sticker JSON：`{ stickerId,fileId,thumbFileId?,url?,md5?,width?,height?,source }`
- `GET /system/im/sticker/list` 建议响应：
  - `recent[]`：最近使用（按 `lastUsedAt` 倒序，建议最多 20）
  - `favorites[]`：稳定收藏列表（按 `sortNo` 升序）
  - `version`：个人表情库版本号，便于端侧缓存
- `PUT /system/im/sticker/sort` 建议 body：
  - `{ items: [{ stickerId: "stk_1", sortNo: 1 }, ...] }`
- `POST /system/im/sticker/recent/use` 建议 body：
  - `{ stickerId: "stk_1" }`
  - 仅更新最近使用，不改变收藏排序

建议代码组织：

- Controller：
  - `controller/app/im/AppImStickerController.java`
- Service：
  - `service/im/ImStickerService.java`
  - `service/im/ImStickerServiceImpl.java`
- VO：
  - `controller/app/im/vo/sticker/AppImStickerUploadReqVO.java`
  - `controller/app/im/vo/sticker/AppImStickerCollectReqVO.java`
  - `controller/app/im/vo/sticker/AppImStickerListRespVO.java`
  - `controller/app/im/vo/sticker/AppImStickerSortReqVO.java`
- DO / Mapper：
  - `dal/dataobject/im/ImUserStickerDO.java`
  - `dal/dataobject/im/ImUserStickerRecentDO.java`
  - `dal/mysql/im/ImUserStickerMapper.java`
  - `dal/mysql/im/ImUserStickerRecentMapper.java`
- 发送链路复用：
  - `AppImMessageController` / `ImMessageServiceImpl` 仅补 `messageType=8` 校验与摘要逻辑，不额外分叉发送主链路

#### 10.4.5 体验与安全约束

- 仅允许用户收藏自己有权查看的消息图片/GIF，禁止通过裸 `fileId` 越权入库
- 上传文件仍走现有 `infra` 文件体系，复用鉴权、缩略图、病毒扫描与审计能力
- 表情库删除只影响入口，不删除底层文件的审计引用关系
- 历史消息渲染失败时需显示占位态，不得导致消息列表断裂

补充约束：

- 收藏来源白名单：仅允许 `IMAGE`、`EMOJI`、`STICKER` 三类消息进入“添加到表情”流程；`VOICE/FILE/LOCATION` 禁止展示该入口
- 上传校验：优先支持 PNG/JPG/GIF；单文件大小、像素边界与动图帧数沿用现有上传策略并可在 IM 侧增加更严格门禁
- 去重规则：同一用户维度下优先按 `md5` 去重；命中后直接复用已有 `stickerId`
- 缓存策略：端侧本地可缓存缩略图与最近使用，但权威排序、删除状态以服务端 `version` 为准

#### 10.4.6 端到端链路（推荐）

场景 A：从相册导入

1. 用户点击 `sticker` 面板首格 `+`
2. 端侧调用 `chooseImage(1)` 选择图片/GIF
3. 端侧调用 `POST /infra/file/upload-and-return-id`
4. 端侧拿到 `fileId/url` 后调用 `POST /system/im/sticker/upload`
5. 服务端完成去重、写入 `im_user_sticker`
6. 服务端返回 `stickerId/fileId/thumbFileId/url/version`
7. 端侧刷新 `GET /system/im/sticker/list`，将新表情插入面板首屏

场景 B：从聊天中收藏

1. 用户长按图片/GIF/贴纸消息
2. 端侧展示“添加到表情”
3. 调用 `POST /system/im/sticker/collect`，body：`{ messageId }`
4. 服务端校验消息可见性、类型合法性，并抽取 `fileId/md5/url`
5. 若已存在同 md5 收藏，则直接返回既有 `stickerId`
6. 端侧刷新表情面板并提示“已添加”

场景 C：点击表情发送

1. 端侧从 `sticker` 面板选择 `StickerItem`
2. 先调用 `POST /system/im/sticker/recent/use`
3. 再复用消息发送接口 `POST /system/im/message/send`
4. 服务端落库 `messageType=8`，摘要统一为 `[动画表情]`
5. 会话页、会话列表、转发详情页统一按 `extra` 渲染贴纸

#### 10.4.7 开发顺序（推荐）

- 第一步：后端先落 `im_user_sticker / im_user_sticker_recent` 与 list/upload/collect/remove/sort/recent 六个接口
- 第二步：前端把 `stickerManager.uts` 从本地 mock 改为服务端数据源，但先保留 `url` 渲染
- 第三步：聊天页补齐 `+上传`、`添加到表情`、`发送 STICKER(8)` 三个主入口
- 第四步：打通最近使用、删除、排序与多端刷新
- 第五步：收敛到 `fileId + presigned`，移除对裸 `url` 的强依赖

### 10.5 音视频/语音通话（RTC，可选，方案 1：信令复用 IM WS）

目标：对标企微/钉钉的“通话能力”时，优先把最难的部分（鉴权、多端一致、push 拉起、可观测、降级）复用到现有 IM 体系；媒体传输不走 IM，由第三方/WebRTC 承担。

范围拆分：

- 信令（Signaling）：复用当前 IM WebSocket（JSON/PB 双栈、鉴权续期、灰度/降级、错误码）
- 媒体（Media）：WebRTC + 第三方（声网/腾讯云/自建 SFU 任选其一），与 IM 解耦

#### 10.5.1 信令消息模型（建议）

建议两种方式（二选一，推荐先用 CUSTOM 演进，后续需要强约束再升为枚举）：

- 方式 A：`messageType=CUSTOM` + `body.subType=CALL_*`
- 方式 B：新增 `CALL_*` 枚举（proto 为权威）

最小信令集：

- `CALL_INVITE`（呼叫）
- `CALL_RINGING`（响铃/已送达）
- `CALL_ACCEPT`（接听）
- `CALL_REJECT`（拒绝）
- `CALL_END`（挂断/结束）
- `CALL_BUSY`（忙线）
- `CALL_TIMEOUT`（超时未接）

建议 body 最小字段：

- `callId`（全局唯一，幂等主键）
- `fromUserId/toUserId` 或 `conversationId`（单聊/群呼可演进）
- `callType`：AUDIO/VIDEO
- `sdpOffer/iceCandidates`（若采用“信令承载 SDP”，需注意大小限制与分片；也可仅承载第三方房间信息）
- `roomId/token`（第三方 RTC 鉴权信息，短 TTL）
- `clientTime/serverTime`、`traceId`

#### 10.5.2 通话状态机（企业级必须可回归）

建议服务端维护 call 会话的最终态与超时，端侧只做展示与媒体控制：

- 状态：INIT -> INVITED -> RINGING -> CONNECTED -> ENDED
- 超时：INVITED/RINGING 超过阈值（例如 30s）自动转 TIMEOUT 并推送结束事件
- 幂等：同一 `callId` 重复 INVITE/ACCEPT/END 不产生多次状态迁移

#### 10.5.3 多端一致与互斥规则（同账号多端）

- 同一账号多端：
  - 允许“多端同时响铃”，但只允许一个端 ACCEPT 成功（其余端收到 END/BUSY 并停止响铃）
  - 若配置“主端优先”（见 8.11）：仅主端响铃，其余端仅同步通话记录

#### 10.5.4 推送拉起与一致性

- 被叫离线：通过离线推送发送最小 payload（tenantId/callId/conversationId/callType），点击拉起后先走鉴权与 `syncConversations/syncMessages`，再进入通话页
- 推送不承载权威通话状态：权威状态以服务端 call state 为准

#### 10.5.5 与 IM 的耦合点：通话记录消息（必选）

- 每次通话结束（END/BUSY/TIMEOUT/REJECT）落一条“通话记录消息”（可作为 `messageType=CUSTOM` 的一种子类型）
- 目的：
  - 漫游/同步可见（在 `syncMessages` 中出现）
  - 可搜索/可审计（按租户合规策略）
  - push 摘要可控（例如“未接来电/通话时长”）

### 10.6 消息转发（Forward，对齐企微/钉钉）

消息转发是企业 IM 高频场景，需保证跨会话/跨群的消息复用体验与一致性。

#### 10.6.1 转发语义

- **逐条转发**：用户选择单条消息 -> 选择目标会话（单聊/群聊）-> 发送一条新消息（引用原消息内容）
- **合并转发**：用户选择多条消息 -> 选择目标会话 -> 生成一条"合并转发消息"（卡片形态，点击可查看原文列表）

#### 10.6.2 转发数据模型

逐条转发：
- 生成新 `messageId`、新 `sequence`
- `body.forwardedFrom`：原消息来源信息（`{ originalMessageId, originalChatId, originalSenderId, originalSendTime, originalMessageType }`)
- 内容复用：`body.content` 直接复用原消息正文（文本/图片/文件等）

合并转发：
- `messageType = FORWARD_COMBINE`（建议新增枚举，或使用 `CUSTOM + subType`）
- `body.messages[]`：被合并的消息列表（每条含 `messageId/chatId/senderId/sendTime/messageType/content/summary`）
- `body.summary`：合并消息摘要（例如 "【聊天记录】来自群xxx，共N条消息"）
- 消息数量限制：单次合并转发建议上限 100 条

#### 10.6.3 转发权限与隐私

- 权限：仅可转发自己可见的消息（已被删除/撤回的不可转发）
- 隐私：转发后，接收方可看到原发送者信息（不暴露原会话成员列表）
- 敏感内容：若原消息含敏感标记，转发时需提示或限制

#### 10.6.4 转发与最终态一致

- 若原消息被撤回/删除：转发后的消息不受影响（转发时已生成独立副本）
- 若转发消息被撤回：仅撤回转发消息，不影响原消息

#### 10.6.5 建议接口

- `POST /system/im/message/forward` body：`{ messageId: string, targetChatId: string }`（逐条转发）
- `POST /system/im/message/forward-combine` body：`{ messageIds: string[], targetChatId: string }`（合并转发）
- `GET /system/im/message/forward-preview?messageIds=...`：预览合并转发内容（可选）

> 注：转发审计功能（记录转发操作用于合规审计）暂不排期，后续迭代视合规需求再引入。

### 10.7 消息重发机制（Resend，对齐企微/钉钉）

消息发送失败时的重发体验是企业 IM 可靠性的关键组成部分。

#### 10.7.1 重发触发场景

- **网络超时**：发送请求超时（默认 30s），客户端显示发送失败
- **服务端异常**：返回 5xx 错误，消息未落库
- **ACK 未收到**：消息已发送但未收到服务端确认（可选，Phase 2）

#### 10.7.2 重发语义

- **幂等保证**：重发必须复用原 `messageId`，服务端按 `messageId` 去重
- **本地状态**：发送中 -> 发送失败 -> 重发中 -> 发送成功
- **用户触发**：失败消息显示重发按钮，用户点击后走正常发送链路

#### 10.7.3 端侧实现要点

- 失败消息在本地保留，标记 `status=FAILED`
- 重发时复用原 `messageId`、`clientTime`，更新 `serverTime`（服务端返回）
- 重发成功后更新本地状态，移除失败标记

#### 10.7.4 与 ACK 机制的关系

- 当前阶段（Phase 1）：重发主要基于 HTTP 请求结果，不依赖 ACK
- 后续阶段（Phase 2）：可结合 ACK 超时触发自动重发（需谨慎，避免重发风暴）

### 10.8 群@提及功能（Group Mention，对齐企微/钉钉）

群聊中@提及特定成员是企业 IM 高频场景，需保证通知可达与体验一致。

#### 10.8.1 @提及语义

- **触发方式**：输入 `@` 符号后弹出成员列表，选择后插入 `@昵称`
- **消息体结构**：`body.mentions[]` 包含被提及用户列表
- **通知规则**：被提及用户收到推送/角标，即使群免打扰开启

#### 10.8.2 数据模型

消息体扩展：
```json
{
  "content": "@张三 请查看这个文件",
  "mentions": [
    { "userId": "123", "nickname": "张三", "offset": 0, "length": 3 }
  ]
}
```

- `mentions[]`：被提及用户列表
  - `userId`：被提及用户 ID（必须）
  - `nickname`：提及时的昵称（用于展示）
  - `offset/length`：在 content 中的位置（可选，用于高亮）

#### 10.8.3 特殊提及类型

- **@所有人**：`mentions = [{ "userId": "ALL", "nickname": "所有人" }]`
  - 权限：仅群主/管理员可使用
  - 通知：所有群成员收到推送（即使群免打扰）
- **@特定人**：仅被提及者收到强提醒

#### 10.8.4 端侧渲染

- 高亮显示 `@昵称`（蓝色/特殊颜色）
- 点击 `@昵称` 可跳转到该用户资料页
- 被提及消息在列表中显示 `[有人@我]` 标记

### 10.9 群管理员撤回权限（Admin Recall，对齐企微/钉钉）

群管理员撤回群成员消息是企业 IM 合规管理的必要能力。

#### 10.9.1 权限模型

- **群主**：可撤回群内任意消息（不限时）
- **群管理员**：可撤回群内任意消息（可配置时限，默认 24 小时）
- **普通成员**：仅可撤回自己发送的消息（默认 2 分钟）

#### 10.9.2 配置开关

- `group.admin.recall.enabled`：是否允许管理员撤回（默认 true）
- `group.admin.recall.window-hours`：管理员撤回时限（默认 24 小时，0 表示不限）

#### 10.9.3 撤回通知

- 管理员撤回时，系统消息显示 "管理员XXX撤回了成员YYY的消息"
- 原发送者收到撤回通知（WS 推送）
- 被撤回消息不支持重新编辑（见 10.2.3）

### 10.10 位置消息（Location Message，对齐微信最小闭环）

位置消息用于“快速告知地点 + 一键导航”，本期只做最小闭环，不引入实时位置共享、轨迹与审计链路。

#### 10.10.0 地图厂商决策（冻结）

- 决策：默认厂商固定为腾讯位置服务（Tencent LBS）
- 决策依据（结合当前项目）：
  - 工程中已存在腾讯地图配置项：`shengyu.tencent-lbs-key`（`application-dev/local`）
  - 前端位置主链路已基于 `uni.chooseLocation + uni.openLocation`，与腾讯方案并不冲突
  - 本期仅需“位置卡片发送 + 搜索可选增强”，不需要引入重型地图 SDK
- 供应商策略：
  - P0：仅使用系统能力，不消耗第三方检索配额
  - P1：开启腾讯 WebService POI 搜索（服务端代理）
  - 若后续切换厂商，必须通过 `provider adapter` 层实现，不允许在页面层写死供应商

#### 10.10.1 最小闭环范围（本期必做）

- 发送入口：聊天页 `+` 面板点击“位置”
- 发送能力：支持“我的位置”与“搜索指定位置”后发送位置卡片
- 会话渲染：卡片展示 `地点名称 + 地址 + 地图缩略占位`
- 点击行为：接收方点击后查看位置详情，并可自行选择是否使用本机地图应用导航
- 非目标：实时位置共享、轨迹回放、围栏、审计留痕

#### 10.10.2 微信 UI 对齐要点（基于现网交互与现有原型）

- 入口在聊天输入区 `+` 面板，和图片/文件并列
- 选点页为“顶部搜索 + 地图 + POI 列表”结构，支持当前定位与关键词检索
- 发送后在聊天内显示位置卡片；点击后再触发地图查看/导航动作，而不是直接强跳第三方 App

#### 10.10.3 消息体冻结（兼容当前工程）

```json
{
  "type": "LOCATION",
  "latitude": 28.6837,
  "longitude": 115.8579,
  "address": "江西省南昌市红谷滩区丰和路",
  "name": "江西金控集团",
  "provider": "system",
  "poiId": ""
}
```

字段约束：

- 必填：`latitude`、`longitude`
- 条件必填：`name/address` 至少一个非空（兜底场景可 `name=位置`、`address` 为空）
- 选填：`provider`、`poiId`
- `name` 为空时，前端展示回退到 `address`
- `provider` 默认 `system`，可取 `tencent/amap/baidu`
- Long 规范：ID/序列相关字段继续按 `string` 传输，不改变现有约束

#### 10.10.4 工程现状校准与收口点（必须落实）

- 现状已具备：
  - 前端有位置气泡渲染与 `uni.openLocation` 打开能力
  - 协议枚举与后端处理器已有 `LOCATION(6/105)` 链路
- 现状差异：
  - 前端 `LocationMessageBody` 仅定义 `latitude/longitude/address`
  - 后端存储侧目前有“只落 `address` 文本”的路径，历史回显可能缺失坐标
- 本期收口（必须）：
  - 入库 `content` 必须可恢复 `latitude/longitude/address/name`（JSON 字符串或等价结构）
  - 禁止仅存纯地址文本，否则刷新后无法稳定导航、转发详情与收藏回跳也会失真
  - 旧数据兼容：若历史消息缺坐标，允许展示但点击导航需提示“历史位置缺少坐标”

#### 10.10.5 低成本地图方案与配额兜底

- 默认方案（P0）：优先使用 `uni.chooseLocation + uni.openLocation`，不引入新增商业 SDK 成本
- 增强方案（可选）：仅在 `chooseLocation` 不可用或搜索体验不达标时，增加 WebService POI 搜索（服务端代理调用）
- 供应商策略：默认优先腾讯（`im.location.search.provider=tencent`），但必须保留可插拔实现
- 配额治理：第三方检索能力必须挂开关 `im.location.search.enabled`，并配置阈值告警
- 免费额度/配额耗尽兜底（必须可用）：
  - 自动关闭远程 POI 搜索，保留“发送我的位置”
  - 允许发送“经纬度基础卡片”（`name=位置`，`address` 可空）
  - 保留本地最近选择地点（建议 20 条）供快速复用
  - 移动端显式提示“地图服务额度已用完，请联系管理员”
  - 提示形态要求：位置搜索页需展示可见“额度已用完”状态页（或阻断弹窗），禁止仅弱提示 toast
  - 管理端/日志补充错误码与配额告警，便于运维排查
- 成本口径约束：
  - 腾讯位置服务配额以控制台实时值为准，不在文档固化静态数字
  - 高德公开文档已给出基础搜索月配额与计费口径，作为兜底供应商比较基线

管理员开通与配置路径（腾讯）：

- 腾讯位置服务 WebService API 概述：`https://lbs.qq.com/service/webService/webServiceGuide/webServiceOverview`
- 腾讯位置服务常见问题（含配额/Key 分类入口）：`https://lbs.qq.com/faq/serverFaq/webServiceKey`
- 腾讯位置服务官网登录：`https://lbs.qq.com/`
- 控制台配额页（账号额度/扩容入口）：`https://lbs.qq.com/dev/console/quotaImprove`
- 控制台内操作路径（页面改版时以菜单为准）：
  - `控制台 -> 应用管理 -> 我的应用 -> 创建应用/添加 Key`
  - `控制台 -> Key 与配额（或配额管理） -> 账号额度 -> 分配额度`
  - `Key 安全设置 -> 授权 IP 或 SN 签名校验`
- 项目配置项（服务端）：
  - `shengyu.tencent-lbs-key`（已有）
  - 建议新增：`im.location.search.enabled`、`im.location.search.provider=tencent`、`im.location.search.quota-exhausted-tip`

参考资料（用于成本口径对齐）：

- 高德 WebService 流量限制说明：`https://lbs.amap.com/api/webservice/guide/tools/flowlevel`
- 高德开放平台升级与基础服务配额说明：`https://lbs.amap.com/upgrade`

#### 10.10.6 与现有消息能力并轨规则

- 转发：位置消息允许单条转发；合并转发预览统一显示 `[位置]`
- 撤回：沿用既有 `RECALLED + rev` 最终态规则，任何入口均不回流原文
- 引用：允许引用位置消息；引用预览优先 `name`，缺失回退 `address`
- 搜索/收藏回跳：统一走 `chatId + anchorSequence`，定位失败回退最近窗口并提示

### 10.10A 名片消息（Contact Card，对齐微信最小闭环）

名片消息用于“把某个用户快速介绍给当前会话”，本期只做企业内部联系人名片。

#### 10.10A.1 最小闭环范围（本期必做）

- 发送入口：聊天页 `+` 面板点击“名片”
- 选择对象：从当前租户通讯录中选择 1 名用户发送
- 消息渲染：会话内显示名片卡片（头像、姓名、部门/岗位摘要）
- 点击动作：接收方点击进入用户详情页，可继续“发消息/拨号（若有手机号）”
- 非目标：外部联系人、好友申请、审计、脱敏、复杂权限控制

#### 10.10A.2 协议策略（最小改动优先）

- 不新增 WS 基础协议版本，不新增 messageType 枚举
- 复用现有 `CUSTOM(9/106)`，约定 `body.type = "CONTACT_CARD"`
- 消息体建议：

```json
{
  "type": "CONTACT_CARD",
  "userId": "1876543210987654321",
  "displayName": "张三",
  "avatar": "",
  "deptName": "研发中心",
  "title": "后端工程师",
  "mobile": ""
}
```

#### 10.10A.3 复用与落地边界

- 发送侧复用通讯录检索/详情能力，不新增名片专用数据表
- 接收侧点击统一走 `pages/contacts/user-detail`
- 若名片用户已离职或不可见：卡片保留但详情页提示“该用户状态不可用”
- 与“应用卡片”区分：名片仅表示“人”，不承载业务审批/流程数据

#### 10.10A.4 工程收口点（必须）

- 会话摘要、搜索结果、合并转发详情需统一识别 `CONTACT_CARD` 并显示 `[名片]`
- `CUSTOM` 解析必须容错：JSON 解析失败时降级 `[自定义消息]`，不得白屏
- 前后端统一使用“发送时快照”，不依赖实时通讯录字段回填

#### 10.10A.5 与现有消息能力并轨规则

- 转发：支持逐条转发；合并转发明细中显示 `[名片] + displayName`
- 撤回：沿用既有撤回最终态，不显示名片原始内容
- 引用：允许引用名片；引用预览使用 `displayName`
- 搜索：关键字命中名片预览时，跳转仍走锚点窗口契约

### 10.11 草稿保存机制（Draft，对齐企微/钉钉）

草稿保存确保用户输入内容不丢失，跨端同步提升体验。

#### 10.11.1 草稿语义

- **本地优先**：草稿优先保存在本地（退出会话页时保存）
- **跨端同步**：可选支持跨端草稿同步（Phase 2）
- **生命周期**：消息发送成功后清除草稿；切换会话时保留

#### 10.11.2 草稿内容

- 文本内容：输入框中的文字
- @提及列表：已选择但未发送的 @用户
- 引用回复：引用的原消息（如有）
- 附件：已选择但未发送的图片/文件（本地路径）

#### 10.11.3 本地存储

- 存储位置：`uni.storage` 或本地文件
- 存储键：`draft_{chatId}`
- 存储时机：`onHide`/`onUnload`/输入停止 N 秒后

#### 10.11.4 跨端同步（可选，Phase 2）

- 接口：`PUT /system/im/conversation/draft`
- 请求体：`{ chatId, draft: { content, mentions, replyTo } }`
- 同步策略：通过 `cursorVersion` 增量同步

### 10.12 输入状态同步（Typing Indicator，对齐企微/钉钉）

输入状态同步增强实时沟通体验，但需控制频率避免风暴。

#### 10.12.1 适用范围

- **单聊**：双方可见输入状态
- **群聊**：默认关闭（可配置开启，仅显示 "有人正在输入"）

#### 10.12.2 状态类型

- `TYPING`：正在输入
- `STOP_TYPING`：停止输入（或超时自动触发）

#### 10.12.3 WS 消息模型

- `messageType = TYPING`（建议新增枚举）
- body：`{ chatId, status: "TYPING"|"STOP_TYPING" }`

#### 10.12.4 频率控制

- 客户端：输入时每 3 秒最多发送一次 TYPING
- 服务端：按 `userId + chatId` 去重，避免重复广播
- 超时：5 秒未收到 STOP_TYPING，自动清除状态

#### 10.12.5 展示规则

- 单聊：显示 "对方正在输入..."
- 群聊（若开启）：显示 "XXX正在输入..."
- 超时/停止：清除提示

### 10.13 收藏功能（Favorite/Collect，对齐微信最小闭环）

收藏功能用于“保存重要消息并可回到原会话定位”，本期仅做消息收藏最小闭环。

#### 10.13.1 最小闭环范围（本期必做）

- 入口：聊天消息长按菜单“收藏/取消收藏”
- 列表：收藏页分页查询（按收藏时间倒序）
- 回跳：点击收藏项可回到原会话并按锚点定位原消息
- 跨端：同账号跨端可见收藏记录
- 非目标：收藏分组/标签、全文检索、审计流水

#### 10.13.2 交互规范（对齐微信语义）

- 收藏动作是“引用消息”，不是复制消息正文
- 原消息撤回/删除后：收藏记录保留，但列表与详情展示“原消息已撤回/删除”最终态
- 聊天菜单中“添加到表情”与“消息收藏”必须区分，禁止复用同一 action

#### 10.13.3 数据模型（最小字段）

- 表：`im_message_favorite`
- 建议字段：
  - `id`、`tenant_id`、`user_id`、`message_id`、`chat_id`
  - `message_type`（收藏时快照类型）
  - `message_preview`（收藏时预览快照，避免列表页重组装）
  - `created_at`、`deleted`
- 唯一约束：`uniq_user_message(user_id, message_id, deleted)`

#### 10.13.4 接口冻结（最小闭环）

- `POST /system/im/favorite/add` body: `{ messageId: string }`
- `DELETE /system/im/favorite/remove?id=...`
- `GET /system/im/favorite/list?pageNo=&pageSize=`
- `GET /system/im/favorite/check?messageId=...`

列表项最小返回建议：

- `favoriteId`、`messageId`、`chatId`
- `messageType`、`preview`
- `status`（`NORMAL|RECALLED|DELETED`）
- `anchorSequence`（用于回会话定位）
- `createdAt`

#### 10.13.5 与会话定位契约

- 收藏页进入聊天页必须优先带 `chatId + anchorSequence`
- 找不到锚点时：自动回退最近窗口并提示“原消息未定位到，已跳转到最近消息”
- 不允许用 `pageNo/pageSize` 表达收藏回跳位置

#### 10.13.6 本期明确不做

- 不做收藏搜索和标签管理
- 不做收藏内容审计与审批
- 不做附件离线备份与永久直链

#### 10.13.7 与既有“添加到表情”解耦（工程强约束）

- 聊天长按菜单必须拆分两个 action：
  - `favorite_message`：消息收藏（进入收藏域）
  - `favorite_sticker`：添加到表情（进入个人表情库）
- 禁止复用同一 action key（当前工程存在复用风险，必须在实现阶段消除）
- `+` 面板“收藏”入口语义统一为“打开消息收藏列表”，不承载“添加到表情”

#### 10.13.8 位置/名片/收藏跨功能交互矩阵（本期冻结）

| 能力 | 位置 | 名片 | 收藏 |
| --- | --- | --- | --- |
| 转发（逐条） | 支持，预览 `[位置]` | 支持，预览 `[名片]` | 收藏记录不等于消息转发 |
| 合并转发详情 | 显示 `[位置]`，有坐标可导航 | 显示 `[名片] + displayName` | 点击收藏项回原会话，不进合并详情 |
| 撤回 | 显示最终态，不回流原文 | 显示最终态，不回流原文 | 收藏记录保留，状态变为 `RECALLED/DELETED` |
| 引用 | 可引用，预览 `name/address` | 可引用，预览 `displayName` | 收藏页跳转后仍可执行引用 |
| 搜索与锚点 | 统一 `anchorSequence` | 统一 `anchorSequence` | 统一 `chatId + anchorSequence` |

### 10.14 系统通知/机器人/应用消息

- 系统通知走独立 `messageType`，可单独限流、单独展示、单独推送策略
- 支持"应用消息卡片"类扩展（对齐企微/钉钉的工作台消息形态）

### 10.15 审计与合规（企业级必须）

合规目标：可审计、可追溯、可保全.

- 留存：消息原文（或加密存储）需按租户策略留存（例如 180 天/365 天）
- 审计：管理员可按合规权限检索消息（需记录访问日志）
- 脱敏：推送摘要/日志中不得泄露敏感内容
- 删除：对我删除不等于物理删除，仍需满足审计留存

---

## 11. 观测与运维

### 11.1 关键日志字段

- `tenantId/userId/deviceType/deviceId/channelId/clientId`
- `messageType/messageId/sequence`
- `action`（KICKED/REAUTH_REQUIRED/RENEW_SUGGEST/LOGOUT/REVOKED）

补充：trace 与错误定位必备字段（企业级必须统一）：

- `traceId`：贯穿 HTTP <-> WS <-> DB/MQ 的链路追踪 ID
- `conversationId`：会话维度定位
- `codec`：PB/JSON（协议双栈定位必备）
- `negotiationMode`：subprotocol/probe
- `code`：错误码（400xxx/401xxx/403xxx/429xxx/500xxx）
- `retryable/retryAfterMs`：可重试判定（尤其对 ACK/限流场景）

日志规范建议：

- 统一 JSON 日志（结构化），禁止拼接字符串导致不可检索
- 日志等级：
  - INFO：关键状态迁移（AUTH 成功/失败、CODEC 绑定、SendAck、sync 拉取）
  - WARN：可恢复异常（限流、重试、降级、探测失败）
  - ERROR：不可恢复异常（decode 崩溃、持久化失败、fanout 失败）
- 敏感信息：accessToken/refreshToken 必须打码；消息正文默认不打印

### 11.2 指标建议

- 在线连接数（按 tenant/deviceType 维度）
- 重连次数、重连成功率
- 401 refresh 次数、refresh 失败率
- KICKED/REAUTH_REQUIRED 次数
- 消息端到端延迟（p50/p95/p99）

当前工程说明（以代码为准）：

- 当前工程主要依赖结构化日志进行排障，尚未在 WebSocket starter 中系统性接入 metrics/仪表盘/告警（本章其余指标/Runbook 口径为企业级规划）。
- 关键日志入口（已落地，便于定位）：
  - 会话与互踢/撤销：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java`
  - 载体约束/协商超时：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/WebSocketFrameHandler.java`
  - PROBE/AUTH/ACK（JSON）：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/AuthHandler.java`
  - 租约提示/到期：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettyAuthLeaseMonitor.java`

### 11.3 企业级指标目录

企业级上线要求必须具备以下指标目录：

当前工程说明（以代码为准）：

- 下述指标目录为企业级落地目标，当前工程尚未在 WebSocket starter 中系统性埋点产出（需后续结合 metrics/告警平台逐项落地）。

- **连接与协商**
  - `ws_connections{codec,tenantId,deviceType}`（当前在线数）
  - `ws_negotiation_fail_total{reason,codec}`
  - `ws_codec_downgrade_total{from,to,reason}`
- **鉴权与租约**
  - `ws_auth_success_total` / `ws_auth_fail_total{code}`
  - `ws_lease_expired_total{mode=SOFT|HARD,reason}`
- **消息与可靠性**
  - `im_send_total{messageType}`
  - `im_send_ack_latency_ms{p50,p95,p99}`（SendAck 延迟）
  - `im_ack_timeout_total`
  - `im_sync_pull_total{type=conversation|message}`
  - `im_gap_repair_total`
- **推送**
  - `push_send_total{provider,result}`
  - `push_dedup_suppressed_total`
  - `push_dnd_suppressed_total`
  - `push_click_open_total`

维度要求：所有指标至少支持按 `tenantId` 聚合（可采样/脱敏），关键链路支持 `userId/deviceType` 下钻。

### 11.4 SLO（服务级别目标）建议（企业级门禁）

建议将以下 SLO 写入上线门禁（并在 Backlog 中固化为验收）：

当前工程说明（以代码为准）：

- 当前工程尚未形成可自动计算的 SLO 指标口径与门禁流水线（需在指标落地后补齐）。

- 连接：
  - WS 建链成功率（排除被踢/撤销）：>= 99.5%
  - 重连成功率（30s 内）：>= 99%
- 消息：
  - SendAck p95：<= 300ms（示例值，按压测调优）
  - 端到端投递 p95：<= 1s（在线）
- 同步：
  - `syncMessages` 成功率：>= 99.9%

### 11.5 告警与自愈（企业级运维要求）

- 连接异常：在线数突降、重连率突增
- 鉴权异常：401/refresh 失败率突增
- 投递异常：ACK 超时比例异常、补偿拉取量异常
- 推送异常：推送失败率、到达率

补充告警规则建议（示例，最终阈值以压测为准）：

当前工程说明（以代码为准）：

- 当前工程尚未落地统一的告警规则与自愈编排（需在 11.3 指标埋点落地后补齐）。

- `ws_negotiation_fail_total` 突增（5min 环比/同比）
- `ws_codec_downgrade_total` 突增（可能 pb 灰度异常）
- `im_ack_timeout_total / im_send_total` 比例 > 阈值
- `im_sync_pull_total{type=message}` 突增（可能 gap/丢包问题）
- `push_send_total{result=failure}` 突增（通道故障）

自愈建议：

- 熔断/降级：触发阈值后临时关闭“非核心消息类型”（输入状态、群已读详情等）
- 限流：对异常租户/用户/连接执行更严格限流
- 灰度回滚：一键关闭 pb（codec 白名单回收）

### 11.6 Dashboard 与 Runbook（落地要求）

企业级上线要求必须具备：

- Dashboard：
  - 连接/协商/鉴权
  - SendAck/ACK 超时/补偿拉取
  - 推送发送量/失败率/去重与 DND 抑制
- Runbook：
  - “ACK 超时暴涨”排查步骤
  - “协商失败/降级暴涨”排查步骤
  - “推送失败率突增”排查步骤

当前工程说明（以代码为准）：

- Dashboard/Runbook 的指标与告警体系尚未工程化落地，当前阶段以“日志 + 接口回归用例 + 联调抓包”为主。

### 11.7 压测与容量评估口径（与 Backlog E2 对齐）

压测必须覆盖并输出：

- 并发连接数（按 tenantId 分布）
- 消息吞吐（TPS/QPS）、SendAck p95/p99
- 断线重连风暴场景（批量断链 -> 30s 内恢复）
- 补偿拉取场景（丢包/缺洞 -> syncMessages）

容量输出必须包含：

- 单节点可承载连接数上限
- 单节点可承载消息吞吐上限
- 推荐集群规模与伸缩策略（含预留冗余）

---

## 12. 现状实现对齐（As-Is）

### 12.1 uniappx 已落地（示例）

- `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`
  - AUTH_REQ 透传 `deviceName`
  - 处理 `CLOSE`：KICKED/REAUTH_REQUIRED/LOGOUT/REVOKED
  - 处理 `RENEW_SUGGEST`：触发无感续期
  - 监听 HTTP token 刷新回调：同连接 reauth（不断链续期）

- `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts`
  - 注入 `Authorization/tenant-id`
  - 401 refresh 单飞 + 队列重放
  - header 规范化：避免 token/tenant 头丢失或重复

### 12.4 REST 契约（端到端对齐，避免漂移）

服务端（module-system）REST 通用返回包装：

- `CommonResult<T>`：`{ code: number, msg: string, data: T }`
- 成功：`code === 0`（业务 `data` 为返回体）
- 失败：`code !== 0`（`msg` 可展示；是否可重试由错误码段决定）

客户端（uniappx）统一约定（以 `utils/request.uts` 为权威）：

- 当 `code===0`：`request()` **直接返回业务 data**（即 `T`），上层不得再判断 `response.code`
- 当 `code!==0`：`request()` 抛出异常（统一 toast/日志），业务层按需 catch

ID 精度约束（企业级必须冻结）：

- chatId/groupId/messageId：端侧统一使用 string（避免 JS number 精度丢失）
- 服务端可接受 string/number 入参，但返回建议统一为 string（或端侧统一 toString）
- 端侧约束的工程化细节与已知坑位（UTS/uni-app-x）：见 `sql/doc/uni-app-x开发资料-摘录.md` 6.1

错误码约束（与 WS 一致的“可重试判定”）：

- `400xxx`：参数/协议错误（不可重试，修复后重试）
- `401xxx`：未认证/过期（触发 refresh/重登策略）
- `403xxx`：无权限/时限限制（不可重试）
- `429xxx`：限流（可按 retryAfterMs 重试）
- `500xxx`：服务端异常（可重试/不可重试需细分）

补充：面向企业级 IM 的关键 REST 契约建议（与 Backlog C3/C5/H 对齐）：

- 会话增量同步：`GET /system/im/conversation/sync`
- 已读水位上报：`PUT /system/im/conversation/read-watermark`
- 群已读聚合（避免风暴）：
  - `GET /system/im/read-receipt/summary?messageId=...`
  - `GET /system/im/read-receipt/detail?messageId=...&status=read|unread&pageNo=&pageSize=`
- 通讯录（组织维度）：建议 `GET /system/im/contact/list-by-dept` 支持分页/权限。
  - 建议形态：`GET /system/im/contact/list-by-dept?deptId=...&pageNo=...&pageSize=...&keyword=...`
  - 企业级约束：
    - 租户隔离：仅能查询当前 tenant 下的组织/用户
    - 数据权限：至少满足“同组织范围可见”或“按角色授权可见范围”
    - 大部门分页（例如 5000+）必须稳定，避免一次性全量返回导致端侧卡顿

### 12.2 待对齐项（To-Be）

- 协议双栈协商与 Protobuf 编解码落地（App）
- 可靠性：ACK/重投/断线补偿完善与验收
- 离线推送接入与与消息拉取一致性

补充：前后端对接（uniappx <-> module-system）的 REST/WS 清单以 `sql/doc/IM即时通讯开发任务清单-v2.0.md` 的 **0.4 节**为准。

当前已识别的对接缺口（代码级 TODO）：

- 消息列表查询当前以 `chatId` 为权威：`GET /system/im/message/list-by-chat?chatId=...`（`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/AppImMessageController.java#getMessageListByConversation`）。
  - 若端侧仅持有 `groupId`：需先通过会话接口映射到 `chatId`（见 2.4.6），再调用该接口。
- 通讯录按部门过滤接口已实现：
  - `GET /system/im/contact/list-by-dept?deptId=...`（`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/AppImContactController.java#getContactListByDept`）
  - `GET /system/im/contact/list-by-dept-page`（`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/AppImContactController.java#getContactPageByDept`）

### 12.3 现状实现对齐表（As-Is vs To-Be）

说明：本表用于把“企业级闭环能力”映射到当前代码的落地点，避免文档与实现脱节。

| 能力域 | 现状状态 | 关键入口（模块/文件） | 闭环缺口/验收要点 |
| --- | --- | --- | --- |
| 统一鉴权（HTTP） | 已落地 | `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts` | 已完成：Authorization/tenant-id 注入、401 refresh 单飞、队列重放、避免重复/丢失 |
| IM 鉴权 + 不断链续期 | 已落地（核心链路） | `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/AuthHandler.java`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java` | 核心闭环已具备（AUTH_REQ/AUTH_RENEW、RENEW_SUGGEST/REAUTH_REQUIRED）。需补齐：企业级错误码、埋点与回归用例体系 |
| 撤销闭环（logout/互踢 -> IM 断链） | 已落地 | `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/mq/consumer/ImSessionRevokeConsumer.java`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java` | 已具备：RedisMQ 撤销、clientId 过滤、精确到 accessToken/设备；验收：跨节点可达、reason/action 标准化 |
| Presence/Lease（前台 gating + 租约状态机） | 已落地（基础） | `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettyAuthLeaseMonitor.java`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySession.java` | 已具备：SOFT/HARD 语义与推送；需补齐：租约参数配置化与运营可观测（到期原因、后台比例） |
| 多端登录与互踢 UX | 已落地 | `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySession.java`；`shengyu-ui/shengyu-ui-admin-uniappx/utils/device.uts`；`shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts` | 已具备：同 deviceType 互踢、KICKED 携带 byDevice/kickedAt，前端提示；验收：同账号不同 deviceType 可共存 |
| 协议双栈（JSON WebSocket） | 已落地（服务端 JSON 业务适配层） | `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/WebSocketFrameHandler.java`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/JsonBusinessMessageHandler.java`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/AuthHandler.java` | 已具备：Text frame JSON -> 复用 processor 分发；缺口：连接层协商（SubProtocol/首帧探测）、统一 Envelope 约束与错误码 |
| 协议双栈（App Protobuf） | 部分落地 | `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/netty/handler/ProtobufMessageHandler.java`（服务端）；`shengyu-ui/shengyu-ui-admin-uniappx/utils/proto/im_message_pb.esm.js`（端侧生成的 pbjs 静态模块，当前在 `utils/websocket.uts` 中引入） | 服务端具备 Protobuf 处理链路；客户端 App 端 Protobuf 编解码、协商与降级待落地 |
| 消息处理器（TEXT/IMAGE/FILE/READ_RECEIPT/RECALL 等） | 已落地（处理器注册） | `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/config/NettyAutoConfiguration.java`（processor 注册） | 注意：处理器存在≠闭环完成。需要业务模块提供真正的存储/查询/补偿/权限校验，否则无法达成企业级可靠性 |
| 消息持久化（先存储后 fanout） | 已落地（含 fail-fast 护栏） | `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/config/NettyAutoConfiguration.java`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/config/WebSocketProperties.java`；`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/processor/impl/*MessageProcessor.java`；`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/config/ImWebSocketConfiguration.java` | 已具备：默认禁用 NoOp、处理器持久化门禁、跨类型“先落库后回推/转发”一致。验收重点：ACK/回推与 DB 可对账、断线补偿后最终态一致 |
| 会话同步与未读一致（lastReadSequence/未读水位） | 部分落地（REST 基础接口存在） | `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/AppImConversationController.java`；`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/ImConversationServiceImpl.java` | 已有 list/mark-read/unread-count 等；缺口：基于 sequence 的水位模型、跨端一致、增量 sync（cursor/pull） |
| 断线补偿/漫游（按 lastSequence 拉取） | 未落地 | 待新增：system 消息同步接口 + 查询 service；客户端 reconnect 流程 | 验收：断网 30s 后恢复不丢/不重/顺序正确，会话未读与角标一致 |
| 离线推送（通道集成） | 未落地（策略已规划） | `OfflinePushService`（starter 默认实现）；uniappx 推送 SDK 待接 | 闭环：token 绑定 -> 离线触发 -> 点击拉起 sync；推送去重、DND、撤回一致 |
| 观测与运维（指标/告警） | 部分落地 | server 日志 + 文档建议；需补 metrics/报警 | 验收：按 tenantId/userId 追踪一次消息链路；在线数、重连率、401、ACK 超时、推送失败率告警 |
| 多节点部署（跨节点投递/KICK/撤销） | 部分落地（撤销侧已具备 Redis pubsub） | `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/mq/consumer/ImSessionRevokeConsumer.java`；后续引入 MQ/registry | 验收：任意节点触发 KICK/REVOKE，目标连接所在节点可达；消息投递跨节点可达 |

---

## 13. 高可用、扩展与降级（对齐企业 IM 的“可用性优先”）

### 13.1 多节点路由与消息总线

- 单机内（当前工程已落地）：channel -> session 映射
  - 关键入口：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettySessionManager.java`（in-memory 索引：channelId/userId/tenantId/accessToken/deviceType/deviceId）
- 多机（规划，未落地）：
  - session 分布式注册（Redis）
  - 跨节点投递通过 MQ（Redis pubsub/RocketMQ/Kafka 等）

当前工程已具备的跨节点基础（撤销/互踢方向）：

- 撤销事件消费入口：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/mq/consumer/ImSessionRevokeConsumer.java`
  - 说明：用于消费“撤销/强退/互踢”等事件，并在本节点对命中的连接执行 CLOSE/KICK。
- 关键要求：
  - KICK/REVOKE/REAUTH_REQUIRED 必须跨节点可达

企业级落地必须明确：

- **会话注册（Session Registry）**
  - 注册键建议：`tenantId + userId + deviceType + deviceId (+ clientId)`
  - 注册值建议：`nodeId + channelId + connectedAt + codec + appVersion + lastSeen`
  - TTL/续租：心跳或 lease 续租刷新（避免僵尸注册）
  - 幂等：同一连接重复注册不应产生多条记录；断链必须清理或等待 TTL 过期

- **路由选择（Route Key）**
  - 单播（toUser）：按 `tenantId + userId` 找在线端列表（按策略全端/主端）
  - 群播（toConversation/group）：优先在服务端做 fanout（按在线端列表分片投递）

- **跨节点投递（Delivery Bus）**
  - 目标：节点 A 触发的投递，必须能到达连接在节点 B 的 channel
  - 推荐抽象：`LocalDeliver`（同进程） + `RemoteDeliver`（跨节点）
  - RemoteDeliver 推荐：
    - 控制类（KICK/REVOKE/CLOSE）：Redis pubsub（低延迟）
    - 消息类（TEXT/IMAGE 等）：MQ（可扩展，可限流）

- **一致性与失败处理**
  - 投递不保证“至少一次”或“恰好一次”的语义必须明确（企业级建议：至少一次 + 端侧去重）
  - 远端不可达：
    - 先从 registry 二次确认连接是否仍存在
    - 若仍存在但投递失败：记录投递失败事件（用于对账/告警），并依赖断线补偿与 push 兜底
  - 节点下线：必须支持优雅下线（见 13.4）

### 13.1.1 多可用区/多机房建议（可选）

- Registry 与 Bus 必须具备跨 AZ 容灾能力（主从/多副本）
- nodeId 需包含 AZ/IDC 信息，便于路由与排障

### 13.2 降级策略（保证核心链路）

- 降级优先级：
  - 保留：AUTH/HEARTBEAT/文本消息
  - 降级：已读回执（群）、输入状态、在线状态高频刷新
  - 关闭：大文件/大图实时透传（改走 HTTP）

企业级要求：降级必须可配置、可回滚、可观测。

- 降级触发条件（示例）：
  - ACK 超时比例突增
  - 补偿拉取量突增（gap/丢包）
  - 推送失败率突增
  - CPU/内存/队列积压超过阈值

- 降级动作（示例）：
  - 关闭群已读详情，只保留聚合数
  - 降低 presence/typing 的推送频率
  - 限制单连接发送速率（连接级限流）
  - 降级 protobuf（codec 白名单回收，客户端自动降级 JSON）

当前工程说明（以代码为准）：

- 服务端“连接级/用户级限流”目前仅提供 SPI 能力与示例实现，尚未在 Netty 消息处理器中强制生效（本节其余内容为企业级规划口径）。
  - SPI 接口：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/service/MessageRateLimitService.java`
  - System 模块实现：`shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/im/spi/SystemMessageRateLimitServiceImpl.java`（Redis INCR，1s 窗口）

- 降级不变式：
  - AUTH/HEARTBEAT/撤销（REVOKE/KICK）必须始终可用
  - 消息可靠性闭环（至少 SendAck）不得被降级破坏

### 13.3 灰度与开关（企业级必备）

- feature flag 维度：tenantId/userId/deviceType/appVersion
- 可控开关：pb 双栈、ACK 模式、补偿策略、推送通道、限流阈值

当前工程说明（以代码为准）：

- 服务端尚未落地统一的 feature-flag 配置中心与灰度开关体系（本节为企业级规划口径）。
- 端侧已实现的“pb 降级兜底”逻辑入口：`shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`（pb 熔断 `pbDisabledUntil` + SLA 超时降级重连）。

建议标准化 Feature Flag：

- 配置源：配置中心/DB（具备审计与回滚记录）
- 生效维度：
  - 租户级（tenantId）
  - 用户级（userId）
  - 设备级（deviceType/appVersion）
- 关键开关建议：
  - `codec.pb.enabled`（pb 灰度开关）
  - `ack.mode`（SendAck/DeliveryReceipt/ReadReceipt 分层开关）
  - `sync.gap.thresholdMs` 与 `sync.limit`
  - `push.provider.primary`（DCloud/JPush）与 `push.enabled`
  - `rateLimit.ws.perConn/perUser/perTenant`

灰度/回滚不变式：

- 任一开关变化必须可观测（指标 + 日志）
- 回滚应在分钟级生效（避免长时间故障）

### 13.4 优雅下线与滚动升级（企业级必须）

- 节点进入 draining：
  - 新连接不再分配到该节点
  - 现有连接允许存量处理一段时间（可配置），并提示客户端重连
- 连接迁移策略：
  - 对非关键连接可主动 CLOSE（reason=SERVER_DRAINING，客户端按退避重连）
  - 对关键链路（如管理员会话）可延后关闭
- Registry 清理：draining 开始立即停止续租，并尽快清理本节点注册，避免路由到已下线节点

当前工程说明（以代码为准）：

- 服务端尚未实现标准化的 `SERVER_DRAINING` 优雅下线协议与节点级 draining 策略（本节为企业级规划口径）。

---

## 14. 演进路线（建议）

- v2.0（近期）：鉴权一致性/撤销闭环/不断链续期/互踢 UX 稳定化，补齐离线补偿最小闭环
- v2.1：App 端 Protobuf 双栈落地（H5 保持 JSON），可靠性 ACK/重投/补偿完善
- v3.0：分布式与多节点一致性、离线推送全链路、观测与压测体系完善

---

## 15. 功能关联性与依赖分析（企业级必须）

本章节分析各功能之间的依赖关系，确保开发顺序合理、架构设计完整。

### 15.1 核心功能依赖图

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                    基础设施层                           │
                    │  WebSocket双栈(PB/JSON) │ 统一鉴权 │ 租户隔离 │ 日志/指标 │
                    └─────────────────────────────────────────────────────────┘
                                              │
                                              ▼
                    ┌─────────────────────────────────────────────────────────┐
                    │                    消息核心层                           │
                    │  消息发送 │ 消息存储 │ sequence分配 │ cursorVersion同步  │
                    └─────────────────────────────────────────────────────────┘
                                              │
                    ┌─────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
            ┌───────────────┐         ┌───────────────┐         ┌───────────────┐
            │   会话管理层   │         │   消息操作层   │         │   扩展功能层   │
            │  会话列表同步  │         │  撤回 │ 删除   │         │  转发 │ 收藏  │
            │  已读水位管理  │         │  重发 │ 编辑   │         │  @提及 │ 输入态│
            │  未读角标计算  │         │  tombstone    │         │  位置 │ 草稿  │
            └───────────────┘         └───────────────┘         └───────────────┘
```

### 15.2 功能依赖矩阵

| 功能 | 前置依赖 | 并行开发 | 风险点 |
|------|----------|----------|--------|
| **消息发送** | WS双栈、统一鉴权 | - | 无 |
| **消息撤回** | 消息发送、rev机制 | 删除 | 需与群管理员撤回和重新编辑规则保持一致 |
| **对我删除** | tombstone表、cursorVersion | 撤回 | 需与撤回最终态合并 |
| **消息转发** | 消息发送、权限校验 | 收藏 | 需校验原消息可见性 |
| **消息重发** | 本地消息状态管理 | - | 幂等处理需完善 |
| **群@提及** | 消息发送、推送链路 | 输入状态 | 强提醒与敏感词过滤后结构保持一致 |
| **自定义表情包** | 文件上传、消息发送、个人表情库 | 收藏 | 个人表情库同步与资产去重 |
| **位置消息** | 地图SDK集成 | - | 新messageType需前后端同步 |
| **草稿保存** | 本地存储 | - | 可独立开发，后端可选 |
| **输入状态** | WS广播机制 | 群@提及 | 需频率控制防风暴 |
| **收藏功能** | 消息查询接口 | 转发 | 需处理原消息撤回/删除场景 |

### 15.3 关键约束与不变式（代码已验证）

基于代码审查，以下不变式已在当前工程中落地：

| 不变式 | 验证状态 | 涉及文件 |
|--------|----------|----------|
| 消息先存储后投递 | ✅ 已落地 | `ImMessageServiceImpl.java:136` |
| sequence 单调递增 | ✅ 已落地 | `chatMapper.nextSequence(chatId)` |
| 撤回不物理删除 | ✅ 已落地 | `ImMessageServiceImpl.java:692` status=RECALLED |
| tombstone 用户维度 | ✅ 已落地 | `ImMessageServiceImpl.java:869` |
| cursorVersion 增量同步 | ✅ 已落地 | `ImMessageServiceImpl.java:726-741` |
| 撤回广播多端 | ✅ 已落地 | `ImMessageServiceImpl.java:782-813` |
| ACK 去重缓存 | ✅ 已落地 | `AckMessageProcessor.java:23-26` |
| TYPING 处理器 | ✅ 已落地 | `NettyAutoConfiguration.java:310-318` |

### 15.4 待完善项（代码审查发现）

| 问题 | 影响 | 建议 |
|------|------|------|
| 自定义表情包仍以本地 mock 列表为主 | 多端不同步，无法形成个人表情库 | 按 L4.1 任务补齐上传/收藏/排序/list 闭环 |
| STICKER 渲染仍依赖 `url` 直出 | 文件鉴权、链接过期与审计能力不足 | 按 Phase 1/2 逐步收敛到 `fileId + presigned` |
| LOCATION 枚举已定义但未处理 | 位置消息未实现 | 按 L5 任务实现 |
| VOICE 发送仍是“录完即传”简化链路 | 录音态/上传态/发送态未分层，红点与已读态耦合 | 按 `6.4.4.2` 与 `S2.3.a` 收口 |

---

## 16. 业界最佳实践对比（企业微信/钉钉对标）

### 16.1 消息可靠性保障（对标 Ably/企业微信）

业界核心要求（来源：Ably WebSocket Reliability）：

| 要求 | 业界标准 | 当前工程状态 | 差距 |
|------|----------|--------------|------|
| 消息投递保证 | ACK + 重试 + 持久化 | ✅ ACK已落地，重试端侧待完善 | 端侧重发逻辑 |
| 自动重连 | 指数退避 + 状态恢复 | ✅ 已落地 | - |
| 水平扩展 | sticky session / pub-sub | ⚠️ 单节点 | 后续迭代 |
| 数据复制 | 跨节点/跨区域 | ⚠️ 未引入 | 后续迭代 |
| 消息顺序 | sequence 单调递增 | ✅ 已落地 | - |

### 16.2 会话一致性模型（对标企业微信）

| 维度 | 企业微信方案 | 当前工程方案 | 一致性 |
|------|--------------|--------------|--------|
| 未读计算 | 服务端权威：lastMsgSeq - lastReadSeq | ✅ 相同 | ✅ |
| 已读上报 | 幂等、只升不降 | ✅ 相同 | ✅ |
| 增量同步 | cursorVersion 驱动 | ✅ 相同 | ✅ |
| 多端同步 | WS广播 + HTTP sync | ✅ 相同 | ✅ |
| 撤回同步 | rev机制 + 广播 | ✅ 相同 | ✅ |

### 16.3 高性能架构要点（对标钉钉）

| 要点 | 钉钉方案 | 当前工程方案 | 建议 |
|------|----------|--------------|------|
| 连接复用 | 长连接 + 心跳保活 | ✅ 已落地 | - |
| 协议优化 | Protobuf优先 | ✅ PB/JSON双栈 | - |
| 消息压缩 | 大消息体压缩 | ⚠️ 未引入 | 后续优化 |
| 批量推送 | 群消息批量投递 | ⚠️ 逐条投递 | 性能优化时可引入 |
| 离线消息 | 增量拉取 + 分页 | ✅ 已落地 | - |

### 16.4 功能完整性对比

| 功能 | 企业微信 | 钉钉 | 当前工程 | 优先级 |
|------|----------|------|----------|--------|
| 文本/图片/文件 | ✅ | ✅ | ✅ | - |
| 消息撤回(2min) | ✅ | ✅ | ✅ | - |
| 管理员撤回 | ✅ | ✅ | ✅ 已落地（待统一验收） | P1 |
| 消息转发 | ✅ | ✅ | ✅ 已落地（待统一验收） | P1 |
| 群@提及 | ✅ | ✅ | ✅ 已落地（待统一验收） | P1 |
| 自定义表情包 | ✅ | ✅ | ⚠️ 方案已冻结，待开发 | P1 |
| 输入状态 | ✅ | ✅ | ⚠️ 待开发 | P2 |
| 位置消息 | ✅ | ✅ | ⚠️ 待开发 | P2 |
| 草稿保存 | ✅ | ✅ | ⚠️ 待开发 | P2 |
| 消息收藏 | ✅ | ✅ | ⚠️ 待开发 | P2 |
| 消息编辑 | ✅ | ✅ | ❌ 未规划 | 后续 |
| 消息引用回复 | ✅ | ✅ | ⚠️ 部分支持 | 已有quoteMessageId字段 |

---

## 17. 架构合理性验证

### 17.1 模块职责清晰度

| 模块 | 职责 | 验证状态 |
|------|------|----------|
| `shengyu-framework/websocket` | 协议、鉴权、连接管理、消息广播 | ✅ 职责单一 |
| `shengyu-module-system/im` | 业务逻辑、数据持久化、REST API | ✅ 职责单一 |
| `shengyu-ui/uniappx/services` | 端侧状态管理、缓存、UI协同 | ✅ 职责单一 |
| `shengyu-ui/uniappx/utils/websocket.uts` | WS连接、认证、心跳、重连 | ✅ 职责单一 |

### 17.2 数据流完整性

```
发送链路（已验证）：
Client → WS/HTTP → Controller → Service → DB → cursorVersion → WS广播 → Client

接收链路（已验证）：
WS → MessageProcessor → Service → DB(可选) → 端侧回调 → UI刷新

同步链路（已验证）：
Client → HTTP /sync → Service → DB(cursorVersion过滤) → 增量返回 → 端侧合并
```

### 17.3 错误处理覆盖

| 错误类型 | 处理方式 | 验证状态 |
|----------|----------|----------|
| 参数错误(400xxx) | 抛异常、不重试 | ✅ |
| 认证失败(401xxx) | 触发refresh | ✅ |
| 权限不足(403xxx) | 抛异常、不重试 | ✅ |
| 限流(429xxx) | 返回retryAfterMs | ✅ |
| 服务异常(500xxx) | 可重试 | ✅ |

### 17.4 扩展性评估

| 扩展点 | 当前支持 | 扩展方式 |
|--------|----------|----------|
| 新消息类型 | ✅ | MessageType枚举 + Processor注册 |
| 新协议 | ✅ | subprotocol协商 |
| 新推送渠道 | ✅ | PushService扩展 |
| 新存储后端 | ✅ | Mapper抽象 |
| 多节点部署 | ⚠️ | 需引入session registry |

---

## 18. 附录：协议权威来源

### 18.1 Protobuf 定义位置

- `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto/im_message.proto`

约束：

- `MessageType` 枚举以 proto 为权威来源（JSON/前端必须与之对齐）
- JSON/H5 侧扩展能力建议统一走 `CUSTOM` + `header.extra/body.subType`（以 v2 架构文档第 6 章为准）

### 18.2 历史文档迁移说明

本仓库早期存在面向“AI 可执行”的大而全 v1 文档（包含阶段看板、待办清单、部分实现假设）。

- 当前权威文档已切换为：
  - `sql/doc/IM即时通讯架构设计文档-v2.0.md`
  - `sql/doc/IM即时通讯开发任务清单-v2.0.md`

迁移原则：

- v1 中仍有价值的“协议权威来源/关键约束/经验总结”迁入 v2（本附录及相关章节）
- v1 中的“任务看板/阶段完成度”不再作为依据，以 v2 Backlog 为准

---

## 19. 附录：IM + HTTP 统一鉴权（详细版，权威）

本附录用于收敛“统一鉴权”完整设计，避免单独维护多份文档导致语义漂移。

### 19.1 设计目标（对齐企微/钉钉）

- 统一鉴权语义：HTTP 与 IM 都基于同一套 accessToken/refreshToken 生命周期与撤销逻辑
- 不断链续期：HTTP token refresh 不应导致 IM 断链/被踢，应在同一连接上完成续期
- 互踢与撤销精确化：按 `userId + deviceType` 互踢；撤销精确到 accessToken/设备优先
- 体验一致：KICKED/REAUTH_REQUIRED 文案可读（deviceName），且前端停止重连并引导登录

### 19.2 HTTP：稳定注入（不丢、不重复）

- 注入字段：
  - `Authorization: Bearer <accessToken>`（白名单接口除外）
  - `tenant-id: <tenantId>`（租户开关开启且非租户白名单接口）

- 规范化策略（uniappx 多端差异）：
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts#ensureHeader`：保证 header 可写，必要时 clone
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts#applyAuthHeader`：清理 `Authorization/authorization` 再写入单一 canonical 值
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts#applyTenantHeaderIfNeeded`：清理变体后写入 `tenant-id`

### 19.3 HTTP：401 refresh 单飞 + 队列重放

- 401 触发 refresh **单飞**；并发请求进入队列
- refresh 成功后：
  - 原请求 retry 前重新注入 `Authorization/tenant-id`
  - 队列请求 replay 前重新注入 `Authorization/tenant-id`

### 19.4 IM：认证 + 不断链续期 + presence gating

- 建链：连接成功后发 `AUTH_REQ(accessToken + deviceType/deviceId/deviceName)`
- 不断链续期：
  - HTTP refresh 成功或服务端提示 `RENEW_SUGGEST` 时，IM 在**同一连接**上复用 `AUTH_REQ` 重新认证（服务端允许已认证连接重复 `AUTH_REQ`），不主动断链
  - 端侧权威入口：`shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts#requestReauth`

- 服务端租约扫描与提示（当前工程已落地）：
  - 入口：`shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/session/NettyAuthLeaseMonitor.java`
  - 输出：
    - `RENEW_SUGGEST`：通过 `SYSTEM_NOTIFY`（pb 走 `header.extra`，json 走 body）提示端侧无感续期
    - `REAUTH_REQUIRED`：通过 `CLOSE` 下发并关闭连接

- 端侧处理（当前工程已落地）：
  - `RENEW_SUGGEST`：`shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts` 收到后触发 `renewAuthSilently()` -> `requestReauth('renew_suggest')`
  - `REAUTH_REQUIRED`：端侧停止重连并引导登录（`allowReconnect=false`）

- presence gating（仿企微/钉钉）：
  - 前台/聊天页：正常 PRESENCE + 续租（体验无感）
  - 后台闲置：降低/停止续租，最终触发 `REAUTH_REQUIRED`

### 19.5 多端互踢与撤销联动（HTTP <-> IM）

- 互踢：`userId + deviceType` 新登录互踢旧会话
- 撤销精确优先级：accessToken -> (userId, deviceType, deviceId) -> userId
- RedisMQ 撤销联动：logout/互踢/强退发布撤销事件；IM 侧订阅后定向 CLOSE/KICKED 并断链

### 19.6 关键不变式（Invariants）

- 非白名单 HTTP 请求必须携带且仅携带一个 `Authorization`
- 租户开关开启时，非租户白名单 HTTP 请求必须携带 `tenant-id`
- refresh 后重试/队列重放必须重新注入 `Authorization/tenant-id`
- token refresh 不应触发 IM 被踢，应走不断链续期
- 互踢必须精确到 `userId + deviceType`（或更细 session/设备维度）

### 19.7 回归用例（上线门禁建议）

- 登录后：`/system/auth/get-permission-info` 与角标同步接口请求头不丢、不重复
- 人为制造 token 过期：refresh 只触发一次；队列重放带新 token + tenant-id
- IM：前台不断链续租；后台闲置触发重登；refresh 后 WS 不断链且续期成功
- 多端互踢：同 deviceType 新登录踢旧端，不同 deviceType 可共存

---

## 20. 附录：开发任务清单（Backlog，权威）

Backlog 已独立维护于：`sql/doc/IM即时通讯开发任务清单-v2.0.md`。

原则：

- 架构文档负责“机制与标准”，Backlog 负责“拆解与执行”
- 避免同一任务在两处维护，防止漂移

---

## 21. 附录：聊天页入口模型权威实现（AI开工入口）

本附录用于把“聊天页入口模型”冻结到可直接编码的粒度。AI/开发实现时，**本附录优先级高于正文中的“建议/推荐”措辞**；若与正文冲突，以本附录为准。

- 文档状态：已冻结（可作为 AI 开工权威实现附录）
- 实现状态：未开始（以任务文档 AI 开工附录为执行入口）

### 21.1 本附录范围（冻结）

本附录只覆盖 IM 核心范围：

- 聊天页首屏进入
- 搜索/引用/转发详情进入聊天页定位
- 向上翻历史
- Web/Android/iOS 视口恢复
- 与现有 IM 消息能力的融合

本附录明确不覆盖：

- 群邀请附带聊天记录
- 非 IM 页面与后台管理页审计
- Favorite 收藏列表新页面开发（本期仅冻结未来入口契约，不要求本期实现）

企业级边界（强制）：

- 本附录只允许改动“聊天页 REST 查询模型、前端入口状态机、外部 IM 入口参数、视口恢复算法”，不得改动 WebSocket 底层协议与连接协商流程
- 不得改变 `App Protobuf + H5 JSON` 双栈策略，不得改变 `PROBE -> AUTH_REQ` 严格协商顺序，不得改变“单连接单 codec”约束
- 不得改变 `messageType`、`messageId`、`sequence`、`cursorVersion`、`conversationVersion`、`lastReadSequence` 的既有权威语义
- 不得把聊天页首屏/历史窗口逻辑下沉到 WS 私有协议；聊天页窗口查询仍以 REST 为权威，WS 只承担实时推送与 `pull(sequence)` 补偿
- Android / iOS / Web 的差异只允许体现在滚动容器、可见区域观测、媒体能力适配层，不得在消息时间线语义、鉴权语义、同步语义上分叉
- 若本附录任一条与第 3 章统一鉴权、第 6 章协议双栈、第 7 章可靠性/sequence/cursorVersion 机制冲突，必须以前述章节为准；本附录无权覆盖底层核心协议与总体架构

### 21.2 统一入口优先级（冻结）

聊天页进入时，路由/状态恢复的判定优先级必须严格按以下顺序执行：

1. 若存在 `anchorSequence`：进入 `anchor` 模式
2. 否则若存在 `anchorMessageId`：先解析为 `anchorSequence`，再进入 `anchor` 模式
3. 否则若存在有效本地视口缓存：进入 `restore` 模式
4. 否则：进入 `latest` 模式

禁止项：

- 禁止以 `pageNo/pageSize` 作为聊天页入口定位参数
- 禁止仅以 `groupId` 或 `bizSessionId` 直接拉消息
- 禁止搜索页、转发详情页、引用定位页分别自定义不同跳转契约
- 禁止为适配聊天页入口模型而新增或修改任何 WS `messageType`、Envelope 字段、编解码规则、鉴权时序

### 21.3 后端接口契约（冻结）

#### 21.3.1 最近窗口：`GET /system/im/message/window`

用途：

- 从会话列表进入聊天页
- 聊天页刷新后无显式锚点
- 已离底部但本地视口状态失效时的兜底

请求参数：

- `chatId: string`，必填
- `mode: string`，固定为 `latest`
- `limit: number`，可选，默认 `30`，最大 `50`

成功响应（`code=0`，`request()` 解包后为 `data`）：

```json
{
  "mode": "latest",
  "chatId": "2033741860720664577",
  "anchorFound": true,
  "anchorSequence": null,
  "oldestSequence": "901",
  "newestSequence": "930",
  "hasOlder": true,
  "hasNewer": false,
  "firstUnreadSequence": "925",
  "items": [
    {
      "id": "2033741860720664701",
      "messageId": "2033741860720664701",
      "chatId": "2033741860720664577",
      "sequence": "901",
      "messageType": 1,
      "content": "hello",
      "extra": "{}",
      "status": 0,
      "rev": "1",
      "senderId": "1001",
      "receiverId": "1002",
      "groupId": "0",
      "sendTime": "2026-03-29 10:00:00",
      "isSelf": true,
      "senderNickname": "张三",
      "mentions": [],
      "quoteMessageId": null
    }
  ]
}
```

冻结规则：

- `items` 必须按 `sequence ASC` 返回
- `oldestSequence/newestSequence` 必须基于返回的**可见消息**计算
- `firstUnreadSequence` 若当前窗口内无未读首条则返回 `null`
- 删除墓碑、清空水位、撤回最终态过滤必须先于窗口截取执行

#### 21.3.2 锚点窗口：`GET /system/im/message/window`

用途：

- 搜索结果进入聊天页
- 引用点击跳转
- 合并转发详情跳转原消息
- `@我`、push、未来 Favorite 打开原消息

请求参数：

- `chatId: string`，必填
- `anchorSequence: string`，可选，优先级最高
- `anchorMessageId: string`，可选，仅在 `anchorSequence` 为空时生效
- `beforeLimit: number`，可选，默认 `15`，最大 `30`
- `afterLimit: number`，可选，默认 `10`，最大 `20`

成功响应：

```json
{
  "mode": "anchor",
  "chatId": "2033741860720664577",
  "anchorFound": true,
  "anchorSequence": "880",
  "oldestSequence": "865",
  "newestSequence": "890",
  "hasOlder": true,
  "hasNewer": true,
  "firstUnreadSequence": null,
  "items": []
}
```

冻结规则：

- 若同时传入 `anchorSequence` 与 `anchorMessageId`：只使用 `anchorSequence`
- 若 `anchorMessageId` 能查到消息但消息对当前用户不可见（被 tombstone / clear-watermark 过滤）：`anchorFound=false`
- 若 `anchorFound=false`：服务端回退返回最近窗口，并把 `mode` 仍标记为 `anchor`
- 客户端收到 `anchorFound=false` 时，必须提示“原消息已不可定位，已为你打开最近消息”

#### 21.3.3 更早历史：`GET /system/im/message/history`

用途：

- 聊天页上滑加载更早消息

请求参数：

- `chatId: string`，必填
- `beforeSequence: string`，必填
- `limit: number`，可选，默认 `30`，最大 `50`

成功响应：

```json
{
  "chatId": "2033741860720664577",
  "oldestSequence": "835",
  "newestSequence": "864",
  "hasOlder": true,
  "items": []
}
```

冻结规则：

- 语义必须是：返回 `sequence < beforeSequence` 的最近一段历史
- `items` 必须按 `sequence ASC` 返回，供前端直接 prepend
- 同一次 `history` 响应不允许包含 `sequence >= beforeSequence` 的消息

#### 21.3.4 较新补偿：`GET /system/im/message/pull`

冻结规则：

- 继续保留现有接口与能力
- 只负责 `sequence > lastSequence`
- 不允许承担聊天页首屏、锚点、历史分页职责

### 21.4 服务端 SQL 口径与索引（冻结）

必需索引：

- `im_chat_message`：新增或确认存在 `(chat_id, sequence)` 复合索引
- 若按租户分库前仍共表：建议 `(tenant_id, chat_id, sequence)` 复合索引

查询口径（逻辑冻结）：

1. `latest window`
   - 先过滤：`chatId + 可见性（tombstone/clear/recalled 等）`
   - 再按 `sequence DESC LIMIT N` 取最近窗口
   - 最后在服务端翻转为 `sequence ASC` 返回

2. `anchor window`
   - 先解析锚点 `anchorSequence`
   - 再取：
     - `sequence < anchorSequence ORDER BY sequence DESC LIMIT beforeLimit`
     - `sequence >= anchorSequence ORDER BY sequence ASC LIMIT afterLimit + 1`
   - 合并后按 `sequence ASC` 返回

3. `history(beforeSequence)`
   - 取 `sequence < beforeSequence ORDER BY sequence DESC LIMIT N`
   - 服务端翻转为 `sequence ASC`

强制要求：

- 聊天页相关查询不得再以 `id DESC` 作为时间线权威
- `sequence` 是唯一时间线权威字段
- 过滤 tombstone / clear-watermark / 最终态必须发生在窗口计算前，而不是窗口计算后

### 21.5 前端存储与恢复算法（冻结）

本地存储 key：

- `IM_CHAT_VIEWPORT_${tenantId}_${userId}_${chatId}`

存储结构：

```json
{
  "entryMode": "latest",
  "atBottom": true,
  "viewportAnchorSequence": "880",
  "topVisibleSequence": "875",
  "bottomVisibleSequence": "890",
  "savedAt": 1770000000000
}
```

TTL：

- 默认 `15 分钟`

保存时机（冻结）：

- `onHide`
- `onUnload`
- H5 `visibilitychange -> hidden`
- 聊天页滚动过程中允许节流保存，节流时间建议 `500ms`

恢复算法（冻结）：

1. 有显式 `anchorSequence/anchorMessageId`：不读本地视口缓存
2. 无显式锚点，且缓存未过期：
   - 若 `atBottom=true`：直接按 `latest` 进入
   - 若 `atBottom=false` 且 `viewportAnchorSequence` 有值：按 `anchor` 进入，`anchorSequence=viewportAnchorSequence`
3. 缓存缺失或过期：按 `latest` 进入

prepend 视口稳定规则：

- 调用 `history(beforeSequence)` 前记录当前首个可见消息 `topVisibleSequence`
- prepend 完成后滚回该消息，使其仍位于 prepend 前的视觉位置
- 不允许 prepend 后跳到列表最顶或最底

### 21.6 外部入口调用方清单（冻结）

本期必须改造的调用方：

- 会话列表页：`/pages/message/message`
  - 打开聊天页：只传 `chatId` + `entryMode=latest`
- 搜索结果页：`/pages/common/search-chat-history`
  - 打开聊天页：必须优先传 `anchorSequence`
  - 无 `anchorSequence` 时才传 `anchorMessageId`
- 合并转发详情页：`/pages/message/forward-combine-detail`
  - 打开原消息：必须优先传 `sourceSequence`
  - 无 `sourceSequence` 时才传 `messageId`
- 聊天页内部引用点击：`chat.uvue`
  - 必须调用锚点窗口，不得固定翻页穷举

本期预留但不要求开发新页面：

- Favorite 收藏列表
- 业务会话列表 / 客服会话列表

### 21.7 消息能力回归矩阵（本期必须）

必须回归的 IM 能力：

- 引用回复
- 撤回 / 管理员撤回 / 撤回后重新编辑
- `@成员` / `@所有人` / `@我`
- 单聊已读 / 群聊聚合已读
- `STICKER / EMOJI`
- `VOICE / IMAGE / VIDEO / FILE / LOCATION`
- 合并转发详情跳转原消息

本期不要求新增页面，但要求入口契约预留：

- Favorite 收藏列表
- 业务会话列表

回归规则（冻结）：

- 任一能力从搜索/转发详情进入聊天页时，优先走 `anchorSequence`
- 任一能力在聊天页刷新后，不得回到固定第一页
- 任一能力在 `latest / history / pull` 三条链路下，最终态必须一致

### 21.8 当前代码与本附录的差异（供 AI 开工时直接识别）

- 前端聊天页当前仍固定 `getMessageList(chatId, 1, 20)`
- 搜索结果与合并转发详情当前仍主要传 `messageId`
- 搜索服务当前未把 `sequence` 映射为一等字段
- 后端当前仅有 `list-by-chat(pageNo/pageSize)`，尚无 `window/history`
- mapper 当前老分页仍以 `id DESC` 为排序口径

