# IM Flutter 数据模型与存储设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：核心实体、字段原则、本地存储策略、缓存结构  

---

## 1. 字段总原则

1. 所有 ID、版本号、序列号使用 `String`
2. 时间统一使用明确语义字段：
   - `DateTime`
   - 或 `int millisecondsSinceEpoch`
3. DTO 与 Entity 字段命名允许不同，但语义必须稳定

---

## 2. Auth 模型

### 2.1 `AuthToken`

字段：

- `accessToken`
- `refreshToken`
- `expiresAt`
- `refreshExpiresAt`

### 2.2 `CurrentUser`

字段：

- `userId`
- `tenantId`
- `nickname`
- `avatar`
- `deptId`
- `deptName`
- `postName`

### 2.3 `DeviceInfo`

字段：

- `deviceType`
- `deviceId`
- `clientVersion`
- `deviceName`

---

## 3. 会话模型

### 3.1 `Conversation`

字段：

- `chatId`
- `conversationType`
- `targetId`
- `targetName`
- `targetAvatar`
- `lastMessageType`
- `lastMessageContent`
- `lastMessageHasAtMe`
- `lastMessageTime`
- `lastMessageSequence`
- `lastReadSequence`
- `unreadCount`
- `isPinned`
- `noDisturb`
- `groupMemberCount`
- `conversationVersion`

### 3.2 `ConversationCursorState`

字段：

- `userId`
- `tenantId`
- `cursorVersion`
- `updatedAt`

---

## 4. 聊天入口与视口模型

### 4.1 `ChatEntryArgs`

- `chatId`
- `conversationType`
- `targetId`
- `title`
- `entryMode`
- `anchorSequence`
- `anchorMessageId`
- `restoreKey`

### 4.2 `ChatViewportState`

- `entryMode`
- `atBottom`
- `viewportAnchorSequence`
- `topVisibleSequence`
- `bottomVisibleSequence`
- `savedAt`

---

## 5. 消息模型

### 5.1 `Message`

字段：

- `messageId`
- `chatId`
- `senderId`
- `receiverId`
- `groupId`
- `sequence`
- `rev`
- `type`
- `status`
- `content`
- `extra`
- `quote`
- `createdAt`
- `isSelf`

### 5.2 `MessageExtra`

字段：

- `fileId`
- `duration`
- `durationMs`
- `size`
- `format`
- `md5`
- `mentionUserIds`
- `recallBy`
- `recallTime`
- `quoteContent`
- `quoteSenderName`

### 5.3 `QuoteInfo`

字段：

- `quoteMessageId`
- `quoteSenderId`
- `quoteSenderName`
- `quoteContent`

---

## 6. 群模型

### 6.1 `GroupInfo`

- `groupId`
- `chatId`
- `name`
- `avatar`
- `ownerId`
- `ownerName`
- `memberCount`
- `notice`
- `muteAll`
- `allowMemberInvite`
- `needApproval`
- `myRole`

### 6.2 `GroupMember`

- `userId`
- `userName`
- `avatar`
- `role`
- `nickname`
- `joinTime`
- `muteEndTime`

---

## 7. 联系人模型

### 7.1 `Contact`

- `userId`
- `nickname`
- `remarkName`
- `avatar`
- `deptName`
- `postName`
- `pinyin`
- `star`

### 7.2 `DeptNode`

- `deptId`
- `parentId`
- `name`
- `children`

---

## 8. 搜索与收藏模型

### 8.1 `GlobalSearchItem`

- `id`
- `type`
- `title`
- `subTitle`
- `snippet`
- `time`
- `chatId`
- `messageId`
- `sequence`

### 8.2 `FavoriteItem`

- `favoriteId`
- `messageId`
- `chatId`
- `type`
- `summary`
- `createdAt`

---

## 9. badge 与回执模型

### 9.1 `BadgeState`

- `totalUnread`
- `conversationBadges`
- `menuBadges`
- `updatedAt`

### 9.2 `ReadReceiptSummary`

- `messageId`
- `readCount`
- `unreadCount`

### 9.3 `VoicePlayedState`

- `messageId`
- `chatId`
- `played`
- `updatedAt`

---

## 10. Storage Key Registry

统一定义：

- `auth.token`
- `auth.current_user`
- `app.theme_mode`
- `app.language_mode`
- `im.badge_state`
- `im.search_history`
- `im.chat_draft.{chatId}`
- `im.viewport.{chatId}`
- `im.conversation_cursor.{tenantId}.{userId}`

说明：

- `app.theme_mode` 与 `app.language_mode` 仅做设备本地保存
- 主题与语言不要求跨端同步
- 仅聊天气泡偏好要求服务端统一

规则：

- 通过统一 registry 构造，不允许散落硬编码

---

## 11. 本地数据库表建议

### 11.1 conversations

- `chat_id`
- `target_id`
- `target_name`
- `conversation_type`
- `last_message_sequence`
- `last_read_sequence`
- `unread_count`
- `conversation_version`
- `updated_at`

### 11.2 messages

- `message_id`
- `chat_id`
- `sequence`
- `rev`
- `sender_id`
- `type`
- `content_json`
- `extra_json`
- `status`
- `created_at`

### 11.3 message_quotes

- `message_id`
- `quote_message_id`
- `quote_sender_name`
- `quote_content`

### 11.4 voice_played

- `message_id`
- `chat_id`
- `played`
- `updated_at`

---

## 12. 缓存策略

### 12.1 会话

- 列表缓存允许本地启动快速展示
- 最终态以服务端 sync 为准

### 12.2 消息

- 当前聊天窗口本地缓存
- 历史按 chatId + sequence 索引

### 12.3 搜索

- 搜索历史本地缓存
- 热搜允许 TTL 缓存

---

## 13. Mapper 规范

1. DTO -> Entity 映射集中实现
2. Entity -> UIModel 映射集中实现
3. 所有 string id 在 mapper 层统一规范化
