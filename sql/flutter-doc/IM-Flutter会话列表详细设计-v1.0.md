# IM Flutter 会话列表详细设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter 会话列表页的页面结构、状态、交互、同步与多端策略详细设计  

---

## 1. 目标

把会话列表页从“总纲级设计”推进到“可直接编码”的详细设计。

会话列表页的高频菜单与交互覆盖以 `IM-Flutter功能覆盖与交互验收清单-v1.0.md` 为总基线。

---

## 2. 页面职责

`ConversationListPage` 负责：

- 会话首屏展示
- pinned / normal 分区展示
- 分类筛选
- 搜索入口
- 未读展示
- `@我` 提示
- 角标与会话协同
- 下拉刷新
- 前后台前台同步
- 长按菜单操作
- 进入聊天页

---

## 3. 页面结构

推荐组件树：

- `ConversationListScaffold`
  - `ConversationStatusBar`
  - `ConversationHeader`
  - `ConversationSearchBar`
  - `ConversationCategoryBar`
  - `ConversationInlineNoticeBar`
  - `ConversationRefreshContainer`
    - `PinnedConversationSection`
    - `NormalConversationSection`
  - `ConversationContextMenuSheet`

---

## 4. 页面状态

### 4.1 `ConversationListState`

建议字段：

- `status`
- `conversations`
- `pinnedConversations`
- `normalConversations`
- `selectedCategory`
- `searchKeyword`
- `cursorVersion`
- `totalUnread`
- `inlineNotice`
- `refreshing`
- `syncing`
- `isPinnedFolded`
- `contextMenuTarget`
- `lastSyncAt`
- `errorMessage`

### 4.2 状态枚举

- `initial`
- `loading`
- `refreshing`
- `syncing`
- `ready`
- `empty`
- `failed`

---

## 5. 数据来源

### 5.1 首屏来源

优先级：

1. 本地 conversation cache
2. 本地 badge cache
3. 服务端 conversation list / sync
4. socket 实时提示

### 5.2 最终态规则

1. socket 只做提示
2. 最终会话态以 `conversation/sync` 为准
3. 最终未读态以 sync + badge 收敛结果为准

---

## 6. 分类与筛选

### 6.1 推荐分类

- `latest`
- `user`
- `group`
- `at`
- `nodisturb`

### 6.2 筛选规则

- `latest`：全部会话
- `user`：单聊
- `group`：群聊
- `at`：`lastMessageHasAtMe = true`
- `nodisturb`：`noDisturb = true`

### 6.3 搜索规则

- 搜索只作用于当前会话列表展示集
- 输入框清空后恢复当前分类默认列表

---

## 7. pinned / normal 分区

### 7.1 分区规则

- `isPinned = true` 进入 pinned 区
- 其余进入 normal 区

### 7.2 排序规则

优先级：

1. `isPinned`
2. `lastMessageTime`
3. stable fallback

### 7.3 折叠规则

- pinned 会话超过阈值时允许折叠
- 折叠态只影响展示，不影响数据源

---

## 8. 会话卡片设计

### 8.1 展示字段

- 头像 / 群图标
- 名称
- 群成员数
- 最近消息时间
- 最近消息摘要
- `@我` 标识
- 未读数 / 免打扰红点
- 免打扰图标

### 8.2 摘要规则

- 统一通过 `ConversationPreviewBuilder`
- 不允许页面内直接拼各种消息类型摘要

### 8.3 未读展示规则

- 免打扰会话显示红点
- 普通会话显示数字 badge
- 超过阈值统一显示 `99+`

---

## 9. 交互动作

### 9.1 点击会话

动作：

- 使用 `ChatEntryArgs.latest`
- 进入 `ChatPage`

### 9.2 长按会话

动作菜单建议：

- 置顶 / 取消置顶
- 标记已读 / 标记未读
- 删除会话

### 9.3 下拉刷新

动作：

- 拉取最新会话列表 / sync
- 刷新 badge
- 收敛 inline notice

### 9.4 顶部快捷动作

保留抽象入口：

- 扫码
- 新建群聊
- 手动刷新/调试入口

这些入口通过 action coordinator 统一派发。

---

## 10. inline notice 设计

### 10.1 用途

- 群移除提示
- 轻量业务提示
- 非阻塞异常提示

### 10.2 行为规则

- 自动消失
- 可手动关闭
- 不打断会话列表操作

---

## 11. 前后台与刷新策略

### 11.1 on foreground

前台恢复时判断：

- 本地列表是否为空
- socket 是否断开
- 最近 sync 是否过旧
- 页面隐藏时长是否超过阈值

满足任一条件则触发 sync。

### 11.2 refresh throttling

- 手动刷新需节流
- 若刚完成实时同步，可跳过重复请求
- 若服务端返回 `429`，尊重 `Retry-After`

---

## 12. controller 设计

### 12.1 `ConversationListController`

建议动作：

- `load()`
- `refresh()`
- `syncIncrementally()`
- `selectCategory()`
- `inputSearchKeyword()`
- `clearSearch()`
- `togglePinnedFold()`
- `openConversation()`
- `showContextMenu()`
- `hideContextMenu()`
- `pinConversation()`
- `markConversationRead()`
- `markConversationUnread()`
- `deleteConversation()`
- `showInlineNotice()`
- `hideInlineNotice()`

### 12.2 协调器

- `ConversationSyncCoordinator`
- `BadgeController`
- `SocketSessionController`

---

## 13. use case 建议

- `LoadConversationListUseCase`
- `RefreshConversationListUseCase`
- `SyncConversationsIncrementallyUseCase`
- `PinConversationUseCase`
- `ToggleConversationNoDisturbUseCase`
- `DeleteConversationUseCase`
- `MarkConversationReadUseCase`
- `OpenOrCreateConversationUseCase`

---

## 14. 多端差异

### 14.1 Mobile

- 单栏
- 长按菜单用 action sheet

### 14.2 Web/Desktop

- 左栏常驻
- 右键菜单可替代长按
- pinned 折叠与筛选更适合常驻显示

---

## 15. 验收标准

1. 首屏优先从本地缓存快速展示
2. socket 提示与 sync 不互相打架
3. pinned / normal 分区稳定
4. badge 与会话未读一致
5. 点击会话能稳定进入聊天页
6. 长按操作后列表状态正确收敛
