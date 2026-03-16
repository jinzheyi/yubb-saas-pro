# IM即时通讯开发任务清单-v2.0

## 强制规范：Long 精度（前端 / JSON）

1. 所有涉及 ID / 序列号的 `Long` 字段（包含但不限于：`messageId`、`sequence`、`chatId`、`groupId`、`userId`、`targetId`、`tenantId` 等），在 **前端与 JSON 传输层必须按 `string` 处理**，禁止按 JS `number` 持久化或参与去重/索引。
2. App/uniapp 对应的后端 **Response VO** 中，所有 `Long` 字段必须使用 `@JsonSerialize(using = ToStringSerializer.class)` 输出为字符串，避免超过 `2^53-1` 时前端精度丢失导致的去重/ACK/排序错误。
3. 前端消息/会话模型中，上述字段必须定义为 `string`，仅在排序/比较需要时临时转换（例如 `BigInt`），且不得把转换后的 `number` 写回缓存。

> **版本**: v2.0.0  \
> **创建日期**: 2026-03-05  \
> **配套架构文档**: `sql/doc/IM即时通讯架构设计文档-v2.0.md`

---

## 已落地能力清单（截至当前工程实现）

- **会话增量同步（cursorVersion 版）**：`GET /system/im/conversation/sync`，服务端按 `cursor_version > cursor` 增量扫描，端侧合并并存储本地 cursor。
- **会话幂等/乱序保护（conversationVersion）**：端侧基于 `conversationVersion` 丢弃旧快照，避免乱序覆盖。
- **WS 推送版本透传（cursorVersion/conversationVersion）**：WS payload root 透传版本号，端侧可做 gap 检测与补偿。
- **WS 重连补偿**：WS 鉴权成功后触发节流的会话补偿 sync。
- **已读/角标一致性闭环（按 sequence 水位）**：`PUT /system/im/conversation/mark-read-seq` 推进水位，角标刷新与会话列表一致。
- **群聊会话摘要前缀一致性**：非文本消息摘要在推送与刷新场景均保留发送者前缀（如 `"张三: [图片]"` / `"我: [图片]"`）。

---

## 0. 说明与验收通用规则

### 0.1 任务格式

- **目标**：本任务完成后系统具备的能力
- **范围**：改动哪些模块
- **依赖**：前置任务
- **验收标准**：可测、可复现、可回归
- **涉及文件/目录**：便于定位

### 0.2 通用验收（所有 Milestone 都必须满足）

- HTTP：鉴权接口可正常调用
- IM：被踢/重登时停止重连，弹窗提示信息可读

### 0.2.a 已执行变更标记规则

- 状态取值：`已完成` / `进行中` / `未开始`
- 标记位置：写在对应任务块的第一条说明后

### 0.3 实现入口索引（开工必看）

说明：下表用于把 Backlog 任务与当前工程入口文件对齐，便于直接开工与回归。

| 能力域 | 当前关键入口（模块/文件） | 备注 |
| --- | --- | --- |
| HTTP 统一鉴权 | `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts`；`store/user.uts` | 401 refresh 单飞、队列重放 |
| IM 统一鉴权/续期 | `shengyu-ui/.../utils/websocket.uts`；`shengyu-framework/.../AuthHandler.java` | AUTH_REQ/AUTH_RENEW/RENEW_SUGGEST/REAUTH_REQUIRED |
| 撤销闭环（RedisMQ） | `shengyu-framework/.../core/mq/consumer/ImSessionRevokeConsumer.java` | clientId 过滤、精确撤销优先级 |
| 多端互踢 | `shengyu-framework/.../NettySessionManager.java`；`NettySession.java` | 同 deviceType 互踢、byDevice 友好展示 |
| JSON 双栈入口 | `WebSocketFrameHandler.java`；`JsonBusinessMessageHandler.java` | WebSocket TextFrame JSON -> processor |
| Protobuf 链路入口 | `ProtobufMessageHandler.java`；`NettyAutoConfiguration.java` | App 端 Protobuf 编解码待补 |
| 消息处理器注册 | `NettyAutoConfiguration.java` | 处理器注册存在≠可靠性闭环完成 |
| 存储 SPI | `MessageStorageService`；`NoOpMessageStorageServiceImpl` | 默认 NoOp，需要由业务模块覆盖 |
| 会话 REST | `AppImConversationController.java`；`ImConversationService` | 已有基础接口，需补 sequence 水位与增量 sync |

---

### 0.4 前后端对接清单（uniappx <-> module-system）

说明：本节用于把移动端实际调用点与后端 Controller 精确对齐，避免“接口存在但端侧没接/参数不一致”。

#### 0.4.1 REST API 对接清单（移动端 -> 租户端）

| 能力 | uniappx 调用入口 | HTTP URL | module-system Controller（入口） | 备注 |
| --- | --- | --- | --- | --- |
| 角标获取 | `api/badge.uts#getBadgeData`；`services/badge-service.uts` | `GET /system/im/badge/get` | `AppImBadgeController#getBadgeData` | 用于首页/会话列表角标同步 |
| 会话列表 | `api/conversation.uts#getConversationList`；`services/conversation-service.uts#loadConversations` | `GET /system/im/conversation/list` | `AppImConversationController#getConversationList` | 当前为全量列表；建议补增量 sync（见 Milestone C3） |
| 创建/获取会话 | `api/conversation.uts#createConversation` / `getConversationByTarget` | `POST /system/im/conversation/create`；`GET /system/im/conversation/get-by-target` | `AppImConversationController#createOrGetConversation` / `getConversationByTarget` | 单聊/群聊统一会话模型 |
| 会话设置（置顶/免打扰） | `api/conversation.uts#pinConversation` / `setNoDisturb` | `PUT /system/im/conversation/update` | `AppImConversationController#updateConversation` | 字段：`isPinned`、`noDisturb` |
| 清空未读/标记已读 | `api/conversation.uts#markReadBySequence` | `PUT /system/im/conversation/mark-read-seq?chatId=&readSequence=` | `AppImConversationController#markConversationReadBySequence` | 唯一权威接口：按 sequence 水位推进，单调递增 |
| 删除会话 | `api/conversation.uts#deleteConversation` | `DELETE /system/im/conversation/delete?chatId=...` | `AppImConversationController#deleteConversation` | 参数名：chatId |
| 联系人列表/搜索/详情 | `api/contact.uts` | `/system/im/contact/*` | `AppImContactController` | `list-by-dept` 当前后端存在 TODO（见 0.4.3） |
| 群组（创建/更新/列表/成员/公告/邀请） | `api/group.uts`；`services/group-service.uts` | `/system/im/group/*` | `AppImGroupController` | 邀请码/二维码接口已具备 |
| 群文件（上传/列表/删除/下载计数） | `services/group-service.uts`（调用 `/system/im/group/file/*`） | `/system/im/group/file/*` | `AppImGroupFileController` | `upload` multipart；`download` 为记录下载次数 |
| 消息列表 | `api/message.uts#getMessageList` | `GET /system/im/message/list-by-chat` | `AppImMessageController#getMessageListByConversation` | `chatId` + 分页参数 |
| 消息撤回/删除 | `api/message.uts#recallMessage` / `deleteMessage` | `PUT /system/im/message/recall`；`DELETE /system/im/message/delete` | `AppImMessageController#recallMessage` / `deleteMessage` | 撤回闭环需配合 WS 广播（Milestone F1） |
| 消息已读上报 | - | - | - | 已收敛为会话水位：`PUT /system/im/conversation/mark-read-seq?chatId=&readSequence=` |
| 搜索聊天记录 | `api/message.uts#searchMessages`；`services/message-search-service.uts` | `GET /system/im/message/search` | `AppImMessageController#searchMessages` | keyword + chatId + 时间范围 |

#### 0.4.2 WebSocket 对接清单（系统消息）

| 场景 | uniappx 入口 | MessageType | 服务端入口（参考） | 备注 |
| --- | --- | --- | --- | --- |
| 连接认证 | `utils/websocket.uts#sendAuthRequest` | `AUTH_REQ(3)` / `AUTH_RESP(4)` | `shengyu-framework/.../AuthHandler` | body：accessToken/deviceType/deviceId/deviceName/clientVersion |
| 心跳保活 | `utils/websocket.uts#startHeartbeat` | `HEARTBEAT_REQ(1)` / `HEARTBEAT_RESP(2)` | `websocket-starter` 心跳处理链路 | 超时应断开并重连（除非被踢/需重登） |
| 统一关闭/下线通知 | `utils/websocket.uts#handleCloseMessage` | `CLOSE(5)` | `ImSessionRevokeConsumer` / `NettySessionManager` | action：KICKED/LOGOUT/REVOKED/REAUTH_REQUIRED；前端需停止重连 |
| token 刷新不断链续期 | `utils/websocket.uts#requestReauth`（由 `utils/request.uts` 回调触发） | `AUTH_REQ`（同连接重认证） | `AuthHandler` | 当前实现为“同连接重发 AUTH_REQ”，后续可演进为 AUTH_RENEW_REQ |

补充约束（CLOSE action 语义）：

- `KICKED`：互踢下线（需展示 byDevice/kickedAt）
- `REAUTH_REQUIRED`：强制重登（停止重连 + 清 token + 引导登录）
- `LOGOUT/REVOKED`：主动登出/撤销（停止重连 + 清 token + 引导登录）

#### 0.4.3 WebSocket 对接清单（业务消息）

说明：uniappx 侧主要在 `services/message-service.uts#initWebSocketListeners` 注册业务消息监听。

| 场景 | uniappx 入口 | MessageType | 服务端入口（参考） | 备注 |
| --- | --- | --- | --- | --- |
| 文本/图片/语音/视频/文件/位置接收 | `services/message-service.uts#handleReceivedMessage` | `TEXT(100)`/`IMAGE(101)`/`VOICE(102)`/`VIDEO(103)`/`FILE(104)`/`LOCATION(105)` | `NettyAutoConfiguration` 注册的对应 Processor | 依赖消息存储/ACK/sequence 等闭环（Milestone C） |
| 已读回执 | `services/message-service.uts#handleReadReceipt` | `READ_RECEIPT(201)` | READ_RECEIPT Processor | 群已读需聚合（Milestone C5） |
| 撤回通知 | `services/message-service.uts#handleRecall` | `RECALL(202)` | RECALL Processor | |
| 角标更新（跨端） | `services/badge-service.uts`（或 WS listener） | `BADGE_UPDATE(204)` | `ImBadgeService#pushBadgeUpdate`（业务侧触发） | 需与会话未读一致（Milestone C3） |

补充：企业级推送协议（Push-Driven 会话同步）

1. 原则：推送为会话同步/新会话出现的主路径；HTTP 拉取为兜底。
2. 适用范围：服务端向客户端推送的业务消息（WebSocket TextFrame JSON）统一遵循以下 envelope 约束。

WS(JSON) envelope 字段（服务端 -> 客户端）：

- `header.messageId`: string
- `header.messageType`: number
- `header.timestamp`: number
- `header.senderId/receiverId/groupId/tenantId`: string
- `header.sequence`: string
- `header.chatId`: string
- `conversationSnapshot`: object（可选）

`conversationSnapshot` 字段要求（建议与 `AppImConversationRespVO` 对齐，Long 按 string 输出）：

- `chatId`: string
- `targetId`: string
- `conversationType`: number
- `unreadCount`: number
- `lastMessageSequence`: string
- `lastReadSequence`: string
- `lastMessageContent`: string
- `lastMessageTime`: datetime
- `isPinned`: boolean
- `noDisturb`: boolean
- `targetName`: string
- `targetAvatar`: string
- `groupMemberCount`: number

端侧处理规则（必须遵循）：

- 收到业务消息时，优先使用 `header.chatId` 作为会话主键，禁止使用 `groupId/receiverId` 作为会话主键写缓存。
- 若携带 `conversationSnapshot`：端侧必须先 upsert 会话列表缓存（创建或更新），再落消息与角标更新，保证“首条推送即出现会话”。
- 若缺失 `conversationSnapshot` 或会话不存在：端侧允许调用 `GET /system/im/conversation/get-by-target` 做兜底补齐（只作为安全网）。

验收标准（Push-Driven 新会话创建）：

- 单聊/群聊：接收端本地无会话时，收到首条 WS 消息后，会话列表必须自动出现新会话。
- 新会话出现不得依赖用户手动刷新或定时轮询。
- 端侧会话未读展示必须使用服务端水位模型（`lastMessageSequence/lastReadSequence/unreadCount`），本地仅允许做“水位推进后的立即一致性更新”。

#### 0.4.4 已知缺口（代码级 TODO，需补齐到闭环）

（以当前工程为准）已补齐。

建议落地方式：

- 群消息分页：统一按 conversation/chatId 做查询；若仅有 groupId，需先提供 groupId -> chatId 的映射接口或在服务端内部完成转换
- 部门联系人：补齐按 deptId 查询接口的真实实现

说明（以当前工程为准，目标对齐企微/钉钉，不兼容旧业务）：

- 群消息分页 **不提供** `list-by-group` 作为长期契约；统一使用 `GET /system/im/message/list-by-chat`。
- 端侧若仅持有 `groupId`：先 `GET /system/im/conversation/get-by-target?targetId={groupId}&conversationType=2` 得到 `chatId`，再按 `chatId` 拉消息。

#### 0.4.5 已发现的对接不一致（需统一，避免“接口能编译但运行不通”）

说明：以下不一致来源于对 `shengyu-ui/shengyu-ui-admin-uniappx` 与 `shengyu-module-system` 的现状扫描，建议优先在端侧与服务端统一 URL/Method/入参形态，再做后续功能闭环。

| 模块 | uniappx 调用点 | 现状 URL/Method | 服务端现状 | 风险/建议 |
| --- | --- | --- | --- | --- |
| 群组（路径漂移） | `services/group-service.uts` | 统一复用 `api/group.uts` | `AppImGroupController` | 以 `api/group.uts` 为端侧唯一权威契约；`services/group-service.uts` 仅做缓存/聚合，禁止手写 URL |
| 已读回执/标记已读（已对齐） | `api/message.uts#markMessageRead`；`services/read-receipt-service.uts#markMessagesAsRead` | 统一：`PUT /system/im/message/mark-read`（query: `messageIds=...`） | `AppImMessageController#markMessageRead`：`PUT /mark-read`，`@RequestParam List<Long> messageIds` | 端侧保持“按水位推进已读”为权威（`PUT /system/im/conversation/mark-read-seq`）；`mark-read` 仅用于端到端“已读状态可视化/兜底”。 |
| 会话删除（参数形态不一致） | `api/conversation.uts#deleteConversation` vs `services/conversation-service.uts#deleteConversation` | api 通过 URL query：`DELETE /conversation/delete?chatId=...`；service 通过 `params`：`DELETE /conversation/delete` | `AppImConversationController#deleteConversation` 需要 query `chatId`（`@RequestParam`） | 两种写法可能都可用，但建议端侧统一使用 api 层实现，service 不再手写 URL/params，避免漂移 |
| 消息扩展能力（后端缺接口） | `services/message-reaction-service.uts`、`services/message-edit-service.uts`、`services/read-receipt-service.uts` | reaction：`POST /system/im/message/add-reaction`、`POST /system/im/message/remove-reaction`、`GET /system/im/message/reactions`；edit：`POST /system/im/message/edit`、`GET /system/im/message/edit-history`；read-detail：`GET /system/im/message/read-detail`、`GET /system/im/message/unread-detail`、`GET /system/im/message/unread-list` | `AppImMessageController` 当前主要路由：`/page`、`/list-by-chat`、`/pull`、`/recall`、`/delete`、`/mark-read`、`/unread-count`、`/search` | 端侧调用会直接 404。建议：
  - 若产品需要：补齐 Controller/Service（纳入 Milestone C5/F/C7）
  - 若短期不做：端侧入口需隐藏，并在文档标注“未支持/待实现”避免误用 |
| 响应结构（约定需固定） | `utils/request.uts` | `request()` 成功时直接返回业务 `data` | `utils/request.uts` 在 `code===0` 时 `return data.data` | 统一约定：`request()` 返回值=业务 data（推荐）；`api/*.uts` 与 `services/*.uts` 禁止再判断 `code`。需要原始 envelope 时另提供 `rawRequest()`（必须显式命名，避免误用）。 |

#### 0.4.6 对接一致性检查清单（开工前必过）

- URL：端侧 `api/*.uts` 与 `services/*.uts` 不应各自维护两套 URL；统一复用 api 层
- Method：确保端侧 method 与 controller 注解一致（GET/POST/PUT/DELETE）
- 参数形态：明确使用 `query params` 还是 `request body`，避免端侧传 `params` 而服务端仅支持 `@RequestBody`（或相反）
- ID 精度：chatId/groupId/messageId 在端侧统一使用 string（文档已约定）
- 响应结构：明确 `request()` 是返回“业务 data”还是“原始 envelope（code/data/msg）”，service/api 必须一致（否则会出现隐性逻辑不走）

#### 0.4.7 module-system 缺失接口清单（以 uniappx 现状调用为准）

说明：本表用于把“端侧已写死的 URL”与“后端缺失/未实现的 Controller 路由”列清楚，便于排期补齐或端侧降级隐藏。

| 能力 | uniappx 调用点 | 端侧现状 URL/Method | module-system 现状 | 建议的权威契约（推荐） |
| --- | --- | --- | --- | --- |
| 按 groupId 分页查询群消息 | 不提供（对齐企微/钉钉的单一口径） | - | - | 统一使用 `chatId`：端侧必须先通过会话获取 `chatId`，再调用 `list-by-chat`/`pull` |
| 按 deptId 获取联系人 | `api/contact.uts#getContactListByDept` | `GET /system/im/contact/list-by-dept?deptId=` | `AppImContactController#getContactListByDept` 已按 deptId 过滤 | 后续可补齐分页/排序策略（如有性能压力再加） |
| 群组：dismiss/members/add-members 等“历史 URL” | `services/group-service.uts` 多处 | 见 0.4.5（大量 /system/im/group/* 非标准路由） | `AppImGroupController` 未提供这些路由 | 端侧统一改为复用 `api/group.uts`；如确需保兼容，可在后端做临时别名路由，但最终以 `AppImGroupController` 为权威 |
| 消息表情回应 | `services/message-reaction-service.uts` | `POST /system/im/message/add-reaction`；`POST /remove-reaction`；`GET /reactions` | 后端缺路由 | 若要做：建议新增 `AppImMessageReactionController`（或挂在 message controller 下），并定义：`POST /reaction/add`、`POST /reaction/remove`、`GET /reaction/list?messageId=`（注意幂等与去重） |
| 撤回后重新编辑（企微/钉钉口径） | - | - | - | 以文档为准：**重新编辑=回填后发送新消息（1A）**，且**发送者所有设备可用（2B）**。禁止实现“编辑历史消息”能力（修改原消息内容）。 |
| 群已读详情（read-detail/unread-detail/unread-list） | `services/read-receipt-service.uts` | `GET /system/im/message/read-detail`；`GET /unread-detail`；`GET /unread-list` | 后端缺路由 | 企业级推荐优先做聚合（Milestone C5）；详情接口可选：`GET /read-receipt/summary?messageId=`（已读/未读人数）+ `GET /read-receipt/detail?messageId=&pageNo=&pageSize=` |

## Milestone A（P0）：统一鉴权一致性 + 撤销闭环（HTTP <-> IM）

### A1（P0）：撤销事件模型固化

- **验收**：logout/互踢/强退都能映射到统一撤销事件；IM 定向收到 CLOSE/KICKED，且不影响不同 deviceType。
- 状态：已完成（以当前工程为准）

实现对齐点（以代码为准）：

- 同 deviceType 互踢：服务端 `NettySessionManager#addSession` 发现同 `userId + deviceType` 已在线时，向旧连接下发 `CLOSE`，`body.action = KICKED`，并携带 `kickedAt/byDevice`。
- 会话撤销（token 失效/强退）：服务端 `ImSessionRevokeConsumer` 下发 `CLOSE`，`body.action = REVOKED`（或指定 action），并关闭连接。
- 端侧处理：`utils/websocket.uts#handleCloseMessage` 对 `KICKED/LOGOUT/REVOKED/REAUTH_REQUIRED` 禁止自动重连并清 token，弹窗引导登录（对齐企微/钉钉）。

### A2（P0）：在线设备列表与踢人 API（管理态）

- **验收**：返回 deviceName/deviceType/loginTime/lastActive；主动踢人后目标端立即弹窗并退出登录。
- 状态：不做（本期范围仅聚焦 IM 移动端，管理态/后台运维能力不排期）

说明（以当前工程为准）：

- 服务端已具备会话查询基础能力（`NettySessionManager#getSessionsByUserId/getSessionsByTenantId/getOnlineDeviceTypes` 等）。
- 由于本期仅聚焦 IM 移动端：不提供“管理态 REST API（在线设备列表/踢人）”，也不在本期验收范围内。

### A3（P0）：refresh-token 自动续期 tenant-id 透传修复

- **验收**：客户端自动刷新 token 时请求头携带 `tenant-id`，服务端不再报“租户 ID 未传”。
- 状态：已完成

---

## Milestone B（P0）：协议双栈（App Protobuf + H5 JSON）落地

对齐说明（以当前工程代码为准）：

- 当前对外链路为 **WebSocket + JSON Envelope 单栈**：端侧 `uni.connectSocket` 发送 JSON（`{header, body}`），服务端通过 `WebSocketFrameHandler` -> `JsonBusinessMessageHandler` 转为 Protobuf 并进入 processor。
- `enableProtobuf` 分支为 **内部 TCP 直连 Protobuf**（`ProtobufVarint32FrameDecoder/ProtobufDecoder/ProtobufMessageHandler`），并非 WebSocket 子协议（SubProtocol）协商。
- 目前未实现：`im.pb.v1/im.json.v1` SubProtocol 列表、首帧探测（MAGIC/VERSION/CODEC/FLAGS）、端侧 Protobuf 编解码与自动降级。

### B0（P0）：协议与版本基线冻结（SubProtocol + 首帧探测）

- **验收**：固定 `im.pb.v1`/`im.json.v1`；首帧 MAGIC/VERSION/CODEC/FLAGS；形成兼容矩阵。
- 状态：进行中（已落地 SubProtocol 列表 + PROBE/PROBE_RESP；PB BinaryFrame 双栈解码待 B3/B4）

- **目标**：冻结“连接层协商”协议基线。
- **范围**：
  - 服务端：SubProtocol 列表、首帧探测格式、ProbeTimeout
  - 客户端：App/H5 的 protocol 声明与降级重连策略
- **依赖**：Milestone A（统一鉴权的 CLOSE 语义与停止重连策略）
- **验收标准**：
  - 固定：`im.pb.v1`、`im.json.v1`
  - 固定首帧字段：MAGIC/VERSION/CODEC/FLAGS
- **涉及文件/目录**：
  - `shengyu-framework/shengyu-spring-boot-starter-websocket/.../WebSocketFrameHandler.java`
  - `shengyu-framework/.../ProtobufMessageHandler.java`
  - `shengyu-framework/.../JsonBusinessMessageHandler.java`
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`

本期冻结的协商口径（以当前工程为准）：

- SubProtocol：服务端支持 `im.json.v1,im.pb.v1`（可配置）；端侧默认宣告 `im.json.v1`
- 首帧探测（PROBE）：端侧连接建立后先发送 `MessageType.PROBE(6)`，服务端返回 `MessageType.PROBE_RESP(7)`

严格模式（不兼容旧客户端）的硬约束（本期启用）：

- 端侧 **必须** `PROBE -> AUTH_REQ`，禁止 `AUTH_REQ` 作为首帧
- `probeTimeoutMs` 内未收到 PROBE：服务端下发 `CLOSE(action=PROBE_TIMEOUT)` 并断开
- 收到 `AUTH_REQ` 但未 PROBE：服务端下发 `CLOSE(action=PROBE_REQUIRED)` 并断开

PROBE（JSON TextFrame）字段约定（Long/ID 均按 string 透传）：

- `header.messageType = 6`
- `header.messageId`: string
- `header.timestamp`: number
- `body.version`: number
- `body.codec`: string（当前落地 `json`；pb 待 B3/B4）
- `body.features.ack`: boolean
- `body.client.deviceType/deviceId/deviceName/clientVersion`

PROBE_RESP（JSON TextFrame）字段约定：

- `header.messageType = 7`
- `body.codec`: string
- `body.features.ack`: boolean
- `body.serverTime`: number


### B1（P0）：服务端握手协商并绑定 codec

- **验收**：SubProtocol 优先；无 SubProtocol 时首帧探测；失败关闭连接。
- 状态：未开始

- **目标**：服务端在 Upgrade 后完成协商，且把 `codec/negotiationMode` 绑定到连接会话上下文。
- **范围**：
  - Netty pipeline：协商 handler + CODEC_BOUND 状态
  - CLOSE：协商失败关闭连接
- **依赖**：B0
- **验收标准**：
  - SubProtocol 传 `im.pb.v1` -> 绑定 PB
  - 不传 SubProtocol：Text 首帧 -> JSON；Binary magic -> PB/JSON
  - 不可识别首帧 -> 关闭连接
- **涉及文件/目录**：
  - `shengyu-framework/.../WebSocketFrameHandler.java`
  - `shengyu-framework/.../core/session/NettySession.java`（或等价上下文字段）


### B2（P0）：服务端双 decoder/encoder（业务无感）

- **验收**：MaxFrameSize/AuthTimeout 生效；未认证仅允许 AUTH/HEARTBEAT；两栈跑通 AUTH/HEARTBEAT/CLOSE。
- 状态：已完成（WebSocket(pb) 出站统一封装：ImMessage -> BinaryWebSocketFrame + varint32 length-prefix；AUTH_RESP/HEARTBEAT_RESP 已可被端侧稳定解码；队列 flush 已按 PB 发送 BinaryFrame，不再触发 CODEC_MISMATCH(415)）

- 已完成项（本期闭环点）：
  - 服务端：`AuthHandler` PB 认证响应走统一出站封装（`ctx.channel().writeAndFlush(ImMessage)`）
  - 服务端：`HeartbeatHandler` PB 心跳响应走统一出站封装（`ctx.channel().writeAndFlush(ImMessage)`）
  - 端侧：PB 模式下 `flushMessageQueue()` 统一走二进制发送（避免误发 TextFrame 导致 415）
  - 端侧：App Hide/Show 后若 `OPEN` 但未认证会补发 `AUTH_REQ`，确保心跳与队列可恢复

- 下一步（避免重复）：
  - B0：协议基线冻结后补齐“严格模式 PROBE -> AUTH_REQ”与 PB BinaryFrame 双栈解码前置点
  - B1：把协商结果（codec/negotiationMode）作为连接上下文的权威来源，并据此绑定 codec
  - B3：JSON Envelope 必填校验/错误返回（与 PB header 语义对齐）
  - B4：App 端 PB 编解码 + 自动降级（pb 建链失败回落 json）

- **目标**：做到“业务 processor 只面对统一领域对象”，编解码对业务无侵入。
- **范围**：
  - decoder：JSON -> ImMessage；PB -> ImMessage
  - encoder：ImMessage -> JSON/PB
  - 资源保护：MaxFrameSize
- **依赖**：B1
- **验收标准**：
  - JSON/PB 两栈：AUTH_REQ/HEARTBEAT/CLOSE 全部跑通
- **涉及文件/目录**：
  - `shengyu-framework/.../AuthHandler.java`
  - `shengyu-framework/.../JsonBusinessMessageHandler.java`
  - `shengyu-framework/.../ProtobufMessageHandler.java`


### B3（P0）：JSON Envelope 与字段语义对齐

- **验收**：JSON decode 失败可处理。
- 状态：未开始

- **目标**：冻结 JSON Envelope 校验规则，与 Protobuf header 语义完全一致。
- **范围**：
  - header 必填/可选字段校验
  - 服务端覆盖字段：tenantId/userId/sequence/serverTime
  - `extra` 扩展域约束
- **依赖**：B2
- **验收标准**：
  - header 缺必填字段时可返回错误
- **涉及文件/目录**：
  - `shengyu-framework/.../JsonBusinessMessageHandler.java`
  - `shengyu-framework/.../core/netty/handler/*`（若有 Envelope 校验器）


### B4（P0）：App 端 Protobuf 编解码 + 自动降级

- **验收**：App 宣告 pb；收发二进制可解码；服务端不支持 pb 时可降级 json。
- 状态：未开始

- **目标**：App 端在支持 pb 的情况下使用 pb；不支持时可降级 json。
- **范围**：
  - uniappx：pb 编解码、subProtocol 声明、错误码识别与降级重连
- **依赖**：B0~B3
- **验收标准**：
  - App 使用 `im.pb.v1` 建链成功后收发二进制消息可解码
  - 服务端不支持 pb 时：App 可切换 `im.json.v1` 重连
- **涉及文件/目录**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`
  - `shengyu-ui/.../utils/protobuf.uts`（待新增或待落地文件）


---

## Milestone C（P0/P1）：消息可靠性（ACK/幂等/重投/断线补偿）

### C1（P0）：ACK + 先存储后 fanout

- **验收**：ACK 超时重发不产生重复消息；服务端幂等返回同一 sequence。
- 状态：已完成（Phase1：ACK 协议双栈 pb+json 已联调验收通过）

对齐说明（以当前工程代码为准）：

- 已具备：
  - 服务端“先存储后投递”的基本链路（processor -> storage -> sender）。
  - 幂等基础：服务端对同一 `messageId` 重投可做到不重复落库（`DuplicateKeyException` 分支已存在）。
  - 发送端状态推进：服务端会把消息回推给发送者（用于端侧把 `SENDING -> SENT`，但这不是独立 ACK 协议）。
- 尚缺：
  - ACK 驱动的服务端重发队列/超时策略/限流（Phase2，待灰度开关）。
  - WebSocket BinaryFrame 的 PB decode/encode 真正接通（B3/B4），以便 PB 子栈也能使用相同 ACK 协议。

本期补充关键前置（企业级落地口径，确保 C1 幂等/重投/已读聚合可闭环）：

- **统一 `messageId` 为可落库 int64 主键**（端侧生成，服务端按该值落库到 `im_chat_message.id`）
  - 状态：已完成（端侧 snowflake-like 生成 + 发送前校验 + 回推归一化匹配）
  - 原因：read-receipt/撤回等接口按 `messageId(Long)` 查库；若端侧使用不可解析的字符串/或与 DB 主键不一致，会出现“消息不存在”。
  - 前端落点：
    - `shengyu-ui/shengyu-ui-admin-uniappx/utils/message-utils.uts#generateMessageId`
    - `shengyu-ui/shengyu-ui-admin-uniappx/utils/message-handler.uts#MessageBuilder.generateMessageId`（统一复用）
    - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts#normalizeOutboundMessageId`（发送前兜底校验，不合法则重生成并回写 header）
    - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts#normalizeInboundMessageId`（回推/ACK 归一化，避免 number/string 形态不一致导致匹配失败）
  - 服务端落点：
    - `shengyu-framework/.../JsonBusinessMessageHandler#readLong`（兼容 string/number）
    - `shengyu-module-system/.../SystemMessageStorageServiceImpl#saveMessageWithId`（`messageDO.setId(header.getMessageId())`）

验收标准补充：

- 发送端发消息后（服务端回推确认），调用 `GET /system/im/read-receipt/summary?messageId=` **不再出现** `消息不存在`。
- 弱网重投复用同一 `messageId`，服务端不会重复插入（DB 主键幂等命中），并返回相同 `sequence`。
- 回归项（端侧）：
  - `messageId` 必须为纯数字字符串，且 `0 < messageId <= 9223372036854775807`
  - 发送前若发现 `messageId` 非法（空/0/非数字/超 Long）：必须重生成，并保证本地渲染/重试/回推匹配使用同一个 `messageId`
  - 服务端回推时 `messageId` 可能为 number/string：端侧必须归一化为字符串后再匹配本地 `SENDING` 消息，避免“发送成功但一直转圈”

当前阶段落地口径（Phase1：独立 ACK + 可观测，不做重发）：

- **ACK 形态**：新增独立 ACK 消息类型（JSON TextFrame）。端侧收到业务/通知消息后自动回 `ACK(8)`；服务端记录并返回 `ACK_RESP(9)`（可选，便于联调）。
- **目的**：建立端到端可观测性（投递->回执延迟），并为 Phase2（ACK 驱动重发）提供协议与指标基线。
- **幂等要求（端侧）**：ACK 的 `messageId/chatId/sequence` 必须按 string 回传，禁止 number 化导致精度丢失。

ACK（JSON TextFrame）字段约定（所有 Long/ID 均按 string）：

- `header.messageType = 8`
- `header.messageId`: string（ACK 自己的消息ID）
- `header.timestamp`: number
- `body.messageId`: string（被确认的业务消息 messageId）
- `body.chatId`: string
- `body.sequence`: string
- `body.senderId/receiverId/groupId/tenantId`: string
- `body.ackType`: string（当前落地 `RECEIVED`）
- `body.clientReceivedAt`: number（客户端收到业务消息的本地时间戳）
- `body.originalTimestamp`: string（原业务消息 header.timestamp，按 string 透传）

观测口径：

- `deliveryDelayMs = clientReceivedAt - originalTimestamp`
- Phase1 只做日志/指标，不做重发；Phase2 才引入重发队列/超时策略/限流/灰度。

当前关键落点（便于回归定位）：

- `shengyu-framework/.../processor/impl/TextMessageProcessor`：保存消息后回推发送者，并转发给接收者（群聊 fanout 在该类里仍有 TODO 注释，但最终 fanout 已在 `SystemMessageStorageServiceImpl` 中按群成员处理）。

补充拆解：

- **目标**：服务端具备“先持久化后投递”的发送闭环，并返回 SendAck（含 `sequence/serverTime`）；客户端重投不产生重复消息。
- **范围**：
  - `shengyu-framework` websocket-starter（processor 链路）
  - `shengyu-module-system` IM 业务模块（消息落库/会话水位）
  - `shengyu-ui` uniappx（发送重投、pending->sent 状态机）
- **依赖**：Milestone A/B（鉴权、双栈链路打通）
- **验收标准**：
  - 发送端断网/弱网时重投同一 `messageId`，服务端返回同一 `sequence`
  - 服务端重启后再次重投同一 `messageId`，仍返回同一 `sequence`
  - 服务端先写入消息存储成功后再进行 fanout

- **涉及文件/目录**（示例，后续按实现细化）：
  - `shengyu-framework/shengyu-spring-boot-starter-websocket/.../MessageStorageService`（替换 NoOp）
  - `shengyu-framework/.../NoOpMessageStorageServiceImpl`（仅作对比，不直接改）
  - `shengyu-module-system/.../im`（新增 message/conversation seq 相关 service/repository）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
  - `sql/mysql/1.0/im/ddl_im_tables.sql`

### C2（P1）：断线补偿（lastSequence）

- **验收**：断网 30s 恢复后不丢不重、顺序正确；未读与角标一致。
- 状态：已完成（以当前工程为准）

- **目标**：端侧能基于 `lastPulledSequence` 拉取缺失消息；缺洞超过阈值自动触发补偿。
- **范围**：
  - module-system：提供按 `chatId + lastSequence`（拉取 `sequence > lastSequence`）的增量消息拉取接口
  - uniappx：实现 gap 检测、补偿拉取与本地归并
- **验收标准**：
  - 人为制造 WS 丢包/断链：重连后消息按 `sequence` 补齐
  - 同一会话消息严格按 `sequence` 渲染，不出现倒序
  - 补偿拉取不引入重复消息（去重键：`chatId + messageId`）
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImMessageController.java`（`GET /system/im/message/pull` 增量拉取）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`（`lastPulledSequence` 持久化、WS gap 检测、重连后先 sync 再 pull）

### C2.1（P0）：群消息分页查询闭环（groupId -> chatId）

- **背景**：目标对齐企微/钉钉，群消息分页查询只保留一套标准（按 `chatId`），端侧若只有 `groupId` 需先映射出 `chatId`。

- **目标**：端侧仅持有 `groupId` 时，也能稳定分页拉取群聊消息，并与会话/sequence 体系一致（不引入第二套消息查询口径）。

- **范围**：
  - module-system：提供 groupId -> chatId 查询能力（复用会话接口），并复用统一的 message page 查询
  - uniappx：统一通过 `chatId` 做消息分页；若页面入口只有 `groupId`，先获取 chatId 再拉取

- **推荐落地方式（优先）**：
  - 端侧先拿 chatId：复用现有
    - `GET /system/im/conversation/get-by-target?targetId={groupId}&conversationType=2`
  - 然后统一使用：
    - `GET /system/im/message/list-by-chat?chatId=...&pageNo=...&pageSize=...`
  - 开发阶段不保留 `list-by-group`，避免双标准与误用

- **验收标准**：
  - 端侧仅知道 `groupId` 时：先通过会话接口拿到 `chatId`，再分页/补偿拉取消息（pageNo/pageSize 生效）
  - 查询结果按 `sequence` 单调排序，不出现跨页乱序


- **涉及文件/目录**：
  - `shengyu-module-system/.../controller/app/im/AppImConversationController.java`（提供 groupId->chatId 查询能力，或复用已有 createOrGetConversation）
  - `shengyu-ui/shengyu-ui-admin-uniappx`：端侧统一通过 `chatId` 调用 `list-by-chat`/`pull`


### C3（P0）：会话同步与未读水位模型（对齐企微/钉钉）

- **验收**：服务端维护 lastReadSequence/lastMessageSequence；已读上报只升不降；跨端一致。
- 状态：已完成

- **目标**：把“会话未读/已读”从端侧计算升级为服务端权威水位模型，支持增量同步（cursor）。
- **范围**：
  - module-system：会话表/水位字段、会话增量同步接口、已读水位上报接口
  - uniappx：会话列表从 `syncConversations(cursor)` 增量更新，已读上报使用水位（或兼容过渡）
- **验收标准**：
  - 任一端上报已读水位后，另一端会话未读数同步推进
  - 已读水位只升不降（重复上报/乱序上报不回退）
  - 会话同步支持 cursor 增量，拉取结果稳定可回归
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImConversationController.java`（新增 /sync、read-watermark 上报）
  - `shengyu-module-system/.../ImConversationService`
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（会话水位字段/索引）

补充拆解（建议按子任务逐条验收，避免只实现“字段”但闭环不通）：

#### C3.1（P0）：冻结会话水位字段与单调性规则

- **目标**：服务端成为“未读/已读”的权威来源，水位只升不降（`max(old,new)`）。
- **范围**：
  - 会话用户维度（`chatId + userId`）：`lastReadSequence`、`lastReadTime`
  - 会话维度：`lastMessageSequence`、`lastMessageId`、`lastMessageTime`
- **验收标准**：
  - 任意顺序上报（旧值/重复值）不会导致 `lastReadSequence` 回退
  - 会话未读数计算口径固定：`unread = lastMessageSequence - lastReadSequence`（需处理异常/负值保护）

#### C3.x（P0）：会话列表角标即时一致性（对齐企微/钉钉）

- **问题现象**：A、B 都在聊天页；B 给 A 连续发 N 条；A 从聊天页返回会话列表时未读角标仍为 N，刷新也不消失；重新进入会话后才消失。
- **原因**：进入会话时已推进一次 read 水位，但“会话页停留期间新增消息”未在离开页面时再 flush 到服务端；导致服务端 badge 仍认为未读。
- **目标**：返回会话列表页即可清零未读；刷新/重启后一致。
- **落点（端侧）**：
  - `pages/message/chat.uvue`：
    - 进入会话：按最大 `sequence` 调用 `badgeService.clearConversationBadge(chatId, maxSeq)`（推进服务端 read 水位 + 本地清零）
    - 离开会话（`onHide/onUnload/onUnmounted`）：再次 flush 最大 `sequence`，保证返回列表立即一致
    - 性能优化：flush 带去重/节流（in-flight 保护 + 相同 `maxSeq` 短窗口内跳过），避免生命周期多次触发导致重复请求
  - `services/message-service.uts`：
    - 若收到消息且 `activeChatId === chatId`：视为已读，不增加角标；推进本地读水位并清本地角标
- **验收标准**：
  - A 在会话页停留收到消息后，直接返回会话列表：该会话未读为 0
  - 在会话列表页刷新/重新打开 App：该会话未读仍为 0

#### C3.2（P0）：增量会话同步接口（syncConversations）

- **目标**：端侧会话列表可通过 cursor 增量同步（对齐企微/钉钉的“拉增量 + 本地合并”）。
- 状态：已完成
- **建议契约**：
  - `GET /system/im/conversation/sync?cursorVersion=...&limit=...`
  - 响应：`{ nextCursorVersion, hasMore, items: [ { chatId, conversationType, targetId, cursorVersion, conversationVersion, lastMessageSequence, lastReadSequence, unreadCount, isPinned, noDisturb } ] }`
- **验收标准**：
  - cursorVersion 初次为 0/空：返回全量 + `nextCursorVersion`
  - cursorVersion 非空：只返回 `cursorVersion > 入参` 的会话变更（按 cursorVersion 升序）
  - 端侧合并规则：
    - 同 chatId：以 `conversationVersion` 更大者覆盖
    - 游标推进：以 `cursorVersion` 作为唯一推进依据
- **涉及文件/目录**：
  - `AppImConversationController.java`（新增 `sync`）
  - `services/conversation-service.uts`（增量同步与合并）

补充（完整版本号版，P0，强烈建议对标企微/钉钉落地）：

#### C3.2.1（P0）：cursorVersion（用户维度游标）分配器

- **目标**：为同一 `tenantId + userId` 的“会话列表态变更”分配单调递增 `cursorVersion`，用于增量 sync 与缺口检测。
- 状态：已完成
- **实现建议**：
  - 新表 `im_user_cursor(tenant_id, user_id, next_cursor_version)` 或 Redis 原子自增
  - 每次会话用户态变更写入时获取 `cursorVersion = ++next`
- **验收**：
  - 并发下不重复、不回退
  - 单用户高频消息下仍可分配（不成为瓶颈）

#### C3.2.2（P0）：会话-用户态表增加 cursorVersion + conversationVersion

- **目标**：为每个 `(chatId,userId)` 维护：
  - `cursorVersion`（用于 sync 扫描）
  - `conversationVersion`（用于同 chat 快照合并）
- **验收**：
  - `GET /conversation/sync` 可走索引 `(tenant_id,user_id,cursor_version)`
- 状态：已完成

#### C3.2.3（P0）：WS 事件携带 cursorVersion + 缺口补偿

- **目标**：WS 推送（CONVERSATION_UPSERT / WATERMARK_UPDATE / 新消息事件）必须包含 `cursorVersion`。
- 状态：已完成
- **端侧策略**：
  - 若收到 version 跳跃（`v > local+1`）：立刻 `sync(cursorVersion=local)` 补齐
  - 若重复/乱序：按 `conversationVersion` 去重合并
- **验收**：
  - WS 丢包/断线后，sync 可完全补齐会话列表变更

#### C3.3（P0）：已读水位上报接口（reportReadWatermark）

- **目标**：替代 `messageIds[]` 批量已读上报，改为 O(1) 水位上报，并可跨端同步。
- **建议契约**：
  - `PUT /system/im/conversation/read-watermark`
  - body：`{ chatId: string, lastReadSequence: number, clientTime?: number, deviceId?: string }`
  - 响应：`{ applied: boolean, lastReadSequence: number, serverTime: number }`
- **验收标准**：
  - 上报低水位不会覆盖高水位（返回 applied=false 且返回当前水位）
  - 端侧进入会话/滚动到底/回到前台时可按策略上报（避免频繁写）

#### C3.4（P0）：跨端水位变更事件（WS）

- **目标**：同账号多端在线时，水位推进能实时同步到其他端（驱动未读/角标更新）。
- **建议事件**：`CONVERSATION_WATERMARK_UPDATE`（或复用现有 badge update，但建议包含 chatId 水位）
- **验收标准**：
  - A 端上报水位后，B 端 1s 内收到事件并更新会话未读
  - WS 丢包时，B 端通过 `syncConversations(cursor)` 可最终一致

#### C3.5（P0）：从 messageIds 兼容迁移（过渡期）

- **目标**：统一已读口径为服务端水位模型。
- **策略**：
  - 只保留 `PUT /system/im/conversation/mark-read-seq?chatId=&readSequence=`（按 sequence 水位推进）
- **验收标准**：
  - 不出现水位回退


#### C3.6（P0）：数据模型与 SQL 落点（会话用户水位）

- **目标**：把水位字段落到明确的数据模型中，并具备可扩展性（后续群已读聚合、DND、pin/noDisturb、设备策略等）。
- **推荐方案（优先）**：独立表（会话-用户态）
  - 表建议：`im_conversation_user_state`
  - 主键/唯一键：`(tenant_id, chat_id, user_id)`
  - 核心字段：
    - `last_read_sequence BIGINT NOT NULL DEFAULT 0`
    - `last_read_time DATETIME NULL`
    - `unread_count INT NOT NULL DEFAULT 0`（可冗余，便于列表查询；由事务/事件维护）
    - `is_pinned TINYINT NOT NULL DEFAULT 0`
    - `no_disturb TINYINT NOT NULL DEFAULT 0`
    - `updated_at DATETIME NOT NULL`（用于 sync cursor）
  - 索引建议：
    - `(tenant_id, user_id, updated_at)`：支持 `syncConversations(cursor)`
    - `(tenant_id, user_id, unread_count)`：支持未读筛选/统计
- **备选方案（现状兼容）**：沿用/扩展 `im_chat_user`（如当前已存在并承载 unreadCount）
  - 在 `im_chat_user` 上补齐：`last_read_sequence`、`last_read_time`、`updated_at`
  - 约束：后续扩展字段会膨胀，且不同语义（成员关系 vs 会话用户态）易耦合
- **涉及 SQL 文件**：
  - `sql/mysql/1.0/im/ddl_im_tables.sql`
- **验收标准**：
  - 能按 `tenantId + userId` 高效查询“会话列表 + 水位字段”
  - 能按 `updated_at` 做增量 cursor 扫描，不产生全表扫描

#### C3.7（P0）：接口并存策略（list vs sync）与废弃策略（mark-read）

- **目标**：避免端侧在“全量 list”与“增量 sync”之间摇摆，形成稳定演进路径；同时平滑废弃 `messageIds[]` 形态。
- **并存策略**：
  - `GET /system/im/conversation/list`：保留为“全量兜底/首屏快速加载”（可不保证增量能力）
  - `GET /system/im/conversation/sync`：作为企业级权威同步入口（多端一致/离线补偿的基础）
  - 端侧策略：
    - 首次进入：优先 `list` 出首屏，然后以 `sync(cursor)` 补齐/对齐（或直接只用 sync）
    - 后续刷新：只用 `sync(cursor)`
- **已读上报（唯一权威）**：
  - 只保留 `PUT /system/im/conversation/mark-read-seq?chatId=&readSequence=`
  - 端侧进入会话立即上报 `readSequence = 本地最大 sequence`
- **验收标准**：
  - 同一用户在灰度切换前后，不出现未读口径变化或水位回退
  - list 与 sync 返回字段口径一致（至少 chatId/lastMessageSequence/lastReadSequence/unreadCount/isPinned/noDisturb）

### C4（P1）：投递回执与离线队列可对账

- **验收**：在线投递/离线入队可观测；输出投递成功率、离线入队量、补偿拉取量。

- **目标**：引入 DeliveryReceipt（或等价可观测事件），并在指标中可对账。
- **范围**：
  - server：投递结果事件记录（在线写入、离线入队）
  - metrics：ACK 超时比例、补偿拉取量等核心指标
- **验收标准**：
  - 指标可按 tenantId 聚合：发送量、SendAck 延迟、补偿拉取量
  - 可抽样对账：某 messageId 的发送->持久化->投递（在线/离线）链路可追踪

### C5（P1）：群已读聚合

- **验收**：默认只展示已读/未读人数；可选分页查询成员列表。
- 状态：已完成（群聊气泡旁“已读/未读”在刷新/重进后稳定显示）

- **目标**：群已读避免风暴，提供聚合统计与按需分页详情。
- **范围**：
  - module-system：聚合统计接口（count）+ 分页详情接口（可选）
  - uniappx：默认仅展示聚合数字，详情按需加载
- **验收标准**：
  - 1000 人群聊下已读回执不产生风暴（不广播全量成员列表）
  - 统计数字与分页详情一致

补充拆解（把端侧现状 `/system/im/message/read-detail/unread-detail/unread-list` 收敛为企业级契约，避免接口碎片化）：

#### C5.1（P1）：已读聚合摘要接口（summary）

- **目标**：默认只返回聚合数字（已读/未读人数），端侧会话页/消息气泡展示不需要拉全量名单。
- **建议契约**：
  - `GET /system/im/read-receipt/summary?messageId=...`
  - 响应：`{ messageId, chatId, readCount, unreadCount, totalCount, readAtMax?: number }`
- **关键约束**：
  - 总人数口径：以“消息发送时的群成员快照”或“当前群成员”二选一固定（推荐：当前成员 + 说明边界）
  - 服务端需做聚合缓存（可选），避免频繁 count 造成 DB 压力
- **验收标准**：
  - 1000 人群聊下，summary 查询延迟稳定（建议 p95 < 200ms）
  - summary 与 detail 分页总数一致（同一口径）

#### C5.2（P1）：已读/未读详情分页接口（detail）

- **目标**：仅在用户点开“已读详情”时按需分页拉取名单。
- **建议契约**：
  - `GET /system/im/read-receipt/detail?messageId=...&status=read|unread&pageNo=...&pageSize=...`
  - 响应：`PageResult<{ userId, userName, avatar, readTime?: number }>`
- **关键约束**：
  - 未读列表不强制返回 readTime
  - 必须分页（默认 20/50），避免端侧一次性渲染导致卡顿
- **验收标准**：
  - 同一 messageId：read/unread 两类 detail 分页合计总数与 summary 一致
  - 翻页稳定，不重复、不漏项（按 userId 排序或按 readTime 排序需固定）

#### C5.3（P1）：回执上报与聚合数据来源（抗风暴）

- **目标**：避免“每条消息 * 每个成员 * 每个端”的回执风暴。
- **策略建议**：
  - 单聊：可用 `read-watermark`（C3）即可，不做逐条回执
  - 群聊：
    - 默认只维护“用户在会话维度的 lastReadSequence”（水位）
    - 某条 messageId 的 readCount 由 `lastReadSequence >= message.sequence` 聚合得到（推荐）
    - 若必须逐条：也应使用批处理/队列聚合，禁止 WS 广播全量 userId 列表
- **验收标准**：
  - 1000 人群，连续消息 100 条：服务端 QPS 不随成员数线性爆炸
  - 端侧 UI 展示 readCount 不要求“秒级强一致”，允许最终一致（sync 兜底）

#### C5.4（P1）：端侧接口收敛与旧接口废弃

- **目标**：清理端侧对不存在接口的依赖，避免 404；统一对接到 summary/detail。
- **废弃/替代**：
  - 废弃：`GET /system/im/message/read-detail`、`GET /system/im/message/unread-detail`、`GET /system/im/message/unread-list`
  - 替代为：`/system/im/read-receipt/summary` + `/system/im/read-receipt/detail`
- **验收标准**：
  - `services/read-receipt-service.uts` 对接新接口后，不再出现“接口未实现”的降级日志

- **涉及文件/目录**：
  - module-system：
    - `.../controller/app/im`（新增 `AppImReadReceiptController` 或在现有 message controller 下新增子路由）
    - `.../service/im`（读水位/聚合查询 service）
    - `sql/mysql/1.0/im/ddl_im_tables.sql`（如需要索引/冗余表）
  - uniappx：
    - `services/read-receipt-service.uts`（对接 summary/detail，移除旧路由）

### C6（P0）：多端已读水位推进与同步事件

- **目标**：同账号多端在线时，已读推进跨端一致（只升不降），并能通过 WS/HTTP 增量同步到所有端。
- 状态：已完成（企微/钉钉口径：水位只升不降；仅水位推进才产生事件；WS 推送 `SYSTEM_NOTIFY(cursorVersion)` 触发端侧增量 `syncConversations(cursor)`；并推送 `BADGE_UPDATE` 让其它端即时清 tab 红点，最终态以 sync 为准）
- **范围**：
  - module-system：落库 `lastReadSequence`；产生“会话水位变更事件”（WS 推送或增量可见）
  - uniappx：接收水位变更事件并更新会话未读与角标
- **依赖**：C3（会话水位模型与 sync 接口）
- **验收标准**：
  - A 端上报 `lastReadSequence` 后，B 端会话未读数在 1s 内推进（WS 在线）
  - 重复/乱序上报不回退（服务端 `max(old,new)`）
  - 离线端重新上线后，通过 `syncConversations(cursor)` 可拉到最新水位
- 回归项（企微/钉钉口径）：
  - 只升不降（端侧）
    - 端侧合并会话快照/增量项时：
      - `lastReadSequence = max(local.lastReadSequence, incoming.lastReadSequence)`
      - `lastMessageSequence = max(local.lastMessageSequence, incoming.lastMessageSequence)`
      - `unreadCount` 禁止直接覆盖，必须按 `maxSeq - maxReadSeq` 重算（负值保护为 0）
  - 只升不降（服务端）
    - 重复/乱序调用 `PUT /system/im/conversation/mark-read-seq`（旧 readSequence/相同 readSequence）不会导致水位回退
  - 乱序/旧快照不覆盖新快照
    - 端侧合并 `conversationSnapshot` / `sync(items)` 时，必须按 `conversationVersion` 丢弃旧版本（旧快照不得把新状态覆盖掉）
  - 事件顺序无关
    - `BADGE_UPDATE` 与 `SYSTEM_NOTIFY(cursorVersion)` 的到达顺序不固定；任意顺序下最终会话未读口径一致（最终态以 `syncConversations(cursor)` 为准）
  - 离线兜底（断线补偿）
    - 端侧重连/重新认证成功后，必须触发一次节流的 `syncConversationsIncrementally(false)`；确保断线期间无 WS 也能拉到最新水位
  - 必测复现路径（可回归）
    - 用例 1（多端在线推进）：A 端进入会话读到 sequence=S；B 端停留会话列表；1s 内 B 端 `lastReadSequence>=S` 且未读清零
    - 用例 2（重复/乱序上报）：A 端先上报 S=100，再上报 S=80/100；服务端与 B 端都不得出现未读反弹
    - 用例 3（旧快照乱序到达）：先收到包含 `lastReadSequence=100` 的快照，再收到 `lastReadSequence=90` 的旧快照；端侧最终必须保持 100
    - 用例 4（离线端上线兜底）：B 端离线期间 A 端推进已读水位；B 端上线触发 `sync(cursor)` 后能拉到最新 `lastReadSequence/unreadCount`
- 当前落地方式（最小侵入复用既有通道）：
  - 服务端在 `PUT /system/im/conversation/mark-read-seq` 成功落库并写入 `im_conversation_user_state` 后，向同一 userId 的所有 WS 连接推送 `MessageType.SYSTEM_NOTIFY`
  - WS payload 透传 `cursorVersion`（允许不携带 `conversationSnapshot`），端侧收到后触发 `syncConversationsIncrementally(false)` 拉取增量会话状态
  - 同时推送 `MessageType.BADGE_UPDATE` 用于即时刷新 tab 红点（最终态仍以 sync 为准）
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImConversationController.java`（read watermark 上报 + sync 输出）
  - `shengyu-module-system/.../ImConversationServiceImpl.java`（mark-read-seq 后推送 `SYSTEM_NOTIFY`）
  - `shengyu-framework/.../NettyMessageSender`（JSON payload 透传 `cursorVersion`，并支持 BADGE_UPDATE body 序列化）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts`
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`（`handleSystemNotify -> syncConversationsIncrementally`）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/badge-service.uts`

### C7（P0/P1）：消息最终态字段（status/rev）与端侧合并规则

- **目标**：撤回/删除等事件在“实时 WS + 补偿拉取”两条链路下保持最终一致，避免撤回后被补偿拉回原文。
- 状态：已完成（待联调/待验收；撤回/删除最终态一致：status=6 不回滚；rev 合并规则已固化）
- **范围**：
  - 服务端：消息模型增加最终态字段（至少 `status`、`rev`）并在查询/sync 返回
  - 客户端：同一 `messageId` 合并以 `rev` 更大者覆盖（或 serverTime 更新者覆盖）
- **依赖**：C2（断线补偿 syncMessages）、F1（撤回）、（如有）消息编辑能力
- **验收标准**：
  - 先收到撤回事件、后收到原消息：最终渲染为“已撤回”
  - 断线补偿拉取不会把撤回前的旧内容覆盖回去
  - 同一消息多次撤回/最终态变更：端侧最终态与服务端一致（可回归复现）
- 本期已落地（撤回最终态一致，企微/钉钉口径）：
  - 服务端落库 `im_chat_message.status=6`（撤回）后，`list-by-chat`/`pull` 返回 `status`
  - 服务端落库 `im_chat_message.rev`：新消息 `rev=1`；撤回 `rev+1`（原子递增）
  - REST 输出 `rev`（消息列表/补偿拉取）用于端侧最终态合并
  - WS 撤回事件 `header.extra` 携带 `rev/recallBy/recallTime`
  - WS 普通业务消息 `header.extra` 携带 `rev=1`（并与文件元数据等字段合并为同一 JSON）
  - 撤回时间窗配置化：`im.recall.window-seconds`（默认 120 秒）
  - 端侧 WS 收到 `MessageType.RECALL` 后，替换为撤回提示（最终态）
  - 端侧从 HTTP `pull`/`list-by-chat` 映射消息时，若 `status=6` 直接渲染撤回提示
  - 端侧 HTTP `pull` 断线补偿：已透传 `rev` 到 `MessageItem.rev`，确保 pull 场景同样遵循“rev 更大者为最终态”的合并规则
  - 端侧 REST 历史分页 `list-by-chat`：拉取后先写入 `MessageService` 缓存并复用 `addMessageToCache(messageId+rev)` 合并规则，再从缓存读取渲染，避免 UI 层与 Service 层合并规则分叉
  - 端侧合并去重时：若任一侧为撤回最终态（6），禁止被非撤回原文覆盖
  - 端侧 Delete-for-me：删除成功后同步清理 `MessageService` 本地缓存，避免重进会话“死灰复燃”
  - 会话列表预览落库：撤回最后一条消息时，仅当 `last_message_id` 命中才更新 `lastMessageContent/type` 为 `[消息已撤回]`，并通过 `cursorVersion` 增量 sync 跨端可见
- 回归项（必测复现路径）：
  - A 端发送消息 -> 撤回
  - B 端离线/断网 -> 重新上线触发 pull/list-by-chat
  - 期望：B 端最终展示为“已撤回”，不会被补偿拉回原文
  - A 端撤回后，B 端会话列表最后一条预览应更新为 `[消息已撤回]`，换端/重登后仍不回滚
  - 乱序到达：先收到撤回 WS（rev=2），后补偿拉取到原文（rev=1）时仍保持撤回最终态
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImMessageController.java`（查询/sync 输出最终态字段）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`（合并逻辑）
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（消息表字段/索引）

#### C7.x（P0）：对我删除（Delete-for-me）与清空聊天记录（Clear-history）跨端一致（已落地）

- **目标**：对我删除/对我清空必须在“实时 WS + 断线补偿拉取”两条链路下保持最终一致；不会出现删除/清空后被 pull/list-by-chat 拉回。
- **当前落地**：
  - Delete-for-me：落库 `im_chat_message_tombstone`；`DELETE /system/im/message/delete?id=...` 幂等；`page/pull/detail` 过滤
  - Clear-history：落库 `im_chat_clear_watermark(clear_sequence 单调递增)`；`DELETE /system/im/message/clear?chatId=...`；`page/pull/detail` 过滤
  - 多端同步：两者均分配 `cursorVersion` 并 WS 推送 `SYSTEM_NOTIFY(cursorVersion)` 触发端侧增量 sync，同时推送 `BADGE_UPDATE`
- **验收/回归（企业级必测）**：
  - 用例 1（在线多端删除）：A 端删除 messageId=M；B 端在线，1s 内通过 `SYSTEM_NOTIFY(cursorVersion)` 增量 sync 后不再展示 M
  - 用例 2（离线补偿删除）：B 端离线；A 删除 M；B 上线后 `pull/list-by-chat` 返回必须过滤 M
  - 用例 3（在线多端清空）：A 端清空 chatId=C；B 端在线，增量 sync 后消息列表不展示清空前消息
  - 用例 4（离线补偿清空）：B 端离线；A 清空 C；B 上线后 `pull/list-by-chat` 返回不得包含 `sequence <= clear_sequence` 的消息
- **涉及文件/目录**：
  - module-system：
    - `.../service/im/ImMessageServiceImpl.java`（delete/clear 落库 + WS 通知 + 查询过滤）
    - `.../controller/app/im/AppImMessageController.java`（新增 `DELETE /clear`）
    - `.../dal/mysql/im/ImChatMessageTombstoneMapper.java`
    - `.../dal/mysql/im/ImChatClearWatermarkMapper.java`
    - `sql/mysql/1.0/im/ddl_im_tables.sql`（tombstone/clear-watermark 表）
  - uniappx：
    - `api/message.uts`（新增 `clearConversationMessages`）
    - `pages/message/group-settings.uvue`（清空聊天记录调用后端）

### C7.1（P2，可选）：消息表情回应（Reaction）能力（受控开关 + 最终态一致性）

- **背景**：uniappx 已存在 `services/message-reaction-service.uts` 调用，但 module-system 当前缺对应接口。企业级建议以“可控开关”方式纳入，避免端侧误用。

- **目标**：提供消息表情回应能力（添加/取消/聚合展示），并保证在“实时 WS + 断线补偿拉取”两条链路下最终一致（不因补偿覆盖丢失 reaction）。

- **范围**：
  - module-system：reaction 数据模型 + REST 接口 +（可选）WS 事件
  - uniappx：feature-flag 控制入口显示；对接聚合列表接口

- **建议契约（统一路由，避免挂在 message 下无限膨胀）**：
  - `POST /system/im/reaction/add` body：`{ messageId: string, emoji: string }`
  - `POST /system/im/reaction/remove` body：`{ messageId: string, emoji: string }`
  - `GET /system/im/reaction/list?messageId=...` 响应：`[{ emoji, count, isSelf }]`

- **一致性约束**：
  - reaction 的变更必须体现在消息最终态的 `rev` 推进（或单独 reactionRev），端侧合并按 rev 优先
  - 断线补偿 `syncMessages` 返回的 message 结构需包含 reaction 聚合（或包含 reactionRev 触发端侧再拉取）

- **灰度/开关**：
  - 默认关闭；按 tenant/user 灰度开启（与 B6 灰度体系一致）
  - 开关关闭时：端侧不展示入口；服务端可返回 403xxx/feature_disabled

- **验收标准**：
  - 自己 add/remove 的幂等：重复请求不会导致 count 错乱
  - 多端一致：A 端回应后 B 端能看到聚合结果（WS 在线 1s 内；离线通过 sync 最终一致）
  - 大群性能：reaction 聚合查询不会拉全量 userId 列表（只返回 count/isSelf）

- **涉及文件/目录**：
  - module-system：`.../controller/app/im`（新增 `AppImReactionController`）
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（reaction 表/索引）
  - uniappx：`services/message-reaction-service.uts`（解除降级并对接新契约）

### C7.2（P0/P1）：撤回后重新编辑（Re-edit after recall，对齐企微/钉钉）

- 状态：已完成

- **目标**：仅当发送者本人撤回的**文字消息**，在撤回后 **5 分钟窗口内**展示“重新编辑”入口；点击后回填原文并**发送一条新消息**（原撤回消息保持最终态）。
- **强制规则**：
  - 重新编辑=发新消息（1A），禁止修改原撤回消息内容
  - 发送者所有设备可重新编辑（2B）：撤回事件需仅对发送者本人多端下发 `originalContent`
  - 群主/群管理员代撤回：发送者与管理员均不允许重新编辑
  - 非文字消息撤回不支持重新编辑

- **范围**：
  - 服务端：撤回事件对“发送者本人”补充下发 `originalContent`（仅发送者可见，不广播）
  - 端侧：撤回提示条显示“重新编辑”入口；点击后回填输入框并发送新消息

- **验收标准**：
  - 自撤回文字消息：5 分钟内任意设备均可重新编辑并成功发送新消息
  - 超过 5 分钟：入口消失，不可重新编辑
  - 管理员/群主代撤回：所有端均无入口
  - 非文字撤回：无入口
  - 断线补偿：恢复后不出现“撤回被原文覆盖/重新编辑入口异常”

- **涉及文件/目录**：
  - module-system：`ImMessageServiceImpl#recallMessage`（对发送者补充 originalContent 的通知）
  - uniappx：`pages/message/chat.uvue`（撤回提示 + 重新编辑入口）
  - uniappx：`services/message-service.uts`（处理撤回通知并保存 originalContent）

- **接口说明（必须遵循）**：
  - 本功能不提供“编辑原消息内容”的接口，因此 **不应新增** `PUT /system/im/message/edit` 或 edit-history。
  - 重新编辑的发送行为复用“发送消息”接口（端侧回填后正常发送一条新消息）。

### C8（P1）：对我删除（Delete-for-me）墓碑（tombstone）与跨端保持

- **目标**：删除仅影响当前用户展示，但跨端一致（同账号其他设备也不再展示该 messageId）。
- **范围**：
  - module-system：维护用户维度 tombstone（userId/conversationId/messageId/deletedAt）并在查询/sync 过滤
  - uniappx：本地落 tombstone 并过滤渲染
- **依赖**：C3（会话 sync）、C2（消息 sync）、F2（对我删除语义）
- **验收标准**：
  - A 端删除某条消息后，B 端同步后不再展示该消息
  - 重新登录/换设备后仍保持不展示
  - tombstone 不影响服务端审计与管理员能力（仅影响用户视图）
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImMessageController.java`（delete-for-me API + 查询过滤）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（tombstone 表）

### C9（P2，可选）：主端策略（主端优先 vs 全端同步）

- **目标**：支持运营可配置多端投递策略，保证多端体验与资源消耗可控。
- **范围**：
  - 服务端：按 tenant/user/deviceType 配置策略；fanout 选择“全端”或“仅主端”
  - 客户端：非主端仅同步水位/角标，进入会话触发补偿拉取
- **依赖**：C2/C3（补偿与 sync）、B6（灰度开关）
- **验收标准**：
  - 配置为“主端优先”时，非主端不接收实时消息，但会话未读/角标可推进
  - 非主端进入会话后可补偿拉取到最新消息且顺序正确

---

## Milestone R（P2，可选）：音视频/语音通话（RTC，方案 1：信令复用 IM WS）

### R1（P2）：RTC 信令契约与消息类型（WS）

- **目标**：通话信令复用现有 IM WS（JSON/PB 双栈、鉴权续期、灰度/降级、错误码），媒体走第三方/WebRTC，不走 IM。
- **建议信令集**（最小闭环）：
  - `CALL_INVITE` / `CALL_RINGING` / `CALL_ACCEPT` / `CALL_REJECT` / `CALL_END` / `CALL_BUSY` / `CALL_TIMEOUT`
- **建议建模**：
  - 优先：`messageType=CUSTOM` + `body.subType=CALL_*`（后续需要强约束再升为枚举）
  - body 最小字段：`callId`、`callType(AUDIO/VIDEO)`、`conversationId` 或 `fromUserId/toUserId`、`roomId/token`（第三方短 TTL）、`clientTime/traceId`
- **验收标准**：
  - 双端在线：INVITE->RINGING->ACCEPT->END 全链路可回归
  - 乱序/重复信令幂等：同 callId 重复 INVITE/END 不产生多次状态迁移

### R2（P2）：服务端通话状态机与超时回收

- **目标**：服务端维护通话最终态，端侧只做 UI 与媒体控制。
- **范围**：
  - 状态：INIT -> INVITED -> RINGING -> CONNECTED -> ENDED
  - 超时：INVITED/RINGING 超过阈值（如 30s）自动 TIMEOUT 并下发结束事件
- **验收标准**：
  - 超时未接自动结束，双方端侧 UI 统一
  - 服务端状态可查询/可审计（最小可观测）

### R3（P2）：多端一致与互斥（同账号多端）

- **目标**：允许多端同时响铃，但只允许一个端 ACCEPT 成功，其余端必须收到 END/BUSY 并停止响铃。
- **依赖**：Milestone A（设备体系）、C6（多端同步事件）
- **验收标准**：
  - 同账号两台手机：同时响铃，A 端接听后 B 端自动停止并展示“已在其他设备接听”

### R4（P2）：离线推送拉起（通话场景）

- **目标**：被叫离线/后台时可通过 push 唤醒进入通话页，且不破坏 IM 一致性。
- **约束**：push payload 仅携带最小字段（`tenantId/callId/conversationId/callType`），权威状态以服务端为准。
- **验收标准**：
  - 离线被叫收到来电 push，点击后可拉起进入通话（先鉴权与必要 sync）
  - push 不承载权威通话状态，异常场景可正确提示（超时/已结束）

### R5（P2）：通话记录消息（必选耦合点）

- **目标**：每次通话结束（END/BUSY/TIMEOUT/REJECT）落一条“通话记录消息”，用于漫游、搜索、审计与 push 摘要。
- **建议形态**：`messageType=CUSTOM` + `subType=CALL_RECORD`，body 包含 `callId/duration/endReason/callType`。
- **验收标准**：
  - `syncMessages` 可拉到通话记录，跨端一致

### R6（P2）：Feature Flag 与可观测性

- **目标**：RTC 能力默认关闭，按 tenant/user 灰度开启；具备最小指标与日志支撑排障。
- **验收标准**：
  - 关闭时端侧入口隐藏；开启后按灰度生效
  - 具备基础指标：`rtc_invite_total/accept_total/end_total/timeout_total`（按 tenantId 聚合）

---

## Milestone S（P1）：消息体 Schema 冻结 + 媒体资产治理（对标企微/钉钉）

### S0（P0）：开发阶段最优策略：严格 Schema（Strict Mode，Fail-Fast）落地

- **目标**：开发阶段以“字段权威来源唯一 + 缺字段立即暴露”为准则，杜绝端侧从 URL/content 推断媒体元数据导致的图标误判与三端不一致。
- **范围**：
  - uniappx：聊天页/会话列表的媒体渲染与消息转换（只从 `extra/body` 取 `fileName/size/mimeType`）
  - module-system：发送/入库路径确保 `extra` 存在且包含最小字段集
  - websocket-starter：FILE 推送时 `header.extra` 与 `FileMessage body` 一致（便于端侧统一消费）
- **依赖**：S1（Schema 冻结表）
- **验收标准**：
  - FILE 消息在 REST 历史列表与 WS 推送中都必须满足：`extra` 或 body 包含 `url/fileName/size/fileType(mimeType)`
  - 客户端渲染不再从 url/content 解析 fileName/mimeType；缺字段直接报错（console.error/断言失败）
  - 任意端发送 Excel/Word/PDF/ZIP：图标稳定正确（不因 URL 混合内容/编码差异误判）
- **涉及文件/目录**（示例）：
  - uniappx：`pages/message/chat.uvue`；`services/message-service.uts`；`utils/message-handler.uts`
  - module-system：`service/im/*`（发送/查询/落库补齐 extra）
  - websocket-starter：`core/sender/NettyMessageSender.java`

### S1（P1）：MessageType body schema 冻结表（端到端权威）

- **目标**：冻结 `TEXT/IMAGE/VOICE/VIDEO/FILE/LOCATION/CARD/CUSTOM/CALL_RECORD` 的 body 最小字段集，避免端/后端/多端渲染各自扩展导致漂移。
- **范围**：
  - 设计文档：补齐 `6.4.4 消息体（body）Schema 冻结`
  - proto/枚举：以 proto 为权威（JSON/CUSTOM 走 subType）
  - 端侧渲染：未知字段忽略；禁止依赖未冻结字段
- **验收标准**：
  - 新增字段只做可选追加，不改名/改语义
  - 端到端联调时，任一端升级不导致旧端崩溃（兼容回归）

### S2（P1）：媒体/附件上行闭环（上传、引用、权限、缩略图）

- **目标**：图片/视频/语音/文件不走 WS，统一走 HTTP 上传，消息只携带 `fileId` 引用；对标企业级的权限/审计/去重；并最大化复用系统已有文件能力。
- **范围**：
  - 复用现有能力（必须优先）：
    - uniappx：`utils/upload.uts` 已统一走 `POST /infra/file/upload`
    - server：`shengyu-module-infra` 的 `AppFileController(/infra/file/*)` + `FileApi`
    - IM 群文件：`POST /system/im/group/file/upload` 已通过 `FileApi#createFileAndReturnId` 生成 `fileId`
  - 需要补齐/对齐的企业级改造点（不重复造上传轮子）：
    - 统一“IM 媒体上传返回值”形态：优先返回 `fileId`（而不是仅 url string）
      - 现状：`/infra/file/upload` 返回 `String`（url），端侧发送消息时使用 url（见 chat 页面现有逻辑）
      - To-Be：infra 层新增/演进为 `upload -> fileId`（或提供 `url -> fileId` 映射）后，IM 消息体全部切换 `fileId`
    - 目录规范：
      - 单聊：`im/chat/{conversationId}`
      - 群聊：`im/group/{groupId}`（与群文件保持一致）
    - 下载/预览：
      - 统一走“鉴权 + 过期 URL”（或服务端代理下载），禁止静态直链裸奔
      - 与 `FileApi#presignGetUrl` 能力对齐
    - 缩略图：图片/视频生成 thumb 并返回 `thumbFileId`（列表预览与弱网优化）
    - 去重（可选）：按 `md5` 秒传/合并上传
- **验收标准**：
  - 弱网/断点续传（可选）不影响消息幂等
  - 无权限用户无法访问附件（403xxx），且日志可审计
  - IM 消息体中不再携带“裸 url”，统一以 `fileId` 为权威引用（url 仅作为临时兼容）

- **涉及文件/目录**：
  - uniappx：`utils/upload.uts`；`pages/message/chat.uvue`；`services/message-service.uts`
  - infra：`shengyu-module-infra/.../AppFileController.java`；`FileService`；`FileApi`
  - module-system：`AppImGroupFileController`/`ImGroupFileServiceImpl`（作为 fileId 复用示例）

#### S2.1（P1）：infra 上传返回 fileId（或提供 url -> fileId 映射）

- **目标**：把当前 `/infra/file/upload -> url string` 的“阶段性形态”演进为企业级 `fileId` 权威引用。
- **建议方案**（二选一，推荐 A）：
  - A：新增 `POST /infra/file/upload-and-return-id`（推荐命名）
    - form-data：`file` + `directory`
    - 返回：`{ fileId, url?, name, size, mimeType?, md5?, thumbFileId? }`
    - 目录规范：`im/chat/{conversationId}`、`im/group/{groupId}`
    - 对图片/视频：如生成缩略图，返回 `thumbFileId`
  - B：保留 `/infra/file/upload` 返回 url，但新增 `POST /infra/file/resolve`：`{ url } -> { fileId }`
- **兼容要求**：
  - 旧端仍可使用 url；新端优先用 fileId
- **验收标准**：
  - 上传后可拿到稳定 `fileId`
  - fileId 可用于生成过期下载地址（与 `FileApi#presignGetUrl` 对齐）

##### S2.1.a（P1）：错误码/限流/大小限制对齐

- **目标**：上传/下载链路的错误码与限制项端到端一致，端侧可自动化处理（重试/提示/降级）。
- **建议错误码**：
  - `413xxx`：文件过大
  - `415xxx`：不支持的 MIME
  - `429xxx`：限流（返回 retryAfterMs）
  - `403xxx`：目录/下载无权限
- **验收标准**：
  - uniappx 与后端使用同一套限制阈值与提示语（至少语义一致）
  - 429 触发后端侧退避重试策略可回归

#### S2.2（P1）：IM 消息体双写兼容（fileId + url 临时并存）

- **目标**：灰度期间，服务端与端侧同时支持两种引用，保证回滚安全。
- **建议规则**：
  - To-Be：消息体以 `fileId` 为权威；`url` 仅作为临时兼容字段
  - 渲染优先级：`fileId` 可解析则用 `fileId` 生成可访问 url；否则 fallback 到 `url`
- **验收标准**：
  - 新旧端互通：新端发 fileId，旧端至少可降级展示；旧端发 url，新端可展示

#### S2.3（P1）：端侧发送链路切换（chat.uvue/message-service）

- **目标**：端侧发图/视频/语音/文件消息时不再拼接 `CONFIG_BASE_URL + url` 作为权威内容，而是发送 `fileId`（并按 schema 填充 size/width/height/duration 等）。
- **范围**：
  - `utils/upload.uts`：支持拿到 fileId（对接 S2.1）
  - `pages/message/chat.uvue`：构建消息 body 时写入 `fileId`
  - `services/message-service.uts`：发送/渲染统一按 schema
- **验收标准**：
  - 发送成功后，消息列表可立即本地预览（fileId->url 解析可异步）
  - 断线补偿后仍能正确展示（以 fileId 为权威）

#### S2.4（P1）：下载/预览鉴权（过期 URL / 服务端代理）

- **目标**：消灭“静态直链裸奔”，所有附件访问都可审计、可控。
- **建议契约**：
  - `GET /infra/file/presigned-get-url?fileId=...&expirationSeconds=...`（或等价接口）
  - 或：`GET /infra/file/download?fileId=...`（服务端代理，适用于必须强审计场景）
- **验收标准**：
  - 无权限访问返回 403xxx，且有审计日志
  - url 过期后不可访问，端侧可重新换取

##### S2.4.a（P1）：fileId -> url 解析契约与端侧缓存策略冻结

- **目标**：端侧渲染/预览/下载统一通过“短期 URL”解析 `fileId`，禁止把长期 URL 写入消息体或本地永久缓存。
- **建议契约**：
  - `GET /infra/file/presigned-get-url?fileId=...&expirationSeconds=...` -> `{ url, expiresAt }`
  - `expirationSeconds` 设上限（例如 60~600s）
- **端侧策略**：
  - URL 仅做短 TTL 内存缓存；过期/403 自动重取
  - 列表优先解析 `thumbFileId`，点击查看再解析原 `fileId`
- **验收标准**：
  - 抓包检查：消息体不再出现长期可访问 URL（仅 fileId）
  - URL 过期后能自动重取，不影响浏览体验

- **涉及文件/目录**：
  - infra：`AppFileController`（新增 presigned-get-url）/`FileService`
  - uniappx：媒体渲染组件/消息列表（按 fileId 解析 url）

#### S2.5（P1）：灰度/回滚策略（与 B6 统一）

- **目标**：fileId 化迁移必须可灰度、可回滚，避免一次性切换导致大面积媒体不可用。
- **建议开关**：
  - `im.media.useFileId`：端侧发送是否使用 fileId
  - `im.media.renderPreferFileId`：端侧渲染是否优先 fileId
- **验收标准**：
  - 开关分钟级生效；关闭后可回滚到 url 路径

#### S2.6（P1）：缩略图生成与回收策略（thumbFileId）

- **目标**：图片/视频消息统一具备缩略图能力，列表/会话页优先展示缩略图以提升加载体验与弱网表现；缩略图与原文件生命周期一致可回收。
- **范围**：
  - 生成策略：推荐异步生成（不阻塞上传响应），必要时可对“小文件”同步生成
  - 规格建议：短边 240~360px，质量 60~75；视频取封面帧
  - 失败降级：thumb 失败不阻断消息投递，端侧回退原图/占位
  - 回收：thumb 与原文件绑定，支持定期清理孤儿文件
- **验收标准**：
  - 会话列表加载时默认走缩略图，显著减少首屏流量
  - 异步生成完成后，后续 sync/query 能补齐 `thumbFileId`

---

## Milestone V（P1）：文件在线预览（kkFileView 私有化部署 + WebView）

说明：本 Milestone 目标是把“文件点击预览”体验提升到企业可接受程度（对齐企微/钉钉），避免 `openDocument` 依赖第三方 Office 导致“无法打开/系统异常”。方案选择：**kkFileView 私有化部署**，端侧通过 **WebView 打开 onlinePreview**。

### V1（P1）：kkFileView 组件化部署（同环境一套）

- 状态：已完成

- **目标**：在开发/测试环境可一键拉起 kkFileView，并具备最小健康检查与日志定位能力。
- **范围**：运维/部署（docker-compose 或 k8s 均可）
- **依赖**：无
- **验收标准**：
  - kkFileView 可访问：`/onlinePreview` 工作正常
  - 提供 health 探测（HTTP 200 即可）
  - 限制转换并发（避免 CPU 爆）并有明确的失败日志

### V2（P1）：预览 URL 生成链路（fileId -> presigned -> kkFileView onlinePreview）

- 状态：已完成

- **目标**：端侧只依赖 `fileId`，并能获取可预览的短期 URL。
- **范围**：infra（文件服务）+ uniappx
- **依赖**：S2.4 / S2.4.a（presigned-get-url 契约与缓存策略）
- **验收标准**：
  - `fileId` 可换取短期 URL（TTL 上限 60~600s）
  - URL 过期后端侧可自动重取
  - 403/401 可明确提示（无权限/登录失效）

### V3（P1）：端侧统一预览入口（file-preview 页面）

- 状态：已完成

- **目标**：聊天页、群文件列表、搜索结果点击文件统一进入预览页，体验一致。
- **范围**：uniappx
- **依赖**：V2
- **验收标准**：
  - chat 文件消息：非图片/视频默认走在线预览
  - chat-files 群文件：非图片/视频默认走在线预览
  - 预览页包含：加载态、失败态、下载按钮
  - 失败可降级为“仅下载/保存到本地”

---

## Milestone Q（P1）：全局搜索 + 聊天记录搜索（对齐 UI 方案）

说明：本 Milestone 目标是落地“聚合搜索页 + 聊天记录搜索结果页”的可用闭环，并保证与 IM 会话模型（chatId/sequence）一致、与文件统一预览入口（file-preview）一致。

权威接口入口：后端 App 端 IM 接口以 `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im` 为准（Controller 上的 `@RequestMapping/@GetMapping/...` 为最终口径），端侧 API 层需要对齐该目录的路径与 VO。

### Q1（P1）：聚合搜索页（/pages/common/search）

- 状态：已完成

- **目标**：支持搜索联系人/群聊/聊天记录入口，符合 UI 方案的分区结构与交互。
- **范围**：uniappx
- **依赖**：H（通讯录）/C3（会话模型）
- **验收标准**：
  - 输入关键词后展示分区结果：联系人/群聊/聊天记录（TopN）
  - 空态可用、取消返回行为一致
  - 点击“搜聊天记录”进入独立结果页并携带 keyword
- **涉及文件/目录**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/pages/common/search.uvue`

### Q2（P1）：聊天记录搜索结果页（/pages/common/search-chat-history）

- 状态：已完成

- **目标**：分页展示“命中消息”列表，支持上拉加载更多。
- **范围**：uniappx
- **依赖**：接口 `GET /system/im/message/search`（端侧：`api/message.uts#searchMessages`）
- **验收标准**：
  - keyword 搜索返回稳定可回归（分页参数生效）
  - 展示字段最少包含：chatName、snippet、sendTime
  - 上拉加载更多可用，重复加载不重复渲染（去重 key：`chatId + messageId`）
- **涉及文件/目录**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/api/message.uts#searchMessages`
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-search-service.uts`
  - `shengyu-ui/shengyu-ui-admin-uniappx/pages/common/search-chat-history.uvue`（需新增页面并注册 pages.json）

### Q3（P1）：点击结果定位到会话消息（chatId + anchor）

- 状态：已完成

- **目标**：从搜索结果进入会话页后，自动定位到命中的消息。
- **范围**：uniappx
- **依赖**：C2（pull/list-by-chat）
- **验收标准**：
  - 若结果携带 `sequence`：进入会话后能定位到该 sequence 附近（并补齐缺失消息）
  - 若仅携带 `messageId`：能在会话内解析出对应 sequence 并定位
  - 弱网/大群场景不出现“定位失败但无提示”的静默失败

### Q4（P1）：搜索结果中的文件打开统一入口（file-preview）

- 状态：已完成

- **目标**：搜索结果中点击 FILE/IMAGE/VIDEO 等附件时，统一走既有的预览/下载策略闭环。
- **范围**：uniappx
- **依赖**：Milestone V3（file-preview 统一入口）
- **验收标准**：
  - 点击文件：必须调用 `navToFilePreview({ fileId, url, name })`
  - 能传 `fileId` 就必须传 `fileId`，由后端 `getFileOpenStrategy` 决定 PREVIEW/DOWNLOAD
  - 禁止在搜索页直接调用 `uni.openDocument` 或自行实现下载预览逻辑
- **涉及文件/目录**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/nav.uts`
  - `shengyu-ui/shengyu-ui-admin-uniappx/pages/common/file-preview.uvue`

### Q5（P2，可选）：搜索历史/热门搜索/清空能力

- 状态：已完成

- **目标**：完善聚合搜索页体验：历史记录、热门搜索、清空确认。
- **范围**：uniappx
- **验收标准**：
  - 历史记录最多 N 条，去重、最近优先
  - 清空二次确认
  - 热门搜索可配置/可隐藏

### Q6（P1）：后端补齐（企业级适配）— 群聊/会话搜索 + 热门搜索（热词）

- 状态：已完成

- **背景**：当前后端 App 端 IM Controller 已包含 `GET /system/im/message/search`，但未提供
  - 会话/群聊维度的“按 keyword 搜索”（端侧当前用 `conversation/list` 本地过滤，数据量大时性能与实时性不可控）
  - “热门搜索（热词）”的可运营化配置接口（端侧当前为本地默认 + storage 缓存兜底）

- **目标**：补齐企业级搜索能力所需的服务端接口，使端侧聚合搜索完全可由服务端驱动（可运营、可审计、可控）。

- **建议契约**：
  - `GET /system/im/conversation/search?keyword=...&conversationType=2&pageNo=...&pageSize=...`
    - 仅返回当前用户可见的会话（群聊/单聊），默认推荐支持 `conversationType` 筛选
    - 响应：`PageResult<AppImConversationRespVO>`（或精简 VO，至少含 chatId/targetName/groupMemberCount/conversationType）
  - `GET /system/im/search/hot`（或 `GET /system/im/config/hot-search`）
    - 响应：`{ list: string[], version?: string, ttlSeconds?: number }`
    - 支持“可隐藏/可为空”（为空表示不展示热搜区块）

- **验收标准**：
  - 群聊/会话搜索：大租户（会话>=1w）查询响应可接受，分页参数生效
  - 权限：仅返回当前用户可见的会话/群组
  - 热搜：支持运营配置生效（无需发版），端侧可缓存并在 TTL 后刷新

- **涉及文件/目录**：
  - `shengyu-module-system/.../controller/app/im/AppImConversationController.java`（新增 search 接口）
  - `shengyu-module-system/.../service/im/ImConversationService`（新增 search 能力）
  - `shengyu-module-system/.../controller/app/im`（新增热搜接口 Controller，如单独 Controller）
  - `shengyu-ui/shengyu-ui-admin-uniappx/pages/common/search.uvue`（对接服务端热搜/会话搜索）

- **实现说明（以代码为准）**：
  - 会话搜索：`GET /system/im/conversation/search`
  - 热门搜索：`GET /system/im/search/hot`

## Milestone H（P1）：通讯录/组织架构（企业级通讯录能力基线）

### H1（P1）：部门联系人列表（list-by-dept）闭环

- **背景**：`AppImContactController#getContactListByDept` 当前存在 `// TODO: 实现按部门查询联系人`，现状会返回全量联系人，端侧使用会产生“看似可用但数据不可信”。

- 状态：进行中

- **目标**：按部门维度稳定拉取联系人，具备企业级的租户隔离、数据权限与分页/排序能力（对齐企微/钉钉的组织通讯录）。

- **建议契约**：
  - `GET /system/im/contact/list-by-dept?deptId=...&pageNo=...&pageSize=...&keyword=...`
  - 响应：`PageResult<AppImContactRespVO>`（建议分页，避免大部门一次性返回导致卡顿）
  - 排序建议：按 `displayName`（拼音/首字母）或按 `sort` 字段（如组织有配置）

- **关键约束（企业级必须项）**：
  - 租户隔离：仅能查询当前 tenant 下的组织与用户
  - 数据权限：至少满足“只能看到同组织范围”或“按角色授权可见范围”
  - 缓存策略（可选）：部门树/成员列表可做短 TTL 缓存，但必须支持变更失效

- **验收标准**：
  - deptId=本部门：仅返回部门内成员（不多不少）
  - 跨部门 deptId：按权限返回（无权限返回 403xxx）
  - 大部门（>=5000 人）分页查询稳定，响应时间可接受，端侧不卡顿
  - keyword 过滤（可选）：能在部门范围内做姓名/手机号/工号检索

- **涉及文件/目录**：
  - `shengyu-module-system/.../controller/app/im/AppImContactController.java`（实现 list-by-dept）
  - `shengyu-module-system/.../service/im/ImContactService`（新增按部门查询能力）
  - `shengyu-module-system/.../dal/*`（按部门关联 user/dept 的 mapper/dao）
  - `shengyu-ui/shengyu-ui-admin-uniappx/api/contact.uts`（已存在调用，补齐分页参数后对齐）

- **实现说明（以代码为准）**：
  - 新增分页接口：`GET /system/im/contact/list-by-dept-page`（入参：deptId/pageNo/pageSize/keyword）
  - 端侧接入：已完成（组织结构/我的部门/发起群聊选人均已按部门分页拉取，并支持跨部门选择）
  - 精度规则：端侧已落地“ID 全程 string 化避免精度丢失”强制规则（见 `sql/doc/uni-app-x开发资料-摘录.md` 6.1）

- **验收步骤（待联调/待验收）**：
  - **接口可用性**：
    - 调用 `GET /system/im/contact/list-by-dept-page?deptId=xxx&pageNo=1&pageSize=20` 返回结构包含 `list`、`total` 且分页参数生效。
    - `pageNo=2` 时返回结果不与 `pageNo=1` 重叠（除非服务端排序不稳定，需修复排序）。
  - **数据正确性**：
    - `deptId=本部门`：返回成员数与后台组织成员一致（不多不少）。
    - `deptId=子部门/上级部门`：符合预期的组织范围策略（当前实现包含子部门成员；若产品期望仅本部门需确认并调整）。
  - **keyword 过滤**：
    - `keyword=张`：仅返回部门范围内命中用户；清空 keyword 后可恢复全量。
  - **跨部门选人（发起群聊/添加成员）**：
    - 进入 `initiate-group` 后从“组织结构/我的部门”跨部门选择成员，返回后选中数量正确、重复选择不重复计数。
    - 确认提交时 `memberIds` 为 string 数组（不发生精度丢失，ID 不被截断/四舍五入）。
  - **精度回归点（必须）**：
    - 任意页面/全局状态中不得出现对 ID 的 `Number()`/`parseInt()`/`+id` 转换；路由参数与 storage 中 ID 均为 string。
  - **权限与租户隔离（必须）**：
    - 跨租户/无权限 `deptId` 访问：按产品要求返回明确错误（403/业务错误码），不得泄露其它租户成员。
  - **性能**：
    - 大部门（>=5000）分页滚动加载无明显卡顿；接口响应时间在可接受范围。

---

## Milestone D（P1）：离线推送（DCloud 主 + 极光备）

### D1（P1）：推送 token 绑定

- **验收**：换设备/重装/切账号绑定正确；同用户多端多 token。

- **目标**：建立“用户-设备-provider-token”绑定模型，确保多端可推、可解绑、可更新。
- **范围**：
  - uniappx：集成 DCloud（主）推送 SDK，上报 token（含 deviceId/deviceType/provider）
  - module-system：落库 token 绑定；登出/被踢清理或失效处理
- **依赖**：Milestone A（统一鉴权、deviceId/deviceType/deviceName 体系）
- **验收标准**：
  - 同账号 iOS/Android 同时登录：两端 token 均可绑定并可分别推送
  - App 重装/系统更新 token 变化：服务端能覆盖旧 token
  - 切换账号：旧账号 token 解绑（或标记失效），新账号重新绑定
- **涉及文件/目录**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/*`（推送 SDK 集成与 token 上报入口）
  - `shengyu-module-system/.../im`（push token controller/service/repository）
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（token 表）
  - `sql/mysql/1.0/im/dml_im_init_data.sql`（provider 配置默认值，如需）

### D2（P1）：离线触发策略 + 点击拉起对齐

- **验收**：离线可推送提醒；点击进入后会话与消息与服务端一致。

- **目标**：推送只负责“提醒/唤醒”，点击后必须走 `syncConversations/syncMessages` 对齐到最新状态。
- **范围**：
  - server：离线触发判定（是否有在线可达端、未读>0、DND 允许）
  - client：点击 push 后的对齐流程（先会话 sync，再消息 sync，再渲染）
- **依赖**：C2/C3（syncConversations/syncMessages）、C7（消息最终态字段）
- **验收标准**：
  - 完全离线收到 push：点击后进入会话能补齐最新消息
  - 推送携带的摘要与服务端最终态不一致时：以服务端最终态为准（撤回/编辑生效）
  - 未登录/需重登场景：按 REAUTH_REQUIRED 流程引导登录后再对齐
- **涉及文件/目录**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`（拉起后的连接策略）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts`
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
  - `shengyu-module-system/.../AppImConversationController.java`（sync）
  - `shengyu-module-system/.../AppImMessageController.java`（sync）

### D3（P1）：推送去重 + 免打扰（DND）

- **验收**：重投/重复入队不重复推送；DND 不推送但同步不受影响。

- **目标**：同一消息对同一设备最多推送一次；免打扰仅抑制推送，不抑制未读/角标与消息同步。
- **范围**：
  - server：dedupKey 计算与 Redis 去重；DND 判定与统计
  - client：DND 配置入口（会话级免打扰、夜间免打扰）与回显
- **依赖**：C3（会话水位/未读）、9.8/9.9 标准（设计文档）
- **验收标准**：
  - 同一 messageId 多次重投/补偿：对同一 deviceId 只推送一次
  - 开启会话免打扰：不推送，但会话未读与角标仍推进
  - 夜间免打扰窗口：仅抑制 push，不影响 sync
- **涉及文件/目录**：
  - `shengyu-module-system/.../OfflinePushService`（或等价 push service）
  - `shengyu-framework/.../Redis*`（dedup 存储）
  - `shengyu-ui/.../services/conversation-service.uts`（noDisturb 设置）

### D4（P1）：撤回与推送一致

- **验收**：推送下发后撤回，客户端拉起后不回流原文。

- **目标**：推送无法撤回通知时，仍能保证“点击进入后不展示原文”，以服务端最终态为准。
- **范围**：
  - server：撤回后消息最终态字段可查询/sync 返回；必要时推送“撤回事件”到在线端
  - client：点击 push 进入会话前强制 sync；渲染以最终态字段为准
- **依赖**：F1（撤回广播）、C7（最终态字段）、D2（点击拉起对齐流程）
- **验收标准**：
  - 收到 push 后，消息被撤回：点击 push 进入后展示“已撤回”而非原文
  - 离线端上线补偿：不会把撤回前内容回流
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImMessageController.java`
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（撤回事件/状态字段，如需）

---

## Milestone E（P1/P2）：观测与压测

### E1（P1）：关键指标与日志规范

- **验收**：按 tenantId/userId 可追踪一次完整消息链路。

- **目标**：上线前具备可观测、可定位、可回归的观测体系（日志 + 指标 + 追踪）。
- **范围**：
  - server：结构化日志字段统一（tenantId/userId/deviceType/deviceId/channelId/clientId/messageId/sequence/traceId/codec/code）
  - server：关键指标打点（连接/协商/鉴权/ACK/补偿/推送）
  - 运维：基础 Dashboard + 告警规则 + Runbook
- **依赖**：Milestone A/B/C/D（关键链路已存在后才能观测）
- **验收标准**：
  - 任取一次消息发送：能通过 traceId 串起“客户端发送 -> 服务端接收 -> 持久化 -> SendAck -> fanout -> 补偿拉取（如有）”
  - 任取一次协商失败：日志可定位 subProtocol/firstFrameHex/reason
  - 任取一次推送：可查到 provider/result/dedupKey/DND 是否抑制
  - 指标可按 tenantId 聚合，并支持 userId/deviceType 下钻（可采样）
- **涉及文件/目录**：
  - `shengyu-framework/...`（Netty/processor/handler 的日志与指标打点）
  - `shengyu-module-system/.../im`（业务侧 push/sync/持久化的日志与指标）
  - `sql/doc/IM即时通讯架构设计文档-v2.0.md`（11 章为标准来源）

### E2（P2）：压测脚本与容量评估

- **验收**：输出压测报告（CPU/内存/RT/吞吐/99 线）。

- **目标**：形成企业级容量基线与扩容建议，保证稳定性与上线门禁。
- **范围**：
  - 压测场景：
    - 并发连接（按 tenant 分布）
    - 消息吞吐（TPS/QPS）
    - 断线重连风暴（批量断链 -> 30s 内恢复）
    - 补偿拉取（gap -> syncMessages）
  - 报告输出：连接上限、吞吐上限、p95/p99、SLO 对齐与瓶颈分析
- **依赖**：E1（指标/日志齐备）；C1/C2/C3（可靠性与 sync 路径具备）
- **验收标准**：
  - 输出压测报告：CPU/内存/GC/RT/吞吐/p95/p99
  - 明确单节点与集群推荐规模，并给出冗余建议
  - 压测过程中关键告警可触发并可回归
- **涉及文件/目录**：
  - `tools/loadtest/*`（建议新建压测脚本目录，具体落地由你决定）
  - `shengyu-framework/...`（性能瓶颈点通常在 codec/handler/队列/存储）

---

## Milestone F（P1）：消息生命周期（已读/撤回/删除/系统通知）

### F1（P1）：撤回（权限/时限/广播）

- **验收**：所有在线端立即更新；离线端上线同步不回流；管理员可撤回全员消息。

- **目标**：实现企业级撤回闭环（权限/时限/幂等/WS 广播 + sync 最终态一致）。
- **范围**：
  - module-system：撤回权限校验、时限策略、撤回事件落库、消息最终态更新（`status=RECALLED`、`rev+1`、recalledAt/by）
  - WS：撤回事件广播到所有在线端
  - HTTP sync/query：返回消息必须带最终态字段，避免补偿回流原文
- **依赖**：C7（最终态字段与合并规则）、D4（撤回与推送一致）、B2（双栈 WS 基础链路）
- **验收标准**：
  - 普通用户只能撤回自己消息；管理员/群主（开关开启时）可撤回群内任意消息
  - 超过撤回时限：返回 403xxx（不可重试）
  - 重复撤回同一 messageId：幂等成功，不改变 sequence
  - 在线端立即收到撤回事件；离线端上线后通过 `syncMessages` 看到最终态（不回流原文）
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImMessageController.java`（recall API）
  - `shengyu-module-system/.../im`（message service/repository：状态字段与撤回事件）
  - `shengyu-framework/.../MessageProcessor`（RECALL 事件推送）
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（消息状态字段/撤回事件表）

### F2（P1）：对我删除（跨端保持）

- **验收**：删除后本端不展示；重新登录/换端仍保持。

- **目标**：实现企业级“对我删除”语义（用户维度 tombstone），跨端保持一致且不影响审计留存。
- **范围**：
  - module-system：delete-for-me API；tombstone 落库；query/sync 过滤或返回状态标记
  - uniappx：本地过滤渲染；与补偿拉取一致
- **依赖**：C8（tombstone 设计与一致性）、C2/C3（sync 路径）
- **验收标准**：
  - A 端对我删除后：B 端同步后不再展示；重新登录仍保持
  - tombstone 不影响服务端审计与管理员能力（仅用户视图过滤）
  - 与撤回/编辑最终态合并规则不冲突
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImMessageController.java`（delete-for-me API）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（tombstone 表）

### F3（P1）：系统通知/应用消息

- **验收**：独立 messageType；可限流、可推送、可审计。

- **目标**：提供“系统通知/应用消息”独立通道（独立 messageType/展示/限流/推送/审计），对齐企微/钉钉的工作台消息形态。
- **范围**：
  - module-system：系统通知发送 API（面向业务模块/管理端），支持按用户/部门/全员投递
  - WS：在线实时投递；离线入队触发 push（遵循 DND/dedup）
  - 客户端：独立列表/角标或在会话列表单独聚合（由产品选择）
- **依赖**：B5（限流/背压）、D1~D3（push token/dedup/DND）、E1（观测）
- **验收标准**：
  - 系统通知与普通聊天消息使用不同 messageType，且限流策略可单独配置
  - 可配置是否允许推送、推送摘要脱敏
  - 审计：发送者、发送时间、目标范围、投递结果可追踪
- **涉及文件/目录**：
  - `shengyu-module-system/.../im`（system notice service/controller）
  - `shengyu-framework/.../MessageProcessor`（SYSTEM_NOTICE 处理器）
  - `shengyu-ui/.../services/*`（系统通知 UI/数据源，按端侧现状落地）

---

## Milestone G（P1/P2）：高可用、降级与灰度开关

### G1（P1）：多节点会话注册与跨节点投递

- **验收**：任意节点触发 KICK/REVOKE 目标端可达；跨节点投递至少文本可达。

- **目标**：落地多节点 IM 路由与跨节点投递能力（session registry + delivery bus），保证控制类与消息类跨节点可达。
- **范围**：
  - `shengyu-framework`：
    - session registry 抽象（注册键 tenantId/userId/deviceType/deviceId/clientId；注册值 nodeId/channelId/codec/lastSeen）
    - remote deliver 抽象（控制类优先 Redis pubsub，消息类可扩展 MQ）
    - 节点优雅下线（draining）对 registry 清理与连接关闭策略
  - `shengyu-module-system`：
    - 群消息 fanout：按在线端列表分片投递（可先实现文本）
- **依赖**：Milestone A（撤销闭环跨节点已具备基础）；E1（观测字段与指标打点）
- **验收标准**：
  - node-A 触发 KICK/REVOKE：连接在 node-B 的目标端必达（可回归复现）
  - node-A 发送文本：连接在 node-B 的目标端可收到（至少一次，允许端侧去重）
  - registry TTL/续租生效：断链后路由不会长期指向僵尸连接
  - draining 下线：节点下线前不再接新连接，存量连接按策略关闭并触发客户端退避重连
- **涉及文件/目录**（示例）：
  - `shengyu-framework/shengyu-spring-boot-starter-websocket/.../NettySessionManager.java`
  - `shengyu-framework/.../core/mq/*`（Redis pubsub 现有能力复用/扩展）
  - `shengyu-framework/.../router/*`（建议新增 registry/router 抽象包）
  - `shengyu-module-system/.../im`（群 fanout service）

### G2（P1）：降级策略落地（保核心链路）

- **验收**：可配置降级群已读全量/输入状态/在线态刷新；核心链路可用。

- **目标**：把“降级策略”从文档变为可执行开关：在异常/压测下可自动或手动降级非核心能力，保证 AUTH/文本/撤销核心链路稳定。
- **范围**：
  - server：降级开关（群已读详情/typing/presence 刷新/大文件透传/codec pb 等）
  - server：降级触发策略（阈值触发 + 手动触发）与可观测（指标、日志）
  - client：对降级能力的兼容（例如群已读详情接口关闭时仅展示聚合数）
- **依赖**：E1（指标/告警体系）、B6（灰度/降级策略与错误码语义）
- **验收标准**：
  - 打开降级开关后：非核心能力被抑制，核心链路仍可用
  - 关闭降级开关后：能力恢复且无数据不一致
  - 降级触发与回滚全链路可观测（有对应指标与操作审计）
- **涉及文件/目录**：
  - `shengyu-framework/.../config/*`（降级配置项）
  - `shengyu-framework/.../processor/*`（在 processor 层做能力 gating）
  - `shengyu-ui/...`（端侧兼容展示）

### G3（P2）：Feature Flag 平台化

- **验收**：pb 双栈、ACK 模式、补偿策略、推送通道等支持按维度灰度/回滚。

- **目标**：建设企业级 Feature Flag 能力：按 tenantId/userId/deviceType/appVersion 灰度，具备审计、回滚、实时生效。
- **范围**：
  - server：
    - feature flag 数据模型（配置项/维度/生效范围/优先级）
    - 下发与缓存（本地缓存 + 变更通知）
    - 操作审计（谁在什么时候修改了什么开关）
  - client：关键开关的灰度联动（如 codec pb enable、降级回滚）
- **依赖**：B0/B6（codec 灰度与降级）、E1（可观测）
- **验收标准**：
  - 任一开关修改后分钟级生效，并可回滚到上一版本
  - 同一开关按租户灰度、按用户灰度均可生效，且优先级明确
  - 操作审计可追溯，回滚有记录
- **涉及文件/目录**：
  - `shengyu-module-system/.../featureflag/*`（建议新增管理与查询接口）
  - `shengyu-framework/.../featureflag/*`（starter 侧读取与缓存）
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（开关表/审计表，如需）
