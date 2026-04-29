# IM Flutter UseCase 与数据访问分层设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：UseCase、Command/Result、Repository、DataSource、DTO 的企业级分层设计  

---

## 1. 目标

把 application / domain / infrastructure 的分层落实到可直接建文件的层级。

---

## 2. UseCase 规则

### 2.1 命名

- `VerbNounUseCase`

示例：

- `OpenChatUseCase`
- `LoadConversationListUseCase`
- `SendMessageUseCase`

### 2.2 输入输出

复杂 use case 必须显式定义：

- `Command`
- `Result`

简单场景允许直接以单值入参返回 Entity。

---

## 3. Chat UseCase 清单

### 3.1 打开与定位

- `OpenChatUseCase`
- `LoadChatWindowUseCase`
- `LoadOlderMessagesUseCase`
- `LocateMessageUseCase`
- `RestoreViewportUseCase`
- `PersistViewportUseCase`

### 3.2 消息动作

- `SendMessageUseCase`
- `RecallMessageUseCase`
- `DeleteMessageUseCase`
- `ForwardMessagesUseCase`
- `AddFavoriteUseCase`

### 3.3 回执与同步

- `MarkConversationReadUseCase`
- `SyncVoicePlayedUseCase`
- `PullMessagesAfterReconnectUseCase`

---

## 4. Conversation UseCase 清单

- `LoadConversationListUseCase`
- `RefreshConversationListUseCase`
- `SyncConversationsIncrementallyUseCase`
- `PinConversationUseCase`
- `ToggleConversationNoDisturbUseCase`
- `DeleteConversationUseCase`
- `OpenOrCreateConversationUseCase`

---

## 5. Group UseCase 清单

- `LoadGroupSettingsUseCase`
- `UpdateGroupNameUseCase`
- `UpdateGroupPreferenceUseCase`
- `LoadGroupMembersUseCase`
- `SetGroupMemberRoleUseCase`
- `RemoveGroupMemberUseCase`
- `TransferGroupOwnerUseCase`
- `QuitGroupUseCase`
- `DissolveGroupUseCase`
- `LoadGroupJoinRequestsUseCase`
- `ApproveGroupJoinRequestUseCase`
- `RejectGroupJoinRequestUseCase`
- `UpdateGroupNoticeUseCase`

---

## 6. Contact/Search/Favorite UseCase 清单

### 6.1 contact

- `LoadContactsHomeUseCase`
- `LoadOrgTreeUseCase`
- `LoadDeptMembersUseCase`
- `LoadUserProfileUseCase`
- `ToggleStarContactUseCase`
- `CreateGroupUseCase`

### 6.2 search

- `LoadHotSearchUseCase`
- `SearchGlobalUseCase`
- `LoadSearchHistoryUseCase`
- `PersistSearchHistoryUseCase`

### 6.3 favorite

- `LoadFavoritesUseCase`
- `SearchFavoritesUseCase`
- `LoadFavoriteDetailUseCase`
- `RemoveFavoriteUseCase`
- `ResendFavoriteUseCase`

---

## 7. Command 命名清单

- `OpenChatCommand`
- `LoadChatWindowCommand`
- `LocateMessageCommand`
- `SendMessageCommand`
- `ForwardMessagesCommand`
- `MarkConversationReadCommand`
- `UpdateGroupPreferenceCommand`
- `TransferGroupOwnerCommand`
- `SearchGlobalCommand`
- `SearchFavoritesCommand`

---

## 8. Result 命名清单

- `OpenChatResult`
- `ChatWindowResult`
- `LocateMessageResult`
- `SendMessageResult`
- `ConversationSyncResult`
- `GroupSettingsResult`
- `GlobalSearchResult`
- `FavoriteDetailResult`

---

## 9. Repository 分层

### 9.1 domain contract

定义在：

- `domain/repositories/*.dart`

仅定义接口，不依赖 Dio、JSON、Flutter。

### 9.2 infrastructure impl

定义在：

- `infrastructure/repositories/*_repository_impl.dart`

负责：

- 调用 remote/local datasource
- DTO 映射
- 错误转换

---

## 10. DataSource 分层

### 10.1 remote datasource

文件命名：

- `conversation_remote_data_source.dart`
- `message_remote_data_source.dart`

职责：

- 发 HTTP 请求
- 返回 DTO

### 10.2 local datasource

文件命名：

- `conversation_local_data_source.dart`
- `message_local_data_source.dart`

职责：

- 本地数据库 / KV 读写
- 返回 DTO 或持久化模型

---

## 11. DTO 分组

### 11.1 conversation DTO

- `ConversationDto`
- `ConversationSyncResponseDto`
- `ConversationPreferenceRequestDto`

### 11.2 message DTO

- `MessageDto`
- `MessageWindowResponseDto`
- `MessageHistoryResponseDto`
- `SendMessageRequestDto`
- `ForwardMessagesRequestDto`

### 11.3 group DTO

- `GroupInfoDto`
- `GroupMemberDto`
- `GroupJoinRequestDto`
- `UpdateGroupNoticeRequestDto`

### 11.4 search/favorite DTO

- `GlobalSearchItemDto`
- `GlobalSearchResponseDto`
- `FavoriteItemDto`
- `FavoriteDetailDto`

---

## 12. Mapper 设计

每个 feature 至少包含：

- remote dto -> entity mapper
- local record -> entity mapper
- entity -> request dto mapper
- entity -> ui model mapper

---

## 13. 错误映射

Repository 层统一把：

- network error
- auth error
- permission error
- business deny
- data inconsistency

转换为 domain/application 可处理异常。

---

## 14. 典型文件结构示例

```text
features/im/chat/
  application/
    usecases/
      open_chat_use_case.dart
      send_message_use_case.dart
    commands/
      open_chat_command.dart
      send_message_command.dart
    results/
      open_chat_result.dart
      send_message_result.dart
  domain/
    entities/
      message.dart
      quote_info.dart
    repositories/
      message_repository.dart
  infrastructure/
    datasources/
      message_remote_data_source.dart
      message_local_data_source.dart
    dtos/
      message_dto.dart
      send_message_request_dto.dart
      message_window_response_dto.dart
    repositories/
      message_repository_impl.dart
    mappers/
      message_dto_mapper.dart
```

