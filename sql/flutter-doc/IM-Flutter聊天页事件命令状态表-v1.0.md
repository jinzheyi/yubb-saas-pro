# IM Flutter 聊天页事件-命令-状态表 v1.0

> 文档日期：2026-04-29  
> 文档定位：聊天页核心事件、controller 动作、状态迁移总表  

---

## 1. 目标

把聊天页最关键的交互流压缩成可执行表，便于编码和测试。

---

## 2. 页面初始化

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 打开聊天页 | `initialize(args)` | `initial -> initializing` |
| 解析 latest | `openLatest()` | `initializing -> loadingWindow` |
| 解析 anchor | `openAnchor()` | `initializing -> loadingWindow` |
| 解析 restore | `openRestore()` | `initializing -> restoringViewport` |
| 首屏消息加载成功 | `mergeWindow()` | `loadingWindow -> ready` |
| 初始化失败 | `retryInitialize()` | `loadingWindow -> failed` |

---

## 3. 时间线事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 顶部触底加载历史 | `loadOlder()` | `ready -> loadingHistory` |
| 历史加载成功 | `mergeWindow()` | `loadingHistory -> ready` |
| 历史加载失败 | `loadOlder()` | `loadingHistory -> ready` |
| 点击引用定位 | `locateQuote()` | `ready -> locatingAnchor -> ready` |

---

## 4. 发送消息事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 点击发送文本 | `sendText()` | `ready -> sending` |
| 文本发送成功 | `sendMessageUseCase` 返回 | `sending -> ready` |
| 文本发送失败 | `sendMessageUseCase` 抛错 | `sending -> ready` |
| 发送图片/文件/视频/语音 | `sendImage/sendFile/sendVideo/sendVoice` | `ready -> sending -> ready` |

---

## 5. 实时消息事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| socket 收到新消息 | `appendRealtimeMessage()` | `ready -> ready` |
| socket 收到撤回 | `mergeRealtimeRecall()` | `ready -> ready` |
| socket 收到系统提示 | `appendRealtimeMessage()` | `ready -> ready` |
| socket 收到 badge hint | `refreshVisibleBadgeState()` | `ready -> ready` |

---

## 6. 补偿与重连事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| socket 断开 | `handleSocketDisconnected()` | `ready -> reconnecting` |
| socket 恢复 | `pullMessagesAfterReconnect()` | `reconnecting -> ready` |
| reconnect 补偿失败 | `retryCompensation()` | `reconnecting -> ready` |

---

## 7. 已读与未听事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 消息可见范围变化 | `applyVisibleReadWatermark()` | `ready -> ready` |
| 页面离开 | `flushReadWatermark()` | `ready -> flushing -> ready` |
| 语音播放完成 | `markVoicePlayed()` | `ready -> ready` |
| 页面离开 | `flushVoicePlayed()` | `ready -> flushing -> ready` |

---

## 8. 消息操作事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 撤回消息 | `recallMessage()` | `ready -> pendingAction.recalling -> ready` |
| 删除消息 | `deleteMessage()` | `ready -> pendingAction.deleting -> ready` |
| 收藏消息 | `addFavorite()` | `ready -> pendingAction.savingFavorite -> ready` |
| 转发消息 | `forwardMessages()` | `ready -> pendingAction.forwarding -> ready` |

---

## 9. 输入区事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 切换输入模式 | `toggleInputMode()` | `text <-> voice` |
| 进入引用编辑 | `enterQuote()` | `textEditing -> quoteEditing` |
| 取消引用 | `clearQuote()` | `quoteEditing -> textEditing` |
| 展开更多面板 | `toggleExpanded()` | `collapsed <-> expanded` |
| 开始录音 | `startVoiceRecord()` | `idle -> recording` |
| 取消录音 | `cancelVoiceRecord()` | `recording -> idle` |
| 完成录音 | `finishVoiceRecord()` | `recording -> recorded/uploading -> idle` |

---

## 10. 测试建议

优先为以下事件流做测试：

1. `initialize -> openLatest -> ready`
2. `initialize -> openAnchor -> highlight -> ready`
3. `sendText -> success`
4. `sendText -> failed`
5. `socket disconnected -> reconnecting -> pull -> ready`
6. `page leave -> flushReadWatermark`

