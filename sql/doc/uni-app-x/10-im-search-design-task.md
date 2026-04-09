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
- [ ] QA：排序正确性、分页一致性、跨端一致性

验收：

- [ ] 综合排序稳定
- [ ] 接口调用次数下降（前端并发请求减少）

### 8.4 P3（按容量触发）

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
