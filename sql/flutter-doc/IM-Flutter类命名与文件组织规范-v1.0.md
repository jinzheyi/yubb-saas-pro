# IM Flutter 类命名与文件组织规范 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 工程的类命名、provider 命名、文件组织、分文件规范  

---

## 1. 目标

统一命名和文件组织，避免后续 AI 或多人开发时同类对象反复换名、重复建层、边界漂移。

---

## 2. 总命名规则

### 2.1 类名

- 使用 `PascalCase`
- 名称必须体现职责

### 2.2 文件名

- 使用 `snake_case.dart`
- 文件名与主类名保持稳定映射

### 2.3 Provider 名

- 统一以 `Provider` 结尾
- controller provider 统一以 `xxxControllerProvider`

---

## 3. 文件组织规则

### 3.1 feature 目录

每个 feature 目录结构统一为：

```text
feature_name/
  presentation/
    pages/
    controllers/
    states/
    widgets/
    providers/
    mappers/
  application/
    usecases/
    commands/
    results/
    coordinators/
    policies/
  domain/
    entities/
    value_objects/
    repositories/
    services/
    enums/
  infrastructure/
    datasources/
    dtos/
    mappers/
    repositories/
    adapters/
```

---

## 4. Provider 命名清单

### 4.1 app/core

- `appBootstrapProvider`
- `authSessionProvider`
- `dioClientProvider`
- `socketClientProvider`
- `storageRegistryProvider`
- `platformCapabilitiesProvider`

### 4.2 conversation

- `conversationListControllerProvider`
- `conversationFilterProvider`
- `conversationSyncCoordinatorProvider`
- `conversationRepositoryProvider`
- `conversationRemoteDataSourceProvider`
- `conversationLocalDataSourceProvider`

### 4.3 chat

- `chatControllerProvider`
- `chatTimelineControllerProvider`
- `chatComposerControllerProvider`
- `chatMediaControllerProvider`
- `chatReceiptControllerProvider`
- `chatViewportControllerProvider`
- `chatRepositoryProvider`
- `messageRepositoryProvider`

### 4.4 group

- `groupSettingsControllerProvider`
- `groupMembersControllerProvider`
- `groupJoinRequestsControllerProvider`
- `groupRepositoryProvider`

### 4.5 contact

- `contactsHomeControllerProvider`
- `orgBrowserControllerProvider`
- `userProfileControllerProvider`
- `contactRepositoryProvider`

### 4.6 search

- `globalSearchControllerProvider`
- `searchRepositoryProvider`

### 4.7 favorite

- `favoritesControllerProvider`
- `favoriteDetailControllerProvider`
- `favoriteRepositoryProvider`

### 4.8 badge/receipt/media

- `badgeControllerProvider`
- `readReceiptControllerProvider`
- `mediaBrowserControllerProvider`
- `fileRepositoryProvider`

---

## 5. Controller 类命名清单

### 5.1 页面级 controller

- `LoginController`
- `ConversationListController`
- `ChatController`
- `DirectChatSettingsController`
- `GroupSettingsController`
- `GroupMembersController`
- `GroupJoinRequestsController`
- `GroupNoticeController`
- `GroupInviteController`
- `JoinGroupController`
- `ContactsHomeController`
- `OrgBrowserController`
- `CreateGroupController`
- `UserProfileController`
- `GlobalSearchController`
- `FavoritesController`
- `FavoriteDetailController`

### 5.2 子控制器

- `ChatTimelineController`
- `ChatComposerController`
- `ChatMediaController`
- `ChatReceiptController`
- `ChatViewportController`
- `MediaBrowserController`

### 5.3 协调器

- `AuthBootstrapCoordinator`
- `RefreshTokenCoordinator`
- `ConversationSyncCoordinator`
- `GroupLifecycleActionCoordinator`
- `ChatUploadCoordinator`
- `AudioPlaybackCoordinator`
- `FileOpenCoordinator`

---

## 6. State 类命名清单

- `LoginPageState`
- `ConversationListState`
- `ConversationFilterState`
- `ChatPageState`
- `ChatTimelineState`
- `ChatComposerState`
- `ChatReceiptState`
- `ChatViewportState`
- `GroupSettingsState`
- `GroupMembersState`
- `GroupJoinRequestsState`
- `ContactsHomeState`
- `OrgBrowserState`
- `CreateGroupState`
- `UserProfileState`
- `GlobalSearchState`
- `FavoritesState`
- `FavoriteDetailState`
- `BadgeState`

---

## 7. Page 文件组织示例

### 7.1 chat

```text
features/im/chat/presentation/
  pages/
    chat_page.dart
  controllers/
    chat_controller.dart
    chat_timeline_controller.dart
    chat_composer_controller.dart
    chat_media_controller.dart
    chat_receipt_controller.dart
    chat_viewport_controller.dart
  states/
    chat_page_state.dart
    chat_timeline_state.dart
    chat_composer_state.dart
    chat_receipt_state.dart
  widgets/
    chat_app_bar.dart
    chat_notice_banner.dart
    chat_timeline.dart
    chat_message_item.dart
    chat_composer.dart
    chat_more_panel.dart
    chat_action_sheet.dart
```

### 7.2 conversation

```text
features/im/conversation/presentation/
  pages/
    conversation_list_page.dart
  controllers/
    conversation_list_controller.dart
  states/
    conversation_list_state.dart
    conversation_filter_state.dart
  widgets/
    conversation_tile.dart
    pinned_conversation_section.dart
    conversation_context_menu.dart
```

---

## 8. DTO 文件命名规则

DTO 文件统一后缀：

- `_dto.dart`
- `_request_dto.dart`
- `_response_dto.dart`

示例：

- `conversation_dto.dart`
- `message_window_response_dto.dart`
- `send_message_request_dto.dart`

---

## 9. Repository 实现文件命名

domain：

- `conversation_repository.dart`
- `message_repository.dart`

infrastructure：

- `conversation_repository_impl.dart`
- `message_repository_impl.dart`

---

## 10. Mapper 文件命名

- `conversation_dto_mapper.dart`
- `message_dto_mapper.dart`
- `chat_ui_model_mapper.dart`
- `search_result_ui_mapper.dart`

---

## 11. 禁止事项

1. 禁止出现 `manager.dart` 作为兜底命名
2. 禁止出现 `utils.dart` 承载 feature 业务
3. 禁止同一职责同时出现 `service` 和 `controller` 双重命名
4. 禁止页面类名和状态类名语义不一致

