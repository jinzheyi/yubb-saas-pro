# IM Flutter 页面实现蓝图 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter 页面、路由、状态、组件拆分蓝图  

补充：

- 更完整的页面契约见 `sql/flutter-doc/IM-Flutter页面与路由详细设计-v1.0.md`

---

## 1. 页面设计原则

1. 页面只做展示和动作分发。
2. 页面状态由 Controller / Notifier 驱动。
3. 页面之间统一用强类型路由参数通信。
4. 选择器、弹层、动作面板优先组件化，不复制页面实现。

---

## 2. 路由蓝图

### 2.1 一级路由

- `/login`
- `/conversations`
- `/contacts`
- `/workbench`
- `/profile`

### 2.2 IM 二级路由

- `/chat`
- `/chat/settings/direct`
- `/chat/settings/group`
- `/chat/history-search`
- `/chat/media`
- `/chat/forward-target`
- `/chat/forward-detail`
- `/chat/mention-picker`
- `/chat/contact-card-picker`
- `/chat/location-picker`
- `/chat/location-view`
- `/chat/file-preview`
- `/group/members`
- `/group/join-requests`
- `/group/notice`
- `/group/invite`
- `/group/join`
- `/search/global`
- `/favorites`
- `/favorites/detail`
- `/call/incoming`
- `/call/outgoing`
- `/call/session`

---

## 3. 路由参数模型

### 3.1 `ChatEntryArgs`

字段：

- `chatId`
- `conversationType`
- `targetId`
- `title`
- `entryMode`
- `anchorSequence`
- `anchorMessageId`
- `restoreKey`

### 3.2 `GroupContextArgs`

字段：

- `groupId`
- `chatId`
- `groupName`

### 3.3 `UserProfileArgs`

字段：

- `userId`
- `fromChatId`

### 3.4 `FilePreviewArgs`

字段：

- `fileId`
- `fileName`
- `mimeType`
- `messageId`

### 3.5 `CallLaunchArgs`

字段：

- `callSessionId`
- `entryMode`
- `callType`
- `fromChatId`

---

## 4. 一级页面蓝图

### 4.1 `LoginPage`

组件：

- `LoginModeTabs`
- `AccountLoginForm`
- `MobileLoginForm`
- `CaptchaTrigger`
- `LanguageEntry`

状态：

- idle
- submitting
- captchaRequired
- failed

### 4.2 `ConversationListPage`

组件：

- `ConversationHeader`
- `ConversationFilterBar`
- `PinnedConversationSection`
- `ConversationListSection`
- `ConversationContextMenu`

状态：

- loading
- refreshing
- ready
- syncFailed

### 4.3 `ContactsHomePage`

组件：

- `ContactsHeader`
- `ContactsQuickActions`
- `ContactsListSection`
- `ContactsIndexBar`

### 4.4 `ProfilePage`

组件：

- `ProfileHeader`
- `ProfileActionList`
- `ProfileSettingsEntry`

---

## 5. 聊天域页面蓝图

### 5.1 `ChatPage`

组件树：

- `ChatScaffold`
  - `ChatAppBar`
  - `ChatNoticeBanner`
  - `ChatTimeline`
  - `ChatComposer`
  - `ChatMorePanel`
  - `ChatContextActionSheet`

内部控制器：

- `ChatController`
- `ChatTimelineController`
- `ChatComposerController`
- `ChatMediaController`
- `ChatReceiptController`

### 5.2 `DirectChatSettingsPage`

组件：

- `DirectChatProfileSection`
- `ConversationPreferenceSection`
- `ConversationToolsSection`
- `ConversationDangerSection`

### 5.3 `GroupSettingsPage`

组件：

- `GroupOverviewSection`
- `GroupMembersPreviewSection`
- `GroupFunctionSection`
- `GroupConversationPreferenceSection`
- `GroupGovernanceSection`
- `GroupDangerZoneSection`

### 5.4 `GroupMembersPage`

组件：

- `GroupMembersSearchBar`
- `GroupMembersGridOrList`
- `GroupMemberActionSheet`

### 5.5 `GroupJoinRequestsPage`

组件：

- `JoinRequestTabBar`
- `JoinRequestList`
- `JoinRequestActionSheet`

### 5.6 `GroupNoticePage`

组件：

- `NoticeViewMode`
- `NoticeEditMode`

### 5.7 `GroupInvitePage`

组件：

- `InviteCodeCard`
- `InviteQrSection`
- `InviteShareActions`

---

## 6. 搜索与收藏页面蓝图

### 6.1 `GlobalSearchPage`

组件：

- `SearchInputBar`
- `SearchHistorySection`
- `HotSearchSection`
- `SearchTabBar`
- `SearchResultList`

### 6.2 `FavoritesPage`

组件：

- `FavoritesTabBar`
- `FavoritesSearchBar`
- `FavoritesList`

### 6.3 `FavoriteDetailPage`

组件：

- `FavoriteHeader`
- `FavoriteContentRenderer`
- `FavoriteActions`

---

## 7. 联系人与组织页面蓝图

### 7.1 `OrgBrowserPage`

组件：

- `OrgTreePanel`
- `DeptMembersPanel`
- `OrgSelectionFooter`

### 7.2 `MyDepartmentPage`

组件：

- `DeptTreeSummary`
- `DeptMembersList`

### 7.3 `MyGroupsPage`

组件：

- `MyGroupsHeader`
- `MyGroupsList`

### 7.4 `StarContactsPage`

组件：

- `StarContactsSearchBar`
- `StarContactsList`

### 7.5 `UserProfilePage`

组件：

- `UserProfileHeader`
- `UserInfoSection`
- `UserActionSection`

---

## 8. 辅助页面蓝图

### 8.1 `ChatHistorySearchPage`

- 搜索输入
- 结果列表
- 锚点跳转动作

### 8.2 `ChatMediaPage`

- 图片 tab
- 视频 tab
- 文件 tab

### 8.3 `ForwardTargetPickerPage`

- 最近会话
- 搜索会话
- 确认操作栏

### 8.4 `MergedForwardDetailPage`

- 聊天记录摘要
- 原消息跳转入口

### 8.5 `MentionPickerPage`

- 群成员列表
- 搜索成员
- @所有人入口

### 8.6 `ContactCardPickerPage`

- 联系人源切换
- 联系人列表
- 已选状态

### 8.7 `LocationPickerPage`

- 搜索栏
- 定位结果列表
- 当前位置入口

### 8.8 `FilePreviewPage`

- 加载策略
- 预览态 / 下载态

### 8.9 `IncomingCallPage`

- 来电信息
- 权限提示
- 接听 / 拒绝操作

### 8.10 `OutgoingCallPage`

- 呼叫状态
- 取消操作
- 媒体准备提示

### 8.11 `CallSessionPage`

- 语音 / 视频舞台
- 通话控制栏
- 网络重连提示
- 最小化能力

---

## 9. 页面状态标准

每个页面优先采用以下通用状态：

- `initial`
- `loading`
- `refreshing`
- `ready`
- `empty`
- `submitting`
- `failed`

禁止一个页面自行定义杂乱的布尔组合代替状态机。

---

## 10. 聊天页子状态标准

### 10.1 时间线

- `windowLoading`
- `historyLoading`
- `ready`
- `locatingAnchor`

### 10.2 输入区

- `text`
- `voice`
- `quote`
- `expanded`

### 10.3 消息操作

- `idle`
- `multiSelect`
- `actionMenuOpen`

---

## 11. 页面级开发强制规则

1. 页面不可直接构造业务对象。
2. 页面不可直接处理 DTO。
3. 页面不可直接操作数据库。
4. 页面不可直接监听 WebSocket 底层事件。
5. 页面不可拼接复杂 query 参数字符串。

---

## 12. 页面级验收

### 12.1 结构验收

- 页面组件拆分合理
- 路由参数清晰
- 状态对象单一

### 12.2 行为验收

- 页面可刷新
- 页面可恢复
- 页面可回退
- 页面可在多端稳定运行
