# IM Flutter 会话角标 Socket 协同设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：会话列表、角标同步、WebSocket 事件收敛、增量同步与补偿的企业级设计  

---

## 1. 目标

把以下能力统一收口：

- 会话列表
- badge
- websocket 事件
- 增量同步
- 断线补偿

目标是保证：

- 页面体验实时
- 状态最终一致
- 多端不漂移

---

## 2. 核心对象

- `ConversationListController`
- `BadgeController`
- `SocketSessionController`
- `ConversationSyncCoordinator`
- `ConversationEventReducer`

---

## 3. 职责划分

### 3.1 `ConversationListController`

负责：

- 会话列表加载
- 会话排序
- 置顶、免打扰、删除
- 展示态未读更新

### 3.2 `BadgeController`

负责：

- 总未读
- 会话 badge
- 菜单 badge
- badge 本地缓存

### 3.3 `SocketSessionController`

负责：

- websocket session 生命周期
- auth / reauth / reconnect
- 事件流分发

### 3.4 `ConversationSyncCoordinator`

负责：

- 根据 `cursorVersion` 做增量同步
- 处理 gap
- 处理 reconnect 后补偿

---

## 4. 会话列表状态

字段：

- `status`
- `conversations`
- `cursorVersion`
- `lastSyncAt`
- `selectedFilter`
- `inlineNotice`

状态：

- `initial`
- `loading`
- `refreshing`
- `syncing`
- `ready`
- `failed`

---

## 5. badge 状态

字段：

- `totalUnread`
- `conversationBadges`
- `menuBadges`
- `updatedAt`

规则：

- badge 是独立控制器
- 但会话未读展示必须可与会话列表协同

---

## 6. WebSocket 事件分类

### 6.1 session 级

- connected
- authSucceeded
- authFailed
- reauthSucceeded
- invalidated
- reconnecting

### 6.2 conversation 级

- conversationHint
- conversationUpdated
- conversationDeleted

### 6.3 message 级

- messageReceived
- messageRecalled
- readReceiptChanged
- voicePlayedChanged

### 6.4 badge 级

- badgeUpdated

---

## 7. 协同时序

### 7.1 首次启动

1. 加载本地 conversation cache
2. 加载本地 badge cache
3. 页面快速首屏展示
4. 发起服务端 conversation full/incremental load
5. 建立 websocket
6. 收敛实时事件

### 7.2 登录后初始化

1. 拉 conversation list
2. 拉 badge
3. 连接 websocket
4. auth 成功后触发一次增量 sync

### 7.3 websocket 会话恢复

1. reconnect
2. reauth
3. conversation incremental sync
4. 按需触发 chat pull

---

## 8. `ConversationSyncCoordinator` 设计

### 8.1 输入

- current `cursorVersion`
- socket hint `cursorVersion`
- manual refresh
- reconnect success

### 8.2 输出

- new `cursorVersion`
- patched `Conversation` list

### 8.3 规则

1. `cursorVersion` 只前进
2. socket 只负责提示，不负责最终态
3. 最终态以 sync 结果为准
4. 本地列表为空但 cursor 不为空时，允许 reset sync

---

## 9. `ConversationEventReducer` 设计

输入事件：

- local action success
- socket hint
- sync result
- badge result

输出：

- new conversation state
- new badge state

规则：

1. incoming `conversationVersion` 小于等于本地版本时丢弃
2. unread 显示优先以服务端会话数据修正
3. badge 变化可即时展示，但最终态由 sync 收敛

---

## 10. 会话排序规则

排序优先级：

1. `isPinned`
2. `lastMessageTime`
3. fallback stable order

规则：

- 置顶会话内部按时间排序
- 非置顶会话内部按时间排序
- 页面层不做重复排序逻辑

---

## 11. badge 协同规则

1. 会话打开时推进读水位
2. badge 立刻尝试清除该会话显示
3. 服务端 sync 再做最终确认
4. 菜单 badge 独立维护，不从会话 badge 反推

---

## 12. 失败恢复策略

### 12.1 sync 失败

- 保留本地可见列表
- 显示轻提示
- 允许手动刷新

### 12.2 badge 失败

- 不阻塞会话列表
- 下次自动重试

### 12.3 socket 失败

- 显示 reconnecting
- 不清空本地数据

---

## 13. 测试重点

- cursorVersion 前进
- conversationVersion 防回滚
- badge 与 conversation 一致
- reconnect 后恢复
- 本地 cache + 远端 sync 合并

