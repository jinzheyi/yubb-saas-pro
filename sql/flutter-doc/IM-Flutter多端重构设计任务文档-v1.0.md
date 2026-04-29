# IM Flutter 多端重构设计任务文档 v1.0

> 文档日期：2026-04-29  
> 目标工程：`shengyu-ui/shengyu-ui-admin-flutter`  
> 文档定位：Flutter 多端 IM 的目标态设计与开工基线  

---

## 1. 文档目标

本文件只描述 Flutter 版本应该如何实现，不记录历史页面，不保留兼容性叙事，不为旧实现让步。

本文件直接服务于：

- Flutter 架构设计
- Flutter 代码生成与 AI 协作开发
- 功能拆解与验收
- 多端一致性落地

配套详细文档：

- `sql/flutter-doc/IM-Flutter架构与工程规范-v1.0.md`
- `sql/flutter-doc/IM-Flutter核心状态机与时序设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter数据模型与存储设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter聊天页详细设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter会话角标Socket协同设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter群设置通讯录搜索详细设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter类命名与文件组织规范-v1.0.md`
- `sql/flutter-doc/IM-FlutterUseCase与数据访问分层设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter通用业务工具与基础规则-v1.0.md`
- `sql/flutter-doc/IM-Flutter消息类型与组件映射规范-v1.0.md`
- `sql/flutter-doc/IM-Flutter目录树与文件清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter核心字段表-v1.0.md`
- `sql/flutter-doc/IM-Flutter第一阶段文件级实施清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter依赖与Pubspec建议-v1.0.md`
- `sql/flutter-doc/IM-Flutter首批类骨架与文件职责-v1.0.md`
- `sql/flutter-doc/IM-Flutter第一阶段测试清单-v1.0.md`
- `sql/flutter-doc/IM-FlutterPubspec草案-v1.0.md`
- `sql/flutter-doc/IM-Flutter索引总表-v1.0.md`
- `sql/flutter-doc/IM-Flutter聊天页事件命令状态表-v1.0.md`
- `sql/flutter-doc/IM-Flutter会话页事件命令状态表-v1.0.md`
- `sql/flutter-doc/IM-Flutter第一阶段代码骨架模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter对象代码模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览与多格式渲染设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件上传与发送链路设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览控制器与策略设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览页面交互设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览代码模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览对象模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览测试清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter页面实现蓝图-v1.0.md`
- `sql/flutter-doc/IM-Flutter页面与路由详细设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter开发任务拆解清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter音视频通话企业级设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter核心协议与事件契约-v1.0.md`
- `sql/flutter-doc/IM-Flutter基础设施选型与抽象层治理-v1.0.md`
- `sql/flutter-doc/IM-Flutter移动端离线推送设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter地图与位置能力设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter主目录与阅读顺序-v1.0.md`
- `sql/flutter-doc/IM-Flutter后端协同约束与接口整顿建议-v1.0.md`
- `sql/flutter-doc/IM-Flutter视觉与交互设计规范-v1.0.md`

---

## 2. 产品目标

构建一套企业级 IM Flutter 客户端，覆盖：

- Web
- Android
- iOS
- Windows
- macOS

目标能力：

- 统一登录与鉴权
- 消息会话列表
- 单聊 / 群聊
- 多消息类型
- 搜索
- 收藏
- 组织通讯录
- 群管理
- 已读回执
- 角标同步
- 文件与媒体
- 音视频通话
- 多端在线一致性

---

## 3. 全局实现原则

1. 只以 Flutter 最优工程标准实现。
2. 不保留旧前端结构，不保留旧页面职责划分。
3. 所有业务模型、状态机、缓存结构、路由协议重新定义。
4. 所有 Long / ID / 序列号字段统一按 `String` 处理。
5. 多端共享同一套业务域模型，平台差异只允许出现在适配层。
6. 页面只做展示与动作派发，业务规则必须下沉。

### 3.1 基础设施选型治理规则

以下规则适用于音视频、地图、离线推送、文件预览、存储、识别类能力：

1. 能自研并可长期稳定维护的能力，优先自研。
2. 若行业能力无法合理自研，则允许依赖第三方基础设施。
3. 第三方能力优先选择：
   - 真正可持续使用
   - 资费低或基础额度友好
   - 技术与商务稳定
   - 替换成本可控
4. 若存在完整开源且可自部署方案，优先级高于闭源 SaaS 方案。
5. 若必须依赖厂商通道或地图底图等不可替代能力，必须通过平台抽象层接入，避免业务层直接绑定单一供应商。
6. 任何第三方方案都不得让 Flutter 页面层直接感知其 SDK 细节。
7. 所有基础设施能力都必须具备“主方案 + 备选方案 + 替换边界”设计。

### 3.2 UI 设计路线

Flutter IM 的视觉与交互路线冻结为：

- 苹果年轻化
- 简约克制
- 现代轻盈
- 企业级可读性强

实现要求：

1. 页面气质优先参考 Cupertino / Apple HIG 方向。
2. 允许应用壳使用跨平台根容器，但页面内部组件尽量保持 Cupertino 风格。
3. 导航层、工具层、内容层必须明确分离。
4. 不走厚重后台风，不走营销风，不走花哨渐变风。
5. 所有页面最终以统一视觉规范文档为准。


---

## 4. 冻结的业务不变式

以下业务语义必须作为 Flutter 实现基石。

### 4.1 标识与精度

- 所有 ID、版本号、序列号、游标统一使用 `String`
- 包括但不限于：
  - `messageId`
  - `chatId`
  - `groupId`
  - `userId`
  - `tenantId`
  - `sequence`
  - `cursorVersion`
  - `conversationVersion`
  - `lastReadSequence`
  - `lastMessageSequence`

### 4.2 会话规则

- 会话主键统一为 `chatId`
- 群消息查询统一为 `chatId`
- `lastReadSequence` 只升不降
- `cursorVersion` 用于会话增量同步
- `conversationVersion` 用于会话幂等合并

### 4.3 消息规则

- 消息最终态以更大 `rev` 为准
- 引用关系主键为 `quoteMessageId`
- 搜索和定位优先依赖 `sequence`
- 语音未听状态与已读状态分离

### 4.4 鉴权规则

- HTTP 与 WebSocket 共用 token 生命周期
- 401 刷新必须单飞
- refresh 成功后触发 WebSocket 同连接 reauth

### 4.5 文件规则

- 文件访问必须走服务端预签名或打开策略
- 客户端不固化临时地址

---

## 5. Flutter 总体架构

### 5.1 分层

采用四层结构：

1. `presentation`
2. `application`
3. `domain`
4. `infrastructure`

### 5.2 目录

```text
lib/
  app/
    bootstrap/
    router/
    theme/
    l10n/
  core/
    auth/
    network/
    websocket/
    storage/
    platform/
    logging/
    error/
  features/
    login/
    im/
      conversation/
      chat/
      message/
      group/
      contact/
      search/
    favorite/
    receipt/
    media/
    call/
  profile/
  workbench/
  shared/
    widgets/
    models/
    enums/
```

### 5.3 技术基线

推荐：

- 状态管理：`Riverpod`
- 路由：`go_router`
- 网络：`Dio`
- JSON 模型：代码生成方案
- 本地数据：
  - 安全存储：token 等敏感信息
  - KV：设备级主题/语言、草稿、视口恢复
  - 结构化数据库：消息、会话、索引

---

## 6. 模块边界

### 6.1 app

职责：

- 启动流程
- 路由注册
- 主题
- 国际化
- 全局错误处理

### 6.2 core

职责：

- 鉴权
- 网络拦截器
- WebSocket 客户端
- 存储
- 平台适配
- 日志与埋点

### 6.3 features/im

按领域拆分：

- `conversation`
- `chat`
- `message`
- `group`
- `contact`
- `search`
- `favorite`
- `receipt`
- `media`

---

## 7. 必须先冻结的核心实体

- `AuthToken`
- `CurrentUser`
- `DeviceInfo`
- `Conversation`
- `ConversationCursorState`
- `ChatEntryArgs`
- `ChatViewportState`
- `Message`
- `MessageExtra`
- `QuoteInfo`
- `VoicePlayedState`
- `GroupInfo`
- `GroupMember`
- `Contact`
- `DeptNode`
- `GlobalSearchItem`
- `FavoriteItem`
- `BadgeState`
- `ReadReceiptSummary`

---

## 8. Repository 设计

### 8.1 AuthRepository

- login
- smsLogin
- refreshToken
- logout
- getPermissionInfo

### 8.2 ConversationRepository

- getConversationList
- searchConversations
- createConversation
- deleteConversation
- updateConversationPreference
- markReadBySequence
- getConversationByTarget
- syncConversationsIncrementally

### 8.3 MessageRepository

- getMessageWindow
- getMessageHistory
- pullMessages
- sendMessage
- recallMessage
- deleteMessage
- clearConversationMessages
- getMessageDetail
- searchMessages
- markMessageRead
- forwardMessages
- markVoicePlayed
- markVoicePlayedBatch
- getVoicePlayedStatus
- searchLocation

### 8.4 GroupRepository

- createGroup
- getGroup
- updateGroup
- dissolveGroup
- quitGroup
- getGroupMembers
- addMembers
- removeMembers
- setMemberRole
- setMemberMuted
- setMuteAll
- setMemberNickname
- transferOwner
- generateInvite
- verifyInvite
- joinByInvite
- getJoinRequests
- approveJoinRequest
- rejectJoinRequest
- updateGroupNotice

### 8.5 ContactRepository

- getContacts
- searchContacts
- getContact
- updateContactSetting
- getDeptContacts
- getStarContacts
- getMyDeptTree
- getOrgTree

### 8.6 SearchRepository

- getHotSearch
- searchGlobal

### 8.7 FavoriteRepository

- getFavorites
- searchFavorites
- getFavoriteDetail
- addFavorite
- removeFavorite
- resendFavorite

### 8.8 FileRepository

- uploadAndCreateFile
- getChatMediaList
- getGroupFileList
- getPresignedGetUrl
- getFileOpenStrategy

### 8.9 ReceiptRepository

- getReadReceiptSummary
- getReadReceiptDetail

---

## 9. WebSocket 目标设计

独立实现 `ImSocketClient`，职责只包括：

- connect
- disconnect
- auth
- reauth
- heartbeat
- reconnect
- message stream dispatch
- close reason handling
- codec abstraction

禁止把页面状态、消息列表、UI 恢复逻辑写进 socket 客户端。

---

## 10. 页面蓝图

### 10.1 登录页

页面：`LoginPage`

职责：

- 账号登录
- 手机登录
- 验证码触发
- 语言切换入口

实现要求：

- 页面只派发登录动作
- 登录成功后的初始化由 `AuthBootstrapCoordinator` 负责

### 10.2 会话列表页

页面：`ConversationListPage`

职责：

- 会话列表展示
- 会话搜索入口
- 置顶态展示
- 未读态展示
- 进入聊天页

状态：

- loading
- refreshing
- ready
- syncFailed

### 10.3 聊天页

页面：`ChatPage`

职责：

- latest / anchor / restore 三种进入模式
- 消息列表
- 历史翻页
- 发送区
- 多消息类型渲染
- 已读推进
- 语音未听同步
- 引用定位
- 转发、收藏、撤回、删除

必须拆分：

- `ChatController`
- `ChatTimelineController`
- `ChatComposerController`
- `ChatMediaController`
- `ChatReceiptController`

### 10.4 单聊设置页

页面：`DirectChatSettingsPage`

职责：

- 置顶
- 免打扰
- 聊天文件入口
- 聊天记录入口
- 清空聊天记录

### 10.5 群设置页

页面：`GroupSettingsPage`

职责：

- 群概览
- 群成员预览
- 群治理设置
- 会话设置
- 高危操作

必须拆分 section：

- `GroupOverviewSection`
- `GroupMembersPreviewSection`
- `GroupConversationPreferenceSection`
- `GroupGovernanceSection`
- `GroupDangerZoneSection`

### 10.6 群成员页

页面：`GroupMembersPage`

职责：

- 查看成员
- 搜索成员
- 角色操作
- 移除成员

### 10.7 入群申请页

页面：`GroupJoinRequestsPage`

职责：

- 待处理
- 已处理
- 同意/拒绝

### 10.8 群公告页

页面：`GroupNoticePage`

职责：

- 查看公告
- 编辑公告

### 10.9 群邀请页

页面：`GroupInvitePage`

职责：

- 邀请码
- 二维码
- 分享

### 10.10 全局搜索页

页面：`GlobalSearchPage`

职责：

- 热搜
- 搜索历史
- 聚合搜索
- tab 切换
- 结果跳转

### 10.11 收藏页

页面：

- `FavoritesPage`
- `FavoriteDetailPage`

职责：

- 收藏列表
- 搜索收藏
- 收藏详情
- 再转发
- 跳聊天定位

### 10.12 通讯录页

页面：

- `ContactsHomePage`
- `OrgBrowserPage`
- `MyDepartmentPage`
- `MyGroupsPage`
- `StarContactsPage`
- `UserProfilePage`

### 10.13 辅助页

- `ChatHistorySearchPage`
- `ChatMediaPage`
- `ForwardTargetPickerPage`
- `MergedForwardDetailPage`
- `MentionPickerPage`
- `ContactCardPickerPage`
- `LocationPickerPage`
- `LocationViewPage`
- `FilePreviewPage`

---

## 11. 聊天页状态机

### 11.1 入口模式

- `latest`
- `anchor`
- `restore`

优先级：

1. `anchorSequence`
2. `anchorMessageId`
3. `restore`
4. `latest`

### 11.2 页面状态

- idle
- initializing
- loadingWindow
- loadingHistory
- restoringViewport
- ready
- sending
- reconnecting
- failed

### 11.3 输入区状态

- text
- voice
- quoted
- expanded
- multiSelect

### 11.4 视口恢复数据

- `entryMode`
- `atBottom`
- `viewportAnchorSequence`
- `topVisibleSequence`
- `bottomVisibleSequence`
- `savedAt`

TTL：

- 15 分钟

---

## 12. 多消息类型实现要求

必须支持：

- 文本
- 图片
- 视频
- 文件
- 语音
- 位置
- 名片
- 表情
- 自定义表情
- 引用回复
- 合并转发
- 系统提示

实现要求：

- 统一 `MessageType`
- 统一 `MessageBubbleFactory`
- 不允许在聊天页主文件用巨型条件分支直接渲染全部消息类型

---

## 13. 多端适配策略

### 13.1 平台差异边界

平台差异只允许存在于：

- 文件选择
- 录音
- 音视频播放
- 实时音视频通话
- 键盘与焦点
- 浏览器可见性
- 窗口尺寸
- 剪贴板
- 扫码

### 13.2 布局

- Mobile：单栏
- Web / Desktop：双栏或三栏自适应

### 13.3 生命周期

统一抽象：

- app foreground/background
- page show/hide
- visibility change
- pending task flush

---

## 14. 本地数据策略

### 14.1 Secure Storage

- accessToken
- refreshToken
- tenantId
- deviceId

### 14.2 KV Storage

- 设备级主题与语言
- 草稿
- 搜索历史
- 视口恢复

### 14.3 Structured Storage

- 会话缓存
- 消息缓存
- 引用索引
- 语音播放状态
- 最近搜索索引

---

## 15. 页面级强制规则

1. 页面不得直接调用 raw API。
2. 页面不得直接拼 storage key。
3. 页面不得直接处理 WebSocket 连接生命周期。
4. 页面不得直接维护复杂消息合并逻辑。
5. 所有聊天跳转必须统一用 `ChatEntryArgs`。
6. 选择器必须组件化，不得按页面复制。
7. 高危操作必须通过 coordinator 执行。

---

## 16. 开工顺序

1. 冻结实体与枚举
2. 搭建网络层与 refresh coordinator
3. 搭建 `ImSocketClient`
4. 落会话列表
5. 落聊天页状态机
6. 落消息类型与发送链路
7. 落群设置与通讯录
8. 落搜索、收藏、文件
9. 做多端回归

---

## 17. 完成定义

### 17.1 架构完成

- 领域边界清晰
- 页面不直连 API
- socket 与页面解耦
- 路由参数统一

### 17.2 业务完成

- 会话、聊天、群、联系人、搜索、收藏可闭环
- 已读与角标一致
- 撤回与引用不回滚
- 语音未听状态可跨端同步

### 17.3 多端完成

- Web、Android、iOS、Windows、macOS 主链路可用
