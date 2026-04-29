# IM Flutter 页面与路由详细设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：完整页面清单、路由定义、参数、页面状态、controller 契约  

---

## 1. 页面清单

### 1.1 一级页面

- `LoginPage`
- `ConversationListPage`
- `ContactsHomePage`
- `WorkbenchPage`
- `ProfilePage`
- `SettingsPage`
- `ThemeSettingsPage`
- `LanguageSettingsPage`

### 1.2 聊天与会话页面

- `ChatPage`
- `DirectChatSettingsPage`
- `GroupSettingsPage`
- `ForwardTargetPickerPage`
- `MergedForwardDetailPage`
- `MentionPickerPage`
- `ChatHistorySearchPage`
- `ChatMediaPage`
- `ContactCardPickerPage`
- `LocationPickerPage`
- `VideoPlayerPage`
- `FilePreviewPage`

### 1.3 群页面

- `GroupMembersPage`
- `GroupJoinRequestsPage`
- `GroupNoticePage`
- `GroupInvitePage`
- `JoinGroupPage`

### 1.4 通讯录与组织页面

- `CreateGroupPage`
- `OrgBrowserPage`
- `UserProfilePage`
- `MyGroupsPage`
- `StarContactsPage`
- `MyDepartmentPage`

### 1.5 搜索与收藏页面

- `GlobalSearchPage`
- `FavoritesPage`
- `FavoriteDetailPage`

### 1.6 通用能力页面

- `LocationViewPage`
- `SecureBrowserPage`
- `ScanPage`
- `HomeIndexPage`

### 1.7 音视频通话页面

- `IncomingCallPage`
- `OutgoingCallPage`
- `CallSessionPage`

---

## 2. 一级路由设计

- `/login`
- `/shell/conversations`
- `/shell/contacts`
- `/shell/workbench`
- `/shell/profile`
- `/settings`
- `/settings/theme`
- `/settings/language`

推荐：

- 使用 ShellRoute 管理底部主壳
- 大对象和短期上下文通过 `nav state` 传递，不直接放进 URL

---

## 3. IM 路由设计

- `/chat`
- `/chat/settings/direct`
- `/chat/settings/group`
- `/chat/forward-target`
- `/chat/forward-detail`
- `/chat/mention-picker`
- `/chat/history-search`
- `/chat/media`
- `/chat/contact-card-picker`
- `/chat/location-picker`
- `/chat/video-player`
- `/chat/file-preview`

- `/group/members`
- `/group/join-requests`
- `/group/notice`
- `/group/invite`
- `/group/join`

- `/contacts/create-group`
- `/contacts/org`
- `/contacts/user-profile`
- `/contacts/my-groups`
- `/contacts/star`
- `/contacts/my-department`

- `/search/global`
- `/favorites`
- `/favorites/detail`

- `/common/location-view`
- `/common/secure-browser`
- `/common/scan`
- `/home/index`

- `/call/incoming`
- `/call/outgoing`
- `/call/session`

---

## 4. 页面参数定义

### 4.1 `LoginPage`

参数：

- 无

### 4.2 `ConversationListPage`

参数：

- `initialTab` 可选

### 4.3 `ChatPage`

参数：

- `ChatEntryArgs`

### 4.4 `DirectChatSettingsPage`

参数：

- `chatId`
- `targetUserId`

### 4.5 `GroupSettingsPage`

参数：

- `groupId`
- `chatId`

### 4.6 `GroupMembersPage`

参数：

- `groupId`
- `chatId`
- `mode`

### 4.7 `GroupJoinRequestsPage`

参数：

- `groupId`

### 4.8 `GroupNoticePage`

参数：

- `groupId`
- `editable`

### 4.9 `GroupInvitePage`

参数：

- `groupId`
- `groupName`

### 4.10 `JoinGroupPage`

参数：

- `inviteCode`

### 4.11 `GlobalSearchPage`

参数：

- `initialKeyword`
- `initialTab`

### 4.12 `FavoriteDetailPage`

参数：

- `favoriteId`

### 4.13 `FilePreviewPage`

参数：

- `FilePreviewArgs`

### 4.14 `IncomingCallPage`

参数：

- `CallLaunchArgs`

### 4.15 `OutgoingCallPage`

参数：

- `CallLaunchArgs`

### 4.16 `CallSessionPage`

参数：

- `CallLaunchArgs`

---

## 5. 页面 controller 契约

### 5.1 `LoginController`

动作：

- `submitAccountLogin`
- `submitMobileLogin`
- `requestSmsCode`
- `toggleLanguagePanel`

### 5.2 `ConversationListController`

动作：

- `load`
- `refresh`
- `syncIncrementally`
- `pinConversation`
- `markConversationRead`
- `toggleNoDisturb`
- `deleteConversation`

### 5.3 `ChatController`

动作：

- `initialize`
- `openLatest`
- `openAnchor`
- `openRestore`
- `sendText`
- `sendImage`
- `sendVoice`
- `sendVideo`
- `sendFile`
- `sendLocation`
- `sendContactCard`
- `forwardMessages`
- `recallMessage`
- `deleteMessage`
- `markRead`
- `flushPendingStates`

### 5.4 `GroupSettingsController`

动作：

- `load`
- `updatePinned`
- `updateNoDisturb`
- `updateMuteAll`
- `updateAllowMemberInvite`
- `updateNeedApproval`
- `updateMyNickname`
- `transferOwner`
- `quitGroup`
- `dissolveGroup`

### 5.5 `GlobalSearchController`

动作：

- `inputKeyword`
- `search`
- `switchTab`
- `loadMore`
- `clearHistory`

### 5.6 `CallController`

动作：

- `accept`
- `reject`
- `cancel`
- `hangup`
- `toggleMute`
- `toggleSpeaker`
- `toggleCamera`
- `switchCamera`
- `minimize`
- `restore`
- `retryReconnect`

---

## 6. 页面状态标准

### 6.1 列表页

- initial
- loading
- refreshing
- ready
- empty
- failed

### 6.2 表单页

- idle
- validating
- submitting
- success
- failed

### 6.3 聊天页

- initializing
- loadingWindow
- restoringViewport
- ready
- loadingHistory
- failed

---

## 7. 页面组件拆分标准

### 7.1 会话列表页

- `ConversationHeader`
- `ConversationQuickActions`
- `ConversationListView`
- `ConversationTile`
- `ConversationActionMenu`

### 7.2 聊天页

- `ChatAppBar`
- `ChatNoticeBanner`
- `ChatTimeline`
- `ChatMessageItem`
- `ChatComposer`
- `ChatMorePanel`
- `ChatActionSheet`

### 7.3 群设置页

- `GroupOverviewCard`
- `GroupMembersPreview`
- `GroupFunctionList`
- `GroupGovernanceList`
- `GroupDangerList`

---

## 8. 页面间跳转标准

### 8.1 进入聊天页

统一走：

- `ChatEntryArgs.latest`
- `ChatEntryArgs.anchor`
- `ChatEntryArgs.restore`

### 8.2 群相关页面

统一透传：

- `groupId`
- `chatId`

### 8.3 用户相关页面

统一透传：

- `userId`

---

## 9. 可合并页面策略

以下能力应优先通过模式参数或组件复用实现，而不是重复页面：

- 组织浏览 / 组织选择
- 群成员浏览 / 群成员选择
- 联系人选择 / 名片选择
- 聊天历史搜索 / 全局消息搜索子集

---

## 10. 多端布局策略

### 10.1 Mobile

- 单栏页面流
- 聊天页全屏

### 10.2 Web/Desktop

- ConversationList 可作为左栏常驻
- ChatPage 可作为右栏主工作区
- 选择器优先弹层或侧栏

---

## 11. 页面验收定义

每个页面必须满足：

1. 参数明确
2. 状态明确
3. controller 明确
4. 组件拆分明确
5. 多端布局策略明确
