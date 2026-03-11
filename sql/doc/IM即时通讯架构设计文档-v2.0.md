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

## 2.4 当前工程落地情况（关键落点）

说明：本节用于把“对标企微/钉钉的设计”与“当前工程已落地实现”对齐，便于回归与后续迭代。

### 2.4.1 会话增量同步（cursorVersion）

- **后端**：`shengyu-module-system/.../service/im/ImConversationServiceImpl#syncConversations`
  - 数据源：`im_conversation_user_state`
  - 过滤：`cursor_version > cursorVersion`
  - 返回：`nextCursorVersion/hasMore/items`（items 含 `cursorVersion/conversationVersion/lastMessageSequence/lastReadSequence/unreadCount`）

- **前端**：`shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts#syncConversationsIncrementally`
  - 本地存储：按 `tenantId+userId` 维度持久化 cursorVersion
  - reset 策略：本地列表为空但 cursor>0 时强制 reset（避免“刷新后列表为空”）

### 2.4.2 会话幂等/乱序保护（conversationVersion）

- **前端**：`conversation-service.uts#upsertFromSnapshot`
  - 合并规则：incoming `conversationVersion` 不大于 current 时丢弃，避免旧快照覆盖新状态

### 2.4.3 WebSocket 推送版本透传与补偿

- **后端 WS Sender**：`shengyu-framework/.../NettyMessageSender#sendToUser`
  - payload root 透传：`cursorVersion/conversationVersion`
  - cursorVersion 非空时可跳过 snapshot 构建（避免额外查询）

- **前端 WS**：
  - `shengyu-ui/.../utils/websocket.uts`：AUTH 成功后触发节流补偿 sync（对标企微/钉钉的断线恢复）
  - `shengyu-ui/.../services/message-service.uts`：支持从 WS root 读取 `cursorVersion` 做 gap 检测（snapshot 为空也可补偿）

### 2.4.4 已读水位/角标一致性（对标企微/钉钉）

- **权威接口**：`PUT /system/im/conversation/mark-read-seq?chatId=&readSequence=`
  - **后端**：`ImConversationServiceImpl#markConversationReadBySequence` + `ImChatUserMapper#markReadToSequence`
  - 规则：水位只升不降（GREATEST），并把 `unread_count` 清零

- **角标刷新**：`GET /system/im/badge/get`
  - **后端**：`ImBadgeServiceImpl#getBadgeData` -> `ImConversationServiceImpl#getConversationBadges`
  - 口径：`unread = lastMessageSequence - lastReadSequence`（与会话列表一致）

- **前端**：
  - `badge-service.uts#clearConversationBadge`：进入会话始终推进服务端已读水位（幂等），避免“本地 badge 未加载导致服务端未清”
  - `pages/message/chat.uvue`：进入会话上报 readSequence 使用权威 `lastMessageSequence`（并兜底页面消息最大 seq），避免上报 0 导致未清

### 2.4.5 群聊摘要一致性（对标企微/钉钉）

- **后端写入**：`SystemMessageStorageServiceImpl#updateChatUserAsync`
  - 群聊 `last_message_content` 按成员写入 `"我: ..."/"昵称: ..."`（兜底 senderId），保证刷新后仍可展示发送者

- **后端读取**：`ImConversationServiceImpl#buildPreviewByType`
  - raw 非空优先返回 raw（截断），避免类型占位文案覆盖发送者前缀

- **前端渲染**：`pages/message/message.uvue#buildConversationPreview`
  - raw 非空优先展示 raw（截断），保证推送与刷新一致

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
2. **首帧探测（兜底）**：客户端首帧发送 magic/版本头，服务端在 read timeout 内识别

协商输出（必须落到连接会话上下文）：

- `codec`：`PB` / `JSON`
- `protoVersion`：如 `v1`
- `negotiationMode`：`SUB_PROTOCOL` / `FIRST_FRAME_PROBE`

不变式：

- **一个连接只绑定一个 codec**，绑定后不得切换（切换必须重新建链）
- 协商必须在 AUTH 之前完成，否则无法正确解码 AUTH

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

原因：

- 部分终端/代理可能不透传 `Sec-WebSocket-Protocol`

建议首帧格式（Binary）：

- `MAGIC(4 bytes) = 0x49 0x4D 0x50 0x42`（示例："IMPB"）
- `VERSION(1 byte) = 1`
- `CODEC(1 byte) = 1(pb) / 2(json)`
- `FLAGS(2 bytes)`

建议补充字段（可选）：

- `HEADER_CRC(4 bytes)`：用于快速拒绝错误流量（可选）

读超时建议：

- 连接升级成功后 `ProbeTimeoutMs`（例如 3s）内必须收到首帧；否则关闭连接

探测规则：

- 若首帧为 Text：认为 JSON
- 若首帧为 Binary 且 magic 匹配：按 `CODEC` 选择
- 若首帧为 Binary 且无法识别：直接 CLOSE（协议错误）

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
  - `fileId: string`
  - `durationMs: number`
  - `format: string`（amr/aac 等）
  - `sizeBytes: number`
  - `asrText?: string`（可选）

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

#### 6.4.2 Protobuf Envelope（现有形态）

- `ImMessage{ header: MessageHeader, body: bytes }`
- `body` 为具体消息体的 protobuf bytes（如 `AuthRequest/TextMessage`）

#### 6.4.3 JSON Envelope（H5 形态）

```json
{
  "header": {
    "messageId": 1710000000000,
    "messageType": 3,
    "timestamp": 1710000000000,
    "traceId": "...",
    "extra": "{...}"
  },
  "body": {
    "...": "..."
  }
}
```

JSON 兼容建议：

- `header.messageId` 允许 string/number（端侧统一使用 string，但服务端需兼容）
- `header.timestamp` 允许 number
- `body` 允许按 `messageType` 的不同结构变化，但必须可被服务端映射到统一领域对象

### 6.5 Netty Pipeline 设计（同端口双栈）

#### 6.5.1 Pipeline 分层

推荐处理顺序（概念层）：

1. **HTTP 握手 / WebSocket Upgrade**
2. **协议协商**（SubProtocol / 首帧探测）
3. **Frame 聚合与大小限制**（防止超大帧 OOM）
4. **Decoder**（JSON / Protobuf） -> 统一领域对象
5. **AuthHandler**（鉴权前置，未认证仅允许 AUTH_REQ/HEARTBEAT）
7. **Business Processor**（MessageProcessor）
8. **Encoder**（JSON / Protobuf）

---

## 7. 消息可靠性模型

### 7.1 核心字段

- `messageId`：全局唯一（雪花/分布式 ID）
- `sequence`：会话维度或全局递增，用于排序与断线补偿
- `timestamp`：客户端/服务端时间戳（用于展示与冲突处理）

### 7.2 ACK / 重投 / 幂等

- 发送方本地先落 UI（pending），发送后等待 ACK
- 服务端收到消息：
  - 持久化并分配 `sequence`
  - 返回 ACK（含 messageId/sequence）
- 发送方超时未收到 ACK：
  - 按退避策略重投（需服务端幂等保证）

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
  - 更新：`UPDATE ... SET max_sequence = max_sequence + 1 WHERE conversation_id=?`（需事务/行锁）
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
  - 分配规则：每次需要产生会话列表变更时做原子 `+1`（可用 `UPDATE ... SET next=LAST_INSERT_ID(next+1)`）

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

推荐实现：

- 服务端为用户维度维护“删除墓碑（tombstone）”：`(userId, conversationId, messageId, deletedAt)`
- 同步方式：
  - WS：推送删除事件
  - HTTP：`syncMessages` 返回消息时附带 tombstone 过滤（或返回状态字段）

端侧规则：

- tombstone 命中：本地不展示该 messageId
- tombstone 不得影响审计与管理员能力（服务端仍保留原消息）

### 8.11 主端策略（可选，对齐企业产品的“多端体验一致”）

对齐企微/钉钉可选策略：同一账号多端在线时，可配置“主端优先”或“全端同步”。

- **全端同步**（默认推荐）：所有在线端都收到消息与水位变更
- **主端优先**（运营可配）：仅主端接收实时消息，其他端仅同步会话水位/角标，进入会话时再补偿拉取

无论采用哪种策略，必须保证：

- `syncConversations/syncMessages` 仍可把非主端补齐到最新状态
- 被踢/撤销/重登等系统 CLOSE 仍需所有端一致生效

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

#### 10.2.3 编辑（Edit）与历史（可选）

编辑能力若开启：

- 权限：仅编辑自己发送的消息
- 时限：默认 5 分钟（可配置）
- 更新：`edited=true`，`rev+1`，并记录 editHistory（可选）
- 同步：WS 推送编辑事件；syncMessages 返回最终态

补充：表情回应（Reaction，可选）

- 建议受 feature-flag 控制，默认关闭。
- 建议独立路由：`/system/im/reaction/add`、`/system/im/reaction/remove`、`/system/im/reaction/list?messageId=...`
- 返回建议仅包含聚合结果（`emoji/count/isSelf`），避免返回全量 userId 列表导致大群风暴。

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

### 10.3 系统通知/机器人/应用消息

- 系统通知走独立 `messageType`，可单独限流、单独展示、单独推送策略
- 支持“应用消息卡片”类扩展（对齐企微/钉钉的工作台消息形态）

### 10.4 审计与合规（企业级必须）

合规目标：可审计、可追溯、可保全。

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
- `negotiationMode`：SUB_PROTOCOL/FIRST_FRAME_PROBE
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

### 11.3 企业级指标目录

企业级上线要求必须具备以下指标目录：

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

- `AppImMessageController#getMessageListByGroup`：按 groupId 查消息列表尚未闭环（需先映射 chatId/会话）
- `AppImContactController#getContactListByDept`：按 deptId 过滤联系人尚未实现

### 12.3 现状实现对齐表（As-Is vs To-Be）

说明：本表用于把“企业级闭环能力”映射到当前代码的落地点，避免文档与实现脱节。

| 能力域 | 现状状态 | 关键入口（模块/文件） | 闭环缺口/验收要点 |
| --- | --- | --- | --- |
| 统一鉴权（HTTP） | 已落地 | `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts` | 已完成：Authorization/tenant-id 注入、401 refresh 单飞、队列重放、避免重复/丢失 |
| IM 鉴权 + 不断链续期 | 已落地（核心链路） | `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`；`shengyu-framework/.../AuthHandler.java`；`shengyu-framework/.../NettySessionManager.java` | 核心闭环已具备（AUTH_REQ/AUTH_RENEW、RENEW_SUGGEST/REAUTH_REQUIRED）。需补齐：企业级错误码、埋点与回归用例体系 |
| 撤销闭环（logout/互踢 -> IM 断链） | 已落地 | `shengyu-framework/.../core/mq/consumer/ImSessionRevokeConsumer.java`；`NettySessionManager.java` | 已具备：RedisMQ 撤销、clientId 过滤、精确到 accessToken/设备；验收：跨节点可达、reason/action 标准化 |
| Presence/Lease（前台 gating + 租约状态机） | 已落地（基础） | `shengyu-ui/.../utils/websocket.uts`；`shengyu-framework/.../core/session/NettyAuthLeaseMonitor.java`；`NettySession.java` | 已具备：SOFT/HARD 语义与推送；需补齐：租约参数配置化与运营可观测（到期原因、后台比例） |
| 多端登录与互踢 UX | 已落地 | `NettySessionManager.java`；`NettySession.java`；`shengyu-ui/.../utils/device.uts`；`shengyu-ui/.../utils/websocket.uts` | 已具备：同 deviceType 互踢、KICKED 携带 byDevice/kickedAt，前端提示；验收：同账号不同 deviceType 可共存 |
| 协议双栈（JSON WebSocket） | 已落地（服务端 JSON 业务适配层） | `shengyu-framework/.../WebSocketFrameHandler.java`；`JsonBusinessMessageHandler.java`；`AuthHandler.java` | 已具备：Text frame JSON -> 复用 processor 分发；缺口：连接层协商（SubProtocol/首帧探测）、统一 Envelope 约束与错误码 |
| 协议双栈（App Protobuf） | 部分落地 | `ProtobufMessageHandler.java`（服务端）；`uniappx` 侧待补 `utils/protobuf.uts` | 服务端具备 Protobuf 处理链路；客户端 App 端 Protobuf 编解码、协商与降级待落地 |
| 消息处理器（TEXT/IMAGE/FILE/READ_RECEIPT/RECALL 等） | 已落地（处理器注册） | `shengyu-framework/.../NettyAutoConfiguration.java`（processor 注册） | 注意：处理器存在≠闭环完成。需要业务模块提供真正的存储/查询/补偿/权限校验，否则无法达成企业级可靠性 |
| 消息持久化（先存储后 fanout） | 未落地（默认 NoOp） | `shengyu-framework/.../NettyAutoConfiguration.java`：`NoOpMessageStorageServiceImpl` | 当前默认不会持久化消息（企业级不可接受）。验收：存储落库、sequence 分配、ACK、幂等、重投、补偿 |
| 会话同步与未读一致（lastReadSequence/未读水位） | 部分落地（REST 基础接口存在） | `shengyu-module-system/.../AppImConversationController.java`；`ImConversationService` | 已有 list/mark-read/unread-count 等；缺口：基于 sequence 的水位模型、跨端一致、增量 sync（cursor/pull） |
| 断线补偿/漫游（按 lastSequence 拉取） | 未落地 | 待新增：system 消息同步接口 + 查询 service；客户端 reconnect 流程 | 验收：断网 30s 后恢复不丢/不重/顺序正确，会话未读与角标一致 |
| 离线推送（通道集成） | 未落地（策略已规划） | `OfflinePushService`（starter 默认实现）；uniappx 推送 SDK 待接 | 闭环：token 绑定 -> 离线触发 -> 点击拉起 sync；推送去重、DND、撤回一致 |
| 观测与运维（指标/告警） | 部分落地 | server 日志 + 文档建议；需补 metrics/报警 | 验收：按 tenantId/userId 追踪一次消息链路；在线数、重连率、401、ACK 超时、推送失败率告警 |
| 多节点部署（跨节点投递/KICK/撤销） | 部分落地（撤销侧已具备 Redis pubsub） | `ImSessionRevokeConsumer.java`；后续引入 MQ/registry | 验收：任意节点触发 KICK/REVOKE，目标连接所在节点可达；消息投递跨节点可达 |

---

## 13. 高可用、扩展与降级（对齐企业 IM 的“可用性优先”）

### 13.1 多节点路由与消息总线

- 单机内：channel -> session 映射
- 多机：
  - session 分布式注册（Redis）
  - 跨节点投递通过 MQ（Redis pubsub/RocketMQ/Kafka 等）
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

- 降级不变式：
  - AUTH/HEARTBEAT/撤销（REVOKE/KICK）必须始终可用
  - 消息可靠性闭环（至少 SendAck）不得被降级破坏

### 13.3 灰度与开关（企业级必备）

- feature flag 维度：tenantId/userId/deviceType/appVersion
- 可控开关：pb 双栈、ACK 模式、补偿策略、推送通道、限流阈值

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

---

## 14. 演进路线（建议）

- v2.0（近期）：鉴权一致性/撤销闭环/不断链续期/互踢 UX 稳定化，补齐离线补偿最小闭环
- v2.1：App 端 Protobuf 双栈落地（H5 保持 JSON），可靠性 ACK/重投/补偿完善
- v3.0：分布式与多节点一致性、离线推送全链路、观测与压测体系完善

---

## 15. 附录：协议权威来源与历史文档迁移说明

### 15.1 Protobuf 协议权威来源

- 协议文件位置（权威）：
  - `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto/im_message.proto`

约束：

- `MessageType` 枚举以 proto 为权威来源（JSON/前端必须与之对齐）
- JSON/H5 侧扩展能力建议统一走 `CUSTOM` + `header.extra/body.subType`（以 v2 架构文档第 6 章为准）

### 15.2 历史文档迁移说明

本仓库早期存在面向“AI 可执行”的大而全 v1 文档（包含阶段看板、待办清单、部分实现假设）。

- 当前权威文档已切换为：
  - `sql/doc/IM即时通讯架构设计文档-v2.0.md`
  - `sql/doc/IM即时通讯开发任务清单-v2.0.md`

迁移原则：

- v1 中仍有价值的“协议权威来源/关键约束/经验总结”迁入 v2（本附录及相关章节）
- v1 中的“任务看板/阶段完成度”不再作为依据，以 v2 Backlog 为准

---

## 16. 附录：IM + HTTP 统一鉴权（详细版，权威）

本附录用于收敛“统一鉴权”完整设计，避免单独维护多份文档导致语义漂移。

### 16.1 设计目标（对齐企微/钉钉）

- 统一鉴权语义：HTTP 与 IM 都基于同一套 accessToken/refreshToken 生命周期与撤销逻辑
- 不断链续期：HTTP token refresh 不应导致 IM 断链/被踢，应在同一连接上完成续期
- 互踢与撤销精确化：按 `userId + deviceType` 互踢；撤销精确到 accessToken/设备优先
- 体验一致：KICKED/REAUTH_REQUIRED 文案可读（deviceName），且前端停止重连并引导登录

### 16.2 HTTP：稳定注入（不丢、不重复）

- 注入字段：
  - `Authorization: Bearer <accessToken>`（白名单接口除外）
  - `tenant-id: <tenantId>`（租户开关开启且非租户白名单接口）

- 规范化策略（uniappx 多端差异）：
  - `ensureHeader(config)`：保证 header 可写，必要时 clone
  - `applyAuthHeader(config, token)`：清理 `Authorization/authorization` 再写入单一 canonical 值
  - `applyTenantHeaderIfNeeded(config)`：清理变体后写入 `tenant-id`

### 16.3 HTTP：401 refresh 单飞 + 队列重放

- 401 触发 refresh **单飞**；并发请求进入队列
- refresh 成功后：
  - 原请求 retry 前重新注入 `Authorization/tenant-id`
  - 队列请求 replay 前重新注入 `Authorization/tenant-id`

### 16.4 IM：认证 + 不断链续期 + presence gating

- 建链：连接成功后发 `AUTH_REQ(accessToken + deviceType/deviceId/deviceName)`
- 不断链续期：
  - HTTP refresh 成功或服务端提示 `RENEW_SUGGEST` 时，IM 在**同一连接**上发 `AUTH_RENEW_REQ`
  - 成功后刷新 session token/租约，不断开连接

- presence gating（仿企微/钉钉）：
  - 前台/聊天页：正常 PRESENCE + 续租（体验无感）
  - 后台闲置：降低/停止续租，最终触发 `REAUTH_REQUIRED`

### 16.5 多端互踢与撤销联动（HTTP <-> IM）

- 互踢：`userId + deviceType` 新登录互踢旧会话
- 撤销精确优先级：accessToken -> (userId, deviceType, deviceId) -> userId
- RedisMQ 撤销联动：logout/互踢/强退发布撤销事件；IM 侧订阅后定向 CLOSE/KICKED 并断链

### 16.6 关键不变式（Invariants）

- 非白名单 HTTP 请求必须携带且仅携带一个 `Authorization`
- 租户开关开启时，非租户白名单 HTTP 请求必须携带 `tenant-id`
- refresh 后重试/队列重放必须重新注入 `Authorization/tenant-id`
- token refresh 不应触发 IM 被踢，应走不断链续期
- 互踢必须精确到 `userId + deviceType`（或更细 session/设备维度）

### 16.7 回归用例（上线门禁建议）

- 登录后：`/system/auth/get-permission-info` 与角标同步接口请求头不丢、不重复
- 人为制造 token 过期：refresh 只触发一次；队列重放带新 token + tenant-id
- IM：前台不断链续租；后台闲置触发重登；refresh 后 WS 不断链且续期成功
- 多端互踢：同 deviceType 新登录踢旧端，不同 deviceType 可共存

---

## 17. 附录：开发任务清单（Backlog，权威）

Backlog 已独立维护于：`sql/doc/IM即时通讯开发任务清单-v2.0.md`。

原则：

- 架构文档负责“机制与标准”，Backlog 负责“拆解与执行”
- 避免同一任务在两处维护，防止漂移
