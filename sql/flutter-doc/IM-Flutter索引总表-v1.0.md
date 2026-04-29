# IM Flutter 索引总表 v1.0

> 文档日期：2026-04-29  
> 文档定位：路由、provider、usecase、controller 的总索引，作为全局导航文档  

---

## 1. 路由总表

| 路由 | 页面 |
|---|---|
| `/login` | `LoginPage` |
| `/shell/conversations` | `ConversationListPage` |
| `/shell/contacts` | `ContactsHomePage` |
| `/shell/workbench` | `WorkbenchPage` |
| `/shell/profile` | `ProfilePage` |
| `/settings` | `SettingsPage` |
| `/settings/theme` | `ThemeSettingsPage` |
| `/settings/language` | `LanguageSettingsPage` |
| `/chat` | `ChatPage` |
| `/chat/settings/direct` | `DirectChatSettingsPage` |
| `/chat/settings/group` | `GroupSettingsPage` |
| `/chat/history-search` | `ChatHistorySearchPage` |
| `/chat/media` | `ChatMediaPage` |
| `/chat/forward-target` | `ForwardTargetPickerPage` |
| `/chat/forward-detail` | `MergedForwardDetailPage` |
| `/chat/mention-picker` | `MentionPickerPage` |
| `/chat/contact-card-picker` | `ContactCardPickerPage` |
| `/chat/location-picker` | `LocationPickerPage` |
| `/chat/video-player` | `VideoPlayerPage` |
| `/chat/file-preview` | `FilePreviewPage` |
| `/group/members` | `GroupMembersPage` |
| `/group/join-requests` | `GroupJoinRequestsPage` |
| `/group/notice` | `GroupNoticePage` |
| `/group/invite` | `GroupInvitePage` |
| `/group/join` | `JoinGroupPage` |
| `/contacts/create-group` | `CreateGroupPage` |
| `/contacts/org` | `OrgBrowserPage` |
| `/contacts/user-profile` | `UserProfilePage` |
| `/contacts/my-groups` | `MyGroupsPage` |
| `/contacts/star` | `StarContactsPage` |
| `/contacts/my-department` | `MyDepartmentPage` |
| `/search/global` | `GlobalSearchPage` |
| `/favorites` | `FavoritesPage` |
| `/favorites/detail` | `FavoriteDetailPage` |
| `/call/incoming` | `IncomingCallPage` |
| `/call/outgoing` | `OutgoingCallPage` |
| `/call/session` | `CallSessionPage` |

---

## 2. Provider 总表

### 2.1 app/core

- `appBootstrapProvider`
- `authSessionProvider`
- `dioClientProvider`
- `socketClientProvider`
- `storageRegistryProvider`
- `platformCapabilitiesProvider`

### 2.2 feature

- `conversationListControllerProvider`
- `conversationRepositoryProvider`
- `chatControllerProvider`
- `chatTimelineControllerProvider`
- `chatComposerControllerProvider`
- `chatReceiptControllerProvider`
- `chatViewportControllerProvider`
- `messageRepositoryProvider`
- `groupSettingsControllerProvider`
- `groupMembersControllerProvider`
- `groupRepositoryProvider`
- `contactsHomeControllerProvider`
- `orgBrowserControllerProvider`
- `contactRepositoryProvider`
- `globalSearchControllerProvider`
- `searchRepositoryProvider`
- `favoritesControllerProvider`
- `favoriteRepositoryProvider`
- `callControllerProvider`
- `callMediaControllerProvider`
- `activeCallRegistryProvider`
- `callRepositoryProvider`
- `rtcGatewayClientProvider`

---

## 3. Controller 总表

- `LoginController`
- `ConversationListController`
- `ChatController`
- `ChatTimelineController`
- `ChatComposerController`
- `ChatMediaController`
- `ChatReceiptController`
- `ChatViewportController`
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
- `MyGroupsController`
- `StarContactsController`
- `MyDepartmentController`
- `GlobalSearchController`
- `FavoritesController`
- `FavoriteDetailController`
- `CallController`
- `CallMediaController`

---

## 4. UseCase 总表

### 4.1 auth/core

- `AuthBootstrapCoordinator`
- `RefreshTokenCoordinator`

### 4.2 conversation

- `LoadConversationListUseCase`
- `RefreshConversationListUseCase`
- `SyncConversationsIncrementallyUseCase`
- `PinConversationUseCase`
- `ToggleConversationNoDisturbUseCase`
- `DeleteConversationUseCase`
- `OpenOrCreateConversationUseCase`

### 4.3 chat

- `OpenChatUseCase`
- `LoadChatWindowUseCase`
- `LoadOlderMessagesUseCase`
- `LocateMessageUseCase`
- `RestoreViewportUseCase`
- `PersistViewportUseCase`
- `SendMessageUseCase`
- `RecallMessageUseCase`
- `DeleteMessageUseCase`
- `ForwardMessagesUseCase`
- `AddFavoriteUseCase`
- `MarkConversationReadUseCase`
- `SyncVoicePlayedUseCase`
- `PullMessagesAfterReconnectUseCase`

### 4.4 group

- `LoadGroupSettingsUseCase`
- `LoadGroupMembersUseCase`
- `UpdateGroupNameUseCase`
- `UpdateGroupPreferenceUseCase`
- `SetGroupMemberRoleUseCase`
- `RemoveGroupMemberUseCase`
- `TransferGroupOwnerUseCase`
- `QuitGroupUseCase`
- `DissolveGroupUseCase`
- `LoadGroupJoinRequestsUseCase`
- `ApproveGroupJoinRequestUseCase`
- `RejectGroupJoinRequestUseCase`
- `UpdateGroupNoticeUseCase`

### 4.5 contact/search/favorite

- `LoadContactsHomeUseCase`
- `LoadOrgTreeUseCase`
- `LoadDeptMembersUseCase`
- `LoadUserProfileUseCase`
- `ToggleStarContactUseCase`
- `CreateGroupUseCase`
- `LoadHotSearchUseCase`
- `SearchGlobalUseCase`
- `LoadSearchHistoryUseCase`
- `PersistSearchHistoryUseCase`
- `LoadFavoritesUseCase`
- `SearchFavoritesUseCase`
- `LoadFavoriteDetailUseCase`
- `RemoveFavoriteUseCase`
- `ResendFavoriteUseCase`

### 4.6 call

- `CreateCallInviteUseCase`
- `AcceptCallUseCase`
- `RejectCallUseCase`
- `CancelCallUseCase`
- `HangupCallUseCase`
- `ReconnectCallUseCase`
- `SyncActiveCallStateUseCase`

---

## 5. Repository 总表

- `ConversationRepository`
- `MessageRepository`
- `GroupRepository`
- `ContactRepository`
- `SearchRepository`
- `FavoriteRepository`
- `FileRepository`
- `ReceiptRepository`
- `MediaRepository`
- `CallRepository`

---

## 6. 文档治理入口

- `IM-Flutter主目录与阅读顺序-v1.0.md`
- `IM-Flutter开工顺序与进度看板-v1.0.md`
- `IM-Flutter新会话续接说明与推荐指令-v1.0.md`
- `IM-Flutter后端协同约束与接口整顿建议-v1.0.md`
- `IM-Flutter后端协同实施优先级清单-v1.0.md`
