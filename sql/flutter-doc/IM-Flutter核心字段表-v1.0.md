# IM Flutter 核心字段表 v1.0

> 文档日期：2026-04-29  
> 文档定位：核心 entity、state、command、result、dto 的字段表  

---

## 1. 目标

把核心对象字段收口成可直接建类的表结构，减少后续实现时自由发挥。

---

## 2. Entity 字段表

### 2.1 `Conversation`

| 字段 | 类型 | 说明 |
|---|---|---|
| chatId | String | 会话主键 |
| conversationType | int | 1 单聊 / 2 群聊 |
| targetId | String | 对端 userId 或 groupId |
| targetName | String | 标题 |
| targetAvatar | String | 头像 |
| lastMessageType | int | 最后一条消息类型 |
| lastMessageContent | String | 摘要 |
| lastMessageHasAtMe | bool | 是否 @我 |
| lastMessageTime | int | 时间戳 ms |
| lastMessageSequence | String | 最后一条消息序列 |
| lastReadSequence | String | 已读水位 |
| unreadCount | int | 未读数 |
| isPinned | bool | 是否置顶 |
| noDisturb | bool | 免打扰 |
| groupMemberCount | int | 群成员数 |
| conversationVersion | String | 合并版本 |

### 2.2 `Message`

| 字段 | 类型 | 说明 |
|---|---|---|
| messageId | String | 消息主键 |
| chatId | String | 所属会话 |
| senderId | String | 发送者 |
| receiverId | String | 接收者 |
| groupId | String? | 群 ID |
| sequence | String | 消息序列 |
| rev | String | 最终态版本 |
| type | MessageType | 消息类型 |
| status | MessageStatus | 发送状态 |
| content | MessageBody | 消息体 |
| extra | MessageExtra | 扩展字段 |
| quote | QuoteInfo? | 引用信息 |
| createdAt | int | 时间戳 ms |
| isSelf | bool | 是否自己发送 |

### 2.3 `GroupInfo`

| 字段 | 类型 | 说明 |
|---|---|---|
| groupId | String | 群主键 |
| chatId | String | 群对应 chatId |
| name | String | 群名 |
| avatar | String | 群头像 |
| ownerId | String | 群主 ID |
| ownerName | String | 群主名 |
| memberCount | int | 成员数 |
| notice | String | 公告 |
| muteAll | bool | 全员禁言 |
| allowMemberInvite | bool | 成员可邀请 |
| needApproval | bool | 入群需审批 |
| myRole | GroupMemberRole | 我的角色 |

### 2.4 `Contact`

| 字段 | 类型 | 说明 |
|---|---|---|
| userId | String | 用户 ID |
| nickname | String | 昵称 |
| remarkName | String | 备注 |
| avatar | String | 头像 |
| deptName | String | 部门 |
| postName | String | 职位 |
| pinyin | String | 索引拼音 |
| star | bool | 是否星标 |

---

## 3. State 字段表

### 3.1 `ConversationListState`

| 字段 | 类型 | 说明 |
|---|---|---|
| status | LoadStatus | 页面状态 |
| conversations | List<ConversationUiModel> | 会话列表 |
| cursorVersion | String | 当前游标 |
| selectedFilter | ConversationFilterType | 当前筛选 |
| inlineNotice | String? | 行内提示 |
| error | AppError? | 异常 |

### 3.2 `ChatPageState`

| 字段 | 类型 | 说明 |
|---|---|---|
| entryArgs | ChatEntryArgs | 路由参数 |
| chatHeader | ChatHeaderUiModel | 顶部信息 |
| pageStatus | ChatPageStatus | 页面状态 |
| isReadOnly | bool | 是否只读 |
| isMultiSelectMode | bool | 多选模式 |
| highlightedMessageId | String? | 高亮消息 |
| pendingAction | ChatPendingAction | 执行动作 |
| error | AppError? | 错误 |

### 3.3 `ChatTimelineState`

| 字段 | 类型 | 说明 |
|---|---|---|
| timelineStatus | ChatTimelineStatus | 时间线状态 |
| messages | List<MessageUiModel> | 消息列表 |
| oldestLoadedSequence | String | 最早已加载 |
| newestLoadedSequence | String | 最新已加载 |
| anchorMessageId | String? | 当前锚点 |
| hasMoreOlder | bool | 是否还有更早消息 |

### 3.4 `GlobalSearchState`

| 字段 | 类型 | 说明 |
|---|---|---|
| keyword | String | 当前关键词 |
| activeTab | SearchTab | 当前 tab |
| status | LoadStatus | 状态 |
| results | List<SearchResultUiModel> | 结果 |
| hasMore | bool | 是否可加载更多 |
| isLoadingMore | bool | 是否正在加载更多 |
| error | AppError? | 错误 |

---

## 4. Command 字段表

### 4.1 `OpenChatCommand`

| 字段 | 类型 | 说明 |
|---|---|---|
| chatId | String | 会话 ID |
| entryMode | ChatEntryMode | 进入模式 |
| anchorSequence | String? | 锚点序列 |
| anchorMessageId | String? | 锚点消息 ID |
| restoreKey | String? | 恢复 key |

### 4.2 `SendMessageCommand`

| 字段 | 类型 | 说明 |
|---|---|---|
| chatId | String | 会话 ID |
| type | MessageType | 消息类型 |
| body | MessageBody | 消息体 |
| quoteMessageId | String? | 引用消息 ID |
| clientTempId | String | 本地临时 ID |

### 4.3 `ForwardMessagesCommand`

| 字段 | 类型 | 说明 |
|---|---|---|
| targetChatId | String | 目标会话 |
| messageIds | List<String> | 消息 ID 列表 |
| forwardType | int | 1 逐条 / 2 合并 |
| comment | String? | 附言 |

---

## 5. Result 字段表

### 5.1 `OpenChatResult`

| 字段 | 类型 | 说明 |
|---|---|---|
| chatHeader | ChatHeaderUiModel | 头部信息 |
| resolvedEntryMode | ChatEntryMode | 最终模式 |
| initialMessages | List<Message> | 首屏消息 |
| viewportState | ChatViewportState? | 恢复数据 |

### 5.2 `ChatWindowResult`

| 字段 | 类型 | 说明 |
|---|---|---|
| messages | List<Message> | 消息窗口 |
| oldestSequence | String | 最早序列 |
| newestSequence | String | 最新序列 |
| hasMoreOlder | bool | 是否有更早消息 |

### 5.3 `ConversationSyncResult`

| 字段 | 类型 | 说明 |
|---|---|---|
| cursorVersion | String | 新游标 |
| conversations | List<Conversation> | 增量结果 |
| hasMore | bool | 是否还有分页 |

---

## 6. DTO 字段表

### 6.1 `ConversationDto`

建议字段：

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

### 6.2 `MessageDto`

建议字段：

- `messageId`
- `chatId`
- `senderId`
- `receiverId`
- `groupId`
- `sequence`
- `rev`
- `type`
- `content`
- `extra`
- `quoteMessageId`
- `createTime`

### 6.3 `GroupInfoDto`

建议字段：

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

---

## 7. DTO -> Entity 映射规则

1. 所有 ID 字段统一 `String(value ?? '')`
2. 所有时间统一转毫秒
3. `sequence` / `rev` / `cursorVersion` 统一保留原字符串
4. `content` / `extra` 统一在 mapper 层解析

