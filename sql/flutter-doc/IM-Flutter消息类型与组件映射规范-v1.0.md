# IM Flutter 消息类型与组件映射规范 v1.0

> 文档日期：2026-04-29  
> 文档定位：消息类型、消息模型字段、气泡组件、交互动作的统一映射规范  

---

## 1. 目标

消息类型是聊天页复杂度核心，必须统一定义：

- 消息类型枚举
- 数据字段
- UI 组件
- 支持动作
- 预览摘要规则

---

## 2. `MessageType` 枚举建议

- `text`
- `image`
- `voice`
- `video`
- `file`
- `location`
- `contactCard`
- `emoji`
- `sticker`
- `quoteReply`
- `mergedForward`
- `systemTip`
- `custom`

---

## 3. 基础消息字段

所有消息必须具备：

- `messageId`
- `chatId`
- `senderId`
- `sequence`
- `rev`
- `type`
- `status`
- `createdAt`
- `isSelf`

---

## 4. 各类型字段映射

### 4.1 text

字段：

- `text`
- `mentions`

组件：

- `TextMessageBubble`

动作：

- copy
- quote
- forward
- favorite
- recall
- delete

### 4.2 image

字段：

- `url`
- `thumbnailUrl`
- `width`
- `height`
- `fileId`

组件：

- `ImageMessageBubble`

动作：

- preview
- forward
- favorite
- recall

### 4.3 voice

字段：

- `url`
- `fileId`
- `duration`
- `durationMs`
- `size`
- `format`
- `voicePlayed`

组件：

- `VoiceMessageBubble`

动作：

- play
- pause
- resume
- forward

### 4.4 video

字段：

- `url`
- `thumbnailUrl`
- `duration`
- `width`
- `height`
- `fileId`

组件：

- `VideoMessageBubble`

动作：

- play
- preview
- forward

### 4.5 file

字段：

- `fileId`
- `fileName`
- `fileSize`
- `mimeType`
- `extension`

组件：

- `FileMessageBubble`

动作：

- open
- download
- forward

### 4.6 location

字段：

- `name`
- `address`
- `latitude`
- `longitude`
- `mapPreviewUrl`

组件：

- `LocationMessageBubble`

动作：

- openMap
- forward

### 4.7 contactCard

字段：

- `contactUserId`
- `displayName`
- `avatar`
- `deptName`
- `postName`

组件：

- `ContactCardBubble`

动作：

- openProfile
- forward

### 4.8 emoji

字段：

- `emojiKey`
- `emojiUrl`

组件：

- `EmojiMessageBubble`

### 4.9 sticker

字段：

- `stickerId`
- `stickerUrl`
- `width`
- `height`

组件：

- `StickerMessageBubble`

### 4.10 quoteReply

字段：

- `text`
- `quote`

组件：

- `QuoteReplyMessageBubble`

动作：

- locateQuote
- quote
- forward

### 4.11 mergedForward

字段：

- `title`
- `previewLines`
- `detailId`

组件：

- `MergedForwardBubble`

动作：

- openDetail
- forward

### 4.12 systemTip

字段：

- `text`
- `kind`

组件：

- `SystemTipBubble`

---

## 5. 预览摘要规则

### 5.1 会话列表摘要

- 文本：正文截断
- 图片：`[图片]`
- 语音：`[语音]`
- 视频：`[视频]`
- 文件：`[文件]`
- 位置：`[位置]`
- 名片：`[名片]`
- 表情：`[表情]`
- 合并转发：`[聊天记录]`
- 撤回：`[消息已撤回]`

### 5.2 群聊摘要

建议支持：

- `发送者: 摘要`

---

## 6. 气泡工厂规范

工厂：

- `MessageBubbleFactory`

输入：

- `MessageUiModel`

输出：

- 对应 bubble widget

规则：

1. 工厂只负责映射，不承载业务逻辑
2. Bubble widget 自身只处理表现和轻交互

---

## 7. UIModel 建议

定义：

- `MessageUiModel`

字段：

- `messageId`
- `renderType`
- `showTime`
- `showAvatar`
- `avatarText`
- `avatarUrl`
- `senderName`
- `body`
- `status`
- `isHighlighted`

---

## 8. 交互动作矩阵

### 8.1 通用动作

- quote
- forward
- favorite
- delete

### 8.2 仅本人可执行

- recall

### 8.3 媒体特有

- preview
- play
- download

---

## 9. 发送态与失败态

所有可发送消息类型都必须支持：

- localPending
- sending
- failed
- sent

组件必须支持渲染发送状态反馈。

---

## 10. 多端视觉一致性要求

1. 不同消息类型尺寸策略稳定
2. 图片/视频宽高比稳定
3. 文件气泡信息层次清晰
4. 语音气泡支持桌面与移动端交互差异

---

## 11. 测试重点

- 各消息类型 UIModel 映射
- 消息预览摘要
- `rev` 覆盖后渲染正确
- 引用定位跳转
- 媒体动作可用

