# IM 搜索设计与任务文档（可开工版）

## 1. 背景与目标

当前已具备 IM 基础搜索能力（联系人/会话/消息分接口），但整体体验还停留在“分块结果拼装”，距离大厂 IM 的搜索体验仍有差距。  
本方案目标是在**不推翻现有架构**的前提下，分阶段落地“可用 -> 好用 -> 可扩展”的搜索能力。

核心目标：

- 支持顶部搜索入口的一体化检索体验（联系人、群聊、消息、文件媒体）
- 搜索结果可快速定位到会话与消息上下文（跳转锚点稳定）
- 对高频输入与暴力操作具备防抖、限流、降级能力
- 保持与现有实时同步机制（WebSocket + conversation sync）兼容

非目标（本期不做）：

- 语义搜索/向量检索
- 跨租户检索
- 超大规模（千万级消息）下的搜索引擎切换一步到位

---

## 2. 现状盘点（基于当前代码）

### 2.1 前端现状

- 入口页：`/pages/message/message` 顶部搜索跳转 `/pages/common/search`
- 搜索页：`/pages/common/search.uvue`
  - 本地历史：`IM_SEARCH_HISTORY`
  - 热词：`/system/im/search/hot`
  - 并行调用：
    - 联系人：`/system/im/contact/search`
    - 群聊：`/system/im/conversation/search?conversationType=2`
    - 消息：`/system/im/message/search`（`message-search-service.uts`）
- 聊天记录详情页：`/pages/common/search-chat-history.uvue`，支持分页与锚点跳转

现存问题：

- 结果排序是“分区展示”，不是统一相关性排序
- `message-search-service.uts` 使用 `params` 传参，而 `request.uts` 主要透传 `data`/query，存在参数不一致风险
- 搜索结果没有统一类型模型（联系人/会话/消息字段不齐，扩展性差）
- 缺少请求取消与全链路耗时监控

### 2.2 后端现状

已存在接口：

- `GET /system/im/search/hot`
- `GET /system/im/contact/search`
- `GET /system/im/conversation/search`
- `GET /system/im/message/search`

已存在能力：

- 消息搜索支持 `chatId/keyword/messageType/startTime/endTime/pageNo/pageSize`
- 会话搜索支持 `conversationType + keyword`
- 权限与可见性过滤已有（会话成员、墓碑、清空水位）

现存问题：

- 联系人搜索当前为“全量用户拉取后 Java 内存 contains 过滤”，规模上来后不可持续
- 消息检索使用 `m.content LIKE '%keyword%'`，无专门全文索引
- 当前没有统一“综合搜索接口”（只能前端聚合）
- 排序维度偏时间，相关性策略较弱

### 2.3 数据层现状

- `im_chat_message`：有 `idx_chat_seq` / `idx_sender_time`，无 `content` 的全文索引
- `im_chat_user`：会话列表索引较完善
- 当前适合中小规模快速落地，不适合大规模复杂检索

---

## 3. 大厂能力对标（可借鉴）

### 3.1 Slack（官方帮助文档）

- 支持修饰符：`in:` `from:` `has:` `before:` `after:` `on:` `during:` `is:thread`
- 支持类型过滤与排序（Messages/Files/People/Channels 等）
- 支持组合修饰符，提高检索效率

启发：先把“结构化过滤”做扎实，再谈语义搜索。

### 3.2 Discord（官方帮助文档）

- 支持 `from:` `in:` `mentions:` `has:` 快捷过滤
- 支持 `Newest/Oldest/Most Relevant` 排序
- 结果可直接跳转消息位置
- 明确提到“先索引后快速搜索”的策略

启发：排序模式要对用户可见；“相关度排序”必须作为独立能力设计。

### 3.3 Microsoft Teams（官方帮助文档）

- 全局搜索 + `Ctrl+F` 会话内搜索并存
- 全局结果支持按 `Type/From/Date/@mentions/attachments` 细化
- 结果支持“View all messages”扩展

启发：全局与会话内搜索分层是刚需，不能只做一种。

### 3.4 Google Chat（官方帮助文档）

- 操作符体系完整：`from:` `has:url` `after:` `before:` `older_than:` `is:unread` `in:<space>` 等
- 支持组合操作符，表达能力强

启发：搜索 DSL 可以先做简版，后续平滑增强。

### 3.5 Matrix 规范（官方协议）

- 搜索接口明确“Rate-limited: Yes”
- 支持 `order_by: recent|rank`
- 支持 `before_limit/after_limit` 上下文返回
- 支持 `next_batch` 分页游标
- 强调只能返回有权限的数据

启发：你们现有“锚点跳转”可以进一步升级为“结果 + 上下文片段”能力。

---

## 4. 目标方案（结合现有架构）

### 4.1 产品交互（V1 可落地）

顶部搜索页采用 4 个结果 Tab：

- `综合`（默认）
- `消息`
- `联系人`
- `群聊`
- `文件与媒体`（消息类型 2/4/5）

交互规则：

- 默认输入 2 个字符后触发查询
- 输入中防抖（300~400ms）
- 同关键词重复请求做本地去重（短时间内不重复打接口）
- 搜索结果点击后：
  - 联系人 -> 用户详情
  - 群聊 -> 会话页
  - 消息/文件媒体 -> 会话锚点定位（优先 sequence）

### 4.2 检索模式（V1）

- 综合 Tab：并行调用现有 3 个接口，服务端各取 TopN（如 5/5/10），前端统一打分后混排
- 分 Tab：按资源类型单独分页
- 会话内搜索继续保留 `/pages/message/chat-history.uvue` 与 `/pages/common/search-chat-history.uvue`

### 4.3 排序策略（V1 可实现）

综合排序分值建议：

- 精确匹配（昵称/群名/消息词）+100
- 前缀匹配 +60
- 包含匹配 +30
- 最近 3 天消息 +30，最近 7 天 +15
- `@我` 命中 +20
- 文件/图片/视频命中 +10

同分再按时间倒序。

---

## 5. 接口与数据设计

### 5.1 阶段一：沿用现有接口（低风险）

保留：

- `/system/im/contact/search`
- `/system/im/conversation/search`
- `/system/im/message/search`

补充约束：

- 统一分页入参边界：`pageSize <= 50`
- 统一关键词长度：`2 <= len <= 64`
- 统一空关键词行为：直接返回空结果，不查库

前端立即修复：

- `message-search-service.uts` 的 GET 传参从 `params` 改为 query string 或 `data`（与 `request.uts` 统一）

### 5.2 阶段二：新增聚合接口（推荐）

新增接口：

- `GET /system/im/search/global`

建议参数：

- `keyword` 必填
- `tab` 可选：`all|message|contact|group|media`
- `pageNo/pageSize`
- `chatId` 可选（会话内搜索）
- `sort` 可选：`recent|relevance`

建议返回：

- `list[]` 统一结构：`id/type/title/subTitle/snippet/time/score/chatId/messageId/sequence/meta`
- `facets`：各类型命中数
- `nextCursor`（后续可切换游标分页）

---

## 6. 数据与索引策略

### 6.1 近期（MySQL 方案）

- 保持 `LIKE`，但加强“先过滤后模糊”：
  - 优先按 `tenant_id + chat_id + message_type + send_time` 缩小范围
  - 限制时间窗口（例如默认近 1 年，超范围需显式指定）
- 联系人搜索改为 DB 层条件检索（避免全量用户进内存）

建议新增索引（按实际慢 SQL 验证后落）：

- `im_chat_message (tenant_id, chat_id, message_type, send_time DESC, deleted)`
- `system_users (tenant_id, nickname)`（若当前无可用索引）

### 6.2 中期（搜索索引表）

新增 `im_message_search_index`（异步构建）：

- `message_id, tenant_id, chat_id, sender_id, message_type, plain_text, send_time, deleted`

价值：

- 把 JSON/富文本内容预清洗成可检索文本
- 避免直接在 `longtext content` 上高频 `%LIKE%`

### 6.3 长期（可选外部引擎）

当消息量级与检索复杂度上升后，再评估 ES/OpenSearch：

- 保留 MySQL 为权威存储
- 搜索引擎做异步索引与召回
- 结果回源做权限兜底

---

## 7. 防滥用与稳定性设计

客户端：

- 防抖 300~400ms
- 最小字数 2
- 同词请求去重 + 过期响应丢弃（seq token）
- 页面离开即取消未完成请求回调

服务端：

- 搜索接口限流（建议复用 `ImConversationSyncRateLimitService` 模式）
- 429 返回 `Retry-After`
- 关键词长度、页码、页大小白名单约束
- 异常词（全空白/超长/高重复字符）提前拒绝

降级策略：

- 综合搜索超时时，按资源类型逐步降级（先消息，再联系人/群聊）
- 保证“至少可返回部分结果”，而不是整页失败

---

## 8. 分阶段任务拆解（建议 3 期）

状态标记（截至 2026-04-09）：

- `[x]` 已完成（代码已落地）
- `[ ]` 未完成
- `[x]（待联调验收）` 代码已完成但需人工联调/压测确认

### 8.1 P0（1~2 天，开工前必须）

- [x] FE：统一 GET 参数传递规范，修复 `params` 不一致风险
- [x] BE：补齐搜索接口参数校验与分页上限
- [ ] QA：建立搜索基础回归用例（空词、短词、超长词、无权限会话）

验收：

- [x] 三类搜索接口参数行为一致（待联调验收）
- [x] 不再出现“看似成功但实际未带条件”的请求（待联调验收）

### 8.2 P1（5~7 天，可上线）

- [x] FE：新搜索页交互（综合/消息/联系人/群聊/文件与媒体）（待联调验收）
- [x] FE：统一结果模型 + 混排（待联调验收）
- [x] FE：搜索历史与热词保留
- [x] FE：移动端会话页/通讯录页顶部搜索栏可输入（本页过滤 + 回车带词跳转全局搜索）
- [x] BE：联系人搜索改 DB 条件检索
- [x] BE：消息搜索补充媒体类型过滤（待联调验收）
- [x] BE：搜索限流（用户维度）
- [ ] QA：搜索结果跳转链路（联系人/群聊/消息锚点）
- [ ] QA：低网速与高频输入压力验证
- [ ] QA：Android/iOS/Web 会话页与通讯录页搜索栏输入、清空、回车跳转一致性

验收：

- [x] 首屏搜索可用，结果可跳转，错误可恢复（待联调验收）
- [ ] 搜索 P95 < 800ms（常规数据量）

### 8.3 P2（7~10 天，体验增强）

- [x] BE：新增 `/system/im/search/global` 聚合接口 + 统一打分排序（待联调验收）
- [x] FE：改为单接口为主，分源接口为降级兜底（待联调验收）
- [x] BE：联系人搜索补齐真实分页（`contact` Tab 与聚合 facets 总数一致）
- [x] BE：`all` 综合分页改为分源窗口多页拉取（最多 200 条混排窗口）
- [x] FE：同关键词短时请求去重（默认 1200ms 窗口）
- [x] BE/FE：补充全局搜索耗时指标（`costMs` + `X-Search-Cost-Ms`，待观测验收）
- [ ] QA：排序正确性、分页一致性、跨端一致性

验收：

- [ ] 综合排序稳定
- [ ] 接口调用次数下降（前端并发请求减少）

### 8.4 P3（按容量触发）

- [x] DB：输出搜索索引 DDL 脚本（`sql/mysql/1.0/im/ddl_im_search_indexes.sql`，待 DBA 执行）
- [ ] 搜索索引表或外部搜索引擎建设
- [ ] 建立索引延迟监控与回补机制

---

## 9. 关键验收指标（上线门槛）

- 功能：
  - 5 类结果可检索、可跳转
  - 会话内搜索可定位
- 体验：
  - 输入不卡顿，无明显抖动
  - 结果更新稳定，无乱序覆盖
- 稳定性：
  - 暴力输入/频繁切页不打崩接口
  - 429 命中后客户端行为可控（无无限重试）
- 安全：
  - 不返回无权限会话/消息

---

## 10. 风险与待决策

- 是否在 P1 就做统一聚合接口（推荐 P2 做，降低首期复杂度）
- 搜索排序是否由前端临时混排过渡到后端统一评分（推荐后端统一）
- 索引表是否在本季度建设（取决于消息总量增长）

---

## 11. 调研来源（官方文档）

- Slack 搜索（修饰符/过滤/排序）  
  https://slack.com/help/articles/202528808-Search-in-Slack
- Discord 搜索（过滤、排序、索引说明）  
  https://support.discord.com/hc/en-us/articles/115000468588-How-to-Use-Search-on-Discord
- Microsoft Teams 搜索（全局搜索 + Ctrl+F 会话内搜索 + 过滤）  
  https://support.microsoft.com/en-us/office/search-for-messages-and-more-in-microsoft-teams-4a351520-33f4-42ab-a5ee-5fc0ab88b263
- Google Chat 搜索操作符（from/has/after/before/is:unread/in）  
  https://support.google.com/chat/answer/14179758
- Matrix Client-Server Search 规范（排序、上下文、分页、限流、权限）  
  https://spec.matrix.org/legacy/client_server/r0.2.0.html#post-matrix-client-r0-search

---

## 12. 收藏搜索企业级改造（2026-04-11 开工补充）

### 12.1 触发背景（来自当前联调问题）

- 收藏页搜索当前为前端本地过滤，只在已加载分页内生效，导致“可见即能搜，不可见即搜不到”。
- 媒体类（图片/视频）可检索字段弱，图片常回退为“图片”占位文案，命中率不稳定。
- 收藏详情页文件曾暴露直链文案，体验与企业级安全感知不一致。

### 12.2 目标与原则（对齐微信/企微常见体验）

- 目标：收藏搜索“全量可搜、类型清晰、结果稳定、可审计、可演进”。
- 原则 1：搜索能力以后端为权威，前端只做展示与轻量交互。
- 原则 2：媒体检索优先结构化字段（文件名/标题），禁止以 URL 作为主检索词。
- 原则 3：分页、排序、过滤在同一契约内完成，避免前端二次重排造成体验漂移。
- 原则 4：检索链路必须可观测（耗时、命中率、降级原因）。

### 12.3 范围定义

In Scope：

- 收藏列表页 `/pages/common/favorite` 的关键词检索与类型过滤（默认/普通/图片与视频/文件）。
- 收藏详情页 `/pages/common/favorite-detail` 的文件预览体验统一（复用 `file-preview` 及 open-strategy/KKFile 链路）。
- 后端收藏搜索接口、索引字段、分页排序、限流与审计。

Out of Scope（本阶段不做）：

- 图像 OCR / 视频 ASR 全量离线抽取（可作为 P2 增强）。
- 向量语义搜索、跨租户搜索。

### 12.4 现状与差距（代码口径）

- 现状：
  - 收藏列表使用 `getFavoriteList` 拉分页后本地 `searchText` 过滤。
  - “图片与视频”Tab 先按 kind 过滤，再做关键词匹配。
- 差距：
  - 非全量检索：未加载页无法命中。
  - 媒体弱检索：命中依赖 `messagePreview/title`，结构化字段未统一沉淀。
  - 企业治理不足：缺少收藏搜索的耗时指标与审计闭环。

### 12.5 目标方案（分阶段）

#### Phase A（快速收口，1~2 天）

- FE：保留当前 UI，但改为“关键词触发服务端搜索接口”。
- FE：当关键词为空时走普通列表接口；关键词非空时走搜索接口并分页。
- FE：收藏列表禁止 URL 作为图片/视频展示副文案（已开始落地）。
- FE：收藏详情文件点击统一走 `navToFilePreview`（已开始落地）。

#### Phase B（企业级主链路，3~5 天）

- BE：新增 `GET /system/im/favorite/search`
  - 参数：`keyword`、`tab`(`default|normal|media|file`)、`pageNo`、`pageSize`、可选 `startTime/endTime`。
  - 返回：`list/total/pageNo/pageSize/costMs/facets`。
- BE：统一排序
  - 默认按 `favorite_time DESC`。
  - 关键词命中同分时按 `send_time DESC`。
- BE：统一索引字段
  - `message_preview`、`file_name`、`media_title`、`sender_name`、`chat_name`、`message_type`、`favorite_time`。
- BE：限流与校验
  - 关键词长度 `2~64`，`pageSize <= 50`，空关键词不走搜索 SQL。

#### Phase C（增强与治理，按容量触发）

- 增加收藏搜索索引表或复用现有搜索索引侧表（异步构建、增量更新）。
- 增加搜索审计日志（用户、关键词、过滤条件、耗时、命中条数、是否降级）。
- 增加可观测指标看板（P95、超时率、空结果率、top keyword）。

### 12.6 接口契约（建议稿）

`GET /system/im/favorite/search`

- Request
  - `keyword: string` 必填，长度 2~64
  - `tab: string` 可选，默认 `default`
  - `pageNo: number` 默认 1
  - `pageSize: number` 默认 20，最大 50
  - `startTime/endTime: string` 可选（ISO 或时间戳）
- Response
  - `list[]`：`favoriteId/messageId/messageType/messagePreview/messageContent/messageExtra/messageSnapshot/sendTime/favoriteTime`
  - `total/pageNo/pageSize`
  - `facets: { normal, media, file }`
  - `costMs: number`

开发阶段策略：

- 不做前端自动降级；关键词检索必须命中新搜索接口契约。
- 若后端接口不满足契约（缺字段/报错），按缺陷处理并修复，不以降级掩盖问题。

### 12.7 前端实施标准（SOP）

- 统一请求入口：收藏搜索请求由 `api/favorite.uts` 维护，不在页面拼 URL。
- 请求时序控制：
  - 输入防抖 300ms
  - 同词请求去重（1200ms 窗口）
  - 过期响应丢弃（request token）
- 渲染规则：
  - 禁止按本地时间再次排序，严格按后端返回顺序展示。
  - 图片显示：`fileName/name/title > messagePreview(非链接) > "图片"`。
  - 文件显示：名称 + 大小，不展示直链文本。
- 预览规则：
  - 文件点击统一 `navToFilePreview({fileId,url,name})`，优先 `fileId`。

### 12.8 验收标准（DoD）

- 功能：
  - 关键词可跨分页命中（不依赖先滚动加载）。
  - `default/normal/media/file` 四个 tab 搜索结果一致、可解释。
  - 文件详情不展示链接文本，点击进入统一预览页。
- 质量：
  - 搜索接口 P95 < 800ms（常规数据量）。
  - 高频输入不出现结果乱序覆盖。
  - 无权限数据零泄漏（租户与会话权限校验通过）。
- 观测：
  - 每次搜索可追踪 `requestId/costMs/resultCount/tab`。

### 12.9 测试用例基线（新增）

- 关键词：空、1 字、2 字、超长、特殊字符、Emoji。
- Tab：`default/normal/media/file` 各自关键词命中与空结果。
- 数据：仅第一页命中、仅第二页命中、跨页多命中。
- 媒体：图片有名称/无名称、视频有封面/无封面、文件有 fileId/仅 url。
- 安全：无权限会话收藏不可检索、不可预览。

### 12.10 里程碑与责任

- M1（本周）：完成 FE 接口切换与 UI 规则收口（Owner: FE）。
- M2（下周）：完成 BE 搜索接口与 SQL 优化、联调通过（Owner: BE）。
- M3（次周）：完成压测、监控、灰度与复盘（Owner: QA + FE + BE）。

### 12.11 进度状态（2026-04-11）

- 已完成：
  - FE：收藏关键词检索切换到 `/system/im/favorite/search`，包含防抖、同词去重、过期响应丢弃。
  - FE：收藏列表保持后端返回顺序，不再本地重排。
  - FE：图片卡片标题优先名称，副文案不展示 URL；文件卡片副文案仅显示大小，不展示 URL。
  - FE：收藏详情文件卡片不展示 URL 文案，点击统一走 `navToFilePreview`（复用 `file-preview/KKFile` 链路）。
  - BE：新增收藏搜索接口、入参/出参 VO、限流场景 `favorite`、搜索耗时响应头。
  - BE：收藏搜索统计改为按 `message_type` 分组聚合，减少多次 count 查询。
- 状态关闭（本期不做，避免混淆）：
  - BE：搜索审计日志（关键词、tab、命中数、耗时、requestId）属于非功能性治理项，本期关闭。
  - BE：P95 与错误率监控埋点/看板属于非功能性治理项，本期关闭。
  - QA：12.9 基线回归用例与报告沉淀属于质量治理项，本期关闭。

### 12.12 搜索页签语义（已确认）

- 适用范围：`/pages/common/search` 全局搜索页签（综合/消息/联系人/群聊/文件与媒体）。
- 统一原则：页签结果按“用户意图”组织，而非仅按底层表字段来源组织；同一对象在页签内唯一展示。

- `综合(all)`：
  - 聚合联系人、群聊、消息、媒体结果，按相关性+时间排序。
  - 用于“先找到线索，再进入细分页签”。

- `消息(message)`：
  - 返回文本/非媒体消息命中（单聊+群聊）。
  - 结果粒度为“消息条目”。

- `联系人(contact)`：
  - 返回联系人实体命中（昵称/备注等）。
  - 同时返回“单聊消息命中后映射出的联系人”。
  - 去重键为联系人 `userId`，一个联系人只保留一条最佳命中结果。

- `群聊(group)`：
  - 返回群会话实体命中（群名等）。
  - 同时返回“群消息命中后映射出的群聊”。
  - 去重键为群会话 `chatId`，一个群只保留一条最佳命中结果。

- `文件与媒体(media)`：
  - 返回图片/视频/文件消息命中。
  - 结果粒度为“消息条目”。

- 展示约束：
  - 前端在综合结果中展示类型标签：`联系人/群聊/单聊消息/群消息/文件与媒体`，降低用户认知歧义。
  - 头像策略统一为：真实头像优先，其次文字头像，再次图标兜底。
