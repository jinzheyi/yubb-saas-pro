# IM 即时通讯开发任务清单（Backlog）v2.0

> **版本**: v2.0.0  \
> **创建日期**: 2026-03-05  \
> **配套架构文档**: `sql/doc/IM即时通讯架构设计文档-v2.0.md`

---

## 0. 说明与验收通用规则

### 0.1 任务格式

- **目标**：本任务完成后系统具备的能力
- **范围**：改动哪些模块
- **依赖**：前置任务
- **验收标准**：可测、可复现、可回归
- **涉及文件/目录**：便于定位

### 0.2 通用验收（所有 Milestone 都必须满足）

- HTTP：非白名单接口请求头稳定包含 `Authorization` 与 `tenant-id`（且不重复）
- IM：被踢/重登时停止重连，弹窗提示信息可读
- 日志：关键链路打印 tenantId/userId/deviceType/channelId/messageId/sequence

### 0.3 实现入口索引（开工必看）

说明：下表用于把 Backlog 任务与当前工程入口文件对齐，便于直接开工与回归。

| 能力域 | 当前关键入口（模块/文件） | 备注 |
| --- | --- | --- |
| HTTP 统一鉴权 | `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts`；`store/user.uts` | 401 refresh 单飞、队列重放、Authorization/tenant-id 规范化 |
| IM 统一鉴权/续期 | `shengyu-ui/.../utils/websocket.uts`；`shengyu-framework/.../AuthHandler.java` | AUTH_REQ/AUTH_RENEW/RENEW_SUGGEST/REAUTH_REQUIRED |
| 撤销闭环（RedisMQ） | `shengyu-framework/.../core/mq/consumer/ImSessionRevokeConsumer.java` | clientId 过滤、精确撤销优先级 |
| 多端互踢 | `shengyu-framework/.../NettySessionManager.java`；`NettySession.java` | 同 deviceType 互踢、byDevice 友好展示 |
| JSON 双栈入口 | `WebSocketFrameHandler.java`；`JsonBusinessMessageHandler.java` | WebSocket TextFrame JSON -> processor |
| Protobuf 链路入口 | `ProtobufMessageHandler.java`；`NettyAutoConfiguration.java` | App 端 Protobuf 编解码待补 |
| 消息处理器注册 | `NettyAutoConfiguration.java` | 处理器注册存在≠可靠性闭环完成 |
| 存储 SPI | `MessageStorageService`；`NoOpMessageStorageServiceImpl` | 默认 NoOp，企业级必须由业务模块覆盖 |
| 会话 REST | `AppImConversationController.java`；`ImConversationService` | 已有基础接口，需补 sequence 水位与增量 sync |

---

### 0.4 前后端对接清单（uniappx <-> module-system）

说明：本节用于把移动端实际调用点与后端 Controller 精确对齐，避免“接口存在但端侧没接/参数不一致”。

#### 0.4.1 REST API 对接清单（移动端 -> 租户端）

| 能力 | uniappx 调用入口 | HTTP URL | module-system Controller（入口） | 备注 |
| --- | --- | --- | --- | --- |
| 角标获取 | `api/badge.uts#getBadgeData`；`services/badge-service.uts` | `GET /system/im/badge/get` | `AppImBadgeController#getBadgeData` | 用于首页/会话列表角标同步 |
| 会话列表 | `api/conversation.uts#getConversationList`；`services/conversation-service.uts#loadConversations` | `GET /system/im/conversation/list` | `AppImConversationController#getConversationList` | 当前为全量列表；企业级建议补增量 sync（见 Milestone C3） |
| 创建/获取会话 | `api/conversation.uts#createConversation` / `getConversationByTarget` | `POST /system/im/conversation/create`；`GET /system/im/conversation/get-by-target` | `AppImConversationController#createOrGetConversation` / `getConversationByTarget` | 单聊/群聊统一会话模型 |
| 会话设置（置顶/免打扰） | `api/conversation.uts#pinConversation` / `setNoDisturb` | `PUT /system/im/conversation/update` | `AppImConversationController#updateConversation` | 字段：`isPinned`、`noDisturb` |
| 清空未读 | `api/conversation.uts#clearUnreadCount` | `PUT /system/im/conversation/clear-unread/{chatId}` | `AppImConversationController#clearUnread` | 会触发角标推送到其他端 |
| 删除会话 | `api/conversation.uts#deleteConversation` | `DELETE /system/im/conversation/delete?chatId=...` | `AppImConversationController#deleteConversation` | 参数名：chatId |
| 联系人列表/搜索/详情 | `api/contact.uts` | `/system/im/contact/*` | `AppImContactController` | `list-by-dept` 当前后端存在 TODO（见 0.4.3） |
| 群组（创建/更新/列表/成员/公告/邀请） | `api/group.uts`；`services/group-service.uts` | `/system/im/group/*` | `AppImGroupController` | 邀请码/二维码接口已具备 |
| 群文件（上传/列表/删除/下载计数） | `services/group-service.uts`（调用 `/system/im/group/file/*`） | `/system/im/group/file/*` | `AppImGroupFileController` | `upload` multipart；`download` 为记录下载次数 |
| 消息列表 | `api/message.uts#getMessageList` | `GET /system/im/message/list-by-chat` | `AppImMessageController#getMessageListByConversation` | `chatId` + 分页参数 |
| 消息撤回/删除 | `api/message.uts#recallMessage` / `deleteMessage` | `PUT /system/im/message/recall`；`DELETE /system/im/message/delete` | `AppImMessageController#recallMessage` / `deleteMessage` | 撤回闭环需配合 WS 广播（Milestone F1） |
| 消息已读上报 | `api/message.uts#markMessageRead` | `PUT /system/im/message/mark-read` | `AppImMessageController#markMessageRead` | 目前按 messageIds，上线建议演进为 lastReadSequence（Milestone C3） |
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
| 撤回通知 | `services/message-service.uts#handleRecall` | `RECALL(202)` | RECALL Processor | 必须与离线推送/拉取一致（Milestone F1/D4） |
| 角标更新（跨端） | `services/badge-service.uts`（或 WS listener） | `BADGE_UPDATE(204)` | `ImBadgeService#pushBadgeUpdate`（业务侧触发） | 需与会话未读一致（Milestone C3） |

#### 0.4.4 已知缺口（代码级 TODO，需补齐到闭环）

- `AppImMessageController#getMessageListByGroup`：存在 `// TODO: 需要先查询会话ID`（当前按 groupId 查消息链路不闭环）
- `AppImContactController#getContactListByDept`：存在 `// TODO: 实现按部门查询联系人`

建议落地方式：

- 群消息分页：统一按 conversation/chatId 做查询；若仅有 groupId，需先提供 groupId -> chatId 的映射接口或在服务端内部完成转换
- 部门联系人：补齐按 deptId 查询接口的真实实现（含权限/租户过滤）

#### 0.4.5 已发现的对接不一致（需统一，避免“接口能编译但运行不通”）

说明：以下不一致来源于对 `shengyu-ui/shengyu-ui-admin-uniappx` 与 `shengyu-module-system` 的现状扫描，建议优先在端侧与服务端统一 URL/Method/入参形态，再做后续功能闭环。

| 模块 | uniappx 调用点 | 现状 URL/Method | 服务端现状 | 风险/建议 |
| --- | --- | --- | --- | --- |
| 群组（路径漂移） | `services/group-service.uts` | `DELETE /system/im/group/dismiss`；`GET /system/im/group/members`；`POST /system/im/group/add-members`；`POST /system/im/group/remove-members`；`POST /system/im/group/transfer`；`POST /system/im/group/set-admin`；`POST /system/im/group/mute-member`；`POST /system/im/group/unmute-member`；`POST /system/im/group/mute-all`；`POST /system/im/group/set-nickname`；`POST /system/im/group/publish-announcement`；`GET /system/im/group/announcements` | `AppImGroupController` 真实路由为：`DELETE /dissolve?id=`；`GET /member/list?groupId=`；`POST /member/add`；`DELETE /member/remove?groupId=&memberUserId=`；`PUT /transfer-owner`；`PUT /member/set-role`；`PUT /member/set-muted`；`PUT /notice/update` 等 | service 自维护了一套“历史 URL”，会直接 404。建议：统一以 `api/group.uts` 为权威；`services/group-service.uts` 禁止手写 URL（仅做缓存/聚合逻辑），全部复用 api 层 |
| 已读回执/标记已读（Method + 入参形态漂移） | `api/message.uts#markMessageRead` vs `services/read-receipt-service.uts#markMessagesAsRead` | api：`PUT /system/im/message/mark-read`（params: messageIds[]）；service：`POST /system/im/message/mark-read`（body: chatId + messageIds） | `AppImMessageController#markMessageRead`：`PUT /mark-read`，`@RequestParam List<Long> messageIds` | 目前 service 会 405/400。建议短期：端侧统一走 api（PUT + query）；中期：按 Milestone C3 演进为 `reportReadWatermark`（sequence 水位），届时服务端应提供 `PUT /conversation/read-watermark`（body） |
| 会话删除（参数形态不一致） | `api/conversation.uts#deleteConversation` vs `services/conversation-service.uts#deleteConversation` | api 通过 URL query：`DELETE /conversation/delete?chatId=...`；service 通过 `params`：`DELETE /conversation/delete` | `AppImConversationController#deleteConversation` 需要 query `chatId`（`@RequestParam`） | 两种写法可能都可用，但建议端侧统一使用 api 层实现，service 不再手写 URL/params，避免漂移 |
| 消息扩展能力（后端缺接口） | `services/message-reaction-service.uts`、`services/message-edit-service.uts`、`services/read-receipt-service.uts` | reaction：`POST /system/im/message/add-reaction`、`POST /system/im/message/remove-reaction`、`GET /system/im/message/reactions`；edit：`POST /system/im/message/edit`、`GET /system/im/message/edit-history`；read-detail：`GET /system/im/message/read-detail`、`GET /system/im/message/unread-detail`、`GET /system/im/message/unread-list` | `AppImMessageController` 当前仅有：`/page`、`/list-by-chat`、`/list-by-group(TODO)`、`/recall`、`/delete`、`/mark-read`、`/unread-count`、`/search` | 端侧调用会直接 404。建议：
  - 若产品需要：补齐 Controller/Service（纳入 Milestone C5/F/C7）
  - 若短期不做：端侧入口需隐藏，并在文档标注“未支持/待实现”避免误用 |
| 响应结构（隐性逻辑 bug） | `services/*` 多处（`conversation-service.uts`、`group-service.uts`、`read-receipt-service.uts`、`message-reaction-service.uts`、`message-edit-service.uts`、`message-search-service.uts`） | `request()` 成功时被当作 `{code,data}` 使用 | `utils/request.uts` 在 `code===0` 时直接 `return data.data` | service 层大量 `if (response.code === 0)` 永远不成立。建议统一约定：`request()` 返回值=业务 data（推荐），则 service 不应再判断 code；或另提供 `rawRequest()` 返回原始 `{code,data}`（二选一固定） |

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
| 按 groupId 分页查询群消息 | `AppImMessageController#getMessageListByGroup`（后端已有但 TODO） | `GET /system/im/message/list-by-group?groupId=&pageNo=&pageSize=` | Controller 存在，但内部 `// TODO: 需要先查询会话ID`，实际不会按 groupId 生效 | 建议后端内部完成 groupId->chatId 映射后复用 `getMessagePage`；或新增 `GET /system/im/conversation/get-by-target?targetId={groupId}&conversationType=2` 后端先拿 chatId 再查 |
| 按 deptId 获取联系人 | `api/contact.uts#getContactListByDept` | `GET /system/im/contact/list-by-dept?deptId=` | `AppImContactController#getContactListByDept` 存在 TODO（当前直接返回全量） | 落地为真实 deptId 过滤（含租户/数据权限约束），并补齐分页/排序策略 |
| 群组：dismiss/members/add-members 等“历史 URL” | `services/group-service.uts` 多处 | 见 0.4.5（大量 /system/im/group/* 非标准路由） | `AppImGroupController` 未提供这些路由 | 端侧统一改为复用 `api/group.uts`；如确需保兼容，可在后端做临时别名路由，但最终以 `AppImGroupController` 为权威 |
| 消息表情回应 | `services/message-reaction-service.uts` | `POST /system/im/message/add-reaction`；`POST /remove-reaction`；`GET /reactions` | 后端缺路由 | 若要做：建议新增 `AppImMessageReactionController`（或挂在 message controller 下），并定义：`POST /reaction/add`、`POST /reaction/remove`、`GET /reaction/list?messageId=`（注意幂等与去重） |
| 消息编辑与编辑历史 | `services/message-edit-service.uts` | `POST /system/im/message/edit`；`GET /system/im/message/edit-history` | 后端缺路由 | 若要做：建议新增 `PUT /system/im/message/edit`（body: messageId, content, clientTime）与 `GET /edit-history?messageId=`；并与 10.2.3 的 `rev/edited` 最终态一致 |
| 群已读详情（read-detail/unread-detail/unread-list） | `services/read-receipt-service.uts` | `GET /system/im/message/read-detail`；`GET /unread-detail`；`GET /unread-list` | 后端缺路由 | 企业级推荐优先做聚合（Milestone C5）；详情接口可选：`GET /read-receipt/summary?messageId=`（已读/未读人数）+ `GET /read-receipt/detail?messageId=&pageNo=&pageSize=` |

## Milestone A（P0）：统一鉴权一致性 + 撤销闭环（HTTP <-> IM）

### A1（P0）：撤销事件模型固化

- **验收**：logout/互踢/强退都能映射到统一撤销事件；IM 定向收到 CLOSE/KICKED，且不影响不同 deviceType。

### A2（P0）：在线设备列表与踢人 API（管理态）

- **验收**：返回 deviceName/deviceType/loginTime/lastActive；主动踢人后目标端立即弹窗并退出登录。

---

## Milestone B（P0）：协议双栈（App Protobuf + H5 JSON）落地

### B0（P0）：协议与版本基线冻结（SubProtocol + 首帧探测）

- **验收**：固定 `im.pb.v1`/`im.json.v1`；首帧 MAGIC/VERSION/CODEC/FLAGS；形成兼容矩阵。

- **目标**：冻结“连接层协商”协议基线，确保后续演进可灰度、可回归。
- **范围**：
  - 服务端：SubProtocol 列表、首帧探测格式、ProbeTimeout
  - 客户端：App/H5 的 protocol 声明与降级重连策略
- **依赖**：Milestone A（统一鉴权的 CLOSE 语义与停止重连策略）
- **验收标准**：
  - 固定：`im.pb.v1`、`im.json.v1`
  - 固定首帧字段：MAGIC/VERSION/CODEC/FLAGS
  - 输出一份“兼容矩阵”到文档（clientCodec x serverAllowed x expectedResult）
- **涉及文件/目录**：
  - `shengyu-framework/shengyu-spring-boot-starter-websocket/.../WebSocketFrameHandler.java`
  - `shengyu-framework/.../ProtobufMessageHandler.java`
  - `shengyu-framework/.../JsonBusinessMessageHandler.java`
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`


### B1（P0）：服务端握手协商并绑定 codec

- **验收**：SubProtocol 优先；无 SubProtocol 时首帧探测；失败返回 CLOSE(协议错误+code)。

- **目标**：服务端在 Upgrade 后完成协商，且把 `codec/negotiationMode` 绑定到连接会话上下文。
- **范围**：
  - Netty pipeline：协商 handler + CODEC_BOUND 状态
  - CLOSE：协商失败输出 4004xx（可观测）
- **依赖**：B0
- **验收标准**：
  - SubProtocol 传 `im.pb.v1` -> 绑定 PB
  - 不传 SubProtocol：Text 首帧 -> JSON；Binary magic -> PB/JSON
  - 不可识别首帧 -> CLOSE(400402)
  - 协商失败日志包含：clientIp/channelId/subProtocol/firstFrameHex/reason
- **涉及文件/目录**：
  - `shengyu-framework/.../WebSocketFrameHandler.java`
  - `shengyu-framework/.../core/session/NettySession.java`（或等价上下文字段）


### B2（P0）：服务端双 decoder/encoder（业务无感）

- **验收**：MaxFrameSize/AuthTimeout 生效；未认证仅允许 AUTH/HEARTBEAT；两栈跑通 AUTH/HEARTBEAT/CLOSE。

- **目标**：做到“业务 processor 只面对统一领域对象”，编解码对业务无侵入。
- **范围**：
  - decoder：JSON -> ImMessage；PB -> ImMessage
  - encoder：ImMessage -> JSON/PB
  - 资源保护：MaxFrameSize、JSON 最大嵌套/长度、PB 最大 message size
- **依赖**：B1
- **验收标准**：
  - JSON/PB 两栈：AUTH_REQ/HEARTBEAT/CLOSE 全部跑通
  - 未 AUTH 发送业务 messageType（>=TEXT）：CLOSE(401xxx)
  - 超过 MaxFrameSize：CLOSE(400xxx)
- **涉及文件/目录**：
  - `shengyu-framework/.../AuthHandler.java`
  - `shengyu-framework/.../JsonBusinessMessageHandler.java`
  - `shengyu-framework/.../ProtobufMessageHandler.java`


### B3（P0）：JSON Envelope 与字段语义对齐

- **验收**：服务端不信任客户端 tenantId/userId；CUSTOM 扩展规范固定；JSON decode 失败返回 400xxx。

- **目标**：冻结 JSON Envelope 校验规则，与 Protobuf header 语义完全一致。
- **范围**：
  - header 必填/可选字段校验
  - 服务端覆盖字段：tenantId/userId/sequence/serverTime
  - `extra` 扩展域约束
- **依赖**：B2
- **验收标准**：
  - header 缺必填字段：400xxx
  - 客户端传 tenantId/userId：服务端忽略并覆盖（以鉴权会话为准）
  - JSON body 解码失败：400404
- **涉及文件/目录**：
  - `shengyu-framework/.../JsonBusinessMessageHandler.java`
  - `shengyu-framework/.../core/netty/handler/*`（若有 Envelope 校验器）


### B4（P0）：App 端 Protobuf 编解码 + 自动降级

- **验收**：App 宣告 pb；收发二进制可解码；服务端不支持 pb 时自动降级 json 并记录埋点。

- **目标**：App 端在支持 pb 的情况下使用 pb；灰度拒绝/不支持时自动降级 json，体验无感。
- **范围**：
  - uniappx：pb 编解码、subProtocol 声明、错误码识别与降级重连
  - 埋点：降级次数、原因
- **依赖**：B0~B3
- **验收标准**：
  - App 使用 `im.pb.v1` 建链成功后收发二进制消息可解码
  - 服务端返回 CLOSE(400403/400401)：App 自动切换 `im.json.v1` 重连
  - 降级埋点：`codec_downgrade_total{from="pb",to="json",reason}`
- **涉及文件/目录**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`
  - `shengyu-ui/.../utils/protobuf.uts`（待新增或待落地文件）


### B5（P0）：限流/背压/异常保护

- **验收**：连接级、用户级、租户级限流（429xxx）；写队列过大可降级/断开异常连接。

- **目标**：保护服务端稳定性，避免异常客户端拖垮（对齐企微/钉钉的“可用性优先”）。
- **范围**：
  - 连接级 QPS
  - 用户/租户级 QPS
  - 写队列与背压策略（超阈值关闭/降级）
- **依赖**：B2
- **验收标准**：
  - 超限返回/推送 CLOSE(429xxx) 并可观测
  - 写队列超过阈值：主动断开，并记录 reason


### B6（P0）：观测与灰度开关（codec 白名单）

- **验收**：按 tenant/user/device 灰度 pb；可观测 json/pb 连接数、失败率、降级次数。

- **目标**：协议能力可灰度、可回滚、可观测。
- **范围**：
  - 灰度维度：tenantId/userId/deviceType
  - 指标：连接数、协商失败率、降级次数、decode 失败率
- **依赖**：B1~B5
- **验收标准**：
  - 可配置“仅允许 JSON”时，pb 连接进入自动降级（而非业务不可用）
  - 仪表盘可看到 PB/JSON 连接数与失败率
- **涉及文件/目录**：
  - `shengyu-framework/.../config/*`（feature flag/白名单配置落点）
  - `shengyu-framework/.../metrics/*`（若有指标组件）

---

## Milestone C（P0/P1）：消息可靠性（ACK/幂等/重投/断线补偿）

### C1（P0）：ACK + 先存储后 fanout

- **验收**：ACK 超时重发不产生重复消息；服务端幂等返回同一 sequence。

补充拆解（企业级落地必须项）：

- **目标**：服务端具备“先持久化后投递”的发送闭环，并返回 SendAck（含 `sequence/serverTime`）；客户端重投不产生重复消息。
- **范围**：
  - `shengyu-framework` websocket-starter（processor 链路）
  - `shengyu-module-system` IM 业务模块（消息落库/会话水位）
  - `shengyu-ui` uniappx（发送重投、pending->sent 状态机）
- **依赖**：Milestone A/B（鉴权、双栈链路打通）
- **验收标准**：
  - 发送端断网/弱网时重投同一 `messageId`，服务端返回同一 `sequence`
  - 服务端重启后再次重投同一 `messageId`，仍返回同一 `sequence`
  - 服务端必须先写入消息存储成功后才进行 fanout（可通过断点/日志验证顺序）
  - 日志可按 `tenantId/userId/conversationId/messageId/sequence` 对账一次完整链路
- **涉及文件/目录**（示例，后续按实现细化）：
  - `shengyu-framework/shengyu-spring-boot-starter-websocket/.../MessageStorageService`（替换 NoOp）
  - `shengyu-framework/.../NoOpMessageStorageServiceImpl`（仅作对比，不直接改）
  - `shengyu-module-system/.../im`（新增 message/conversation seq 相关 service/repository）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
  - `sql/mysql/1.0/im/ddl_im_tables.sql`

### C2（P1）：断线补偿（lastSequence）

- **验收**：断网 30s 恢复后不丢不重、顺序正确；未读与角标一致。

- **目标**：端侧能基于 `lastPulledSequence` 拉取缺失消息；缺洞超过阈值自动触发补偿。
- **范围**：
  - module-system：提供按 `conversationId + afterSequence` 的增量消息拉取接口
  - uniappx：实现 gap 检测、补偿拉取与本地归并
- **验收标准**：
  - 人为制造 WS 丢包/断链：重连后消息按 `sequence` 补齐
  - 同一会话消息严格按 `sequence` 渲染，不出现倒序
  - 补偿拉取不引入重复消息（去重键：`conversationId + messageId`）
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImMessageController.java`（新增 sync 接口）
  - `shengyu-ui/.../services/message-service.uts`（gap 检测与补偿）

### C2.1（P0）：群消息分页查询闭环（groupId -> chatId）

- **背景**：`AppImMessageController#getMessageListByGroup` 当前存在 `// TODO: 需要先查询会话ID`，导致“按 groupId 拉群消息”链路不闭环。

- **目标**：端侧仅持有 `groupId` 时，也能稳定分页拉取群聊消息，并与会话/sequence 体系一致（不引入第二套消息查询口径）。

- **范围**：
  - module-system：实现 groupId -> chatId 映射获取，并复用统一的 message page 查询
  - uniappx：统一通过 `chatId` 做消息分页；若页面入口只有 `groupId`，先获取 chatId 再拉取

- **推荐落地方式（优先）**：
  - 端侧先拿 chatId：复用现有
    - `GET /system/im/conversation/get-by-target?targetId={groupId}&conversationType=2`
  - 然后统一使用：
    - `GET /system/im/message/list-by-chat?chatId=...&pageNo=...&pageSize=...`
  - `GET /system/im/message/list-by-group` 作为兼容接口保留，但实现上应内部转换并复用 `getMessagePage`

- **验收标准**：
  - 端侧仅知道 `groupId` 时：可拉到该群会话的消息分页（pageNo/pageSize 生效）
  - 后端 `list-by-group` 返回的数据与 `list-by-chat` 返回一致（同 chatId 的同一页结果一致）
  - 查询结果按 `sequence` 单调排序，不出现跨页乱序
  - 失败场景：
    - groupId 不存在/无权限：返回 403xxx
    - 群存在但用户未入群：返回 403xxx

- **涉及文件/目录**：
  - `shengyu-module-system/.../controller/app/im/AppImMessageController.java`（补齐 list-by-group 的 TODO 或标记 deprecated）
  - `shengyu-module-system/.../service/im/ImConversationService`（提供 groupId->chatId 查询能力，或复用已有 createOrGetConversation）
  - `shengyu-ui/shengyu-ui-admin-uniappx/api/message.uts`（如需增加 groupId 入口，需保证最终走 chatId 查询）


### C3（P0）：会话同步与未读水位模型（对齐企微/钉钉）

- **验收**：服务端维护 lastReadSequence/lastMessageSequence；已读上报只升不降；跨端一致。

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

- **目标**：服务端成为“未读/已读”的权威来源，水位只升不降（`max(old,new)`），并提供端到端可对账字段。
- **范围**：
  - 会话用户维度（`chatId + userId`）：`lastReadSequence`、`lastReadTime`
  - 会话维度：`lastMessageSequence`、`lastMessageId`、`lastMessageTime`
- **验收标准**：
  - 任意顺序上报（旧值/重复值）不会导致 `lastReadSequence` 回退
  - 会话未读数计算口径固定：`unread = lastMessageSequence - lastReadSequence`（需处理异常/负值保护）

#### C3.2（P0）：增量会话同步接口（syncConversations）

- **目标**：端侧会话列表可通过 cursor 增量同步（对齐企微/钉钉的“拉增量 + 本地合并”）。
- **建议契约**：
  - `GET /system/im/conversation/sync?cursor=...&limit=...`
  - 响应：`{ nextCursor, hasMore, items: [ { chatId, conversationType, targetId, lastMessageSequence, lastReadSequence, unreadCount, isPinned, noDisturb, updatedAt } ] }`
- **验收标准**：
  - cursor 初次为空：返回全量 + `nextCursor`
  - cursor 非空：只返回 `updatedAt > cursor` 的会话变更
  - 端侧合并规则：同 chatId 以 `updatedAt` 或 `version` 较大者覆盖
- **涉及文件/目录**：
  - `AppImConversationController.java`（新增 `sync`）
  - `services/conversation-service.uts`（增量同步与合并）

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

- **目标**：在不破坏现有端侧逻辑的前提下，平滑迁移到水位上报。
- **策略**：
  - 短期保留 `PUT /system/im/message/mark-read?messageIds=...`（仅用于过渡/兼容）
  - 端侧优先使用 `read-watermark`；若服务端未上线可降级到旧接口（feature flag）
- **验收标准**：
  - 旧接口与新接口不会互相打架导致水位回退
  - 灰度开关可按 tenant/user 切换

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
- **mark-read 废弃策略**：
  - `PUT /system/im/message/mark-read?messageIds=` 标记为“兼容接口（deprecated）”
  - 新端只走 `PUT /system/im/conversation/read-watermark`（水位上报）
  - 灰度：按 tenant/user/device 逐步切换；出现问题可回退到旧接口（但旧接口内部也应推进水位，避免口径分裂）
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
- **范围**：
  - module-system：落库 `lastReadSequence`；产生“会话水位变更事件”（WS 推送或增量可见）
  - uniappx：接收水位变更事件并更新会话未读与角标
- **依赖**：C3（会话水位模型与 sync 接口）
- **验收标准**：
  - A 端上报 `lastReadSequence` 后，B 端会话未读数在 1s 内推进（WS 在线）
  - 重复/乱序上报不回退（服务端 `max(old,new)`）
  - 离线端重新上线后，通过 `syncConversations(cursor)` 可拉到最新水位
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImConversationController.java`（read watermark 上报 + sync 输出）
  - `shengyu-framework/.../MessageProcessor`（若采用 WS 推送水位变更事件）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts`
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/badge-service.uts`

### C7（P0/P1）：消息最终态字段（status/rev/edited）与端侧合并规则

- **目标**：撤回/编辑/删除等事件在“实时 WS + 补偿拉取”两条链路下保持最终一致，避免撤回后被补偿拉回原文。
- **范围**：
  - 服务端：消息模型增加最终态字段（至少 `status`、`rev`、`edited`）并在查询/sync 返回
  - 客户端：同一 `messageId` 合并以 `rev` 更大者覆盖（或 serverTime 更新者覆盖）
- **依赖**：C2（断线补偿 syncMessages）、F1（撤回）、（如有）消息编辑能力
- **验收标准**：
  - 先收到撤回事件、后收到原消息：最终渲染为“已撤回”
  - 断线补偿拉取不会把撤回/编辑前的旧内容覆盖回去
  - 同一消息多次编辑/撤回：端侧最终态与服务端一致（可回归复现）
- **涉及文件/目录**：
  - `shengyu-module-system/.../AppImMessageController.java`（查询/sync 输出最终态字段）
  - `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`（合并逻辑）
  - `sql/mysql/1.0/im/ddl_im_tables.sql`（消息表字段/索引）

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

### C7.2（P2，可选）：消息编辑（Edit）能力（受控开关 + rev 规则）

- **背景**：uniappx 已存在 `services/message-edit-service.uts` 调用，但 module-system 当前缺对应接口。编辑能力与撤回一样属于“最终态”，必须与 C7 合并规则绑定。

- **目标**：支持消息编辑（窗口期/权限/审计），并保证补偿拉取不会覆盖回旧内容。

- **建议契约**：
  - `PUT /system/im/message/edit` body：`{ messageId: string, content: string, clientTime?: number }`
  - `GET /system/im/message/edit-history?messageId=...&pageNo=...&pageSize=...`（可选）

- **一致性约束**：
  - 编辑成功必须推进消息 `rev`，并设置 `edited=true`、`editTime/serverTime`
  - WS 推送 `EDIT(203)`（或等价事件）必须携带 `messageId + rev + edited + content摘要/或拉取标记`
  - `syncMessages` 返回必须包含最新 content + rev（或保证按 rev 合并）

- **灰度/开关**：
  - 默认关闭；按 tenant/user 灰度

- **验收标准**：
  - 超过时间窗口编辑返回 403xxx（或业务码），端侧提示明确
  - 先收到 edit 事件、后补偿拉旧消息：最终展示为已编辑（rev 合并生效）
  - 编辑历史（如开启）分页稳定，且与最终态一致

- **涉及文件/目录**：
  - module-system：`AppImMessageController`（新增 edit/edit-history）
  - uniappx：`services/message-edit-service.uts`（解除降级并对接新契约）

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
  - 清理任务不误删仍被引用的文件
- **涉及文件/目录**：
  - infra：`FileService`（扩展 thumb 生成能力/任务）
  - （可选）异步任务：job/queue（用于生成与清理）

### S3（P1）：CARD/CUSTOM 安全与降级渲染规则

- **目标**：卡片/业务消息可扩展，但必须安全可控、可降级、可审计。
- **范围**：
  - schema 白名单校验：`cardType/subType` 白名单 + 字段校验
  - 降级：不识别的 card/subType 以“不可用占位”展示，不影响会话/同步
  - 跳转：url/payload 必须服务端校验（租户/权限）
- **验收标准**：
  - 任何未知 card/subType 不会导致端侧崩溃
  - 安全扫描：卡片不允许执行任意脚本/富文本注入

---

## Milestone H（P1）：通讯录/组织架构（企业级通讯录能力基线）

### H1（P1）：部门联系人列表（list-by-dept）闭环

- **背景**：`AppImContactController#getContactListByDept` 当前存在 `// TODO: 实现按部门查询联系人`，现状会返回全量联系人，端侧使用会产生“看似可用但数据不可信”。

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
