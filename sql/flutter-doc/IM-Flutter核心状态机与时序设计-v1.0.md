# IM Flutter 核心状态机与时序设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：核心交互状态机、异步时序、控制器协同  

---

## 1. 目标

把 IM 的关键复杂度前置收敛为状态机和时序规范，避免编码时继续把逻辑堆进页面。

---

## 2. 登录启动状态机

状态：

- idle
- submitting
- loginSucceeded
- bootstrapLoading
- ready
- failed

时序：

1. 用户提交凭证
2. 登录成功
3. 保存 token
4. 拉取 permission info
5. 初始化 badge
6. 建立 websocket
7. 进入主壳

---

## 3. 会话列表状态机

状态：

- initial
- loading
- refreshing
- syncing
- ready
- failed

事件：

- load
- pullToRefresh
- socketConversationHint
- badgeChanged
- conversationActionApplied

规则：

- 会话列表只允许 controller 管理排序与合并
- 页面不直接维护会话数据源

---

## 4. 聊天页主状态机

状态：

- initial
- initializing
- loadingWindow
- restoringViewport
- ready
- loadingHistory
- sending
- reconnecting
- failed

入口事件：

- openLatest
- openAnchor
- openRestore

优先级：

1. anchorSequence
2. anchorMessageId
3. restore
4. latest

---

## 5. 聊天时间线状态机

状态：

- empty
- loading
- ready
- locatingAnchor
- loadingOlder
- exhausted
- failed

规则：

- timeline 负责消息窗口与历史扩展
- composer 不直接操作 timeline 原始数据结构

---

## 6. 聊天输入区状态机

状态：

- textIdle
- textEditing
- quoteEditing
- voiceReady
- voiceRecording
- voiceRecorded
- expandedPanel

规则：

- 输入状态与消息发送状态解耦
- 录音上传状态不直接写在页面 UI 层

---

## 7. 消息发送状态机

状态：

- draft
- enqueueing
- uploading
- sending
- sent
- delivered
- read
- failed
- recalled

规则：

- 发送中消息必须有本地临时标识
- 服务端回包后进行 messageId / sequence 归并
- 最终态以 `rev` 保护

---

## 8. 引用定位状态机

状态：

- idle
- locatingLocal
- requestingAnchorWindow
- locatingAfterLoad
- highlighted
- failed

规则：

- 先本地查
- 失败后走 anchor 加载
- 不允许固定页码穷举

---

## 9. 已读与未听状态机

### 9.1 已读水位

状态：

- idle
- pendingFlush
- flushing
- synced
- failed

规则：

- readSequence 只升不降
- 页面离开时强制 flush

### 9.2 语音未听

状态：

- unplayed
- locallyPlayed
- pendingSync
- synced

规则：

- 与已读水位完全分离

---

## 10. WebSocket 状态机

状态：

- disconnected
- connecting
- probing
- authenticating
- connected
- reauthenticating
- reconnectWaiting
- invalidated

事件：

- connectRequested
- authSucceeded
- heartbeatTimeout
- closeByServer
- tokenRefreshed

---

## 11. 群设置状态机

状态：

- loading
- ready
- updatingPreference
- updatingGovernance
- performingDangerAction
- failed

规则：

- 高危动作必须串行
- 页面不允许并发执行多个群治理动作

---

## 12. 搜索状态机

状态：

- idle
- typing
- debouncing
- searching
- ready
- loadingMore
- failed

规则：

- 最小关键字长度限制
- 相同请求去抖与去重

---

## 13. 关键时序

### 13.1 401 refresh + websocket reauth

1. 某 HTTP 请求返回 401
2. refresh coordinator 发起单飞刷新
3. 其余请求进入等待队列
4. refresh 成功
5. 等待请求重放
6. socket client 触发 same-connection reauth

### 13.2 聊天页 latest 打开

1. 构造 `ChatEntryArgs.latest`
2. `ChatController` 初始化
3. 请求消息窗口
4. 注入 timeline
5. 页面 ready
6. 推进已读水位

### 13.3 聊天页 anchor 打开

1. 构造 `ChatEntryArgs.anchor`
2. 请求 anchor window
3. 定位 anchor
4. 高亮
5. ready

### 13.4 断线补偿

1. socket 断开
2. reconnect
3. reauth 成功
4. conversation incremental sync
5. per-chat pull by sequence

---

## 14. Controller 协同关系

- `ConversationListController`
  - 依赖 `ConversationRepository`
  - 监听 badge 和 socket hint

- `ChatController`
  - 编排 timeline / composer / read / media

- `ChatTimelineController`
  - 负责 window/history/pull 合并

- `ChatComposerController`
  - 负责草稿、输入模式、发送动作

- `ChatReceiptController`
  - 负责已读与未听同步

---

## 15. 编码要求

1. 所有状态机必须有明确 state class
2. 所有状态迁移必须通过 controller action
3. 禁止从 Widget 直接改状态对象内部字段

