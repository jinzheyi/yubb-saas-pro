# IM Flutter 群设置、通讯录、搜索详细设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：`GroupSettings`、`Contacts`、`Search` 三个高复杂业务域的企业级详细设计  

---

## 1. 设计目标

这三个模块共同决定 IM 的企业级可用性：

- 群设置：治理能力
- 通讯录：组织协作入口
- 搜索：信息检索效率

必须做到：

- 结构清晰
- 组件可复用
- 多端一致
- 权限与流程可控

群设置、搜索、收藏等功能覆盖以 `IM-Flutter功能覆盖与交互验收清单-v1.0.md` 为总基线。

---

## 2. `GroupSettingsPage` 详细设计

### 2.1 页面目标

- 管理群会话配置
- 管理群治理配置
- 管理高危操作

### 2.2 顶层 section

- `GroupOverviewSection`
- `GroupMembersPreviewSection`
- `GroupConversationPreferenceSection`
- `GroupGovernanceSection`
- `GroupDangerZoneSection`

### 2.3 `GroupSettingsState`

字段：

- `status`
- `groupInfo`
- `membersPreview`
- `pendingJoinRequestCount`
- `canEditGroup`
- `canManageMembers`
- `canManageGovernance`
- `pendingAction`

### 2.4 controller 动作

- `load()`
- `refresh()`
- `updatePinned(bool value)`
- `updateNoDisturb(bool value)`
- `updateMuteAll(bool value)`
- `updateAllowMemberInvite(bool value)`
- `updateNeedApproval(bool value)`
- `updateMyNickname(String nickname)`
- `updateGroupName(String name)`
- `transferOwner(String userId)`
- `quitGroup()`
- `dissolveGroup()`
- `clearChatHistory()`

### 2.5 高危动作规则

- 转让群主
- 退群
- 解散群
- 清空聊天记录

必须统一走：

- `GroupLifecycleActionCoordinator`

---

## 3. `GroupMembersPage` 详细设计

### 3.1 页面模式

- browse
- manage
- select

### 3.2 页面能力

- 搜索成员
- 成员列表
- 角色管理
- 移除成员
- 选择成员

### 3.3 controller 动作

- `loadMembers()`
- `searchMembers(String keyword)`
- `setRole(String userId, GroupMemberRole role)`
- `removeMember(String userId)`
- `selectMember(String userId)`

---

## 4. `ContactsHomePage` 详细设计

### 4.1 页面目标

- 提供企业组织关系的统一入口
- 支持快速发起协作

### 4.2 页面 section

- `ContactsHeader`
- `ContactsQuickEntrySection`
- `ContactsRecentOrStarSection`
- `ContactsAlphabetListSection`

### 4.3 快捷入口

- 我的群组
- 星标联系人
- 组织架构
- 我的部门

### 4.4 controller 动作

- `loadContacts()`
- `refresh()`
- `openContact(String userId)`
- `startDirectChat(String userId)`

---

## 5. `OrgBrowserPage` 详细设计

### 5.1 页面模式

- browse
- pickContact
- pickGroupMember

### 5.2 页面布局

- 左侧组织树
- 右侧部门成员

移动端可改为：

- 组织树 -> 成员列表的层级式流转

### 5.3 controller 动作

- `loadTree()`
- `expandNode(String deptId)`
- `selectDept(String deptId)`
- `loadDeptMembers(String deptId)`
- `searchDeptMembers(String keyword)`

---

## 6. `CreateGroupPage` 详细设计

### 6.1 页面目标

- 创建群
- 选择群成员

### 6.2 页面子模块

- `SelectedMembersBar`
- `MemberPickerBody`
- `CreateGroupActionBar`

### 6.3 controller 动作

- `toggleMember(String userId)`
- `removeSelected(String userId)`
- `submitCreateGroup(String name)`

---

## 7. `UserProfilePage` 详细设计

### 7.1 页面目标

- 查看用户信息
- 联系人偏好设置
- 发消息

### 7.2 页面动作

- `toggleStar()`
- `startDirectChat()`
- `shareContactCard()`

---

## 8. `GlobalSearchPage` 详细设计

### 8.1 页面目标

- 聚合搜索消息、联系人、群、媒体
- 高效跳转结果

### 8.2 顶层 section

- `SearchInputBar`
- `SearchHistorySection`
- `HotSearchSection`
- `SearchTabs`
- `SearchResults`

### 8.3 `GlobalSearchState`

字段：

- `keyword`
- `activeTab`
- `status`
- `results`
- `facets`
- `hasMore`
- `isLoadingMore`

### 8.4 controller 动作

- `inputKeyword(String value)`
- `submitSearch()`
- `switchTab(SearchTab tab)`
- `loadMore()`
- `clearHistory()`
- `selectHistory(String keyword)`
- `selectHot(String keyword)`

### 8.5 跳转协议

- message result -> `ChatEntryArgs.anchor`
- contact result -> `UserProfilePage`
- group result -> group chat latest
- media result -> `ChatEntryArgs.anchor`

---

## 9. `FavoritesPage` 详细设计

### 9.1 页面目标

- 查看收藏
- 搜索收藏
- 打开收藏详情

### 9.2 controller 动作

- `loadFavorites()`
- `searchFavorites(String keyword, FavoriteTab tab)`
- `removeFavorite(String favoriteId)`
- `openFavorite(String favoriteId)`

---

## 10. 组件复用策略

优先抽象以下复用组件：

- `UserAvatar`
- `MessageSummaryTile`
- `SearchInputBar`
- `PagedListView`
- `EmptyStateView`
- `PermissionAwareActionTile`
- `DangerActionTile`
- `SelectionFooterBar`

---

## 11. 权限与可见性规则

### 11.1 群设置

- 根据用户角色显示治理入口
- 不满足权限时不展示或置灰

### 11.2 通讯录

- 按企业组织范围展示
- 选择器模式禁止展示无关动作

### 11.3 搜索

- 搜索结果只展示当前用户有权限访问的数据

---

## 12. 多端设计要求

### 12.1 Web/Desktop

- 搜索页允许更宽结果布局
- 组织架构页优先双栏
- 群设置页允许 section 常驻

### 12.2 Mobile

- 使用更强的分层导航
- 选择器优先独立页面

---

## 13. 测试重点

- 群权限显隐
- 退群/解散群动作链路
- 组织浏览与选择模式切换
- 搜索结果跳转准确性
- 收藏详情二次跳转准确性
