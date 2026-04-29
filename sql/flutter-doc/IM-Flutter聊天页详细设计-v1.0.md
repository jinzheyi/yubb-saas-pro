# IM Flutter 聊天页详细设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：`ChatPage` 的企业级实现设计，覆盖 controller、state、usecase、事件流、组件树、交互约束  

---

## 1. 设计目标

`ChatPage` 是 IM 客户端最复杂的页面，必须作为独立子系统设计，而不是普通页面。

目标：

- 支持 latest / anchor / restore 三种进入模式
- 支持多消息类型
- 支持实时消息与断线补偿
- 支持视口恢复
- 支持已读与语音未听同步
- 支持引用、转发、撤回、收藏
- 支持多端一致的状态推进

功能覆盖与高频交互验收以 `IM-Flutter功能覆盖与交互验收清单-v1.0.md` 为总基线。

---

## 2. 页面职责边界

### 2.1 页面负责

- 渲染聊天页面壳
- 组合 timeline、composer、action sheet、more panel
- 派发用户动作

### 2.2 页面不负责

- 直接调 API
- 合并消息最终态
- 维护 websocket 生命周期
- 直接推进已读水位
- 直接处理上传队列

---

## 3. 顶层对象设计

### 3.1 页面对象

- `ChatPage`
- `ChatPageScaffold`

### 3.2 控制器对象

- `ChatController`
- `ChatTimelineController`
- `ChatComposerController`
- `ChatMediaController`
- `ChatReceiptController`
- `ChatViewportController`

### 3.3 application use case

- `OpenChatUseCase`
- `LoadChatWindowUseCase`
- `LoadOlderMessagesUseCase`
- `LocateMessageUseCase`
- `SendMessageUseCase`
- `RecallMessageUseCase`
- `DeleteMessageUseCase`
- `ForwardMessagesUseCase`
- `AddFavoriteUseCase`
- `MarkConversationReadUseCase`
- `SyncVoicePlayedUseCase`
- `RestoreViewportUseCase`
- `PersistViewportUseCase`

---

## 4. `ChatController` 设计

### 4.1 职责

- 编排聊天页初始化
- 管理子控制器依赖
- 处理页面级动作
- 协调页面离开时 flush

### 4.2 公开动作

- `initialize(ChatEntryArgs args)`
- `retryInitialize()`
- `handleAppResume()`
- `handleSocketEvent(ChatDomainEvent event)`
- `handleBackPressed()`
- `flushBeforeLeave()`

### 4.3 依赖

- `OpenChatUseCase`
- `ChatTimelineController`
- `ChatComposerController`
- `ChatReceiptController`
- `ChatViewportController`
- `ConversationListBridge`

---

## 5. `ChatPageState` 设计

### 5.1 顶层状态

- `entryArgs`
- `chatHeader`
- `pageStatus`
- `isReadOnly`
- `isMultiSelectMode`
- `highlightedMessageId`
- `pendingAction`
- `error`

### 5.2 `pageStatus`

枚举：

- `initial`
- `initializing`
- `loadingWindow`
- `restoringViewport`
- `ready`
- `reconnecting`
- `failed`

### 5.3 `pendingAction`

枚举：

- `none`
- `sending`
- `recalling`
- `deleting`
- `forwarding`
- `savingFavorite`
- `flushing`

---

## 6. `ChatTimelineController` 设计

### 6.1 职责

- 管理消息窗口
- 管理历史翻页
- 管理 anchor 定位
- 合并实时消息与 pull 补偿消息
- 管理消息列表最终态

### 6.2 公开动作

- `openLatest(ChatEntryArgs args)`
- `openAnchor(ChatEntryArgs args)`
- `openRestore(ChatEntryArgs args)`
- `loadOlder()`
- `appendRealtimeMessage(Message message)`
- `mergePulledMessages(List<Message> messages)`
- `mergeWindow(List<Message> messages)`
- `locateQuote(String messageId)`
- `highlightMessage(String messageId)`

### 6.3 状态

- `timelineStatus`
- `messages`
- `oldestLoadedSequence`
- `newestLoadedSequence`
- `anchorMessageId`
- `hasMoreOlder`
- `isAnchorLocated`

### 6.4 `timelineStatus`

- `empty`
- `loading`
- `ready`
- `locatingAnchor`
- `loadingOlder`
- `failed`

### 6.5 合并规则

1. `messageId` 相同，按更大 `rev` 覆盖
2. 同步窗口数据不可回退已存在最终态
3. `sequence` 作为排序基准
4. 本地发送态消息在服务端确认后做归并替换

---

## 7. `ChatComposerController` 设计

### 7.1 职责

- 输入模式管理
- 草稿管理
- 引用编辑态管理
- 发送动作触发
- 录音输入状态机

### 7.2 状态

- `inputMode`
- `draftText`
- `quotedMessage`
- `isExpanded`
- `voiceRecordState`
- `sendingQueueState`

### 7.3 `inputMode`

- `text`
- `voice`

### 7.4 `voiceRecordState`

- `idle`
- `recording`
- `recorded`
- `uploading`
- `failed`

### 7.5 公开动作

- `updateDraft(String text)`
- `toggleInputMode()`
- `enterQuote(Message message)`
- `clearQuote()`
- `toggleExpanded()`
- `sendText()`
- `sendImage()`
- `sendFile()`
- `sendVideo()`
- `sendVoice()`
- `sendLocation()`
- `sendContactCard()`
- `startVoiceRecord()`
- `cancelVoiceRecord()`
- `finishVoiceRecord()`

---

## 8. `ChatMediaController` 设计

### 8.1 职责

- 处理文件上传
- 处理图片/视频预览
- 处理语音播放
- 处理文件打开策略

### 8.2 子能力

- `ChatUploadCoordinator`
- `AudioPlaybackCoordinator`
- `VideoPlaybackCoordinator`
- `FileOpenCoordinator`

上传主链路的完整规则以 `IM-Flutter文件上传与发送链路设计-v1.0.md` 为准。

### 8.3 公开动作

- `pickAndUploadImage()`
- `pickAndUploadFile()`
- `pickAndUploadVideo()`
- `playVoice(Message message)`
- `pauseVoice(Message message)`
- `resumeVoice(Message message)`
- `openFile(Message message)`
- `previewImage(Message message)`
- `playVideo(Message message)`

---

## 9. `ChatReceiptController` 设计

### 9.1 职责

- 推进会话已读水位
- 聚合语音已播放上报
- 页面离开时 flush
- 处理回执详情入口数据

### 9.2 状态

- `readSyncState`
- `voicePlayedSyncState`
- `lastPendingReadSequence`
- `pendingVoicePlayedMessageIds`

### 9.3 公开动作

- `applyVisibleReadWatermark(String sequence)`
- `flushReadWatermark()`
- `markVoicePlayed(String messageId)`
- `flushVoicePlayed()`
- `openReadReceiptSummary(Message message)`

---

## 10. `ChatViewportController` 设计

### 10.1 职责

- 保存视口恢复信息
- 恢复滚动定位
- 统一移动端和 Web 可见性时机

### 10.2 公开动作

- `captureViewport()`
- `persistViewport()`
- `loadViewport()`
- `restoreViewport()`
- `clearExpiredViewport()`

### 10.3 恢复优先级

1. anchor
2. restore
3. latest

---

## 11. UseCase 详细契约

### 11.1 `OpenChatUseCase`

输入：

- `ChatEntryArgs`

输出：

- `OpenChatResult`

字段：

- `chatHeader`
- `resolvedEntryMode`
- `initialWindow`
- `viewportState`

### 11.2 `LoadChatWindowUseCase`

输入：

- `chatId`
- `entryMode`
- `anchorSequence`
- `anchorMessageId`

输出：

- `ChatWindowResult`

### 11.3 `SendMessageUseCase`

输入：

- `SendMessageCommand`

输出：

- `SendMessageResult`

### 11.4 `LocateMessageUseCase`

输入：

- `chatId`
- `messageId`
- `sequence`

输出：

- `LocateMessageResult`

---

## 12. 消息类型渲染体系

### 12.1 工厂

- `MessageBubbleFactory`

### 12.2 渲染组件

- `TextMessageBubble`
- `ImageMessageBubble`
- `VideoMessageBubble`
- `VoiceMessageBubble`
- `FileMessageBubble`
- `LocationMessageBubble`
- `ContactCardBubble`
- `StickerMessageBubble`
- `QuoteMessageBubble`
- `MergedForwardBubble`
- `SystemTipBubble`

### 12.3 约束

- 页面主文件不能用超长 `switch/if` 渲染所有类型
- 每类消息单独文件、单独 props

---

## 13. 页面组件树

```text
ChatPage
  ChatAppBar
  ChatNoticeBanner
  ChatTimeline
    MessageTimeSeparator
    MessageItem
      MessageBubbleFactory
  ChatComposer
    QuoteEditorBar
    TextComposer
    VoiceComposer
    ComposerActions
  ChatMorePanel
  ChatActionSheet
  ChatReadReceiptSheet
```

---

## 14. 企业级交互规则

1. 进入聊天页后不应阻塞输入过久。
2. 历史加载不得抖动当前可视区。
3. 撤回、删除、转发、收藏动作必须可追踪 pending 状态。
4. 引用定位失败后必须有可恢复反馈。
5. 页面离开时必须 flush 已读与语音状态。
6. 文件、图片、视频打开都要经过统一策略层。

---

## 15. 多端适配点

### 15.1 Mobile

- 键盘顶起
- 录音权限
- 图片/视频选取

### 15.2 Web

- 页面可见性
- 文件下载策略
- 大图预览

### 15.3 Desktop

- 双栏布局
- 窗口尺寸变更
- 拖拽文件上传

---

## 16. 测试清单

### 16.1 单元测试

- timeline merge by `rev`
- anchor locate state flow
- read watermark flush
- voice played batching
- local pending -> server ack merge

### 16.2 集成测试

- latest open
- anchor open
- restore open
- send text/image/file/voice
- recall
- quote locate
- pull compensation after reconnect
