# IM Flutter 统一任务文档 v1.0

> 文档日期：2026-05-01
> 目标工程：`shengyu-ui/shengyu-ui-admin-flutter`
> 文档定位：Flutter IM 项目统一执行文档。后续开发、续接、排期、状态判断逐步收敛到本文件。

---

## 1. 文档使用规则

本文件用于把 `sql/flutter-doc` 下分散的 Flutter IM 文档逐步收敛成一份总任务文档。

当前执行规则：

1. 先整合，后归档保留
2. 每次只收敛一批明确范围的源文档
3. 每收敛一批，都要在本文件登记来源与状态
4. 源文档不删除，统一保留为归档参考
5. 非必要的 mock 交互、临时测试入口、演示型流程默认不做，节省 token、时间与无效返工
6. 后续新任务默认先看本文件任务状态，再决定是否进入代码实现
7. 当页面或链路从 mock / 本地骨架切到真实功能时，凡属稳定用户文案、真实设置项、真实网络交互结果，需同步接入国际化；纯占位中文不强制国际化
8. 测试服务、联调服务、调试服务默认由用户手动启动，当前代理不主动启动服务，节省 token 与无效过程输出
9. 每完成一项明确任务后，必须同步更新本文件中的任务状态标记、当前正在进行的任务、以及下一项即将开始的任务
10. 页面状态判断、按钮显示、权限分支、字段映射必须优先基于服务端真实接口返回的 VO / DTO 语义字段实现，禁止使用中文展示文案做逻辑判断，例如禁止 `role == '群主'` 这类写法，应该改为基于 `role` 枚举值、状态码、布尔字段或明确标识字段判断
11. 本文件后续新增或推进的每个真实功能任务，必须补充对应接口依据，至少写明：接口路径、核心入参、核心出参字段、页面侧如何消费这些字段；如果接口缺失，则明确标记为 `blocked` 或“待后端补充”
12. 后续专题不单独建设审计、日志、监控子功能；文档只保留真实后端接口流程链路、页面联动规则、状态收口规则，避免偏离功能主线

续接约定：

1. 当前会话内，用户一般只需输入：`继续`
2. 新开对话时，统一续接指令固定为：
   - `系统性阅读sql/flutter-doc/IM-Flutter统一任务文档-v1.0.md文档继续稳步推进`
3. 每次续接后，默认先做三件事：
   - 读取本文件当前任务状态
   - 明确当前正在进行的任务
   - 明确下一项即将开始的任务
4. 后续不再额外要求用户重复说明执行方式；若无新约束，默认严格按本节续接

当前保留策略：

- `sql/flutter-doc/IM-Flutter统一任务文档-v1.0.md`：统一执行入口
- `sql/flutter-doc/img/`：老项目视觉参考
- `sql/flutter-doc/环境.md`：环境说明
- 其余 `IM-Flutter*.md`：即使完成收敛也继续保留，作为归档参考

---

## 2. 本轮收敛范围

当前收敛状态：

1. 统一文档已覆盖原 Flutter IM 文档体系的 9 个批次内容
2. 旧 `IM-Flutter*.md` 文档全部保留为归档参考
3. 后续推进默认只读本文件，进入具体专题时再按需回看源文档
4. 本文件当前定位已经从“汇总文档”提升为“唯一执行主文档”

批次总览：

| 批次 | 范围 | 状态 |
|---|---|---|
| Batch 1 | 主目录、进度、第一阶段清单、骨架、索引 | `completed` |
| Batch 2 | 总纲、协议、架构、目录、后端协同 | `completed` |
| Batch 3 | 状态机、模型、字段、分层、命名、基础能力 | `completed` |
| Batch 4 | 页面、路由、登录、会话、聊天、群设置、通讯录、搜索 | `completed` |
| Batch 5 | 视觉、主题、国际化、验收 | `completed` |
| Batch 6 | 文件上传、文件预览、打开策略 | `completed` |
| Batch 7 | 音视频通话 | `completed` |
| Batch 8 | 多端平台、OpenHarmony/HarmonyOS、推送、地图 | `completed` |
| Batch 9 | 依赖、测试、模板、任务拆解、后端优先级、续接规则 | `completed` |

来源文档分组索引见文末“归档来源分组索引”。

完整性说明：

1. 本文件当前已完整收敛原 Flutter IM 旧专题文档的任务目标、约束、顺序、状态、骨架与专题摘要
2. 后续继续推进企业级 IM 客户端时，应默认以本文件作为唯一执行依据
3. 旧专题文档保留的意义主要是归档、追溯来源、核对历史表述，不再承担主执行职责
4. 这里的“完整”指：
   - 已完整覆盖任务规划与专题设计层
   - 已完整覆盖页面/协议/状态机/平台/通话/文件/测试等主范围
   - 已完整覆盖当前已知执行约束与后续续接规则
5. 这里的“完整”不等于：
   - 代码已经全部实现完成
   - 后端接口已经全部闭环
   - 所有细节都不再需要继续查漏
6. 因此后续工作方式应是：
   - 不再新增平行任务文档
   - 直接依据本文件持续推进实现
   - 在推进中把新发现的真实差距持续回填到本文件

---

## 3. 项目目标

Flutter IM 客户端目标覆盖：

- Web
- Android
- iOS
- Windows
- macOS

目标能力包括：

- 登录与鉴权
- 会话列表
- 单聊/群聊
- 多消息类型
- 搜索
- 收藏
- 组织通讯录
- 群管理
- 已读与角标
- 文件与媒体
- 音视频通话
- 多端在线一致性

---

## 4. 冻结业务不变式

以下规则作为 Flutter IM 实现基石：

### 4.1 标识与精度

所有 ID、版本号、序列号、游标统一按 `String` 处理，包括但不限于：

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
- `cursorVersion` 只前进
- `conversationVersion` 用于会话幂等合并

### 4.3 消息规则

- 消息最终态以更大 `rev` 为准
- 引用关系主键为 `quoteMessageId`
- 搜索和定位优先依赖 `sequence`
- 语音未听状态与已读状态分离

### 4.4 鉴权规则

- HTTP 与 WebSocket 共用 token 生命周期
- 401 刷新必须单飞
- refresh 成功后必须触发 WebSocket 同连接 reauth

### 4.5 文件规则

- 文件访问必须走服务端预签名或打开策略
- 客户端不固化临时地址

---

## 5. 当前执行原则

### 5.1 总原则

1. 先主链路，后复杂专题
2. 先真实数据/真实接口挂点，后页面细节
3. 暂停继续扩张设计文档，优先把既有文档收敛
4. 不投入 mock 交互、mock 事件、演示型测试入口
5. 非必要测试不执行，只保留最小校验：
   - `dart format`
   - `flutter analyze`
6. 所有真实功能接线、页面显隐规则、状态切换、权限判断，默认先核对服务端真实接口与返回字段，再落 Flutter 页面逻辑

### 5.2 当前纠偏规则

禁止继续陷入两类偏差：

1. 在单一复杂专题里持续局部优化
2. 没有真实数据接线支撑时继续泛化做 UI 收口

### 5.3 controller 默认含义

若无特别说明，`controller` 默认指 Flutter 端：

- controller
- coordinator
- provider
- state

不代表已经开始改后端 `service/controller`。

---

## 6. 核心协议总线

### 6.1 HTTP 契约

- `accessToken` 用于业务接口
- `refreshToken` 用于续期
- 401 刷新必须单飞
- 单飞刷新成功后等待中的请求统一重放
- 基础请求拦截层必须具备：
  - `Authorization`
  - `tenantId`
  - `deviceId`
  - `locale`
  - `requestId`
- DTO 只停留在 `infrastructure`
- 页面层不接触 raw response

### 6.2 WebSocket 契约

`ImSocketClient` 只负责：

- connect
- disconnect
- auth
- reauth
- heartbeat
- reconnect
- codec
- event dispatch

明确禁止：

- 在 socket 客户端持有 UI 状态
- 在 socket 客户端维护消息列表
- 在 socket 客户端做页面恢复逻辑

Socket 状态机：

- `disconnected`
- `connecting`
- `probing`
- `authenticating`
- `connected`
- `reauthenticating`
- `reconnectWaiting`
- `invalidated`

### 6.3 Socket 事件分层

- session 级：`connected` `authSucceeded` `authFailed` `reauthSucceeded` `invalidated` `reconnecting`
- conversation 级：`conversationHint` `conversationUpdated` `conversationDeleted`
- message 级：`messageReceived` `messageRecalled` `readReceiptChanged` `voicePlayedChanged`
- badge 级：`badgeUpdated`
- call 级：`callInvite` `callAccepted` `callRejected` `callBusy` `callCancelled` `callEnded` `callStateSync` `callDeviceTerminated`

### 6.4 会话增量同步

1. socket 只负责提示，不负责最终态
2. 最终会话状态以增量同步结果为准
3. `cursorVersion` 只前进
4. reconnect 后顺序：
   - socket reconnect
   - socket reauth
   - conversation incremental sync
   - chat pull after reconnect

### 6.5 聊天消息

- 本地先创建临时发送态消息
- 服务端确认后归并 `messageId / sequence`
- 最终展示态受 `rev` 保护
- 必须支持：
  - text
  - image
  - video
  - file
  - voice
  - location
  - contactCard
  - emoji
  - customEmoji
  - quoteReply
  - mergedForward
  - system
  - callRecord

### 6.6 已读与语音未听

- `readSequence` 只升不降
- 页面离开时必须 flush
- 语音未听与 read watermark 完全分离

### 6.7 文件打开协议

服务端必须返回打开策略对象，建议字段：

- `renderStrategy`
- `contentType`
- `previewUrl`
- `downloadUrl`
- `viewerUrl`
- `convertedPdfUrl`
- `expiresAt`
- `unstable`
- `message`

客户端只消费 `FilePreviewDescriptor`。

### 6.8 音视频通话协议

- 业务信令与媒体信令分离
- IM 后端负责业务状态
- WebRTC 层负责媒体连接
- 页面只消费 `CallState`
- 建议冻结事件：
  - `call.invite`
  - `call.ringing`
  - `call.accepted`
  - `call.rejected`
  - `call.busy`
  - `call.cancelled`
  - `call.ended`
  - `call.timeout`
  - `call.media-token-issued`
  - `call.device-terminated`

---

## 7. 架构与目录约束

### 7.1 分层

采用四层结构：

1. `presentation`
2. `application`
3. `domain`
4. `infrastructure`

### 7.2 分层职责

- `presentation`：页面、组件、UI 状态、用户动作派发
- `application`：use case、协调器、controller/notifier、feature 内编排
- `domain`：entity、value object、repository contract、business rule、policy
- `infrastructure`：datasource、dto、dio、websocket codec、local db、storage impl、platform impl

禁止事项：

- 页面直接调用 raw API
- 页面直接处理 DTO
- socket 层持有页面 UI 状态
- 页面/组件内拼接 storage key

### 7.3 技术基线

- 状态管理：`Riverpod`
- 路由：`go_router`
- 网络：`Dio`
- JSON 模型：代码生成方案
- 本地数据：
  - 安全存储：token
  - KV：主题/语言/草稿/视口恢复
  - 结构化数据库：消息/会话/索引

### 7.4 工程目录

```text
lib/
  app/
    bootstrap/
    router/
    theme/
    l10n/
    shell/
  core/
    auth/
    network/
    websocket/
    storage/
    formatting/
    dict/
    avatar/
    navigation/
    platform/
      push/
      map/
      rtc/
    logging/
    error/
    analytics/
  features/
    login/
    im/
      conversation/
      chat/
      call/
      group/
      contact/
      search/
      favorite/
      receipt/
      media/
    profile/
    workbench/
  shared/
    widgets/
    layout/
    extensions/
    constants/
    enums/
```

### 7.5 Feature 模板

每个 feature 统一采用：

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

### 7.6 核心规范

- provider 命名遵循 `xxxControllerProvider`
- controller 状态必须是强类型对象
- 聊天页入口统一走 `ChatEntryArgs`
- 所有业务跳转必须有强类型参数对象
- DTO / Entity / UIModel 三层分离
- 第三方基础设施必须通过 `adapter / facade` 接入

---

## 8. 后端协同边界

### 8.1 已反推主链路接口

- 认证：`/system/auth/login` `/system/auth/refresh-token` `/system/auth/get-permission-info`
- 会话：`/system/im/conversation/list` `/sync` `/mark-read-seq` `/get-by-target`
- 消息：`/system/im/message/window` `/history` `/send` `/pull` `/mark-read`
- 角标：`/system/im/badge/get`
- 用户：`/system/user/get` `/system/user/get-profile`

### 8.2 出口统一策略

第一优先级是对客户端出口层统一字符串化：

1. HTTP Response VO 关键标识字段统一声明为 `String`
2. WebSocket 客户端事件统一按字符串语义接收
3. Flutter 文档与实现全部按 `String` 处理

适用字段：

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

### 8.3 WebSocket starter 边界

starter 继续只负责：

- 连接管理
- 鉴权
- 心跳
- session 生命周期
- 多端会话治理
- 消息编解码
- processor 分发

不应下沉：

- 会话业务状态机
- 消息存储业务规则
- IM 通话业务状态
- 群治理规则
- 页面语义

### 8.4 session 协议建议

建议标准 session 级事件：

- `session.reauth-required`
- `session.kicked`
- `session.invalidated`
- `session.revoked`

### 8.5 会话与消息最终态

- WebSocket `conversationHint` 只做提示
- 会话最终态以 `/conversation/sync` 为准
- socket 实时到达负责实时性
- `/message/pull` 负责断线补偿
- `/message/window` `/history` 负责聊天页窗口正确性
- `/conversation/mark-read-seq` 是读水位主链路

---

## 9. 状态标记规范

统一状态：

- `not_started`
- `analyzing`
- `documented`
- `ready_for_codegen`
- `coding`
- `verifying`
- `completed`
- `blocked`

---

## 10. 当前总进度

### 6.1 总纲层

| 项目 | 状态 |
|---|---|
| 主目录与阅读顺序 | `completed` |
| 核心协议与事件契约 | `completed` |
| 架构与工程规范 | `completed` |
| 目录树与文件清单 | `completed` |
| 后端协同约束 | `completed` |

### 6.2 核心业务层

| 项目 | 状态 |
|---|---|
| 会话列表详细设计 | `documented` |
| 聊天页详细设计 | `documented` |
| 聊天页平台能力接线图 | `ready_for_codegen` |
| 登录页详细设计 | `documented` |
| 国际化与语言设置设计 | `documented` |
| 主题模式设计 | `documented` |
| 通用业务工具与基础规则 | `documented` |
| 多端平台兼容落地设计 | `documented` |
| 功能覆盖与交互验收清单 | `documented` |
| 核心基础能力代码模板 | `ready_for_codegen` |
| 文件上传与发送链路设计 | `ready_for_codegen` |
| 文件预览体系设计 | `ready_for_codegen` |
| 音视频通话体系设计 | `documented` |
| 地图与位置能力设计 | `documented` |
| 移动端离线推送设计 | `documented` |

### 6.3 可直接代码生成层

| 项目 | 状态 |
|---|---|
| 第一阶段代码骨架模板 | `documented` |
| 文件上传对象模板 | `ready_for_codegen` |
| 文件上传代码骨架模板 | `ready_for_codegen` |
| 文件预览控制器与策略设计 | `ready_for_codegen` |
| 文件预览代码模板 | `ready_for_codegen` |
| 通话控制器与状态设计 | `ready_for_codegen` |
| 通话事件命令状态表 | `ready_for_codegen` |
| 通话对象代码模板 | `ready_for_codegen` |
| 通话代码骨架模板 | `ready_for_codegen` |
| 聊天页事件命令状态表 | `ready_for_codegen` |
| 会话页事件命令状态表 | `ready_for_codegen` |

---

## 11. 推荐开工顺序

### Phase A 文档总纲冻结

1. 主目录
2. 主设计文档
3. 核心协议
4. 架构规范
5. 后端协同约束

### Phase B 代码基线

1. 目录树与文件清单
2. 依赖与 pubspec
3. 第一阶段文件级实施清单
4. 首批类骨架与文件职责
5. 第一阶段代码骨架模板

### Phase C 核心主链路

1. 登录
2. WebSocket
3. 会话列表
4. 聊天页
5. 已读与角标

### Phase D 复杂专题

1. 文件上传
2. 文件预览
3. 音视频通话
4. 地图与位置
5. 离线推送

---

## 12. 第一阶段目标与完成定义

第一阶段只做最小企业级主链路：

- 启动与壳
- 鉴权与网络
- 路由
- WebSocket 骨架
- 会话列表
- 聊天页主状态机

第一阶段必须完成：

1. 登录后进入主壳
2. 会话列表显示
3. 点击会话进入聊天页
4. 聊天页 latest 打开
5. 聊天页 anchor 打开
6. 文本消息发送
7. websocket 收消息
8. 已读水位推进

第一阶段暂不要求：

- 全部消息类型
- 群设置全量能力
- 收藏
- 全局搜索
- 文件预览细节

---

## 13. 第一阶段文件级施工顺序

### Step 1 应用基线

创建：

- `lib/main.dart`
- `lib/app/bootstrap/app_bootstrap.dart`
- `lib/app/router/app_router.dart`
- `lib/app/shell/app_shell.dart`
- `lib/app/theme/app_theme.dart`

DoD：

- App 能启动到空白壳

### Step 2 核心基础设施

创建：

- `core/auth/auth_session.dart`
- `core/auth/refresh_token_coordinator.dart`
- `core/network/dio_client.dart`
- `core/network/interceptors/auth_interceptor.dart`
- `core/network/interceptors/tenant_interceptor.dart`
- `core/network/interceptors/locale_interceptor.dart`
- `core/websocket/im_socket_client.dart`
- `core/storage/storage_key_registry.dart`

DoD：

- 网络客户端与 socket 客户端可注入

### Step 3 路由参数与共享枚举

创建：

- `app/router/route_args/chat_entry_args.dart`
- `app/router/route_args/group_context_args.dart`
- `shared/enums/conversation_type.dart`
- `shared/enums/message_type.dart`
- `shared/enums/message_status.dart`

DoD：

- 聊天路由参数模型冻结

### Step 4 conversation domain contract

创建：

- `features/im/conversation/domain/entities/conversation.dart`
- `features/im/conversation/domain/entities/conversation_cursor_state.dart`
- `features/im/conversation/domain/repositories/conversation_repository.dart`

### Step 5 chat domain contract

创建：

- `features/im/chat/domain/entities/message.dart`
- `features/im/chat/domain/entities/message_extra.dart`
- `features/im/chat/domain/entities/quote_info.dart`
- `features/im/chat/domain/entities/chat_viewport_state.dart`
- `features/im/chat/domain/repositories/message_repository.dart`

### Step 6 conversation application

- `load_conversation_list_use_case.dart`
- `sync_conversations_incrementally_use_case.dart`
- `conversation_sync_result.dart`
- `conversation_sync_coordinator.dart`

### Step 7 chat application

- `open_chat_use_case.dart`
- `load_chat_window_use_case.dart`
- `load_older_messages_use_case.dart`
- `send_message_use_case.dart`
- `mark_conversation_read_use_case.dart`
- `open_chat_command.dart`
- `open_chat_result.dart`

### Step 8 remote datasource + dto

- `conversation_remote_data_source.dart`
- `message_remote_data_source.dart`
- `conversation_dto.dart`
- `message_dto.dart`
- `message_window_response_dto.dart`

### Step 9 repository impl + mapper

- `conversation_repository_impl.dart`
- `message_repository_impl.dart`
- `conversation_dto_mapper.dart`
- `message_dto_mapper.dart`

### Step 10 presentation state + controller

- `conversation_list_state.dart`
- `conversation_list_controller.dart`
- `chat_page_state.dart`
- `chat_timeline_state.dart`
- `chat_controller.dart`
- `chat_timeline_controller.dart`
- `chat_composer_controller.dart`
- `chat_receipt_controller.dart`

### Step 11 page + widgets

- `conversation_list_page.dart`
- `chat_page.dart`
- `conversation_tile.dart`
- `chat_timeline.dart`
- `chat_composer.dart`
- `message_bubble_factory.dart`
- `text_message_bubble.dart`

---

## 14. 第一阶段骨架模板摘要

当前统一骨架形状：

1. `main.dart`
   - `ProviderScope`
   - `ShengyuImApp`
   - `AppBootstrap`
2. `app_bootstrap.dart`
   - `MaterialApp.router`
   - `AppTheme.light/dark`
   - `appRouterProvider`
3. `app_router.dart`
   - `GoRouter`
   - 默认首屏 `/login`
4. `conversation_repository.dart`
   - 会话列表、增量同步、置顶、免打扰 contract
5. `load_conversation_list_use_case.dart`
   - repository 包装型 use case
6. `conversation_list_state.dart`
   - `status/conversations/cursorVersion/error`
7. `conversation_list_controller.dart`
   - load -> ready/failed 状态推进
8. `message_repository.dart`
   - 消息窗口、历史拉取、消息发送 contract
9. `open_chat_use_case.dart`
   - latest / anchor / restore 编排入口
10. `chat_page_state.dart`
   - `entryArgs/pageStatus/chatHeader/isReadOnly/isMultiSelectMode`

说明：

- 本节只保留骨架结构摘要，不在统一文档内重复大段代码模板
- 后续若需要删掉源模板文档，先确认这些模板要点已足够支撑继续开发

---

## 15. 全局索引摘要

### 11.1 路由主干

- `/login`
- `/shell/conversations`
- `/shell/contacts`
- `/shell/workbench`
- `/shell/profile`
- `/chat`
- `/chat/settings/direct`
- `/chat/settings/group`
- `/group/members`
- `/search/global`
- `/favorites`
- `/call/incoming`
- `/call/outgoing`
- `/call/session`

### 11.2 Provider 主干

- `authSessionProvider`
- `dioClientProvider`
- `socketClientProvider`
- `conversationListControllerProvider`
- `chatControllerProvider`
- `chatTimelineControllerProvider`
- `chatComposerControllerProvider`
- `chatReceiptControllerProvider`
- `groupSettingsControllerProvider`
- `contactsHomeControllerProvider`
- `globalSearchControllerProvider`
- `favoritesControllerProvider`
- `callControllerProvider`

### 11.3 UseCase 主干

- Auth/Core：`AuthBootstrapCoordinator` `RefreshTokenCoordinator`
- Conversation：`LoadConversationListUseCase` `SyncConversationsIncrementallyUseCase`
- Chat：`OpenChatUseCase` `LoadChatWindowUseCase` `SendMessageUseCase` `MarkConversationReadUseCase`
- Group：`LoadGroupSettingsUseCase` `LoadGroupMembersUseCase`
- Contact/Search/Favorite：`LoadContactsHomeUseCase` `SearchGlobalUseCase` `LoadFavoritesUseCase`
- Call：`CreateCallInviteUseCase` `AcceptCallUseCase` `HangupCallUseCase` `SyncActiveCallStateUseCase`

### 11.4 Repository 主干

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

## 16. 状态机与模型摘要

### 16.1 核心状态机

- 登录启动：`idle -> submitting -> loginSucceeded -> bootstrapLoading -> ready/failed`
- 会话列表：`initial/loading/refreshing/syncing/ready/failed`
- 聊天页：`initial/initializing/loadingWindow/restoringViewport/ready/loadingHistory/sending/reconnecting/failed`
- 时间线：`empty/loading/ready/locatingAnchor/loadingOlder/exhausted/failed`
- 输入区：`textIdle/textEditing/quoteEditing/voiceReady/voiceRecording/voiceRecorded/expandedPanel`
- 消息发送：`draft/enqueueing/uploading/sending/sent/delivered/read/failed/recalled`
- 已读水位：`idle/pendingFlush/flushing/synced/failed`
- 语音未听：`unplayed/locallyPlayed/pendingSync/synced`
- 搜索：`idle/typing/debouncing/searching/ready/loadingMore/failed`

### 16.2 核心实体

- `AuthToken`：`accessToken/refreshToken/expiresAt/refreshExpiresAt`
- `CurrentUser`：`userId/tenantId/nickname/avatar/deptId/deptName/postName`
- `Conversation`：`chatId/conversationType/targetId/targetName/lastMessageSequence/lastReadSequence/unreadCount/conversationVersion`
- `ConversationCursorState`：`userId/tenantId/cursorVersion/updatedAt`
- `ChatEntryArgs`：`chatId/conversationType/targetId/title/entryMode/anchorSequence/anchorMessageId/restoreKey`
- `ChatViewportState`：`entryMode/atBottom/viewportAnchorSequence/topVisibleSequence/bottomVisibleSequence/savedAt`
- `Message`：`messageId/chatId/senderId/receiverId/groupId/sequence/rev/type/status/content/extra/quote/createdAt/isSelf`
- `MessageExtra`：`fileId/duration/durationMs/size/format/md5/mentionUserIds/recallBy/quoteContent`
- `QuoteInfo`：`quoteMessageId/quoteSenderId/quoteSenderName/quoteContent`
- `GroupInfo`：`groupId/chatId/name/avatar/ownerId/memberCount/notice/muteAll/allowMemberInvite/needApproval/myRole`
- `Contact`：`userId/nickname/remarkName/avatar/deptName/postName/pinyin/star`
- `BadgeState`：`totalUnread/conversationBadges/menuBadges/updatedAt`
- `VoicePlayedState`：`messageId/chatId/played/updatedAt`

### 16.3 核心状态对象

- `ConversationListState`
- `ChatPageState`
- `ChatTimelineState`
- `GlobalSearchState`

### 16.4 关键 Command / Result

- Command：`OpenChatCommand` `SendMessageCommand` `ForwardMessagesCommand`
- Result：`OpenChatResult` `ChatWindowResult` `ConversationSyncResult`

---

## 17. UseCase、命名与基础能力摘要

### 17.1 UseCase 分层规则

- UseCase 命名统一为 `VerbNounUseCase`
- 复杂 UseCase 必须显式定义 `Command` 与 `Result`
- `domain/repositories` 只放 contract
- `infrastructure/repositories/*_repository_impl.dart` 负责 datasource、DTO 映射、错误转换

### 17.2 UseCase 主干

- Chat：`OpenChatUseCase` `LoadChatWindowUseCase` `LoadOlderMessagesUseCase` `LocateMessageUseCase` `RestoreViewportUseCase` `PersistViewportUseCase` `SendMessageUseCase`
- Conversation：`LoadConversationListUseCase` `RefreshConversationListUseCase` `SyncConversationsIncrementallyUseCase`
- Group：`LoadGroupSettingsUseCase` `LoadGroupMembersUseCase` `TransferGroupOwnerUseCase`
- Contact/Search/Favorite：`LoadContactsHomeUseCase` `SearchGlobalUseCase` `LoadFavoritesUseCase`

### 17.3 命名与文件组织

- 类名：`PascalCase`
- 文件名：`snake_case.dart`
- Provider：统一以 `Provider` 结尾
- Controller Provider：统一以 `xxxControllerProvider`
- DTO 文件统一后缀：`_dto.dart` `_request_dto.dart` `_response_dto.dart`

核心命名主干：

- Controller：`LoginController` `ConversationListController` `ChatController` `GroupSettingsController` `ContactsHomeController` `GlobalSearchController`
- 子控制器：`ChatTimelineController` `ChatComposerController` `ChatMediaController` `ChatReceiptController` `ChatViewportController`
- 协调器：`AuthBootstrapCoordinator` `RefreshTokenCoordinator` `ConversationSyncCoordinator` `ChatUploadCoordinator` `FileOpenCoordinator`

### 17.4 通用业务工具规则

- token 敏感信息进入安全存储，内存态和持久态分离
- 启动后必须 bootstrap 校验登录态，不能只看本地 token
- refresh 成功后触发 WebSocket `reauth`
- 时间格式必须走统一 formatter facade
- 聊天页时间分隔规则下沉到 helper/policy
- 字典能力通过 `DictRepository/DictCacheStore/DictFacade`
- 页面只消费 `avatarUrl/avatarText/avatarBgColor`
- 复杂跳转使用 `nav state`，不把重对象直接塞路由
- 文件预览导航优先传 `fileId`

### 17.5 核心基础能力模板

- `DictFacade`
- `NavStateStore`
- `AvatarPresenter`
- `AppTimeFormatter`
- 对应 provider：
  - `dictFacadeProvider`
  - `navStateStoreProvider`
  - `avatarPresenterProvider`
  - `appTimeFormatterProvider`

---

## 18. 消息类型映射摘要

统一消息类型：

- `text`
- `image`
- `voice`
- `video`
- `file`
- `location`
- `contactCard`
- `emoji`
- `sticker`
- `quoteReply`
- `mergedForward`
- `systemTip`
- `custom`

基础消息字段：

- `messageId`
- `chatId`
- `senderId`
- `sequence`
- `rev`
- `type`
- `status`
- `createdAt`
- `isSelf`

组件映射主干：

- `text -> TextMessageBubble`
- `image -> ImageMessageBubble`
- `voice -> VoiceMessageBubble`
- `video -> VideoMessageBubble`
- `file -> FileMessageBubble`
- `location -> LocationMessageBubble`
- `contactCard -> ContactCardBubble`
- `emoji -> EmojiMessageBubble`
- `sticker -> StickerMessageBubble`
- `quoteReply -> QuoteReplyMessageBubble`
- `mergedForward -> MergedForwardBubble`

规则：

- 消息类型、字段、气泡组件、动作支持必须统一映射
- 页面和气泡组件不各自发明消息类型解释逻辑

---

## 19. 页面与路由主链路摘要

### 19.1 页面设计总原则

1. 页面只做展示和动作分发
2. 页面状态由 Controller / Notifier 驱动
3. 页面之间统一用强类型路由参数通信
4. 选择器、弹层、动作面板优先组件化
5. 页面不直接调 API、不直接处理 DTO、不直接写平台能力细节

### 19.2 路由主干

一级路由：

- `/login`
- `/shell/conversations`
- `/shell/contacts`
- `/shell/workbench`
- `/shell/profile`
- `/settings`
- `/settings/theme`
- `/settings/language`

IM 与业务路由：

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
- `/call/incoming`
- `/call/outgoing`
- `/call/session`

约束：

- 使用 `ShellRoute` 管理主壳
- 大对象和短期上下文通过 `nav state` 传递
- 聊天页入口统一走 `ChatEntryArgs`

### 19.3 路由参数模型

- `ChatEntryArgs`：`chatId/conversationType/targetId/title/entryMode/anchorSequence/anchorMessageId/restoreKey`
- `GroupContextArgs`：`groupId/chatId/groupName`
- `UserProfileArgs`：`userId/fromChatId`
- `FilePreviewArgs`：`fileId/fileName/mimeType/messageId`
- `CallLaunchArgs`：`callSessionId/entryMode/callType/fromChatId`

### 19.4 一级页面蓝图

- `LoginPage`
- `ConversationListPage`
- `ContactsHomePage`
- `WorkbenchPage`
- `ProfilePage`
- `SettingsPage`
- `ThemeSettingsPage`
- `LanguageSettingsPage`

### 19.5 聊天域页面蓝图

- `ChatPage`
- `DirectChatSettingsPage`
- `GroupSettingsPage`
- `GroupMembersPage`
- `GroupJoinRequestsPage`
- `GroupNoticePage`
- `GroupInvitePage`
- `ForwardTargetPickerPage`
- `MergedForwardDetailPage`
- `MentionPickerPage`
- `ChatHistorySearchPage`
- `ChatMediaPage`
- `ContactCardPickerPage`
- `LocationPickerPage`
- `VideoPlayerPage`
- `FilePreviewPage`

### 19.6 搜索、收藏、通讯录页面蓝图

- `GlobalSearchPage`
- `FavoritesPage`
- `FavoriteDetailPage`
- `CreateGroupPage`
- `OrgBrowserPage`
- `UserProfilePage`
- `MyGroupsPage`
- `StarContactsPage`
- `MyDepartmentPage`

---

## 20. 登录、会话、聊天主链路摘要

### 20.1 登录页

`LoginPage` 负责：

- 账号登录
- 手机验证码登录
- 语言切换入口
- 验证码触发
- remember account
- 登录提交与反馈

不负责：

- 主壳初始化编排
- websocket 持久状态管理
- 复杂首页跳转策略

组件树主干：

- `LoginScaffold`
- `LoginTopActions`
- `LoginHeroSection`
- `LoginCard`
- `LanguageBottomSheet`
- `CaptchaOverlay`

`LoginPageState` 主字段：

- `status/loginMode/username/password/mobile/smsCode/rememberAccount/showLanguageSheet/showCaptcha/captchaRequired/smsCountdown/errorMessage`

状态主干：

- `idle`
- `validating`
- `captchaRequired`
- `submitting`
- `bootstrapLoading`
- `success`
- `failed`

初始化链路：

1. 保存 token
2. 获取 permission info
3. 保存 current user / device info
4. 初始化 badge
5. 建立 websocket
6. 跳转主壳

责任划分：

- `LoginController`：触发登录请求
- `AuthBootstrapCoordinator`：完成登录后初始化

### 20.2 会话列表页

`ConversationListPage` 负责：

- 会话首屏展示
- pinned / normal 分区
- 分类筛选
- 搜索入口
- 未读与 `@我`
- 角标协同
- 下拉刷新
- 长按菜单
- 进入聊天页

组件树主干：

- `ConversationStatusBar`
- `ConversationHeader`
- `ConversationSearchBar`
- `ConversationCategoryBar`
- `ConversationInlineNoticeBar`
- `PinnedConversationSection`
- `NormalConversationSection`
- `ConversationContextMenuSheet`

`ConversationListState` 主字段：

- `status/conversations/pinnedConversations/normalConversations/selectedCategory/searchKeyword/cursorVersion/totalUnread/inlineNotice/refreshing/syncing/isPinnedFolded/contextMenuTarget/lastSyncAt/errorMessage`

分类主干：

- `latest`
- `user`
- `group`
- `at`
- `nodisturb`

最终态规则：

1. socket 只做提示
2. 最终会话态以 `conversation/sync` 为准
3. 最终未读态以 sync + badge 收敛结果为准

排序规则：

1. `isPinned`
2. `lastMessageTime`
3. stable fallback

### 20.3 聊天页

`ChatPage` 作为独立子系统，支持：

- latest / anchor / restore 三种进入模式
- 多消息类型
- 实时消息
- 断线补偿
- 视口恢复
- 已读与语音未听同步
- 引用、转发、撤回、收藏

顶层对象：

- `ChatPage`
- `ChatController`
- `ChatTimelineController`
- `ChatComposerController`
- `ChatMediaController`
- `ChatReceiptController`
- `ChatViewportController`

`ChatPageState` 主字段：

- `entryArgs/chatHeader/pageStatus/isReadOnly/isMultiSelectMode/highlightedMessageId/pendingAction/error`

`pageStatus`：

- `initial`
- `initializing`
- `loadingWindow`
- `restoringViewport`
- `ready`
- `reconnecting`
- `failed`

`pendingAction`：

- `none`
- `sending`
- `recalling`
- `deleting`
- `forwarding`
- `savingFavorite`
- `flushing`

`ChatTimelineController` 规则：

1. `messageId` 相同按更大 `rev` 覆盖
2. `sequence` 作为排序基准
3. 本地发送态消息服务端确认后归并替换

`ChatComposerController` 负责：

- 草稿
- 输入模式
- 引用编辑
- 发送触发
- 录音状态机

---

## 21. 平台接线与事件流摘要

### 21.1 聊天页平台接线原则

任何依赖原生能力的动作统一走：

```text
Page Widget
  -> ChatController / ChatComposerController / ChatMediaController
  -> application coordinator / use case
  -> core/platform/* service
  -> platform adapter
```

禁止：

- 页面直接调图片/文件/录音插件
- 页面直接处理权限弹窗细节
- 页面直接处理本地文件路径与外部打开

### 21.2 `+` 面板动作主干

- 相册发图：`pickAndUploadImage -> PermissionService -> ImagePickerService -> ChatUploadCoordinator -> SendUploadedMessageUseCase.sendImage`
- 拍照发图：`captureAndUploadImage -> PermissionService -> ImagePickerService -> ChatUploadCoordinator -> SendUploadedMessageUseCase.sendImage`
- 选视频：`pickAndUploadVideo -> ImagePickerService -> ChatUploadCoordinator -> SendUploadedMessageUseCase.sendVideo`
- 选文件：`pickAndUploadFile -> FilePickerService -> ChatUploadCoordinator -> SendUploadedMessageUseCase.sendFile`
- 发位置：`openLocationPicker -> MapFacade / LocationPickerCoordinator -> SendMessageUseCase.sendLocation`
- 发名片：`openContactPicker -> ContactRepository.loadPickableContacts -> SendMessageUseCase.sendContactCard`
- 发起通话：`startCallEntry -> CallCoordinator.openOutgoingCall`

### 21.3 录音与播放主干

- 录音开始：`startVoiceRecord -> PermissionService.request(microphone) -> RecorderService.start`
- 录音取消：`cancelVoiceRecord -> RecorderService.cancel`
- 录音发送：`finishVoiceRecord -> RecorderService.stop -> ChatUploadCoordinator.uploadVoice -> SendUploadedMessageUseCase.sendVoice`
- 语音播放：`playVoice -> AudioPlaybackCoordinator.play -> AudioPlayerService.play -> ChatReceiptController.markVoicePlayed`

### 21.4 文件预览与打开

- 图片/视频点击进入 `FilePreviewPage`
- 文件点击走 `FileOpenCoordinator.resolve`
- 站内预览则路由到 `FilePreviewPage`
- 下载/外部打开则走 `DownloadService -> ExternalOpenerService`

### 21.5 聊天页事件流

初始化：

- `initialize(args)`：`initial -> initializing`
- `openLatest/openAnchor/openRestore`：进入 `loadingWindow/restoringViewport`
- `mergeWindow()`：`loadingWindow -> ready`

时间线：

- `loadOlder()`：`ready -> loadingHistory -> ready`
- `locateQuote()`：`ready -> locatingAnchor -> ready`

发送：

- `sendText/sendImage/sendFile/sendVideo/sendVoice`：`ready -> sending -> ready`

实时与补偿：

- `appendRealtimeMessage()`
- `mergeRealtimeRecall()`
- `handleSocketDisconnected()`：`ready -> reconnecting`
- `pullMessagesAfterReconnect()`：`reconnecting -> ready`

已读与未听：

- `applyVisibleReadWatermark()`
- `flushReadWatermark()`
- `markVoicePlayed()`
- `flushVoicePlayed()`

### 21.6 会话页事件流

- `load()`：`initial -> loading -> ready`
- `refresh()`：`ready -> refreshing -> ready`
- `syncIncrementally()`：`ready -> syncing -> ready`
- `applyBadgeState()`：badge 即时刷新
- `pinConversation/toggleNoDisturb/deleteConversation/markConversationRead`：保持 `ready`
- `socket invalidated -> redirectToLogin()`：`ready -> initial`

### 21.7 会话、角标、Socket 协同

核心对象：

- `ConversationListController`
- `BadgeController`
- `SocketSessionController`
- `ConversationSyncCoordinator`
- `ConversationEventReducer`

协同时序：

1. 加载本地 conversation cache
2. 加载本地 badge cache
3. 页面快速首屏展示
4. 发起服务端 conversation load / sync
5. 建立 websocket
6. auth 成功后再触发一次增量 sync

规则：

1. `cursorVersion` 只前进
2. `conversationVersion` 小于等于本地版本时丢弃
3. badge 可即时展示，但最终态由 sync 收敛
4. socket 失败不清空本地数据

---

## 22. 群设置、通讯录、搜索摘要

### 22.1 GroupSettings

页面 section：

- `GroupOverviewSection`
- `GroupMembersPreviewSection`
- `GroupConversationPreferenceSection`
- `GroupGovernanceSection`
- `GroupDangerZoneSection`

`GroupSettingsState` 主字段：

- `status/groupInfo/membersPreview/pendingJoinRequestCount/canEditGroup/canManageMembers/canManageGovernance/pendingAction`

主动作：

- `load/refresh`
- `updatePinned/updateNoDisturb`
- `updateMuteAll/updateAllowMemberInvite/updateNeedApproval`
- `updateMyNickname/updateGroupName`
- `transferOwner/quitGroup/dissolveGroup/clearChatHistory`

规则：

- 高危动作统一走 `GroupLifecycleActionCoordinator`

### 22.2 GroupMembers

模式：

- `browse`
- `manage`
- `select`

主动作：

- `loadMembers`
- `searchMembers`
- `setRole`
- `removeMember`
- `selectMember`

### 22.3 Contacts / Org / CreateGroup / UserProfile

`ContactsHomePage`：

- 快捷入口：我的群组、星标联系人、组织架构、我的部门
- 动作：`loadContacts/refresh/openContact/startDirectChat`

`OrgBrowserPage`：

- 模式：`browse/pickContact/pickGroupMember`
- 动作：`loadTree/expandNode/selectDept/loadDeptMembers/searchDeptMembers`

`CreateGroupPage`：

- 动作：`toggleMember/removeSelected/submitCreateGroup`

`UserProfilePage`：

- 动作：`toggleStar/startDirectChat/shareContactCard`

### 22.4 GlobalSearch / Favorites

`GlobalSearchPage` 主字段：

- `keyword/activeTab/status/results/facets/hasMore/isLoadingMore`

主动作：

- `inputKeyword`
- `submitSearch`
- `switchTab`
- `loadMore`
- `clearHistory`
- `selectHistory`
- `selectHot`

跳转协议：

- message result -> `ChatEntryArgs.anchor`
- contact result -> `UserProfilePage`
- group result -> group chat latest
- media result -> `ChatEntryArgs.anchor`

`FavoritesPage`：

- 查看收藏
- 搜索收藏
- 打开收藏详情

---

## 23. 视觉、主题、语言与验收摘要

### 23.1 视觉与交互路线

统一冻结为：

- 苹果年轻化
- 简约克制
- 轻盈现代
- 企业级可读性强

明确不是：

- 花哨营销风
- 夸张拟物
- 浓重安卓原生味
- 重卡片、重边框、重阴影的旧式后台风

设计基调：

- 清爽
- 明亮
- 高留白但不空
- 信息分层明确
- 控件轻量
- 动效克制

页面审美要求：

- 登录页：年轻、轻量、可信任
- 会话列表：高密度但不压抑，扫描效率高
- 聊天页：时间线优先，输入区轻量固定
- 设置页：iOS 设置风格语义
- 音视频页：沉浸、状态清晰、控制条简洁

禁止项：

1. 大面积厚重渐变背景
2. 卡片套卡片
3. 重阴影 + 重描边 + 重色块并用
4. 工具条和内容区争抢主视觉
5. 页面之间风格不一致

### 23.2 组件与交互建议

优先使用：

- `CupertinoNavigationBar`
- `CupertinoSliverNavigationBar`
- `CupertinoTextField`
- `CupertinoButton`
- `CupertinoSwitch`
- `CupertinoActionSheet`
- `CupertinoAlertDialog`
- `CupertinoSlidingSegmentedControl`

约束：

- 应用壳可由 `MaterialApp.router` 承载
- 页面内交互组件尽量保持 Cupertino 气质
- 图标优先 `CupertinoIcons`
- 手势自然，不做炫技交互
- 动效小而快，不过度表演

### 23.3 主题模式

冻结结论：

1. 主题模式仅本地保存
2. 支持 `system/light/dark`
3. 修改后立即生效
4. 可展示当前实际应用主题预览
5. 聊天气泡主题与全局主题分离

核心对象：

- `ThemeModeController`
- `ThemeState`
- `ThemeSettingsPage`

本地存储 key：

- `app.theme_mode`

### 23.4 国际化与语言设置

冻结结论：

1. 语言模式仅本地保存
2. 支持 `system/zh-CN/en`
3. 修改后立即生效
4. HTTP 请求头同步 `Accept-Language`
5. websocket 认证时同步 `locale`

核心对象：

- `AppLocaleController`
- `LocaleState`
- `LanguageSettingsPage`

本地存储 key：

- `app.language_mode`

现阶段规则补充：

- 页面中的功能占位中文不强制国际化
- 已进入真实流程、真实设置、真实网络链路的稳定文案应接国际化
- 时间格式、相对时间、会话列表、聊天页、搜索结果等共享文案必须走统一 formatter / l10n 通路
- 当实现“去 mock / 接真实接口 / 接真实设置项”这类落地动作时，若产生稳定用户可见文案，同轮一并完成国际化，不拖到后补
- 测试服务与联调服务默认由用户手动启动，本代理只负责代码与文档推进，不负责代启动服务

### 23.5 功能覆盖与交互验收基线

会话列表必须覆盖：

- 会话列表展示
- pinned / normal 分区
- 未读角标
- `@我` 标识
- 分类筛选
- 搜索入口
- 下拉刷新
- Mobile 长按菜单 / Web Desktop 右键菜单

聊天页必须覆盖：

- 文本、图片、视频、文件、语音、位置、名片、emoji、自定义表情、引用回复、合并转发
- 文本输入、语音输入、`+` 面板、emoji 面板、引用编辑态
- 历史翻页、引用定位、高亮锚点、断线补拉合并
- 消息菜单：复制、引用、转发、收藏、删除、撤回
- 语音消息：播放、暂停、续播、未听转已听、前后台恢复
- 媒体交互：图片预览、视频播放、文件打开、文件下载

`+` 面板默认能力：

- 相册
- 拍照
- 视频
- 文件
- 位置
- 名片
- 音视频通话入口

群设置必须覆盖：

- 群概览
- 成员预览
- 群会话偏好
- 群治理设置
- 高危操作区

单聊设置必须覆盖：

- 会话置顶
- 免打扰
- 清空聊天记录
- 查看对方资料
- 发起音视频

通讯录 / 搜索必须覆盖：

- 组织树浏览
- 部门成员浏览
- 联系人详情
- 发起单聊
- 创建群聊
- 全局搜索
- 搜索历史
- 热门搜索
- 搜索结果跳转聊天锚点

收藏与文件必须覆盖：

- 收藏消息 / 列表 / 搜索 / 详情 / 再转发
- 聊天文件上传 / 发送 / 预览 / 下载
- 聊天媒体页
- 群文件列表

多端交互映射：

- Mobile：长按、底部 action sheet / bottom sheet、全屏媒体预览
- Web/Desktop：右键菜单、hover、拖拽上传、多栏布局

验收结论：

- 交互入口可因平台变化，但业务动作集合不能缩水

### 23.6 UI 原型图参考索引

`sql/flutter-doc/img/` 中新增的 `img_xx.png` 有参考价值，但当前判断应作为“局部交互参考索引”，不应直接升级为全局视觉规范。

原因：

1. 图集主要覆盖聊天、群管理、搜索、收藏、组织架构等二级页面
2. 对四个一级页、应用壳层、桌面/大屏布局覆盖不完整
3. 更适合指导局部交互、信息层级、弹层样式，而不是反推整套产品视觉系统

当前建议参考方式：

- 登录与验证码：`img.png`
- 发起群聊 / 选人器：`img_1.png`
- 聊天输入区 + emoji 面板：`img_2.png`
- 已读详情弹层：`img_3.png`
- 聊天页语音输入 / 更多面板：`img_4.png`
- 消息收藏：`img_6.png`
- 群成员管理 / 删除确认：`img_10.png`
- 组织架构选人：`img_12.png`
- 聊天记录搜索：`img_16.png`
- 群系统消息 / 名片 / 公告更新在时间线中的呈现：`img_20.png`
- 群公告详情：`img_22.png`
- 全局搜索：`img_28.png`

使用规则：

1. 优先参考这些图里的信息结构和交互位置
2. 不回退到旧项目的默认 Flutter 观感
3. 不机械复刻旧图的颜色、间距、组件实现
4. 若旧图与当前统一文档的架构/交互规则冲突，以统一文档为准
5. 若后续继续补图，应优先补会话列表、四个一级页、设置页、桌面多栏布局

结论：

- 有必要整合进文档
- 但只整合成“参考索引”和“适用范围说明”，不整合成强制逐像素还原规范

---

## 24. 文件上传、预览与打开策略摘要

### 24.1 上传链路冻结规则

1. 聊天媒体与文件消息统一采用“先上传，再发消息”
2. 上传成功后的权威标识是 `fileId`，不是 `url`
3. 消息体可带 `url` 作为当前链路回显兜底
4. 后续读取、预览、下载都必须优先走 `fileId`
5. 文件预览、播放、下载统一通过：
   - `open-strategy`
   - `presigned-get-url`
6. 上传目录必须由客户端按业务规则标准化生成

首期主方案：

- `POST /infra/file/upload-and-return-id`
- 服务端代理上传并直接返回 `fileId`
- 上传完成后立刻发送消息

保留扩展方案但首期不落地：

- `GET /infra/file/presigned-url`
- 客户端直传对象存储
- `POST /infra/file/create`

### 24.2 上传分层与对象

统一分层：

```text
features/im/chat/
  application/coordinators/chat_upload_coordinator.dart
  application/usecases/upload_chat_asset_use_case.dart
  application/usecases/send_uploaded_message_use_case.dart
  domain/entities/upload_task.dart
  domain/entities/upload_result.dart
  domain/value_objects/upload_purpose.dart
  domain/value_objects/upload_scope.dart
  domain/value_objects/upload_directory.dart
  infrastructure/repositories/file_repository_impl.dart
  infrastructure/datasources/file_http_data_source.dart
```

页面层只触发：

- `pickImage`
- `pickVideo`
- `pickFile`
- `startVoiceUpload`

上传编排统一收口到：

- `ChatUploadCoordinator`

核心对象：

- `UploadPurpose`：`chatImage/chatVideo/chatFile/chatVoice/avatar/stickerOriginal/stickerThumb`
- `UploadScope`：`directChat/groupChat/profile/sticker`
- `UploadTask`
- `UploadedFile`
- `UploadResult`

`UploadStatus`：

- `queued`
- `preparing`
- `uploading`
- `uploaded`
- `sending`
- `sent`
- `failed`
- `cancelled`

### 24.3 上传目录规则

单聊：

- 图片：`im/chat/{chatId}/image`
- 视频：`im/chat/{chatId}/video`
- 文件：`im/chat/{chatId}/file`
- 语音：`im/chat/{chatId}/voice`

群聊：

- 图片：`im/group/{groupId}/image`
- 视频：`im/group/{groupId}/video`
- 文件：`im/group/{groupId}/file`
- 语音：`im/group/{groupId}/voice`

其他：

- 头像：`profile/avatar/{userId}`
- 贴纸：`im/sticker/{userId}`

规则：

- 页面层不手写目录字符串
- 服务端可基于目录做归属校验与审计

### 24.4 发送消息体规则

图片消息必带：

- `fileId`
- `url`
- `thumbnailUrl`
- `size`

视频消息必带：

- `fileId`
- `url`
- `coverUrl`
- `size`

文件消息必带：

- `fileId`
- `url`
- `fileName`
- `size`
- `mimeType`
- `extension`

语音消息必带：

- `fileId`
- `duration`
- `durationMs`
- `size`
- `format`
- `md5`

### 24.5 文件预览总体方案

采用分层式文件预览架构：

1. 常见格式原生预览优先
2. Office 主方案采用服务端转换
3. 所有文件打开先走服务端打开策略接口
4. 无法在线稳定预览时降级为下载

推荐预览分层：

1. 原生直预览：
   - PDF
   - 图片
   - 视频
   - 音频
   - 纯文本
   - Markdown
   - 常见代码文本
2. 服务端转换预览：
   - DOC / DOCX
   - XLS / XLSX
   - PPT / PPTX
   - ODT / ODS / ODP
3. 保留型嵌入 viewer：
   - 只作扩展位，不是首期主方案
4. 下载降级：
   - 不适合在线预览或服务端暂不支持时直接降级

### 24.6 文件预览核心对象

- `FilePreviewArgs`
- `FilePreviewDescriptor`
- `FileCapability`
- `FileRenderStrategy`
- `ResolvedFileOpenPlan`
- `FilePreviewState`

`FileRenderStrategy`：

- `nativePdf`
- `nativeImage`
- `nativeVideo`
- `nativeAudio`
- `nativeText`
- `nativeMarkdown`
- `serverConvertedPdf`
- `serverConvertedHtml`
- `embeddedOfficeViewer`
- `downloadOnly`

`FilePreviewStatus`：

- `initial`
- `loadingStrategy`
- `resolvingCapability`
- `rendering`
- `downloadOnly`
- `failed`

`FilePreviewAction`：

- `none`
- `downloading`
- `openingExternal`
- `retrying`
- `sharing`

### 24.7 Repository、Coordinator、Controller

`FileRepository` 主方法：

- `uploadAndCreateFile`
- `getFileOpenStrategy`
- `getPresignedGetUrl`
- `getFilePreviewDescriptor`
- `getDownloadUri`
- `getConvertedPdfUri`

`FileOpenCoordinator` 负责：

- 根据文件类型与服务端返回策略决定最终打开方式
- 屏蔽页面对平台差异的感知

`FilePreviewController` 负责：

- 加载文件打开策略
- 决定渲染方式
- 处理下载、重试、外部打开、分享

公开动作：

- `initialize(FilePreviewArgs args)`
- `retry()`
- `download()`
- `openExternal()`
- `share()`

### 24.8 FilePreviewPage 交互

组件树：

```text
FilePreviewPage
  FilePreviewAppBar
  FilePreviewBody
    LoadingStrategyView
    ErrorView
    DownloadOnlyView
    PdfPreviewBody
    ImagePreviewBody
    VideoPreviewBody
    AudioPreviewBody
    TextPreviewBody
    HtmlPreviewBody
    EmbeddedOfficePreviewBody
  FilePreviewBottomActions
```

多端布局：

- Mobile：顶部栏紧凑，主体全屏，底部动作区固定
- Web：可加右侧信息栏，转换结果优先全宽
- Desktop：工具栏更明显，增强外部打开 / 下载

用户体验约束：

1. 点击文件后不允许长时间白屏
2. 无法预览时要快速明确降级
3. PDF 阅读位置要支持恢复
4. Office 文档加载失败要自动降级
5. 嵌入式 viewer 不是默认路径
6. 外部打开前要校验权限与地址有效性

### 24.9 测试与验收基线

P0 测试项：

1. `FileOpenStrategyResponseDtoMapper`
2. `FileOpenCoordinator`
3. `FilePreviewController.initialize`
4. `downloadOnly` 降级流程

P1 测试项：

1. `FilePreviewPage` Widget 渲染
2. PDF / 文本策略 body 渲染
3. 外部打开动作

验收标准：

1. mapper 与 coordinator 单测已建
2. controller 状态流单测已建
3. `downloadOnly` 降级链路已覆盖

---

## 25. 音视频通话摘要

### 25.1 通话专题当前定位

通话专题当前只收敛：

- Flutter 端状态机
- 页面进入与恢复策略
- 业务信令与媒体状态边界
- 控制器 / 协调器 / repository / rtc gateway 骨架

当前不做：

- mock 通话流程
- 演示型事件面板
- 过度 UI 细抠
- 把 RTC 细节直接塞进页面

### 25.2 技术路线

- Flutter 客户端媒体层：`flutter_webrtc`
- 业务信令：复用 IM 自有 WebSocket
- 媒体信令与转发：自建 Janus SFU
- NAT 穿透：自建 `coturn`
- 呼叫状态、通话记录、离线推送、多端裁决：IM 业务后端

明确不采用：

- 托管式大厂 RTC SDK 作为主方案
- 纯客户端裁决方案
- 1v1 纯 P2P 作为长期默认方案

### 25.3 架构分层

1. `presentation`
   - `IncomingCallPage`
   - `OutgoingCallPage`
   - `CallSessionPage`
   - 悬浮中控条
2. `application`
   - `CallCoordinator`
   - `CallController`
   - `CallMediaController`
   - `CallPermissionCoordinator`
3. `domain`
   - `CallSession`
   - `CallParticipant`
   - `CallInvite`
   - `CallMediaState`
   - `CallEndReason`
4. `infrastructure`
   - `CallRepository`
   - `CallSocketDataSource`
   - `CallHttpDataSource`
   - `RtcGatewayClient`
   - `TurnConfigProvider`

### 25.4 核心原则

1. 业务状态机与媒体状态机分离
2. 多端只允许一个终端正式接听
3. 先业务建会话，再发媒体凭证
4. 弱网场景优先保留会话，不立即结束业务通话
5. 端能力降级明确

### 25.5 第一阶段范围

- 单聊语音通话
- 单聊视频通话
- 来电响铃
- 去电等待
- 接听 / 拒绝 / 挂断
- 静音
- 扬声器切换
- 摄像头开关
- 前后摄切换
- 小窗悬浮态
- 弱网重连
- 通话记录消息

第二阶段才考虑：

- 屏幕共享
- 通话中切语音/视频模式
- 质量诊断面板
- 录制
- 多人会议

### 25.6 后端业务链路

发起呼叫：

1. `CreateCallInvite`
2. 后端校验在线状态、会话合法性、黑名单、忙线
3. 创建 `callSessionId`
4. 推进业务状态到 `ringing`
5. 通过 IM WebSocket 广播来电
6. 离线时走推送

被叫接听：

1. 被叫提交 `accept`
2. 后端以 `callSessionId` 做 CAS 裁决
3. 成功接听设备成为 `acceptedDeviceId`
4. 后端向双方签发 RTC 房间参数
5. 其余设备收到 `terminated_elsewhere`

结束通话：

1. 后端推进业务状态到 `ended`
2. 广播结束事件
3. 客户端停止采集与渲染
4. 后端生成通话记录消息
5. 会话列表刷新最近消息与未读

### 25.6.1 服务端必须补的业务接口与模块

通话专题不是仅客户端工作，服务端至少要补齐以下业务模块：

- `AppImCallController`
- `ImCallService`
- `ImCallStateMachine`

服务端接口主干至少包括：

- `CreateCallInvite`
- `AcceptCall`
- `RejectCall`
- `CancelCall`
- `HangupCall`
- `SyncActiveCallState`

服务端还需要负责：

- `call.media-token-issued` 所需的 RTC 房间参数签发
- 多端唯一接听裁决
- 忙线判定
- 超时结束
- 通话记录消息落库与分发
- 来电离线推送编排

### 25.6.2 通话服务端开发顺序

推荐顺序：

1. 先补 `AppImCallController` HTTP 入口
2. 再补 `ImCallService` 业务编排
3. 再补 `ImCallStateMachine`，冻结状态流转与结束原因
4. 再补 socket 业务事件分发：
   - `call.invite`
   - `call.accepted`
   - `call.rejected`
   - `call.busy`
   - `call.cancelled`
   - `call.timeout`
   - `call.ended`
   - `call.state-sync`
   - `call.device-terminated`
   - `call.media-token-issued`
5. 再补 RTC 参数签发与 Janus / TURN 配置下发
6. 最后补离线推送与通话记录消息

冻结约束：

- 通话业务闭环在业务模块实现
- 不把通话状态机塞进 websocket starter
- Flutter 侧只对接正式业务接口和正式业务事件

### 25.6.3 通话服务端接口字段约定

为避免后续前后端再次各自发挥，通话接口至少按以下字段级口径冻结。

`CreateCallInvite` 请求建议字段：

- `chatId`
- `callType`
- `targetUserId`
- `clientDeviceId`
- `requestId`

`CreateCallInvite` 响应建议字段：

- `callSessionId`
- `inviteId`
- `businessStatus`
- `expiresAt`
- `serverTime`

`AcceptCall` 请求建议字段：

- `callSessionId`
- `inviteId`
- `clientDeviceId`
- `callType`

`RejectCall` / `CancelCall` / `HangupCall` 请求建议字段：

- `callSessionId`
- `inviteId`
- `clientDeviceId`
- `reason`

`SyncActiveCallState` 响应建议字段：

- `callSessionId`
- `chatId`
- `callType`
- `businessStatus`
- `endReason`
- `callerUserId`
- `calleeUserId`
- `acceptedDeviceId`
- `elapsedSeconds`
- `rtcRoomBundle`

`rtcRoomBundle` 建议字段：

- `roomId`
- `publisherId`
- `displayName`
- `janusUrl`
- `turnUrls`
- `turnUsername`
- `turnCredential`
- `token`

Socket `call.*` 事件建议公共字段：

- `eventType`
- `callSessionId`
- `chatId`
- `callType`
- `fromUserId`
- `toUserId`
- `deviceId`
- `serverTime`
- `payload`

规则：

1. `callSessionId`、`inviteId`、`userId`、`chatId` 一律按 `String`
2. Flutter 不消费未冻结字段名的临时结构
3. 若后端先行落地，必须保持与本口径一致，避免客户端再做二次适配

### 25.7 通话状态与页面映射

业务状态：

- `idle`
- `outgoing`
- `incoming`
- `accepting`
- `connecting`
- `connected`
- `reconnecting`
- `ended`

结束原因：

- `cancelled_by_caller`
- `rejected_by_callee`
- `busy`
- `no_answer`
- `hangup_by_local`
- `hangup_by_remote`
- `kicked_by_other_device`
- `network_timeout`
- `rtc_error`
- `permission_denied`

页面映射：

- `IncomingCallPage`：`incoming/accepting/ended`
- `OutgoingCallPage`：`outgoing/connecting/ended`
- `CallSessionPage`：`connecting/connected/reconnecting/ended`

### 25.8 CallState / CallMediaState

`CallState` 主字段：

- `callSessionId`
- `chatId`
- `callType`
- `entryMode`
- `businessStatus`
- `endReason`
- `pageStatus`
- `isIncoming`
- `isOutgoing`
- `hasAccepted`
- `hasConnected`
- `isMinimized`
- `showPermissionBanner`
- `showReconnectingBanner`
- `elapsedSeconds`
- `callerProfile`
- `calleeProfile`
- `acceptedDeviceId`
- `errorMessage`
- `mediaState`

`CallMediaState` 主字段：

- `microphoneEnabled`
- `cameraEnabled`
- `speakerEnabled`
- `frontCamera`
- `localTrackReady`
- `remoteTrackReady`
- `localVideoFirstFrameReady`
- `remoteVideoFirstFrameReady`
- `isPublishing`
- `isSubscribing`
- `networkQualityLevel`
- `rtcConnectionStatus`
- `localRendererAttached`
- `remoteRendererAttached`

`CallPageStatus`：

- `initial`
- `loading`
- `ringing`
- `accepting`
- `connecting`
- `connected`
- `reconnecting`
- `minimized`
- `ending`
- `ended`
- `failed`

### 25.9 控制器与协调器

`CallController` 负责：

- 通话主状态编排
- 页面动作入口
- 业务事件收敛
- 与 `CallCoordinator` 协同

主动作：

- `startOutgoing`
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

`CallMediaController` 负责：

- 本地媒体流创建与销毁
- 远端流订阅与解绑
- 静音、摄像头、扬声器、切前后摄
- 首帧与重连状态上报

`CallCoordinator` 负责：

- 页面进入策略
- 悬浮态切换
- 前后台恢复
- 路由跳转与恢复

`ActiveCallRegistry` 负责：

- 当前活动通话唯一性
- 悬浮态引用
- 防重复进入

### 25.10 事件流摘要

用户动作：

- `startOutgoing -> CreateCallInviteUseCase -> outgoing`
- `accept -> AcceptCallUseCase -> accepting`
- `reject -> RejectCallUseCase -> ended`
- `cancel -> CancelCallUseCase -> ended`
- `hangup -> HangupCallUseCase -> ended`

业务信令：

- `call.invite -> incoming`
- `call.accepted -> connecting`
- `call.rejected -> ended`
- `call.busy -> ended`
- `call.cancelled -> ended`
- `call.timeout -> ended`
- `call.ended -> ended`
- `call.device-terminated -> ended`
- `call.state-sync -> 服务端状态决定`
- `call.media-token-issued -> connecting`

媒体事件：

- `permissionGranted -> prepareLocalMedia`
- `permissionDenied -> ended/failed`
- `rtcJoining -> connecting`
- `remoteTrackReady -> connected`
- `rtcReconnecting -> reconnecting`
- `rtcRecovered -> connected`
- `rtcFailed -> ended/failed`

生命周期：

- `pageOpened -> initialize`
- `appForegrounded -> SyncActiveCallStateUseCase`
- `authInvalidated -> forceTerminate -> ended`

### 25.11 对象与代码骨架

核心对象：

- `CallLaunchArgs`
- `CallParticipantProfile`
- `CallMediaState`
- `CallState`
- `RtcRoomBundle`
- `CallSummaryMessage`
- `CallSocketEvent`

核心接口与骨架：

- `CallRepository`
- `CallController`
- `CallMediaController`
- `CallCoordinator`
- `CallPermissionCoordinator`
- `callControllerProvider`
- `callMediaControllerProvider`
- `callRepositoryProvider`

### 25.12 测试与放行条件

单元测试至少覆盖：

1. `CallController.initialize`
2. `startOutgoing -> outgoing/ringing`
3. `accept -> accepting`
4. `reject -> ended`
5. `hangup -> ending -> ended`
6. `call.accepted` 进入 `connecting`
7. `call.ended` 释放媒体并进入 `ended`
8. 权限拒绝映射为 `permissionDenied`
9. `CallEndReason` 映射正确

集成测试至少覆盖：

1. 主叫发起语音通话
2. 被叫接听语音通话
3. 被叫拒绝
4. 主叫取消
5. 通话中挂断
6. 重连后状态恢复
7. 最终生成通话记录消息

放行条件：

1. 单元测试通过
2. 关键集成测试通过
3. Android / iOS 真机双端至少一轮通过

---

## 26. 多端平台与基础设施摘要

### 26.1 基础设施治理原则

核心原则：

- 核心对话与通话业务尽量自研
- 优先完全开源、可自部署、可控方案
- 不能合理自研的能力允许依赖第三方
- 只实现一个主方案，其余先空实现

能力分级：

- A 类核心自控：IM HTTP、WebSocket、会话同步、消息状态机、聊天编排、通话业务状态机
- B 类优先开源自部署：WebRTC、SFU、TURN、文档转换
- C 类允许供应商：地图底图与 POI、移动端离线推送、部分系统通知通道

抽象层规则：

1. 每类外部能力都必须拆成 `domain contract + facade + provider adapter + optional stub adapter`
2. 页面层禁止直接 import 供应商 SDK
3. 业务层只允许感知统一接口、统一结果模型、统一错误模型

### 26.2 当前冻结主方案

- 音视频：`flutter_webrtc + Janus + coturn`
- 离线推送：iOS APNs，Android 国内聚合推送主方案
- 地图与位置：只实现一个主地图 provider adapter
- 文件预览：Flutter 原生预览 + 服务端 `open-strategy` + 服务端转换链路

空实现策略允许：

- `NoopPushVendorAdapter`
- `ReservedMapProviderAdapter`
- `ReservedRtcCallKitAdapter`

要求：

- 能编译
- 明确返回 unsupported / notConfigured
- 不静默吞错

### 26.3 多端平台优先级

当前重要排序冻结为：

1. Android
2. iOS
3. OpenHarmony
4. Windows
5. macOS
6. Web
7. HarmonyOS

P0 主交付平台：

- Android
- iOS
- OpenHarmony

P1 次级正式交付平台：

- Windows
- macOS
- Web
- HarmonyOS

### 26.4 各端主链路要求

Android / iOS 必须可用：

- 登录 / refresh / reauth
- 会话列表
- 聊天页主链路
- 图片/视频/文件/语音发送
- 文件预览
- 语音播放暂停续播
- emoji / 自定义表情
- 消息菜单
- 群设置 / 单聊设置
- 音视频 1v1
- 离线推送主链路

OpenHarmony 必须可用：

- 登录 / refresh / reauth
- 会话列表
- 聊天页主链路
- 图片/视频/文件发送
- 语音发送与播放暂停续播
- 文件预览
- emoji / 自定义表情
- 消息菜单
- 群设置 / 单聊设置

OpenHarmony 首阶段允许暂缓：

- 音视频 1v1
- 离线推送
- 地图位置选择器原生主体验

Web 必须可用：

- 登录 / refresh / reauth
- 会话列表
- 聊天页主链路
- 图片/视频/文件发送
- 语音播放
- 文件预览
- 右键菜单
- 多栏布局
- 音视频 1v1

Windows / macOS 必须可用：

- 登录 / refresh / reauth
- 会话列表
- 聊天页主链路
- 文件拖拽上传
- 图片/视频/文件发送
- 语音播放暂停续播
- 文件预览
- 右键菜单
- 多栏布局
- 音视频 1v1

HarmonyOS 当前定位：

- 正式交付目标
- 但优先级低于 Web
- 先跟随 OpenHarmony，同抽象，不抢首轮资源

### 26.5 高风险平台差异点

- 输入与菜单：Mobile 长按，Web/Desktop 右键
- 语音播放：音频焦点、前后台、窗口焦点变化
- 文件选择与上传：相册/相机/文件系统/Blob/拖拽差异
- 通知与推送：iOS APNs、Android 聚合推送、Desktop/Web 非首期离线推送主平台
- 地图与位置：Mobile 内嵌地图，Desktop/Web 可降级为静态卡片 + 外链

### 26.6 OpenHarmony / HarmonyOS 矩阵与缺口

`green`：

- 纯 Dart domain/usecase/state
- Dio
- WebSocket
- JSON/codegen/freezed

`yellow`：

- secure storage
- shared preferences / KV
- path provider
- audio play
- video play
- file download
- wakelock
- system share

`red`：

- file picker
- image picker / camera
- recorder
- external opener
- permission
- audio session
- local notification
- push
- map
- scan
- WebRTC

OpenHarmony 首轮主链路可先达成：

- 登录 / refresh / reauth
- 会话列表
- 文本聊天
- emoji / 自定义表情展示与发送
- 文件消息展示
- 服务端文件预览策略消费
- 基础菜单交互

P0 阻塞缺口：

- `FilePickerService`
- `ImagePickerService`
- `PermissionService`
- `ExternalOpenerService`
- `AudioPlayerService`
- `RecorderService`

P1 高价值缺口：

- secure storage 替代实现
- `PathProviderAdapter`
- `VideoPlayerService`
- `ShareService`

P2 后补缺口：

- 地图与位置
- 扫码
- 音视频通话
- 离线推送

### 26.7 OpenHarmony / HarmonyOS adapter 规则

统一目录：

```text
core/platform/ohos/
  picker/
  permission/
  media/
  file/
  share/
  notification/
  rtc/
```

统一命名：

- `OhosFilePickerAdapter`
- `OhosImagePickerAdapter`
- `OhosPermissionAdapter`
- `OhosRecorderAdapter`
- `OhosAudioPlayerAdapter`
- `OhosExternalOpenerAdapter`

HarmonyOS 如需独立实现，仅允许新增 adapter 层：

- `HarmonyFilePickerAdapter`
- `HarmonyPermissionAdapter`
- `HarmonyPlatformBridge`
- `HarmonyCapabilities`

禁止：

- 页面级平台直连 SDK
- 聊天页内部硬编码平台分支
- 上传或预览逻辑内散落平台特判

### 26.8 OpenHarmony / HarmonyOS 门槛

OpenHarmony 当前状态结论：

- `ready_for_codegen`

要进入 `ready_for_release_scope`，必须通过：

- 构建与运行基线
- 协议与登录基线
- 存储基线
- 文件基线
- 语音基线
- 文件打开
- 聊天主链路

OpenHarmony 首轮允许暂缓：

- 1v1 音视频通话
- 离线推送
- 原生地图选点
- 扫码
- 系统分享

HarmonyOS 当前状态结论：

- `analyzing`

HarmonyOS 进入独立实现前，至少先满足：

1. `core/platform/*` 抽象稳定
2. OpenHarmony P0 adapter 已有实现或验证结论
3. Web 不再阻塞主交付节奏
4. 聊天、上传、文件预览、语音播放主链路已在其他正式平台收敛

### 26.9 离线推送

冻结结论：

1. 不自研离线推送主通道
2. 只实现一个主推送方案
3. 其他厂商通道只保留抽象和空实现
4. 服务端负责统一推送编排

主方案：

- iOS：APNs
- Android 国内：聚合推送主方案
- Android 其他环境：预留 FCM / 厂商直连接口 adapter

Flutter 侧职责：

1. 初始化 `PushFacade`
2. 获取并上报 push token / clientId
3. 接收通知点击或透传
4. 统一路由回应用内页面
5. 与登录态、用户态绑定和解绑

服务端职责：

1. 保存设备推送标识
2. 选择供应商
3. 下发通知/透传
4. 记录审计
5. 支持重试与降级

统一打开载荷：

- `targetType`
- `chatId`
- `messageId`
- `callSessionId`
- `bizId`
- `extra`

兜底策略：

1. App 冷启动补拉未读
2. WebSocket 重连后做增量同步
3. 通话场景允许未收到离线来电通知
4. 会话最终态以服务端同步为准

### 26.10 地图与位置

首期只覆盖：

- 位置选择
- 当前位置查看
- 地图点位展示
- POI 搜索
- 地理编码 / 逆地理编码
- 位置消息发送

冻结结论：

- 不自研地图底图与 POI
- 当前建议主方案：百度地图 Flutter 体系
- 备选方案仅保留空实现 adapter

抽象层：

```text
core/platform/map/
  map_facade.dart
  map_provider.dart
  map_models.dart
  adapters/
    baidu_map_adapter.dart
    reserved_tencent_map_adapter.dart
```

统一模型：

- `LocationPoint`
- `LocationPreview`
- `PoiItem`

`MapFacade` 建议接口：

- `initialize()`
- `requestLocationPermission()`
- `getCurrentLocation()`
- `reverseGeocode()`
- `searchPoi()`
- `buildStaticPreview()`
- `openExternalMap()`

降级策略：

1. 无定位权限：允许只搜索地点或手动选择
2. 地图 SDK 初始化失败：回退为文本地址选择
3. 无法显示内嵌地图：展示位置卡片并提供外部打开

---

## 27. 工程治理与续接摘要

### 27.1 第一阶段依赖建议

第一阶段核心依赖：

- `flutter_riverpod`
- `riverpod_annotation`
- `go_router`
- `dio`
- `freezed_annotation`
- `json_annotation`
- `flutter_secure_storage`
- `shared_preferences`
- `web_socket_channel`
- `collection`
- `uuid`
- `crypto`

第一阶段 `dev_dependencies`：

- `build_runner`
- `freezed`
- `json_serializable`
- `riverpod_generator`
- `custom_lint`
- `riverpod_lint`

第一阶段不建议直接加入：

- `drift`
- `file_picker`
- `image_picker`
- `just_audio`
- `video_player`
- `record`
- `mobile_scanner`
- `logger`
- `flutter_webrtc`
- `permission_handler`
- `wakelock_plus`
- `audio_session`

这些放到第二阶段按专题引入。

### 27.2 Pubspec 草案结论

- `MaterialApp.router + cupertino_icons` 作为应用壳基线
- SDK 基线按文档草案维护
- 真正落地时只做版本兼容核对，不再改变依赖分层思路

### 27.3 首批类骨架与文件职责

应用基线首批类：

- `ShengyuImApp`
- `AppBootstrap`
- `AuthBootstrapCoordinator`
- `AppRouter`
- `AppShell`

Core 首批类：

- `AuthSession`
- `RefreshTokenCoordinator`
- `DioClientFactory`
- `ImSocketClient`
- `StorageKeyRegistry`

Conversation 首批类：

- `Conversation`
- `ConversationRepository`
- `LoadConversationListUseCase`
- `SyncConversationsIncrementallyUseCase`
- `ConversationListController`
- `ConversationListState`
- `ConversationListPage`

Chat 首批类：

- `Message`
- `MessageExtra`
- `QuoteInfo`
- `MessageRepository`
- `OpenChatUseCase`
- `LoadChatWindowUseCase`
- `SendMessageUseCase`
- `ChatController`
- `ChatTimelineController`
- `ChatComposerController`
- `ChatPageState`
- `ChatTimelineState`
- `ChatPage`

### 27.4 第一阶段测试基线

P0 单测重点：

- `refresh_token_coordinator`
- `auth_interceptor`
- `im_socket_client`
- `sync_conversations_incrementally_use_case`
- `open_chat_use_case`
- `send_message_use_case`
- `message_merge_policy`

Widget 测试重点：

- `conversation_list_page`
- `chat_page`
- `message_bubble_factory`

集成测试建议：

- `login_to_conversation_flow`
- `open_chat_latest_flow`
- `open_chat_anchor_flow`
- `send_text_message_flow`

当前规则补充：

- 非必要测试流程不做
- 只保留高风险主链路最小校验

### 27.5 对象代码模板结论

统一模板风格覆盖：

- Entity
- DTO
- State
- Command
- Result
- Mapper
- Provider
- UseCase
- Repository Impl
- Controller

统一要求：

- 常见对象优先 `freezed`
- DTO 统一 `json_serializable`
- Provider 与 Repository 命名按前文约束执行

### 27.6 开发任务拆解里程碑

- M0 设计冻结
- M1 工程基线
- M2 鉴权与基础设施
- M3 WebSocket 骨架
- M4 会话域
- M5 聊天页骨架
- M6 消息域
- M7 已读与角标
- M8 联系人与组织
- M9 群域
- M10 搜索、收藏、文件
- M11 多端专项
- M12 回归清单

当前统一口径：

- 先完成主链路与统一文档收敛
- 再按这些里程碑落代码和校验状态

### 27.7 后端协同优先级

P0 必做：

1. 出口层字符串化策略落地
2. 聊天气泡偏好边界冻结
3. websocket starter 中间件边界冻结

P1 应做：

1. session 系统事件正式化
2. 位置 provider 抽象化
3. 音视频业务层建模：
   - `AppImCallController`
   - `ImCallService`
   - `ImCallStateMachine`

推荐顺序：

1. 出口层字符串化
2. session 系统事件正式化
3. 音视频业务层建模
4. 位置 provider 抽象化

### 27.8 新会话续接规则

新会话最小上下文至少给出：

1. 主目录文档路径
2. 当前目标专题
3. 当前状态
4. 是否允许继续写文档 / 是否开始写代码

当前统一后的续接原则：

- 优先只读 `IM-Flutter统一任务文档-v1.0.md`
- 若进入具体专题实现，再按需回看归档源文档
- 新会话第一句应明确“不要从 0 开始分析”

---

## 28. 当前查漏清单

当前统一文档已可执行，但仍有几类缺口值得后续只做查漏，不扩新主题：

1. 四个一级页参考仍偏文字约束，缺少更完整的原型覆盖：
   - `ConversationListPage`
   - `ContactsHomePage`
   - `WorkbenchPage`
   - `ProfilePage`
2. 设置页参考不足：
   - `SettingsPage`
   - `ThemeSettingsPage`
   - `LanguageSettingsPage`
3. 桌面 / Web 多栏布局参考不足
4. 通话服务端字段级定义虽已补齐，但尚未与真实后端代码做逐项对照
5. 统一文档前后仍存在少量重复口径，后续可继续压缩

查漏原则：

- 只补缺口
- 不新增同类平行文档
- 不重新发散专题范围

### 28.1 通话专题与真实后端对照结论

截至 `2026-05-01` 的仓库实况：

1. 服务端已存在 `ImCallService / ImCallServiceImpl`，但当前能力仍偏“通话记录服务”，未形成统一文档要求的完整业务闭环
2. 当前仓库内未检出 `AppImCallController`
3. 当前仓库内未检出 `ImCallStateMachine`
4. 当前已见 `ImCallService` 方法主干包括：
   - `initiateCall`
   - `acceptCall`
   - `rejectCall`
   - `hangupCall`
   - `forwardCallSignal`
   - `getCallRecord / getCallRecords`
5. 当前未看到与统一文档完全对齐的正式主干：
   - `CreateCallInvite`
   - `CancelCall`
   - `SyncActiveCallState`
   - `call.state-sync` 服务端状态恢复闭环
   - `call.media-token-issued` RTC 参数签发闭环
   - 多端唯一接听裁决
   - 忙线判定
   - 通话超时推进
   - 通话记录消息分发到会话流
   - 来电离线推送编排

结论：

- 音视频通话专题当前不适合进入“完整联调阶段”
- 现阶段只适合继续维持 Flutter 侧真实状态骨架与接口挂点
- 后续若推进通话落地，必须先补服务端业务闭环，再进入客户端接线

### 28.2 通话专题与 Flutter 客户端对照结论

截至 `2026-05-01` 的仓库实况：

1. Flutter 已存在 `features/im/call` 目录，包含：
   - page
   - controller
   - provider
   - repository
   - dto / mapper
2. Flutter 端已按统一文档方向预留正式接口：
   - `POST /system/im/call/create-invite`
   - `POST /system/im/call/accept`
   - `POST /system/im/call/reject`
   - `POST /system/im/call/cancel`
   - `POST /system/im/call/hangup`
   - `GET /system/im/call/state`
3. Flutter 端已支持 `call.*` 事件映射：
   - `call.invite`
   - `call.accepted`
   - `call.rejected`
   - `call.busy`
   - `call.cancelled`
   - `call.timeout`
   - `call.ended`
   - `call.device-terminated`
   - `call.media-token-issued`
   - `call.state-sync`
4. 但 provider 默认仍指向 `CallRepositoryMode.mock`
5. `MockCallRepository` 仍在仓库内，说明当前通话链路默认不走真实后端

结论：

- 通话客户端骨架已进入“真实接口命名已冻结、默认实现仍为 mock”阶段
- 后续真正推进时，优先级不是继续细抠通话 UI，而是：
  1. 先移除默认 mock 依赖
  2. 再对齐后端接口字段
  3. 再补 RTC 权限与房间参数闭环

### 28.3 其它已确认的代码级偏差

截至 `2026-05-01` 的仓库实况：

1. 通讯录历史 `contacts_mock_data.dart` 残留已清理：`completed`
2. 群设置页 controller 历史 mock 成员方法已清理：`completed`
3. 英文文案中的 `groupSettingsSimulateAddMember/groupSettingsSimulateRemoveMember` 历史残留已清理：`completed`
4. 文件预览 feature 已有实际目录与页面，并非缺失专题

结论：

- 当前更值得推进的是“静态骨架残留清理与真实数据接线”
- 不值得继续投入新的 mock 交互或 mock 事件

### 28.4 Workbench 专题当前结论

截至 `2026-05-01` 的仓库实况：

1. `WorkbenchPage` 当前定义为静态一级入口页，不承担真实业务接口承接任务
2. 当前工作台的主要目标是：
   - 保持四个一级页的视觉与交互层级一致
   - 保持入口分组清晰
   - 避免误导性的假数据表达
3. 因此工作台不再作为“需要持续补录真实后端接口”的模块推进
4. 后续若产品层面重新定义工作台为真实业务聚合页，再单独重新立项

结论：

- `WorkbenchPage` 当前继续保持骨架页定位
- 当前不要求为 `WorkbenchPage` 补齐真实接口路径
- 不继续往工作台灌 mock 数据或假联调逻辑

### 28.5 页面级真实接口补录总任务

该任务为当前阶段新增的系统级持续任务，目标是按页面/功能模块补齐：

1. 对应服务端真实接口路径
2. 核心入参
3. 核心出参字段
4. Flutter 页面如何消费这些字段
5. 若接口缺失，明确标记 `blocked`

执行依据来源优先级：

1. `shengyu-ui/shengyu-ui-admin-uniappx/api/`
2. `shengyu-ui/shengyu-ui-admin-uniappx/services/`
3. `shengyu-ui/shengyu-ui-admin-uniappx/utils/`
4. Flutter 当前仓库已接入的 repository / datasource

补录规则：

1. 后续所有真实功能模块都要持续补录到本节及其后续小节
2. 页面逻辑判断必须基于接口真实字段，不基于中文展示值
3. 旧项目 `services` 中出现的字段消费口径，默认可作为 Flutter 端页面字段消费的高优先参考
4. 如果某模块设计上就是静态页面或纯入口页，则不强行补录真实接口，直接在文档中明确其静态定位

### 28.6 第一批页面接口映射

#### 28.6.1 登录与鉴权

来源：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/login.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts`

接口映射：

| 页面/功能 | 接口路径 | 方法 | 核心入参 | 核心出参/消费说明 | 状态 |
|---|---|---|---|---|---|
| 账号密码登录 | `/system/auth/login` | `POST` | `username/password` + `deviceType/deviceId/clientVersion` | 登录态主入口 | `confirmed` |
| 短信登录 | `/system/auth/sms-login` | `POST` | 短信登录参数 + `deviceType/deviceId/clientVersion` | 登录态主入口 | `confirmed` |
| 发送短信验证码 | `/system/auth/send-sms-code` | `POST` | 手机号等短信入参 | 登录前置流程 | `confirmed` |
| 登录后权限信息 | `/system/auth/get-permission-info` | `GET` | 无 | 用户信息、权限、角色、菜单 | `confirmed` |
| 登出 | `/system/auth/logout` | `POST` | 无 | 清理登录态 | `confirmed` |
| 刷新令牌 | `/system/auth/refresh-token?refreshToken=...` | `POST` | `refreshToken` | 401 单飞刷新主依据 | `confirmed` |
| 获取图形验证码 | `/system/captcha/get` | `POST` | 验证码请求参数 | 登录前图形验证 | `confirmed` |
| 校验图形验证码 | `/system/captcha/check` | `POST` | 验证码校验参数 | 登录前图形验证 | `confirmed` |
| 租户解析 | `/system/tenant/get-id-by-name` | `GET` | 租户名 | `request.uts` 白名单已确认存在该链路 | `confirmed_reference` |

补充约束：

1. `request.uts` 已确认登录前白名单包含 `/system/captcha/`、`/login`、`/refresh-token`、`/system/tenant/get-id-by-name`
2. 请求头中存在 `tenant-id` 与 `Accept-Language`
3. 登录链路默认补设备信息，不能只传账号密码

#### 28.6.2 我的 / 设置 / 个人资料

来源：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/user.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/services/user-preference-service.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/app-upgrade.uts`

接口映射：

| 页面/功能 | 接口路径 | 方法 | 核心入参 | 核心出参/消费说明 | 状态 |
|---|---|---|---|---|---|
| 当前用户资料 | `/system/user/get-profile` | `GET` | 无 | 旧项目已消费 `themeMode/chatBubbleColor/chatBubbleMode` | `confirmed` |
| 用户详情 | `/system/user/get?id={id}` | `GET` | `id` | 联系人详情页补资料主接口 | `confirmed` |
| 更新头像 | `/system/user/avatar` | `POST upload` | `avatarFile` | 返回头像 URL 或 URL 对象 | `confirmed` |
| 清空头像 | `/system/user/avatar` | `DELETE` | 无 | 删除自定义头像 | `confirmed` |
| 更新主题偏好 | `/system/user/theme` | `PUT` | `themeMode` | 设置页主题项真实写口 | `confirmed` |
| 更新聊天气泡偏好 | `/system/user/chat-bubble` | `PUT` | `chatBubbleColor/chatBubbleMode` | 气泡主题专题真实写口 | `confirmed` |
| 应用升级检查 | `/system/app-upgrade/check` | `POST` | 版本、平台、设备信息 | 设置页升级检查依据 | `confirmed` |
| 升级事件上报 | `/system/app-upgrade/report-event` | `POST` | 升级事件参数 | 升级弹窗行为统计 | `confirmed` |

#### 28.6.3 通讯录 / 组织 / 联系人详情

来源：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/contact.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/dept.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/user.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/conversation.uts`

接口映射：

| 页面/功能 | 接口路径 | 方法 | 核心入参 | 核心出参/消费说明 | 状态 |
|---|---|---|---|---|---|
| 联系人列表 | `/system/im/contact/list` | `GET` | 无 | 通讯录主页联系人列表 | `confirmed` |
| 搜索联系人 | `/system/im/contact/search` | `GET` | `keyword/pageNo/pageSize` | 搜索结果页联系人分组 | `confirmed` |
| 联系人详情 | `/system/im/contact/get?contactId=...` | `GET` | `contactId` | 联系人关系详情 | `confirmed` |
| 联系人设置更新 | `/system/im/contact/setting/update` | `PUT` | `contactId/star/...` | 联系人关注、设置写口 | `confirmed` |
| 星标联系人 | `/system/im/contact/list-star` | `GET` | 无 | 我的关注页 | `confirmed` |
| 部门联系人 | `/system/im/contact/list-by-dept` | `GET` | `deptId` | 部门页成员列表 | `confirmed` |
| 部门联系人分页 | `/system/im/contact/list-by-dept-page` | `GET` | `deptId/pageNo/pageSize/keyword` | 大部门分页 | `confirmed` |
| 我的部门树 | `/system/dept/my-dept-tree` | `GET` | `keyword?` | 我的部门页顶部树 | `confirmed` |
| 组织树 | `/system/dept/org-tree` | `GET` | 无 | 组织结构页树数据 | `confirmed` |
| 部门成员 | `/system/dept/dept-members` | `GET` | `deptId/keyword?` | 按部门加载成员 | `confirmed` |
| 部门详情 | `/system/dept/get?id=...` | `GET` | `id` | 部门详情补充 | `confirmed_reference` |
| 用户详情补充 | `/system/user/get?id=...` | `GET` | `id` | 电话、邮箱、岗位等资料 | `confirmed` |
| 发消息建会话 | `/system/im/conversation/get-by-target` | `GET` | `targetId/conversationType` | 联系人详情进入单聊前取 `chatId` | `confirmed` |

#### 28.6.4 会话列表 / 角标 / 会话设置

来源：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/conversation.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/badge.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/services/conversation-service.uts`

旧项目字段消费口径：

- `chatId`
- `conversationType`
- `targetId`
- `targetName`
- `targetAvatar`
- `lastMessageType`
- `lastMessageContent`
- `lastMessageHasAtMe`
- `lastMessageTime`
- `unreadCount`
- `lastMessageSequence`
- `lastReadSequence`
- `isPinned`
- `noDisturb`
- `groupMemberCount`
- `conversationVersion`

接口映射：

| 页面/功能 | 接口路径 | 方法 | 核心入参 | 核心出参/消费说明 | 状态 |
|---|---|---|---|---|---|
| 会话列表 | `/system/im/conversation/list` | `GET` | 无 | 会话首页主列表 | `confirmed` |
| 会话搜索 | `/system/im/conversation/search` | `GET` | `keyword/conversationType/pageNo/pageSize` | 会话搜索页 | `confirmed` |
| 创建会话 | `/system/im/conversation/create` | `POST` | 创建会话参数 | 新建会话 | `confirmed` |
| 删除会话 | `/system/im/conversation/delete?chatId=...` | `DELETE` | `chatId` | 删除当前用户会话 | `confirmed` |
| 更新会话设置 | `/system/im/conversation/update` | `PUT` | `chatId/isPinned/noDisturb/...` | 置顶、免打扰等 | `confirmed` |
| 按序列标记已读 | `/system/im/conversation/mark-read-seq` | `PUT` | `chatId/readSequence` | 会话已读水位推进主接口 | `confirmed` |
| 按目标取会话 | `/system/im/conversation/get-by-target` | `GET` | `targetId/conversationType` | 联系人/群跳转会话 | `confirmed` |
| 角标快照 | `/system/im/badge/get` | `GET` | 无 | 总未读数、会话角标、菜单角标 | `confirmed` |

#### 28.6.5 聊天页 / 消息 / 已读回执 / WebSocket

来源：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/message.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/read-receipt.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts`

旧项目字段消费口径：

- `messageId`
- `sequence`
- `rev`
- `quoteMessageId`
- `fileId`
- `senderId`
- `receiverId`
- `groupId`
- `voicePlayed`
- `status`

接口映射：

| 页面/功能 | 接口路径 | 方法 | 核心入参 | 核心出参/消费说明 | 状态 |
|---|---|---|---|---|---|
| 聊天窗口初始化 | `/system/im/message/window` | `GET` | `chatId/mode/anchorSequence/anchorMessageId/limit/beforeLimit/afterLimit` | 聊天页 latest/anchor 双模式主接口 | `confirmed` |
| 更早历史消息 | `/system/im/message/history` | `GET` | `chatId/beforeSequence/limit` | 上拉翻页 | `confirmed` |
| 增量补偿拉取 | `/system/im/message/pull` | `GET` | `chatId/lastSequence/limit` | 断线重连后增量同步 | `confirmed` |
| 发送消息 | `/system/im/message/send` | `POST` | 消息体 | 回填 `messageId/sequence` | `confirmed` |
| 消息详情 | `/system/im/message/detail?id=...` | `GET` | `messageId` | 跳锚点/详情补拉 | `confirmed` |
| 分页消息列表 | `/system/im/message/list-by-chat` | `GET` | `chatId/pageNo/pageSize` | 备用分页读取 | `confirmed_reference` |
| 撤回消息 | `/system/im/message/recall?id=...` | `PUT` | `messageId` | 撤回操作 | `confirmed` |
| 撤回配置 | `/system/im/message/recall-config` | `GET` | 无 | 撤回能力配置 | `confirmed` |
| 删除消息 | `/system/im/message/delete?id=...` | `DELETE` | `messageId` | 单条删除 | `confirmed` |
| 清空聊天记录 | `/system/im/message/clear?chatId=...` | `DELETE` | `chatId` | 清空聊天记录 | `confirmed` |
| 会话内搜索 | `/system/im/message/search` | `GET` | `chatId/keyword/pageNo/pageSize/startTime/endTime` | 聊天记录搜索页 | `confirmed` |
| 未读总数 | `/system/im/message/unread-count` | `GET` | 无 | 总未读统计 | `confirmed_reference` |
| 批量标记消息已读 | `/system/im/message/mark-read` | `PUT` | `messageIds[]` | 消息级已读补充 | `confirmed` |
| 标记语音已播放 | `/system/im/message/mark-voice-played` | `PUT` | `messageId` | 语音未听点同步 | `confirmed` |
| 批量标记语音已播放 | `/system/im/message/mark-voice-played-batch` | `PUT` | `messageIds[]` | 聚合上报 | `confirmed` |
| 语音已播放状态查询 | `/system/im/message/voice-played-status` | `GET` | `chatId/messageIds[]` | 推送丢失补偿 | `confirmed` |
| 转发消息 | `/system/im/message/forward` | `POST` | `targetChatId/messageIds/forwardType/comment?` | 转发功能 | `confirmed` |
| 位置检索 | `/system/im/message/location-search` | `GET` | `keyword/latitude/longitude/pageSize` | 位置消息选择器 | `confirmed` |
| 群聊已读摘要 | `/system/im/read-receipt/summary` | `GET` | `messageId` | 已读回执概览 | `confirmed` |
| 群聊已读详情 | `/system/im/read-receipt/detail` | `GET` | `messageId/status/pageNo/pageSize` | 已读/未读详情页 | `confirmed` |
| WebSocket 长连 | `/ws` | `WS` | token 生命周期联动 | 实时消息、会话提示、已读回执、通话事件总线 | `confirmed_reference` |

#### 28.6.6 群设置 / 群成员 / 群公告 / 加群 / 群文件

来源：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/group.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/file.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/services/group-service.uts`

旧项目字段消费口径：

- 群信息：`groupId/groupName/ownerUserId/memberCount/notice/muteAll/myRole`
- 群成员：`userId/userName/nickname/role/joinTime/muteEndTime`
- 角色字段：`role` 为数值语义字段，`0=成员 1=管理员 2=群主`

接口映射：

| 页面/功能 | 接口路径 | 方法 | 核心入参 | 核心出参/消费说明 | 状态 |
|---|---|---|---|---|---|
| 群详情 | `/system/im/group/get?id=...` | `GET` | `groupId` | 群设置页基础信息 | `confirmed` |
| 我的群列表 | `/system/im/group/list` | `GET` | 无 | 我的群组页 | `confirmed` |
| 创建群 | `/system/im/group/create` | `POST` | 建群参数 | 创建群 | `confirmed` |
| 更新群信息 | `/system/im/group/update` | `PUT` | 群信息字段 | 群名、头像等 | `confirmed` |
| 解散群 | `/system/im/group/dissolve?id=...` | `DELETE` | `groupId` | 解散群聊 | `confirmed` |
| 退出群 | `/system/im/group/quit?id=...` | `POST` | `groupId` | 退出群聊 | `confirmed` |
| 群成员列表 | `/system/im/group/member/list?groupId=...` | `GET` | `groupId` | 群成员页、预览列表 | `confirmed` |
| 添加群成员 | `/system/im/group/member/add` | `POST` | `groupId/memberIds` | 添加成员 | `confirmed` |
| 移除群成员 | `/system/im/group/member/remove` | `DELETE` | `groupId/memberUserId` | 移除成员 | `confirmed` |
| 设置成员角色 | `/system/im/group/member/set-role` | `PUT` | `groupId/memberUserId/role` | 按 `role` 数值判断权限 | `confirmed` |
| 设置成员禁言 | `/system/im/group/member/set-muted` | `PUT` | `groupId/memberUserId/muted` | 单成员禁言 | `confirmed` |
| 设置全员禁言 | `/system/im/group/mute-all` | `PUT` | `groupId/muted` | 全员禁言 | `confirmed` |
| 设置群昵称 | `/system/im/group/member/set-nickname` | `PUT` | 群昵称字段 | 我在本群昵称 | `confirmed` |
| 转让群主 | `/system/im/group/transfer-owner` | `PUT` | `groupId/newOwnerId` | 群主转让 | `confirmed` |
| 生成群邀请码 | `/system/im/group/invite/generate` | `POST` | `groupId/expireHours/maxUseCount` | 群二维码/邀请码 | `confirmed` |
| 获取有效邀请码 | `/system/im/group/invite/get?groupId=...` | `GET` | `groupId` | 当前邀请码 | `confirmed` |
| 校验邀请码 | `/system/im/group/invite/verify?code=...` | `GET` | `inviteCode` | 扫码入群前校验 | `confirmed` |
| 邀请码入群 | `/system/im/group/invite/join` | `POST` | `inviteCode` | 加群链路 | `confirmed` |
| 入群申请列表 | `/system/im/group/join-request/list` | `GET` | `groupId/status?` | 群申请页 | `confirmed` |
| 当前群待处理数 | `/system/im/group/join-request/pending-count` | `GET` | `groupId` | 群设置待处理数 | `confirmed` |
| 我管理的群待处理数 | `/system/im/group/join-request/managed-pending-count` | `GET` | 无 | 管理群申请总览 | `confirmed` |
| 同意入群 | `/system/im/group/join-request/approve` | `PUT` | `requestId` | 处理申请 | `confirmed` |
| 拒绝入群 | `/system/im/group/join-request/reject` | `PUT` | `requestId/rejectReason` | 处理申请 | `confirmed` |
| 更新群公告 | `/system/im/group/notice/update` | `PUT` | `groupId/notice` | 群公告编辑页 | `confirmed` |
| 上传群文件 | `/system/im/group/file/upload` | `POST upload` | `groupId` + 文件 | 群文件上传 | `confirmed` |
| 群文件列表 | `/system/im/group/file/list` | `GET` | `groupId/pageNo/pageSize/fileName?/fileType?` | 群文件页 | `confirmed` |
| 删除群文件 | `/system/im/group/file/delete?id=...` | `DELETE` | `fileId` | 群文件删除 | `confirmed` |
| 记录群文件下载 | `/system/im/group/file/download?id=...` | `POST` | `fileId` | 下载统计/权限校验 | `confirmed` |

#### 28.6.7 文件预览 / 上传

来源：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/file.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/utils/upload.uts`

接口映射：

| 页面/功能 | 接口路径 | 方法 | 核心入参 | 核心出参/消费说明 | 状态 |
|---|---|---|---|---|---|
| 通用文件上传 | `/infra/file/upload` | `POST upload` | 文件 + 目录等 | 通用上传底座 | `confirmed` |
| 上传并返回文件 ID | `/infra/file/upload-and-return-id` | `POST upload` | 文件 + 目录等 | 需要直接拿 `fileId` 的链路 | `confirmed_reference` |
| 文件预签名读取地址 | `/infra/file/presigned-get-url` | `GET` | `fileId/expirationSeconds` | 读取下载 URL | `confirmed` |
| 文件打开策略 | `/infra/file/open-strategy` | `GET` | `fileId/expirationSeconds` | 返回 `action/previewUrl/downloadUrl/unstable/message` | `confirmed` |
| 会话媒体列表 | `/system/im/message/media` | `GET` | `chatId/pageNo/pageSize/fileType?` | 图片/视频/文件媒体页 | `confirmed` |

#### 28.6.8 搜索 / 收藏 / 贴纸

来源：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/search.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/favorite.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/api/sticker.uts`

接口映射：

| 页面/功能 | 接口路径 | 方法 | 核心入参 | 核心出参/消费说明 | 状态 |
|---|---|---|---|---|---|
| 热门搜索 | `/system/im/search/hot` | `GET` | `limit` | 全局搜索前置 | `confirmed` |
| 全局搜索 | `/system/im/search/global` | `GET` | `keyword/tab/pageNo/pageSize/sort/chatId?` | 聚合搜索单接口 | `confirmed` |
| 收藏消息 | `/system/im/favorite/add` | `POST` | `messageId` | 收藏操作 | `confirmed` |
| 取消收藏 | `/system/im/favorite/remove` | `DELETE` | `favoriteId` | 取消收藏 | `confirmed` |
| 收藏列表 | `/system/im/favorite/list` | `GET` | `pageNo/pageSize` | 收藏页 | `confirmed` |
| 收藏搜索 | `/system/im/favorite/search` | `GET` | `keyword/tab/pageNo/pageSize` | 收藏搜索页 | `confirmed` |
| 收藏详情 | `/system/im/favorite/detail` | `GET` | `favoriteId` | 收藏详情 | `confirmed` |
| 收藏转发 | `/system/im/favorite/resend` | `POST` | `favoriteId/targetChatId` | 收藏转发 | `confirmed` |
| 贴纸列表 | `/system/im/sticker/list` | `GET` | 无 | 贴纸面板 | `confirmed` |
| 上传贴纸 | `/system/im/sticker/upload` | `POST upload` | 贴纸文件 | 自定义贴纸 | `confirmed` |
| 收藏贴纸 | `/system/im/sticker/collect` | `POST` | `messageId` | 从消息收藏贴纸 | `confirmed` |
| 删除贴纸 | `/system/im/sticker/remove` | `DELETE` | `stickerId` | 贴纸管理 | `confirmed` |
| 贴纸排序 | `/system/im/sticker/sort` | `PUT/POST` | 排序参数 | 贴纸排序 | `confirmed` |
| 记录最近使用贴纸 | `/system/im/sticker/recent/use` | `POST/PUT` | `stickerId` | 最近使用 | `confirmed` |

#### 28.6.9 当前明确缺口与 blocked 事项

1. `音视频通话`：
   - 当前旧项目 IM `api/` 目录中未发现独立的 `api/call.uts` 或同级 HTTP 接口封装
   - 当前能确认的证据主要来自：
     - `sql/flutter-doc/IM-Flutter音视频通话企业级设计-v1.0.md`
     - `shengyu-ui/shengyu-ui-admin-uniappx/utils/proto/im_message.proto`
     - `shengyu-ui/shengyu-ui-admin-flutter/lib/core/websocket/socket_message_type.dart`
   - 已确认存在 `callSignal` socket 消息类型，但未确认 app 端完整 HTTP 控制面
   - 仍需继续补“接口差距清单”
   - 当前维持 `blocked`
2. 音视频通话当前已确认的字段/事件证据：
   - socket 消息类型：`callSignal`
   - proto 字段痕迹：`callId/callType/callerId/calleeId/rejectReason`
   - 设计文档中的核心实体：`callSessionId/callType/callerUserId/calleeUserId/acceptedDeviceId/rtcRoomId`
   - 设计文档中的核心事件：`call.invite/call.accepted/call.rejected/call.busy/call.cancelled/call.ended/call.state-sync`
3. 音视频通话当前待确认的真实服务端接口差距：
   - 是否已存在 WS `CALL_SIGNAL` 的服务端 Processor 入口
   - 是否已存在 `handleCall/handleAnswer/handleReject/handleHangup/handleTimeout/queryState/markConnected` 这一组服务端处理入口
   - 是否已存在 `call.state-sync` 对应查询或恢复能力
   - 是否已存在 RTC token / room 签发接口
4. 其余未补录专题：
   - 后续继续按本节格式逐页补录
   - 未补录完成前，不视为文档任务闭环

#### 28.6.10 音视频通话后端体系设计补充

本小节用于把“当前仓库已有少量通话记录能力”与“企业级通话目标态后端体系”明确区分，避免后续误判为已可直接联调。

##### A. 当前仓库已存在的后端基础

已确认存在：

1. 数据表：
   - `sql/mysql/1.0/im/ddl_im_tables.sql` 中已有 `im_call_record`
2. Java DO / Mapper / Service：
   - `ImCallRecordDO`
   - `ImCallRecordMapper`
   - `ImCallService`
   - `ImCallServiceImpl`
3. WebSocket proto / messageType：
   - `CALL_SIGNAL = 206`
   - `CallSignalMessage` proto 字段痕迹：`callId/callType/signalType/callerId/calleeId/rejectReason/extraData`

当前这层实现的本质：

1. 更接近“通话记录 + 基础状态改写”的薄服务
2. 还不是完整的企业级通话控制面
3. 尚未看到以下关键能力的完整后端实现闭环：
   - `AppImCallController`
   - `CallSignalMessageProcessor`
   - `CallSignalService`
   - `call.state-sync` 用户维度恢复
   - 多端唯一接听 CAS 裁决
   - RTC token / room 签发
   - `CALL_RECORD` 消息落聊天链路
   - `im_call_event` 信令事件流水

##### B. 当前已有实现与目标态的主要差距

当前 `ImCallServiceImpl` 的局限：

1. `initiateCall/acceptCall/rejectCall/hangupCall` 仅修改 `im_call_record`
2. 还没有清晰的业务状态机字段：
   - 缺 `state`
   - 缺 `endReason`
   - 缺 `acceptedDeviceId`
   - 缺 `chatId`
   - 缺 `recordMessageId`
3. 还没有多端裁决：
   - 不能保证只允许一个设备接听
4. `forwardCallSignal()` 只有校验和日志，没有处理器编排
5. 还没有“瞬态信令”和“通话记录消息”分层
6. 还没有服务端超时任务与状态恢复能力

结论：

- 当前仓库的通话后端基础可作为“通话记录底座”
- 不能直接视为“已具备 Flutter 音视频通话完整后端”
- 统一文档后续对通话专题的所有推进，都应采用“在现有记录底座上做增量重构”的策略

##### C. 推荐的后端目标态分层

通话后端应拆成三层：

1. 控制面 Control Plane
   - IM WebSocket `CALL_SIGNAL(206)`
   - 负责发起、接听、拒绝、取消、挂断、忙线、多端裁决、状态恢复
2. 查询面 Query Plane
   - App REST API
   - 负责通话记录列表、通话详情、TURN/RTC 参数查询、离线唤醒恢复
3. 媒体面 Media Plane
   - Janus SFU / `coturn`
   - 负责音视频轨道协商与转发

冻结原则：

1. 发起/接听/拒绝/挂断等强状态推进动作，优先走 WS 信令，不走 REST
2. REST 主要承担：
   - 记录查询
   - 状态恢复
   - RTC/TURN 配置查询
3. Flutter 页面状态恢复以：
   - `callSessionId`
   - `call.state-sync`
   - `GET /system/im/call/detail`
   为主

##### D. 推荐新增/调整的数据模型

现有 `im_call_record` 建议继续保留，但需扩充为“通话主表”：

建议新增字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `state` | `varchar(20)` | `INIT/RINGING/CONNECTING/CONNECTED/ENDED` |
| `end_reason` | `varchar(20)` | `HANGUP/REJECT/TIMEOUT/BUSY/CANCEL/CALLEE_OFFLINE/ERROR` |
| `accepted_device_id` | `varchar(64)` | 多端裁决后成功接听的设备ID |
| `chat_id` | `bigint` | 关联会话ID |
| `record_message_id` | `bigint` | 结束后生成的 `CALL_RECORD` 消息ID |

建议新增事件流水表：

- `im_call_event`

用途：

1. 记录所有 `CALL_SIGNAL` 事件流水
2. 按 `callId + eventId(messageId)` 做幂等
3. 为问题排查、灰度联调、恢复补偿提供依据，不单独扩成审计产品能力

##### E. 推荐后端核心枚举

建议统一冻结以下枚举：

1. `ImCallTypeEnum`
   - `VOICE(1)`
   - `VIDEO(2)`
2. `ImCallStateEnum`
   - `INIT`
   - `RINGING`
   - `CONNECTING`
   - `CONNECTED`
   - `ENDED`
3. `ImCallStatusEnum`
   - `MISSED(1)`
   - `ANSWERED(2)`
   - `REJECTED(3)`
   - `BUSY(4)`
   - `CANCELLED(5)`
4. `ImCallEndReasonEnum`
   - `HANGUP`
   - `REJECT`
   - `TIMEOUT`
   - `BUSY`
   - `CANCEL`
   - `CALLEE_OFFLINE`
   - `ERROR`
5. `ImCallSignalTypeEnum`
   - `CALL(1)`
   - `ANSWER(2)`
   - `REJECT(3)`
   - `HANGUP(4)`
   - `BUSY(5)`
   - `SWITCH_CAMERA(6)`
   - `SDP_OFFER(7)`
   - `SDP_ANSWER(8)`
   - `ICE_CANDIDATE(9)`
   - `STATE_SYNC(10)`
   - `TIMEOUT(11)`

##### F. 推荐中间件与服务组件

建议新增或拆分以下后端组件：

1. `CallSignalMessageProcessor`
   - WebSocket `CALL_SIGNAL(206)` 入口
   - 不接 `MessageStorageService`
   - 只做瞬态信令处理与投递
2. `CallSignalService`
   - 通话业务状态机权威入口
   - 发起、接听、拒绝、挂断、超时、状态恢复
3. `ImCallTimeoutJob`
   - 扫描 `RINGING/CONNECTING` 超时通话
   - 统一推进 `ENDED/TIMEOUT`
4. `RtcCredentialService`
   - 生成或装配 Janus / TURN / room / token
5. `CallStateSyncService`
   - 用户重连后恢复 `STATE_SYNC`
6. `CallRecordMessageFactory`
   - 生成 `CALL_RECORD` 消息体
7. `CallPushService`
   - 被叫离线时触发离线推送

##### G. 推荐后端服务接口

建议把当前 `ImCallService` 逐步拆分为两层：

1. 保留 `ImCallService`
   - 偏记录与查询
2. 新增 `CallSignalService`
   - 偏状态推进与信令控制

建议 `CallSignalService` 接口形状：

```java
public interface CallSignalService {
    String handleCall(Long callerId, Long calleeId, Integer callType, Long tenantId);
    CallAnswerResult handleAnswer(String callId, Long userId, String deviceId);
    void handleReject(String callId, Long userId, String rejectReason);
    ImCallEndResult handleHangup(String callId, Long userId);
    ImCallEndResult handleTimeout(String callId);
    CallStateSnapshot queryState(String callId, Long userId);
    boolean isCalleeAvailable(Long calleeId, Long tenantId);
    void markConnected(String callId, Long userId);
}
```

建议 `ImCallService` 保留/收敛为：

```java
public interface ImCallService {
    ImCallRecordDO getCallRecord(String callId);
    List<ImCallRecordDO> getCallRecords(Long userId, Integer limit);
    List<ImCallRecordDO> getCallRecordsBetweenUsers(Long userId1, Long userId2, Integer limit);
    Long saveCallRecord(ImCallRecordDO callRecord);
    void updateCallStatus(String callId, Integer status);
    void calculateAndUpdateDuration(String callId);
}
```

##### H. 推荐 App REST API 设计

说明：

1. 当前仓库可确认的“已存在能力”主要还是记录查询底座
2. 以下 REST 设计分为：
   - `confirmed_baseline`：从现有服务能力与旧设计稿可直接承接
   - `proposed_required`：为完整通话体系建议新增

###### H.1 推荐 Controller

- `AppImCallController`

建议路径前缀：

- `/system/im/call`

###### H.2 推荐接口表

| 能力 | HTTP URL | 方法 | 状态 | 说明 |
|---|---|---|---|---|
| 通话记录列表 | `/system/im/call/records` | `GET` | `confirmed_baseline` | 当前用户分页通话记录 |
| 两人通话记录 | `/system/im/call/records-between` | `GET` | `confirmed_baseline` | 两用户之间记录 |
| 通话详情 | `/system/im/call/detail` | `GET` | `confirmed_baseline` | 离线唤醒或断线恢复查询 |
| TURN/STUN 配置 | `/system/im/call/turn-config` | `GET` | `confirmed_baseline` | 返回 TURN/STUN 列表与超时配置 |
| RTC 凭证 | `/system/im/call/rtc-credential` | `GET` | `proposed_required` | 按 `callId` 返回 room/token/bundle |
| 当前活跃通话 | `/system/im/call/active` | `GET` | `proposed_required` | 按当前 userId 查是否存在活跃通话 |

说明：

1. 发起/接听/拒绝/挂断不建议开放 REST 主入口
2. 这些动作应通过 WS `CALL_SIGNAL` 走统一状态机
3. 只有查询类、配置类、恢复类接口适合放在 App REST

###### H.3 推荐 ReqVO / RespVO

1. `AppImCallRecordsReqVO`
   - `pageNo`
   - `pageSize`
   - `callType?`
   - `status?`
2. `AppImCallRecordsBetweenReqVO`
   - `targetUserId`
   - `pageNo`
   - `pageSize`
3. `AppImCallRecordRespVO`
   - `callId`
   - `callType`
   - `callerId`
   - `calleeId`
   - `startTime`
   - `endTime`
   - `duration`
   - `status`
   - `state`
   - `endReason`
   - `chatId`
   - `recordMessageId`
4. `AppImCallDetailRespVO`
   - `callId`
   - `callType`
   - `callerId`
   - `calleeId`
   - `state`
   - `status`
   - `endReason`
   - `acceptedDeviceId`
   - `startTime`
   - `endTime`
   - `duration`
   - `chatId`
   - `recordMessageId`
   - `isCurrentUserCaller`
   - `isCurrentUserCallee`
5. `AppImCallTurnConfigRespVO`
   - `signalOnlyMode`
   - `ringingTimeoutSeconds`
   - `connectingTimeoutSeconds`
   - `stunServers[]`
   - `turnServers[]`
6. `AppImCallRtcCredentialRespVO`
   - `callId`
   - `rtcRoomId`
   - `publisherToken`
   - `subscriberToken`
   - `janusUrl`
   - `turnServers[]`
   - `acceptedDeviceId`
   - `expireAt`
7. `AppImActiveCallRespVO`
   - `hasActiveCall`
   - `callId`
   - `callType`
   - `state`
   - `entryModeSuggested`
   - `chatId`

##### I. 推荐 WebSocket 信令协议

通话信令继续复用：

- `messageType = CALL_SIGNAL(206)`

`CallSignalMessage` 建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `callId` | `string` | 通话主键，统一使用字符串 |
| `callType` | `int32` | `1=语音 2=视频` |
| `signalType` | `int32` | 见 `ImCallSignalTypeEnum` |
| `callerId` | `int64` | 呼叫方 |
| `calleeId` | `int64` | 被叫方 |
| `rejectReason` | `string` | 拒绝原因 |
| `extraData` | `string(JSON)` | SDP/ICE/STATE_SYNC/connected 标记等 |

Header 约束：

1. `messageId` 必须存在，用于幂等
2. `senderId/tenantId/timestamp` 服务端覆盖
3. 通话信令不分配 `sequence`
4. 仅通话结束后生成的 `CALL_RECORD` 消息才进入消息列表

##### I.1 推荐信令处理总线

建议按以下顺序实现：

1. 客户端发 `CALL_SIGNAL(206)`
2. `CallSignalMessageProcessor` 从 session 中覆盖：
   - `userId`
   - `deviceId`
   - `tenantId`
3. `Processor` 调 `CallSignalService`
4. `CallSignalService` 推进状态机与裁决结果
5. `Processor` 按结果向：
   - 主叫用户全部设备
   - 被叫用户全部设备
   - 或 `acceptedDeviceId`
   做 fanout / 定向投递
6. 通话结束时由服务端生成 `CALL_RECORD` 消息并写入消息链路

建议责任边界：

1. `Processor`
   - 解析协议
   - 鉴权兜底
   - 设备级投递
   - 不做复杂业务规则
2. `CallSignalService`
   - 忙线检测
   - 多端 CAS 裁决
   - 状态推进
   - 超时结束
   - 恢复态快照
3. `MessageStorageService`
   - 只负责最终 `CALL_RECORD`
   - 不负责瞬态 `CALL_SIGNAL`

##### I.2 推荐 signalType 到后端处理动作映射

| signalType | 名称 | 服务端入口 | 说明 |
|---|---|---|---|
| `1` | `CALL` | `handleCall` | 主叫发起呼叫 |
| `2` | `ANSWER` | `handleAnswer` | 被叫接听，内部做 CAS |
| `3` | `REJECT` | `handleReject` | 被叫拒绝 |
| `4` | `HANGUP` | `handleHangup` | 主叫取消或通话中挂断 |
| `5` | `BUSY` | 服务端派生结果 | 一般不由客户端主动发起 |
| `6` | `SWITCH_CAMERA` | 透传或轻状态同步 | UI/媒体附属动作 |
| `7` | `SDP_OFFER` | 定向透传 | A -> accepted device |
| `8` | `SDP_ANSWER` | 定向透传 | B -> caller active device |
| `9` | `ICE_CANDIDATE` | 定向透传 | accepted devices 之间交换 |
| `10` | `STATE_SYNC` | 服务端主动下发 | 重连恢复 |
| `11` | `TIMEOUT` | `handleTimeout` | 服务端超时任务生成 |

##### J. `extraData` JSON 约定

1. `SDP_OFFER / SDP_ANSWER`

```json
{
  "sdp": "v=0\r\n...",
  "type": "offer"
}
```

2. `ICE_CANDIDATE`

```json
{
  "candidate": "candidate:842163049 1 udp ...",
  "sdpMid": "0",
  "sdpMLineIndex": 0
}
```

3. `STATE_SYNC`

```json
{
  "state": "RINGING",
  "callType": 1,
  "callerId": "123456",
  "calleeId": "789012",
  "startTime": 1711929600000,
  "acceptedDeviceId": null
}
```

4. `CONNECTED` 回执建议

```json
{
  "connected": true,
  "rtcConnectedAt": 1711929600000
}
```

##### K. 推荐通话消息类型补充

建议在 proto 与消息体系中新增：

- `CALL_RECORD = 209`

用途：

1. 通话结束后生成聊天记录消息
2. 进入消息列表
3. 参与最近消息预览
4. 与瞬态 `CALL_SIGNAL(206)` 分层

建议 `CallRecordMessage` 字段：

- `callId`
- `callType`
- `duration`
- `status`
- `endReason`
- `callerId`
- `calleeId`

##### L. 推荐服务端状态推进规则

建议冻结主状态机：

```text
INIT -> RINGING -> CONNECTING -> CONNECTED -> ENDED
```

说明：

1. `CALL` 发起成功后进入 `RINGING`
2. 被叫某设备通过 CAS 裁决后进入 `CONNECTING`
3. 端侧 ICE 连通并上报后进入 `CONNECTED`
4. 拒绝/取消/忙线/超时/挂断统一进入 `ENDED`

多端规则：

1. 同账号多设备可同时收到来电
2. 只允许一个 `acceptedDeviceId`
3. 其他设备收到 `HANGUP` 或 `BUSY`

##### M. 与 Flutter 现有前端的结合点

当前 Flutter 已有：

1. 路由：
   - `/call/incoming`
   - `/call/outgoing`
   - `/call/session`
2. 参数对象：
   - `CallLaunchArgs`
3. 页面骨架：
   - `IncomingCallPage`
   - `OutgoingCallPage`
   - `CallSessionPage`
4. socket message type：
   - `callSignal = 206`

因此后端设计必须保证 Flutter 能直接消费：

1. `callSessionId`
2. `chatId`
3. `callType`
4. `entryMode`
5. `acceptedDeviceId`
6. `rtcRoomBundle/janusUrl/turnServers/token`
7. `call.state-sync`

##### N. 推荐分阶段实施

`Phase 0`

1. 扩 `im_call_record`
2. 新增 `ImCallStateEnum/ImCallEndReasonEnum/ImCallSignalTypeEnum`
3. 建 `CallSignalService`
4. 建 `CallSignalMessageProcessor`
5. 打通 `CALL_SIGNAL` 基础状态推进
6. 保留“信令联调模式”，先不强依赖 RTC

`Phase 1`

1. 新增 `AppImCallController`
2. 完成：
   - `/records`
   - `/records-between`
   - `/detail`
   - `/turn-config`
   - `/rtc-credential`
3. 新增 `CALL_RECORD = 209`
4. 结束通话时生成消息记录
5. 补离线推送唤醒与 `STATE_SYNC`

`Phase 2`

1. 落 `im_call_event`
2. 增强可观测性、审计、问题回放
3. 做多人通话/屏幕共享等扩展准备

##### O. 当前文档阶段结论

1. 通话专题不能只围绕“通话记录接口”推进
2. 当前最合理的策略是：
   - 以现有 `ImCallRecord` 作为底座
   - 增量补状态机、信令处理器、查询接口、RTC 凭证接口
3. 通话专题后续在统一文档中的推进，应优先补：
   - 真实 Java controller / service / mapper 差距
   - VO / ReqVO / proto 约定
   - 中间件信令处理流程
   - 再决定具体代码实现顺序

##### P. 推荐 Java 文件清单与职责映射

本节用于把“建议新增哪些文件、放在哪、谁负责什么”固定下来，后续后端实现按此拆任务。

###### P.1 当前已存在文件

| 类型 | 建议保留文件 | 当前状态 | 说明 |
|---|---|---|---|
| DO | `.../dal/dataobject/im/ImCallRecordDO.java` | `exists` | 当前通话记录主表 DO |
| Mapper | `.../dal/mysql/im/ImCallRecordMapper.java` | `exists` | 当前通话记录查询与保存底座 |
| Service | `.../service/im/ImCallService.java` | `exists` | 当前偏记录接口 |
| ServiceImpl | `.../service/im/ImCallServiceImpl.java` | `exists` | 当前偏记录实现 |
| Proto | `shengyu-framework/.../proto/im_message.proto` | `exists` | 已有 `CALL_SIGNAL = 206` |
| Netty Config | `shengyu-framework/.../config/NettyAutoConfiguration.java` | `exists` | 具备注册 message processor 的扩展位 |
| ProcessorFactory | `shengyu-framework/.../core/processor/MessageProcessorFactory.java` | `exists` | 具备按 messageType 注册 processor 的基础能力 |

###### P.2 建议新增文件

| 类型 | 建议文件 | 状态 | 职责 |
|---|---|---|---|
| Controller | `.../controller/app/im/AppImCallController.java` | `proposed_required` | App 侧记录查询、详情恢复、TURN/RTC 配置接口 |
| ReqVO | `.../controller/app/im/vo/call/AppImCallRecordsReqVO.java` | `proposed_required` | 通话记录分页查询入参 |
| ReqVO | `.../controller/app/im/vo/call/AppImCallRecordsBetweenReqVO.java` | `proposed_required` | 两人记录查询入参 |
| RespVO | `.../controller/app/im/vo/call/AppImCallRecordRespVO.java` | `proposed_required` | 通话记录列表出参 |
| RespVO | `.../controller/app/im/vo/call/AppImCallDetailRespVO.java` | `proposed_required` | 通话详情与恢复出参 |
| RespVO | `.../controller/app/im/vo/call/AppImCallTurnConfigRespVO.java` | `proposed_required` | STUN/TURN 配置出参 |
| RespVO | `.../controller/app/im/vo/call/AppImCallRtcCredentialRespVO.java` | `proposed_required` | RTC 凭证出参 |
| RespVO | `.../controller/app/im/vo/call/AppImActiveCallRespVO.java` | `proposed_required` | 当前活跃通话查询出参 |
| Enum | `.../enums/im/ImCallStateEnum.java` | `proposed_required` | 业务状态机枚举 |
| Enum | `.../enums/im/ImCallEndReasonEnum.java` | `proposed_required` | 结束原因枚举 |
| Enum | `.../enums/im/ImCallSignalTypeEnum.java` | `proposed_required` | 信令类型枚举 |
| Service | `.../service/im/CallSignalService.java` | `proposed_required` | 通话控制面权威接口 |
| ServiceImpl | `.../service/im/CallSignalServiceImpl.java` | `proposed_required` | 控制面实现 |
| DTO | `.../service/im/dto/CallAnswerResult.java` | `proposed_required` | 接听裁决结果 |
| DTO | `.../service/im/dto/ImCallEndResult.java` | `proposed_required` | 结束结果 |
| DTO | `.../service/im/dto/CallStateSnapshot.java` | `proposed_required` | 恢复态快照 |
| Service | `.../service/im/RtcCredentialService.java` | `proposed_required` | Janus/TURN/Token 签发 |
| Service | `.../service/im/CallStateSyncService.java` | `proposed_required` | auth 后恢复态下发 |
| Service | `.../service/im/CallRecordMessageFactory.java` | `proposed_required` | 生成 `CALL_RECORD` 消息体 |
| Job | `.../job/im/ImCallTimeoutJob.java` | `proposed_required` | 响铃/连接超时任务 |
| DO | `.../dal/dataobject/im/ImCallEventDO.java` | `phase2_required` | 事件流水表 |
| Mapper | `.../dal/mysql/im/ImCallEventMapper.java` | `phase2_required` | 事件流水读写 |
| Processor | `shengyu-framework/.../processor/impl/CallSignalMessageProcessor.java` | `proposed_required` | WebSocket `CALL_SIGNAL` 处理入口 |

###### P.3 建议改造文件

| 文件 | 建议改造内容 |
|---|---|
| `ImCallRecordDO.java` | 增 `state/endReason/acceptedDeviceId/chatId/recordMessageId` |
| `ImCallRecordMapper.java` | 增 CAS 更新、按状态查询、活跃通话查询、超时扫描查询 |
| `ImCallService.java` | 收敛为记录与查询能力，不再承载完整信令编排 |
| `ImCallServiceImpl.java` | 迁出控制面逻辑，保留记录底座 |
| `im_message.proto` | 增 `CALL_RECORD = 209` 与 `CallRecordMessage` |
| `NettyAutoConfiguration.java` | 注册 `CallSignalMessageProcessor` |

##### Q. 推荐 DDL 变更草案

###### Q.1 `im_call_record` 增量改造

建议迁移 SQL：

```sql
ALTER TABLE `im_call_record`
  ADD COLUMN `state` varchar(20) NOT NULL DEFAULT 'INIT'
    COMMENT '业务状态(INIT/RINGING/CONNECTING/CONNECTED/ENDED)' AFTER `status`,
  ADD COLUMN `end_reason` varchar(32) NULL DEFAULT NULL
    COMMENT '结束原因(HANGUP/REJECT/TIMEOUT/BUSY/CANCEL/CALLEE_OFFLINE/ERROR)' AFTER `state`,
  ADD COLUMN `accepted_device_id` varchar(64) NULL DEFAULT NULL
    COMMENT '接听设备ID（多端裁决结果）' AFTER `end_reason`,
  ADD COLUMN `chat_id` bigint NULL DEFAULT NULL
    COMMENT '关联会话ID' AFTER `accepted_device_id`,
  ADD COLUMN `record_message_id` bigint NULL DEFAULT NULL
    COMMENT '通话记录消息ID（CALL_RECORD=209）' AFTER `chat_id`;
```

建议新增索引：

```sql
ALTER TABLE `im_call_record`
  ADD INDEX `idx_tenant_state`(`tenant_id`, `state`),
  ADD INDEX `idx_tenant_callee_state`(`tenant_id`, `callee_id`, `state`),
  ADD INDEX `idx_tenant_caller_state`(`tenant_id`, `caller_id`, `state`);
```

用途：

1. 查活跃通话
2. 查被叫是否忙线
3. 扫描超时任务

###### Q.2 `im_call_event` 建议表结构

```sql
CREATE TABLE `im_call_event` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `call_id` varchar(64) NOT NULL COMMENT '通话ID',
  `event_id` varchar(64) NOT NULL COMMENT '事件ID，对应 websocket header.messageId',
  `signal_type` tinyint NOT NULL COMMENT '信令类型',
  `sender_id` bigint NOT NULL COMMENT '事件发送者',
  `device_id` varchar(64) DEFAULT NULL COMMENT '设备ID',
  `payload_json` text DEFAULT NULL COMMENT 'extraData 原始载荷',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_call_event` (`call_id`, `event_id`),
  KEY `idx_call_id_time` (`call_id`, `create_time`),
  KEY `idx_tenant_call_id` (`tenant_id`, `call_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM通话事件流水表';
```

##### R. 推荐字段对照表

###### R.1 Flutter `CallLaunchArgs` 与后端字段对照

| Flutter 字段 | 后端来源 | 说明 |
|---|---|---|
| `callSessionId` | `callId` | 一律字符串 |
| `chatId` | `im_call_record.chat_id` 或会话查询结果 | 页面恢复、记录消息落地 |
| `callType` | `callType` | `1=语音 2=视频` |
| `entryMode` | 本地路由决策 + `state/isCurrentUserCaller` | `incoming/outgoing/restore` |
| `fromUserId` | `callerId` | 主叫 |
| `toUserId` | `calleeId` | 被叫 |
| `inviteId` | 可选扩展 | 若后续引入 invite 级子标识再补 |

###### R.2 WebSocket `CallSignalMessage` 与服务端处理字段对照

| 协议字段 | 服务端消费字段 | 用途 |
|---|---|---|
| `callId` | `im_call_record.call_id` | 通话主键 |
| `callType` | `im_call_record.call_type` | 语音/视频 |
| `signalType` | `ImCallSignalTypeEnum` | 路由到处理动作 |
| `callerId` | `im_call_record.caller_id` | 呼叫方 |
| `calleeId` | `im_call_record.callee_id` | 被叫方 |
| `rejectReason` | `end_reason` / reject VO | 拒绝原因 |
| `extraData` | 事件载荷 | SDP/ICE/恢复态/connected |
| `header.messageId` | `im_call_event.event_id` | 幂等键 |
| `header.senderId` | session 覆盖 | 防伪造 |
| `header.tenantId` | session 覆盖 | 租户隔离 |

###### R.3 `AppImCallDetailRespVO` 与 Flutter 恢复态消费对照

| RespVO 字段 | Flutter 消费点 | 说明 |
|---|---|---|
| `callId` | `CallLaunchArgs.callSessionId` | 恢复主键 |
| `callType` | `CallType` | 页类型 |
| `state` | `CallPageStatus` 初始映射 | `incoming/connecting/connected/ended` |
| `status` | 记录摘要与结束文案 | 与 `CALL_RECORD` 对齐 |
| `endReason` | `CallEndReason` | 页面结束理由 |
| `acceptedDeviceId` | 多端接听后设备判断 | 恢复与定向 |
| `chatId` | 结束后回会话/聊天 | 页面恢复与落记录 |
| `callerId/calleeId` | `isCurrentUserCaller/isCurrentUserCallee` | 主被叫视角 |

##### S. 推荐关键时序补充

###### S.1 发起呼叫时序

1. Flutter 主叫页发 `CALL_SIGNAL(CALL)`
2. `CallSignalMessageProcessor` 接收并解析
3. `CallSignalService.handleCall()`：
   - 校验权限
   - 校验会话合法性
   - 忙线检测
   - 创建/更新 `im_call_record`
   - 状态推进到 `RINGING`
4. Processor fanout 到被叫全部在线设备
5. 若全部离线：
   - `CallPushService` 触发离线推送
   - 主叫侧仍保留 `RINGING`

###### S.2 被叫接听时序

1. 某设备发 `CALL_SIGNAL(ANSWER)`
2. `CallSignalService.handleAnswer(callId, userId, deviceId)` 做 CAS
3. 成功设备：
   - 写 `accepted_device_id`
   - 状态推进到 `CONNECTING`
4. Processor：
   - 通知主叫 `ANSWER`
   - 通知被叫其它设备 `HANGUP` 或终止事件
5. Flutter 双端进入 `connecting`

###### S.3 RTC 连通时序

1. Flutter 成功连上 Janus / WebRTC
2. 主被叫设备上报“connected”确认
3. `CallSignalService.markConnected(callId, userId)`
4. 服务端推进到 `CONNECTED`
5. 如有需要，可补发一次 `STATE_SYNC`

###### S.4 挂断 / 超时 / 生成记录消息时序

1. `HANGUP` / `REJECT` / 超时任务触发结束
2. `CallSignalService` 推进：
   - `state = ENDED`
   - `endReason`
   - `status`
   - `endTime`
   - `duration`
3. Processor 向双方设备广播结束
4. `CallRecordMessageFactory` 生成 `CALL_RECORD = 209`
5. `MessageStorageService` 存消息
6. 回填 `record_message_id`
7. 会话最近消息、聊天页、通话记录列表同步刷新

###### S.5 断线恢复时序

1. 用户重连并重新 AUTH
2. `CallStateSyncService` 查询该 userId 是否存在活跃通话
3. 若存在：
   - 下发 `CALL_SIGNAL(STATE_SYNC)`
   - 或 Flutter 主动拉 `GET /system/im/call/detail`
4. Flutter 根据：
   - `state`
   - `callType`
   - `acceptedDeviceId`
   决定进入：
   - `/call/incoming`
   - `/call/outgoing`
   - `/call/session`

##### T. 当前下一步建议

通话专题文档后续继续补的优先级建议：

1. 把 `AppImCallController` 的接口清单继续细化到方法级
2. 把 `CallSignalMessageProcessor` 的 signalType 分发伪代码补到统一文档
3. 把 `CALL_RECORD = 209` 的 proto 草案补进统一文档
4. 把 `turn-config / rtc-credential / active` 三个 RespVO 细化成字段级定义
5. 再进入后端代码实现阶段

##### U. `AppImCallController` 方法级接口建议

建议位置：

- `shengyu-module-system/.../controller/app/im/AppImCallController.java`

建议方法清单：

```java
@Tag(name = "App 端 - IM 通话")
@RestController
@RequestMapping("/system/im/call")
@Validated
public class AppImCallController {

    @GetMapping("/records")
    public CommonResult<PageResult<AppImCallRecordRespVO>> getCallRecords(
            @Valid AppImCallRecordsReqVO reqVO) { ... }

    @GetMapping("/records-between")
    public CommonResult<PageResult<AppImCallRecordRespVO>> getCallRecordsBetween(
            @Valid AppImCallRecordsBetweenReqVO reqVO) { ... }

    @GetMapping("/detail")
    public CommonResult<AppImCallDetailRespVO> getCallDetail(
            @RequestParam("callId") String callId) { ... }

    @GetMapping("/turn-config")
    public CommonResult<AppImCallTurnConfigRespVO> getTurnConfig() { ... }

    @GetMapping("/rtc-credential")
    public CommonResult<AppImCallRtcCredentialRespVO> getRtcCredential(
            @RequestParam("callId") String callId) { ... }

    @GetMapping("/active")
    public CommonResult<AppImActiveCallRespVO> getActiveCall() { ... }
}
```

方法职责冻结：

1. `getCallRecords`
   - 当前用户分页查询通话记录
   - 支持 `callType/status` 筛选
2. `getCallRecordsBetween`
   - 当前用户与目标用户之间的通话记录分页
3. `getCallDetail`
   - 断线恢复、离线推送唤醒恢复主接口
4. `getTurnConfig`
   - 返回 STUN/TURN 与超时配置
5. `getRtcCredential`
   - 返回 Janus / room / token / expireAt
   - 必须校验当前用户是否属于该 `callId`
6. `getActiveCall`
   - 当前用户是否仍存在活跃通话
   - 为 Flutter 重进应用时的主动恢复提供依据

接口鉴权要求：

1. 全部要求登录态
2. `callId` 相关接口必须校验当前用户是否是：
   - `callerId`
   - 或 `calleeId`
3. 严禁通过前端直接传 `userId` 决定查询归属

##### V. 关键 RespVO 字段冻结说明

###### V.1 `AppImCallTurnConfigRespVO`

建议字段：

```java
public class AppImCallTurnConfigRespVO {
    private Boolean rtcEnabled;
    private Boolean signalOnlyMode;
    private Integer ringingTimeoutSeconds;
    private Integer connectingTimeoutSeconds;
    private List<String> stunServers;
    private List<TurnServerItemRespVO> turnServers;
    private String janusWsUrl;
    private String janusHttpUrl;
}
```

其中 `TurnServerItemRespVO`：

```java
public class TurnServerItemRespVO {
    private String url;
    private String username;
    private String credential;
    private String credentialType;
}
```

字段说明：

1. `rtcEnabled`
   - 总开关
2. `signalOnlyMode`
   - 仅信令联调模式
3. `ringingTimeoutSeconds`
   - 响铃超时阈值
4. `connectingTimeoutSeconds`
   - 连接中超时阈值
5. `stunServers/turnServers`
   - Flutter `RtcGatewayClient` 初始化 ICE servers 直接消费
6. `janusWsUrl/janusHttpUrl`
   - 视实际 Janus 接入方式选择其一或都保留

###### V.2 `AppImCallRtcCredentialRespVO`

建议字段：

```java
public class AppImCallRtcCredentialRespVO {
    private String callId;
    private String rtcRoomId;
    private String publisherToken;
    private String subscriberToken;
    private String janusWsUrl;
    private String janusHttpUrl;
    private List<String> stunServers;
    private List<TurnServerItemRespVO> turnServers;
    private String acceptedDeviceId;
    private Long expireAt;
    private Boolean caller;
    private Boolean callee;
}
```

字段说明：

1. `rtcRoomId`
   - 默认可与 `callId` 一致
2. `publisherToken/subscriberToken`
   - Phase 1 即便先给同一 token，也建议字段先分开
3. `acceptedDeviceId`
   - 用于多端裁决后的设备级恢复
4. `expireAt`
   - Flutter 可据此做凭证刷新或失效处理
5. `caller/callee`
   - 前端快速判断当前视角，减少重复推导

###### V.3 `AppImActiveCallRespVO`

建议字段：

```java
public class AppImActiveCallRespVO {
    private Boolean hasActiveCall;
    private String callId;
    private Integer callType;
    private String state;
    private String chatId;
    private String acceptedDeviceId;
    private String entryModeSuggested;
    private Long callerId;
    private Long calleeId;
}
```

字段说明：

1. `hasActiveCall=false`
   - 其余字段允许为空
2. `entryModeSuggested`
   - 建议值：`incoming/outgoing/restore/session`
3. Flutter 若拿到该结构，可直接映射到：
   - `CallLaunchArgs`
   - 路由页类型

##### W. `CallSignalMessageProcessor` 推荐分发伪代码

说明：

1. 该 Processor 是通话控制面的核心入口
2. 目标是把“协议解析”和“业务状态推进”彻底分离
3. 瞬态信令不走 `MessageStorageService`

建议伪代码：

```java
public class CallSignalMessageProcessor implements MessageProcessor {

    @Override
    public void process(NettySession session, ImMessage message) {
        Long userId = session.getUserId();
        String deviceId = session.getDeviceId();
        Long tenantId = session.getTenantId();

        CallSignalMessage body = CallSignalMessage.parseFrom(message.getBody());
        int signalType = body.getSignalType();

        switch (signalType) {
            case 1:
                handleCall(session, body, userId, deviceId, tenantId);
                break;
            case 2:
                handleAnswer(session, body, userId, deviceId, tenantId);
                break;
            case 3:
                handleReject(session, body, userId, deviceId, tenantId);
                break;
            case 4:
                handleHangup(session, body, userId, deviceId, tenantId);
                break;
            case 7:
                relaySdpOffer(session, body, userId, deviceId, tenantId);
                break;
            case 8:
                relaySdpAnswer(session, body, userId, deviceId, tenantId);
                break;
            case 9:
                relayIceCandidate(session, body, userId, deviceId, tenantId);
                break;
            default:
                ignoreOrAckUnsupported(session, body);
                break;
        }
    }
}
```

###### W.1 `CALL(1)` 分支

1. 检查 `rtcEnabled`
2. 校验：
   - 当前用户登录态
   - 不能给自己打电话
   - `callType` 合法
3. `callSignalService.isCalleeAvailable(calleeId, tenantId)`
4. 若忙线：
   - 向主叫回 `BUSY`
   - return
5. `callId = callSignalService.handleCall(...)`
6. fanout 到被叫在线设备
7. 若无在线设备：
   - 触发离线推送
   - 保持 `RINGING`
8. 回显给主叫，确保主叫拿到 `callId`

###### W.2 `ANSWER(2)` 分支

1. `result = callSignalService.handleAnswer(callId, userId, deviceId)`
2. 若 `ACCEPTED`
   - 通知主叫 `ANSWER`
   - 通知被叫其它设备停止响铃
3. 若 `BUSY`
   - 当前设备收到 `BUSY`
4. 若 `NOT_FOUND/ENDED`
   - 当前设备收到 `TIMEOUT` 或结束态提示

###### W.3 `REJECT(3)` 分支

1. `callSignalService.handleReject(callId, userId, rejectReason)`
2. 通知主叫 `REJECT`
3. 通知被叫其它设备停止响铃

###### W.4 `HANGUP(4)` 分支

1. `endResult = callSignalService.handleHangup(callId, userId)`
2. 通知对端所有设备
3. 通知当前用户其它设备
4. 若状态进入 `ENDED`
   - 触发 `CALL_RECORD` 生成

###### W.5 `SDP_OFFER/SDP_ANSWER/ICE_CANDIDATE`

1. 不落消息存储
2. 不进入消息列表
3. 按 `acceptedDeviceId` 与当前活跃设备做定向透传
4. 可写 `im_call_event` 作为接口流程事件记录

##### X. `CALL_RECORD = 209` proto 草案

当前 proto 已有：

- `CALL_SIGNAL = 206`
- `WORKFLOW_NOTIFY = 207`
- `TODO_REMINDER = 208`

建议新增：

```protobuf
enum MessageType {
  ...
  CALL_SIGNAL = 206;
  WORKFLOW_NOTIFY = 207;
  TODO_REMINDER = 208;
  CALL_RECORD = 209;
}

message CallRecordMessage {
  string callId = 1;
  int32 callType = 2;
  int32 duration = 3;
  int32 status = 4;
  string endReason = 5;
  int64 callerId = 6;
  int64 calleeId = 7;
  int64 startTimestamp = 8;
  int64 endTimestamp = 9;
  int64 chatId = 10;
}
```

字段冻结说明：

1. `callId`
   - 与 `callSessionId` 一致
2. `callType`
   - `1=语音 2=视频`
3. `duration`
   - 秒
4. `status`
   - `MISSED/ANSWERED/REJECTED/BUSY/CANCELLED`
5. `endReason`
   - 更细结束原因，补足 `status` 语义不够细的问题
6. `startTimestamp/endTimestamp`
   - 端侧直接渲染时间与排序
7. `chatId`
   - 方便回跳会话

##### Y. 当前这一轮文档推进结论

1. 通话专题在统一文档中已经不再只是“blocked 提醒”
2. 当前已具备以下后端实施依据：
   - 状态机
   - 信令类型
   - Java 文件清单
   - DDL 变更草案
   - App REST 方法级接口
   - RespVO 字段冻结
   - Processor 分发伪代码
   - `CALL_RECORD` proto 草案
3. 后续继续完善时，优先补：
   - `CallSignalService` 方法级业务规则
   - `ImCallTimeoutJob` 任务扫描策略
   - 离线推送 payload 草案
   - `CALL_RECORD` 聊天气泡与预览文案映射

##### Z. `CallSignalService` 方法级业务规则冻结

说明：

1. `CallSignalService` 负责通话控制面，不负责聊天消息通用存储
2. 权威状态推进只允许在该 Service 内发生
3. 所有方法都必须带 `tenantId`、`operatorUserId`、必要时带 `deviceId`
4. 所有写操作都必须具备幂等与状态前置校验

###### Z.1 `handleCall`

建议签名：

```java
CallCreateResult handleCall(CallCreateCommand command);
```

入参核心字段：

- `tenantId`
- `callerId`
- `calleeId`
- `callType`
- `deviceId`
- `clientMessageId`
- `chatId`

前置校验：

1. `callerId != calleeId`
2. `callType` 仅允许 `1=voice`、`2=video`
3. 当前租户是否开启 `rtcEnabled`
4. 当前用户是否属于 `chatId` 对应单聊
5. 主叫/被叫当前不存在冲突中的活跃通话

状态推进：

1. 新建 `im_call_record`
2. 初始 `state=INIT`
3. 完成 fanout 准备后推进到 `RINGING`

幂等要求：

1. 同一 `clientMessageId + callerId + tenantId` 重试，必须返回同一 `callId`
2. 不允许重复创建多条 `RINGING` 记录

结果模型建议：

- `SUCCESS`
- `BUSY_SELF`
- `BUSY_PEER`
- `RTC_DISABLED`
- `CHAT_NOT_FOUND`
- `FORBIDDEN`

###### Z.2 `handleAnswer`

建议签名：

```java
CallAnswerResult handleAnswer(CallAnswerCommand command);
```

入参核心字段：

- `tenantId`
- `callId`
- `operatorUserId`
- `deviceId`
- `clientMessageId`

前置校验：

1. 当前记录存在且属于当前租户
2. `operatorUserId == calleeId`
3. 当前 `state == RINGING`
4. 当前 `acceptedDeviceId` 为空

状态推进：

1. 使用 CAS：`where call_id=? and state='RINGING' and accepted_device_id is null`
2. 成功则写入 `accepted_device_id`
3. 推进 `state=CONNECTING`

多端裁决：

1. 只有一个设备允许成功 `ACCEPTED`
2. 同账号其它未接听设备全部收到 `HANGUP(4)` 或 `BUSY(5)`
3. 若同一设备因重试再次提交，按幂等返回 `ACCEPTED_DUPLICATE`

结果模型建议：

- `ACCEPTED`
- `ACCEPTED_DUPLICATE`
- `BUSY_OTHER_DEVICE_ACCEPTED`
- `NOT_FOUND`
- `ENDED`
- `FORBIDDEN`

###### Z.3 `handleReject`

建议签名：

```java
CallEndResult handleReject(CallRejectCommand command);
```

前置校验：

1. 当前用户必须是 `calleeId`
2. 只允许在 `RINGING` 阶段拒绝

状态推进：

1. 推进 `state=ENDED`
2. `status=REJECTED`
3. `endReason=CALLEE_REJECTED`
4. 回填 `endTime/duration=0`

幂等要求：

1. 若该通话已经 `ENDED` 且结束原因为拒绝，重复提交返回 `ALREADY_ENDED`
2. 若已被其它设备接听，则返回 `BUSY_OTHER_DEVICE_ACCEPTED`

###### Z.4 `handleHangup`

建议签名：

```java
CallEndResult handleHangup(CallHangupCommand command);
```

前置校验：

1. 当前用户必须是 `callerId` 或 `calleeId`
2. 允许的源状态：
   - `RINGING`
   - `CONNECTING`
   - `CONNECTED`

状态推进规则：

1. `caller` 在 `RINGING` 阶段取消：`status=CANCELLED`
2. `callee` 在 `CONNECTING/CONNECTED` 结束：`status=ANSWERED`
3. 任一方在 `CONNECTED` 结束：按时长回填 `duration`
4. 统一推进到 `ENDED`

幂等要求：

1. 同一 `callId` 多次挂断只允许第一次真正落最终态
2. 后续请求返回已结束快照，不重复生成 `CALL_RECORD`

###### Z.5 `handleTimeout`

建议签名：

```java
CallEndResult handleTimeout(CallTimeoutCommand command);
```

来源：

1. 仅允许 `ImCallTimeoutJob`
2. 不允许端侧直接触发

超时判定：

1. `RINGING` 超时：
   - `status=MISSED`
   - `endReason=NO_ANSWER_TIMEOUT`
2. `CONNECTING` 超时：
   - `status=CANCELLED`
   - `endReason=RTC_CONNECT_TIMEOUT`

幂等要求：

1. 同一 `callId + timeoutStage` 只能结算一次
2. 若调用时记录已结束，直接返回 `ALREADY_ENDED`

###### Z.6 `queryState`

建议签名：

```java
CallStateSnapshot queryState(Long tenantId, String callId, Long operatorUserId);
```

用途：

1. `STATE_SYNC`
2. `GET /system/im/call/detail`
3. 离线推送点击后的恢复校验

返回字段最低要求：

- `callId`
- `state`
- `status`
- `endReason`
- `callType`
- `callerId`
- `calleeId`
- `acceptedDeviceId`
- `chatId`
- `startTime`
- `endTime`

###### Z.7 `markConnected`

建议签名：

```java
CallConnectResult markConnected(CallConnectCommand command);
```

前置校验：

1. 当前用户必须是 `callerId` 或 `calleeId`
2. 当前状态必须为 `CONNECTING`
3. 若是被叫侧上报，`deviceId` 必须等于 `acceptedDeviceId`

推进规则：

1. 双端任一端首次上报可先记事件
2. 当服务端确认会话已进入有效媒体阶段后，统一推进到 `CONNECTED`
3. 同时记录 `connectedAt`

结果模型建议：

- `CONNECTED`
- `ALREADY_CONNECTED`
- `WAITING_PEER`
- `FORBIDDEN`
- `ENDED`

##### AA. `ImCallTimeoutJob` 任务扫描策略

建议位置：

- `.../job/im/ImCallTimeoutJob.java`

职责冻结：

1. 统一处理 `RINGING` 与 `CONNECTING` 超时
2. 不负责 fanout 之外的业务分发判断
3. 真正结束逻辑统一委托 `CallSignalService.handleTimeout()`

执行策略：

1. 调度周期：建议每 `5s` 扫描一次
2. 分布式锁：`redisson lock key = im:call:timeout:job`
3. 单次扫描窗口：
   - `state=RINGING` 且 `start_time <= now - ringingTimeoutSeconds`
   - `state=CONNECTING` 且 `accept_time <= now - connectingTimeoutSeconds`
4. 分页批量处理，避免单次全表扫描

查询建议：

```sql
where deleted = 0
  and tenant_id = ?
  and state in ('RINGING', 'CONNECTING')
  and id > ?
order by id asc
limit 200
```

补充要求：

1. Mapper 必须提供“按状态 + 时间阈值 + 游标分页”查询
2. 每条记录处理前再次校验最新状态，避免脏读误结束
3. 任务失败不阻断后续记录，但必须落 error log

监控指标建议：

- `im_call_timeout_scan_count`
- `im_call_timeout_end_count`
- `im_call_timeout_skip_count`
- `im_call_timeout_error_count`
- `im_call_timeout_scan_cost_ms`

日志字段最低要求：

- `tenantId`
- `callId`
- `stateBefore`
- `timeoutStage`
- `jobTraceId`
- `resultCode`

##### AB. 通话离线推送 payload 与设备注册草案

设计定位：

1. 离线推送只负责“唤醒并引导恢复”
2. 最终是否展示来电页，必须再以 `GET /system/im/call/detail` 为准
3. 推送供应商可替换，但服务端 payload 语义要统一

建议接口补充：

| 模块 | 路径 | 方法 | 状态 | 说明 |
|---|---|---|---|---|
| Push 设备注册 | `/system/im/push/register-cid` | `POST` | `proposed_required` | 上报 clientId / token / platform / deviceId |
| Push 设备解绑 | `/system/im/push/unregister-cid` | `POST` | `proposed_required` | 登出或 token 失效解绑 |

`register-cid` ReqVO 建议字段：

- `deviceId`
- `platform`
- `vendor`
- `clientId`
- `pushToken`
- `brand`
- `model`
- `appVersion`

推送 payload 最小字段集合：

```json
{
  "bizType": "IM_CALL_INCOMING",
  "tenantId": "100",
  "callId": "c_9f4d6d2a",
  "callType": 2,
  "callerId": "10001",
  "calleeId": "10002",
  "chatId": "90001",
  "entryModeSuggested": "incoming",
  "ts": 1770000000000
}
```

服务端编排要求：

1. 仅当被叫无在线 session 时触发离线推送
2. 仅对当前登录用户绑定且未失效的 push 设备下发
3. 推送成功只代表“已提交厂商”，不代表用户必然收到
4. 推送后不改写通话状态，仍保持 `RINGING`

端侧恢复约束：

1. App 被点击唤醒后先鉴权恢复
2. 然后调用 `GET /system/im/call/detail?callId=...`
3. 仅当返回仍是活跃态：
   - `RINGING`
   - 或 `CONNECTING`
   才展示来电页/恢复页
4. 若返回 `ENDED`，直接落回会话或忽略

##### AC. `CALL_RECORD` 聊天气泡与会话预览映射

冻结原则：

1. 只有服务端生成的 `CALL_RECORD=209` 进入消息链路
2. 聊天气泡文案由 `status + endReason + callerId/currentUserId` 共同决定
3. 页面逻辑不得再以中文标签反推状态

建议 `status` 语义：

| status | 说明 |
|---|---|
| `MISSED` | 未接听 |
| `ANSWERED` | 已接通并结束 |
| `REJECTED` | 被拒绝 |
| `BUSY` | 忙线 |
| `CANCELLED` | 主叫取消或连接中失败 |

建议会话预览映射：

| status | 预览文案 |
|---|---|
| `MISSED` | `[未接来电]` |
| `ANSWERED` | `[语音通话]` / `[视频通话]` |
| `REJECTED` | `[通话已拒绝]` |
| `BUSY` | `[对方忙线]` |
| `CANCELLED` | `[已取消通话]` |

聊天气泡文案映射建议：

| 视角 | status | 建议文案 |
|---|---|---|
| 主叫 | `MISSED` | `对方未接听` |
| 被叫 | `MISSED` | `未接来电` |
| 主叫 | `ANSWERED` | `语音通话 ${durationText}` / `视频通话 ${durationText}` |
| 被叫 | `ANSWERED` | `语音通话 ${durationText}` / `视频通话 ${durationText}` |
| 主叫 | `REJECTED` | `对方已拒绝` |
| 被叫 | `REJECTED` | `已拒绝通话` |
| 主叫 | `BUSY` | `对方忙线` |
| 被叫 | `BUSY` | `当前设备未接听` |
| 主叫 | `CANCELLED` | `已取消通话` |
| 被叫 | `CANCELLED` | `通话已结束` |

补充约束：

1. `durationText` 应由 `duration` 真实秒数格式化，不允许端侧自行猜测
2. 会话预览优先按消息体 `callType/status/endReason` 渲染
3. `MessageStorageService.buildConversationPreview()` 必须新增 `CALL_RECORD` 分支
4. Flutter `message renderer` 与后端 preview 口径必须保持一致

##### AD. 当前这一轮补强后的结论

1. 通话专题当前已经补齐到“可指导后端控制面设计”的文档深度
2. 当前统一文档中已明确：
   - 控制面 Service 方法规则
   - 超时任务扫描与分布式锁策略
   - 离线推送载荷与恢复链路
   - `CALL_RECORD` 聊天气泡与预览口径
3. 后续若继续推进通话专题，下一步应优先补：
   - `AppImCallController` ReqVO/RespVO 示例 JSON
   - `im_call_event` 查询索引与归档策略
   - Janus / TURN 凭证下发的安全边界
   - 多租户灰度开关与监控告警字段

##### AE. `AppImCallController` ReqVO/RespVO 示例 JSON

说明：

1. 以下示例用于冻结字段语义与端侧消费方式
2. 最终实现时允许补充非核心字段，但不应改动核心字段含义
3. 所有 `Long` 类型对 App 侧统一按字符串输出处理

###### AE.1 `GET /system/im/call/records`

ReqVO 示例：

```json
{
  "pageNo": 1,
  "pageSize": 20,
  "callType": 2,
  "status": "ANSWERED"
}
```

RespVO 示例：

```json
{
  "total": 2,
  "list": [
    {
      "callId": "c_202605020001",
      "chatId": "90001",
      "callType": 2,
      "status": "ANSWERED",
      "endReason": "NORMAL_HANGUP",
      "callerId": "10001",
      "calleeId": "10002",
      "duration": 186,
      "startTime": 1770000000000,
      "endTime": 1770000186000,
      "recordMessageId": "88001001"
    }
  ]
}
```

页面消费要点：

1. 通话记录列表页按 `status/callType/duration/startTime`
2. 点击记录可跳转聊天页或详情页，使用 `chatId/callId`

###### AE.2 `GET /system/im/call/records-between`

ReqVO 示例：

```json
{
  "targetUserId": "10002",
  "pageNo": 1,
  "pageSize": 20
}
```

RespVO 示例沿用 `AppImCallRecordRespVO`，不再重复定义。

页面消费要点：

1. 个人资料页、单聊设置页可按 `targetUserId` 拉双方历史通话
2. 逻辑依据必须是 `targetUserId`，不能靠昵称或展示名推断

###### AE.3 `GET /system/im/call/detail`

RespVO 示例：

```json
{
  "callId": "c_202605020001",
  "chatId": "90001",
  "callType": 2,
  "state": "CONNECTING",
  "status": "ANSWERED",
  "endReason": null,
  "callerId": "10001",
  "calleeId": "10002",
  "acceptedDeviceId": "ios_abc123",
  "caller": true,
  "callee": false,
  "startTime": 1770000000000,
  "connectedAt": null,
  "endTime": null
}
```

页面消费要点：

1. Flutter 依据 `state` 决定进入：
   - `RINGING` -> `/call/incoming` 或 `/call/outgoing`
   - `CONNECTING/CONNECTED` -> `/call/session`
   - `ENDED` -> 不再恢复来电 UI
2. 被叫侧需校验 `acceptedDeviceId` 是否等于当前设备，避免非接听设备错误恢复

###### AE.4 `GET /system/im/call/turn-config`

RespVO 示例：

```json
{
  "rtcEnabled": true,
  "signalOnlyMode": false,
  "ringingTimeoutSeconds": 30,
  "connectingTimeoutSeconds": 60,
  "stunServers": [
    "stun:stun.l.google.com:19302"
  ],
  "turnServers": [
    {
      "url": "turn:turn.example.com:3478?transport=udp",
      "username": "1746163200:user_10001",
      "credential": "hmac-signature",
      "credentialType": "password"
    }
  ],
  "janusWsUrl": "wss://janus.example.com/ws",
  "janusHttpUrl": "https://janus.example.com/janus"
}
```

页面消费要点：

1. Flutter `RtcGatewayClient` 直接消费 `stunServers/turnServers`
2. 页面不可自行拼接 TURN 用户名或密码

###### AE.5 `GET /system/im/call/rtc-credential`

RespVO 示例：

```json
{
  "callId": "c_202605020001",
  "rtcRoomId": "room_c_202605020001",
  "publisherToken": "janus_pub_token_xxx",
  "subscriberToken": "janus_sub_token_xxx",
  "janusWsUrl": "wss://janus.example.com/ws",
  "janusHttpUrl": "https://janus.example.com/janus",
  "stunServers": [
    "stun:stun.l.google.com:19302"
  ],
  "turnServers": [
    {
      "url": "turn:turn.example.com:3478?transport=udp",
      "username": "1746163200:user_10001",
      "credential": "hmac-signature",
      "credentialType": "password"
    }
  ],
  "acceptedDeviceId": "ios_abc123",
  "expireAt": 1770000300000,
  "caller": true,
  "callee": false
}
```

页面消费要点：

1. 仅当前活跃设备允许申请并消费 RTC 凭证
2. 端侧只缓存到本次会话结束，不写长期本地存储
3. `expireAt` 到期前可做刷新，但刷新仍必须走服务端接口

###### AE.6 `GET /system/im/call/active`

RespVO 示例：

```json
{
  "hasActiveCall": true,
  "callId": "c_202605020001",
  "callType": 2,
  "state": "RINGING",
  "chatId": "90001",
  "acceptedDeviceId": null,
  "entryModeSuggested": "incoming",
  "callerId": "10001",
  "calleeId": "10002"
}
```

页面消费要点：

1. App 冷启动、前后台切换、重连后可先查 `active`
2. 若 `hasActiveCall=false`，则不强行恢复通话页

##### AF. `im_call_event` 查询索引与归档策略

设计定位：

1. `im_call_event` 是 call 维度的信令流程记录
2. 用于问题排查、重连恢复分析、状态回放，不进入聊天消息主链路，也不扩成独立审计功能
3. Phase 1 可先建表 + 写关键事件；Phase 2 再补完整查询与运维工具

建议索引：

```sql
KEY `idx_call_id_created_time` (`call_id`, `created_time`),
KEY `idx_tenant_call_id` (`tenant_id`, `call_id`),
KEY `idx_user_id_created_time` (`user_id`, `created_time`),
KEY `idx_signal_type_created_time` (`signal_type`, `created_time`),
UNIQUE KEY `uk_event_id` (`event_id`)
```

推荐查询场景：

1. 按 `callId` 回放整条信令时序
2. 按 `userId + createdTime` 查指定用户近期开通话异常
3. 按 `signalType` 统计超时、拒绝、挂断、连接中断分布

建议字段补充：

- `device_id`
- `session_id`
- `trace_id`
- `result_code`
- `result_message`
- `server_ip`

归档策略：

1. 在线表默认保留近 `90` 天
2. 超过 `90` 天按月归档到 `im_call_event_archive_yyyyMM`
3. 归档后在线表只保留问题排查高频窗口
4. 归档任务按 `created_time` 分批迁移，不做大事务整表搬迁

运维要求：

1. 归档前先校验目标分表存在
2. 归档与删除分两步执行，避免误删
3. 归档任务必须记录：
   - `batchNo`
   - `fromTable`
   - `toTable`
   - `migrateCount`
   - `deleteCount`
   - `costMs`

##### AG. Janus / TURN 凭证下发安全边界

冻结原则：

1. Flutter 端永远不内置长期 Janus/TURN 静态密钥
2. 所有 RTC 凭证必须由服务端按 `callId + userId + deviceId` 动态签发
3. 凭证有效期必须短，且只对本次活跃通话有效

服务端鉴权要求：

1. `GET /system/im/call/rtc-credential` 调用前必须校验：
   - 当前用户属于该 `callId`
   - 当前 `callId.state in (CONNECTING, CONNECTED, RINGING)`
   - 若存在 `acceptedDeviceId`，被叫侧仅允许该设备获取
2. `GET /system/im/call/turn-config` 可返回公共 ICE 基础配置，但动态 TURN 用户名/凭证建议仍按用户实时签发

推荐凭证策略：

1. TURN 凭证：
   - 使用短期 `username + HMAC credential`
   - `expireAt` 建议 `5~10` 分钟
2. Janus 凭证：
   - 与 `callId/deviceId/userId` 绑定
   - 只授予当前房间的 publish/subscribe 能力
   - 不得复用后台管理口令或全局管理员 token

设备级约束：

1. 同一 `callId` 被叫多端场景下，只允许 `acceptedDeviceId` 拿到可用媒体凭证
2. 其它设备即便拿到 `call/detail`，也只能恢复展示状态，不能进入媒体连接

失效与刷新：

1. 通话结束后服务端应视为凭证立即失效
2. 若端侧因网络波动需要续期，必须重新请求 `rtc-credential`
3. 若 `callId` 已结束或设备已失去接听资格，续期接口必须拒绝

日志与运行监控要求：

1. 每次签发 RTC/TURN 凭证都必须记录：
   - `tenantId`
   - `callId`
   - `userId`
   - `deviceId`
   - `credentialType`
   - `expireAt`
2. 不记录明文 token/credential 到业务日志
3. 如需排查，只记录摘要或掩码值

##### AH. 当前这一轮继续后的结论

1. 通话专题的 REST 查询面、流程记录、RTC 凭证边界已继续补强
2. 统一文档当前已覆盖：
   - WS 控制面
   - REST 查询面
   - 推送恢复面
   - `CALL_RECORD` 消息面
   - `im_call_event` 流程记录面
   - Janus / TURN 凭证安全边界
3. 下一步再继续通话专题时，优先补：
   - 多租户灰度开关与告警指标
   - 推送设备表建议与清理策略
   - Flutter 通话页与这些接口字段的最终消费对照

##### AI. 多租户灰度开关与降级策略

设计目标：

1. 通话能力必须支持按租户、用户、设备类型逐步放量
2. 灰度关闭时，入口、接口、信令、媒体层都要有一致降级行为
3. 灰度策略必须可追踪，避免“客户端可见但服务端拒绝”长期失配

建议配置层级：

1. 全局总开关：`im.rtc.enabled`
2. 租户级开关：`im.rtc.tenants.allowlist`
3. 用户级灰度：`im.rtc.users.allowlist`
4. 设备类型灰度：`im.rtc.device-types.allowlist`
5. 信令联调模式：`im.rtc.signal-only-mode`

推荐判定顺序：

1. 先判全局总开关
2. 再判租户是否允许
3. 再判用户是否命中灰度名单
4. 最后判设备类型是否允许

服务端行为冻结：

1. 若总开关关闭：
   - `CALL_SIGNAL` Processor 直接返回 `RTC_DISABLED`
   - `/turn-config` 返回 `rtcEnabled=false`
   - `/rtc-credential` 直接拒绝
2. 若租户未开通：
   - 仅该租户被拒绝
   - 其它租户不受影响
3. 若用户或设备类型未命中灰度：
   - 页面不展示入口
   - 即便客户端误发起，也由服务端再次拒绝
4. 若 `signal-only-mode=true`：
   - 允许走控制面
   - 不下发真实 Janus/TURN 凭证
   - `/rtc-credential` 返回 `signalOnlyMode=true` 与空媒体凭证

建议返回字段补充：

在 `GET /system/im/call/turn-config` 中增加：

- `tenantRtcEnabled`
- `deviceTypeAllowed`
- `userRtcEnabled`
- `degradeReason`

降级文案来源规则：

1. Flutter 页面只消费服务端 `rtcEnabled/degradeReason`
2. 不自行写死“该租户未开通”“当前设备不支持”等判断文案

##### AJ. 监控指标与告警字段建议

设计目标：

1. 指标必须能按 `tenantId/userId/callId` 定位问题
2. 告警要覆盖“发起失败、接通失败、超时异常、推送异常、凭证异常”
3. 监控口径要与状态机口径一致

核心指标建议：

- `im_call_initiate_total`
- `im_call_answer_total`
- `im_call_connect_total`
- `im_call_end_total`
- `im_call_busy_total`
- `im_call_reject_total`
- `im_call_timeout_total`
- `im_call_ringing_duration_ms`
- `im_call_connecting_duration_ms`
- `im_call_connected_duration_ms`
- `im_call_push_attempt_total`
- `im_call_push_success_total`
- `im_call_push_skip_total`
- `im_call_rtc_credential_issue_total`
- `im_call_rtc_credential_reject_total`

推荐维度：

- `tenantId`
- `callType`
- `state`
- `endReason`
- `platform`
- `deviceType`
- `signalOnlyMode`

关键告警建议：

1. 发起异常率告警：
   - `im_call_initiate_total` 中失败占比异常升高
2. 接通率告警：
   - `connect_total / initiate_total` 连续低于阈值
3. 超时率告警：
   - `timeout_total / initiate_total` 连续高于阈值
4. 推送异常告警：
   - `push_attempt_total - push_success_total` 持续扩大
5. 凭证签发异常告警：
   - `rtc_credential_reject_total` 突增

日志最小字段集合：

- `tenantId`
- `callId`
- `userId`
- `calleeId`
- `deviceId`
- `signalType`
- `stateBefore`
- `stateAfter`
- `resultCode`
- `latencyMs`
- `traceId`

##### AK. 推送设备表建议与清理策略

建议表名：

- `im_push_device`

建议核心字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `bigint` | 主键 |
| `tenant_id` | `bigint` | 租户 |
| `user_id` | `bigint` | 用户 |
| `device_id` | `varchar(64)` | 设备唯一标识 |
| `platform` | `tinyint` | `1=iOS 2=Android 3=OHOS` |
| `vendor` | `varchar(32)` | 推送供应商 |
| `client_id` | `varchar(128)` | 厂商 clientId |
| `push_token` | `varchar(256)` | 厂商 token |
| `brand` | `varchar(64)` | 品牌 |
| `model` | `varchar(64)` | 型号 |
| `app_version` | `varchar(32)` | App 版本 |
| `last_active_time` | `datetime` | 最近活跃时间 |
| `status` | `tinyint` | `1=active 2=invalid 3=logout` |

建议索引：

```sql
UNIQUE KEY `uk_user_device_tenant` (`user_id`, `device_id`, `tenant_id`),
KEY `idx_user_tenant_status` (`user_id`, `tenant_id`, `status`),
KEY `idx_client_id` (`client_id`),
KEY `idx_last_active_time` (`last_active_time`)
```

写入规则：

1. `register-cid` 以 `user_id + device_id + tenant_id` 幂等 upsert
2. token/clientId 变化时覆盖更新
3. 登录成功后上报一次，token 刷新后再次上报

清理策略：

1. 登出时调用 `unregister-cid`，状态改为 `logout`
2. 厂商返回“token 无效”时，状态改为 `invalid`
3. 超过 `90` 天未活跃设备可转 `invalid`
4. 超过 `180` 天未活跃且 `invalid/logout` 的记录可物理归档或清理

发送前筛选规则：

1. 仅发送给 `status=active`
2. 仅发送给当前租户下属于该用户的设备
3. 同一设备若存在多条异常重复记录，以最近更新时间最新的一条为准

##### AL. Flutter 通话页字段消费最终对照

###### AL.1 `CallLaunchArgs` 与接口字段最终对照

| Flutter 字段 | 来源接口/事件 | 后端字段 | 说明 |
|---|---|---|---|
| `callSessionId` | `call.detail` / `call.active` / `CALL_SIGNAL` | `callId` | 通话主键 |
| `entryMode` | `call.active` / 本地恢复决策 | `entryModeSuggested` + `state` | `incoming/outgoing/restore/session` |
| `callType` | `call.detail` / `call.active` / `CALL_SIGNAL` | `callType` | `1=语音 2=视频` |
| `fromChatId` | `call.detail` / `call.active` | `chatId` | 回跳会话 |

###### AL.2 页面与接口关系

| 页面 | 主接口/事件 | 关键字段 | 页面决策 |
|---|---|---|---|
| `/call/incoming` | `CALL_SIGNAL(CALL)`、`GET /call/detail` | `callId/callType/state/callerId/acceptedDeviceId` | 来电展示、接听/拒绝 |
| `/call/outgoing` | `CALL_SIGNAL(CALL)` 回显、`GET /call/detail` | `callId/state/calleeId` | 拨出等待、取消 |
| `/call/session` | `GET /call/detail`、`GET /call/rtc-credential` | `state/acceptedDeviceId/rtcRoomId/publisherToken` | 建立媒体连接、展示会中状态 |

###### AL.3 Flutter 路由恢复规则

1. App 冷启动先查 `GET /system/im/call/active`
2. 若 `hasActiveCall=false`，不恢复通话页
3. 若 `entryModeSuggested=incoming`：
   - 进入 `/call/incoming`
4. 若 `entryModeSuggested=outgoing`：
   - 进入 `/call/outgoing`
5. 若 `state in (CONNECTING, CONNECTED)`：
   - 进入 `/call/session`

###### AL.4 Flutter 页面禁止自行推断的内容

1. 不以中文文案判断状态
2. 不以本地缓存判断“我是否接听成功”
3. 不本地生成 TURN 用户名、credential、Janus token
4. 不绕过 `acceptedDeviceId` 规则直接建媒体连接

##### AM. 当前这一轮继续后的结论

1. 通话专题治理层与 Flutter 消费层对照已经补齐
2. 当前统一文档中的通话专题已覆盖：
   - 状态机
   - 控制面 Service
   - Processor 分发
   - REST 查询面
   - 离线推送
   - `CALL_RECORD`
   - `im_call_event`
   - RTC 凭证边界
   - 灰度与监控
   - Push 设备表
   - Flutter 页面消费对照
3. 下一步若继续深推通话专题，优先补：
   - `CALL_SIGNAL` / `CALL_RECORD` 错误码与异常码表
   - Janus 房间生命周期与回收策略
   - 通话结束后会话列表、聊天页、通话记录页三端刷新时序

##### AN. `CALL_SIGNAL` / `CALL_RECORD` 错误码与异常码表

设计目标：

1. REST、WS、Flutter 页面结束态必须使用同一组错误语义
2. 瞬态信令错误与记录查询错误分层管理
3. 端侧不根据中文错误文案做逻辑判断，只根据错误码与状态字段判断

###### AN.1 已确认基础错误码

沿用并冻结以下后端错误码：

| 常量 | 错误码 | 说明 |
|---|---:|---|
| `CALL_RECORD_NOT_EXISTS` | `1002030500` | 通话记录不存在 |
| `CALL_PERMISSION_DENIED` | `1002030501` | 无权操作该通话 |
| `CALL_ALREADY_IN_PROGRESS` | `1002030502` | 对方正在通话中 |
| `CALL_STATE_INVALID` | `1002030503` | 当前通话状态不允许此操作 |
| `CALL_FEATURE_DISABLED` | `1002030504` | 音视频通话功能未启用 |
| `CALL_CALLEE_OFFLINE` | `1002030505` | 被叫方不在线 |

###### AN.2 建议补充错误码

| 常量 | 建议错误码 | 说明 |
|---|---:|---|
| `CALL_ACCEPT_DEVICE_CONFLICT` | `1002030506` | 其它设备已接听 |
| `CALL_RTC_CREDENTIAL_DENIED` | `1002030507` | 无权获取 RTC 凭证 |
| `CALL_RTC_CREDENTIAL_EXPIRED` | `1002030508` | RTC 凭证已过期 |
| `CALL_PUSH_DEVICE_INVALID` | `1002030509` | 推送设备无效 |
| `CALL_SIGNAL_UNSUPPORTED` | `1002030510` | 不支持的通话信令 |
| `CALL_ROOM_NOT_FOUND` | `1002030511` | 通话房间不存在或已回收 |

###### AN.3 WS 信令异常语义

| 场景 | 推荐返回 | Flutter 处理 |
|---|---|---|
| 功能关闭 | `CALL_FEATURE_DISABLED` | 结束页提示，不进入媒体页 |
| 对方忙线 | `CALL_ALREADY_IN_PROGRESS` 或 `BUSY` | 主叫页直接结束 |
| 通话已结束 | `CALL_STATE_INVALID` 或 `TIMEOUT` | 当前页结束并停止重试 |
| 其它设备已接听 | `CALL_ACCEPT_DEVICE_CONFLICT` 或 `BUSY` | 当前设备退出来电页 |
| 设备无权拿凭证 | `CALL_RTC_CREDENTIAL_DENIED` | 不建连，回结束态 |

###### AN.4 `CALL_RECORD` 查询异常语义

| 场景 | 推荐错误码 | 页面处理 |
|---|---|---|
| `callId` 不存在 | `CALL_RECORD_NOT_EXISTS` | 通话记录页空态或 toast |
| 当前用户无权查看 | `CALL_PERMISSION_DENIED` | 拦截跳转 |
| 记录消息已删但记录仍在 | `CALL_RECORD_NOT_EXISTS` | 回退记录详情 |

###### AN.5 Flutter 使用规则

1. REST 失败优先用错误码决定分支
2. WS 异常优先用 `signalType + code + state` 决定分支
3. 中文错误文案只做展示，不做业务判断

##### AO. Janus 房间生命周期与回收策略

设计目标：

1. 房间生命周期必须绑定 `callId`
2. 房间创建、使用、回收必须与通话状态机一致
3. 不能出现“通话结束但房间长期泄漏”或“房间提前回收导致仍在通话中断”的情况

推荐房间标识：

1. `rtcRoomId` 默认可由 `callId` 映射生成
2. Janus 内部房间号可单独维护，但对 Flutter 暴露的逻辑主键仍建议是 `callId/rtcRoomId`

生命周期阶段：

1. `PREPARED`
   - `handleAnswer` 成功后或首个 `rtc-credential` 申请时创建
2. `ACTIVE`
   - 至少一端已成功 attach / publish / subscribe
3. `IDLE_WAIT_RECYCLE`
   - 通话已结束，等待短暂回收窗口
4. `RECYCLED`
   - 房间已销毁，不再允许申请凭证

创建策略：

1. 不建议在 `CALL` 发起瞬间就创建 Janus 房间
2. 建议在：
   - `CONNECTING` 阶段首次申请 `rtc-credential`
   - 或被叫成功接听后
   再创建房间

回收策略：

1. 通话进入 `ENDED` 后立即标记 `IDLE_WAIT_RECYCLE`
2. 建议保留 `30~60s` 回收窗口，用于：
   - 双端结束确认
   - 断线日志补采
   - 极短时间内的状态恢复判断
3. 超过窗口后由 `RtcRoomRecycleJob` 回收并标记 `RECYCLED`

异常回收：

1. 若 Janus 已无 publisher/subscriber 且通话状态已结束，可提前回收
2. 若通话状态仍为 `CONNECTED`，不得仅因单端短暂掉线就销毁房间
3. 若服务端重启，恢复任务需按 `callId.state` 与 `expireAt` 补建或判定失效

日志字段建议：

- `callId`
- `rtcRoomId`
- `roomStateBefore`
- `roomStateAfter`
- `janusHandleId`
- `recycleReason`
- `tenantId`

##### AP. 通话结束后三端刷新时序

三端定义：

1. 会话列表
2. 聊天页消息列表
3. 通话记录页

目标：

1. 三端都以服务端生成的最终 `CALL_RECORD` 为准
2. 先落记录、再投递消息、再刷新会话预览
3. 不允许三端各自猜测最终态

###### AP.1 服务端结束链路顺序

1. `CallSignalService` 推进 `im_call_record.state=ENDED`
2. 回填：
   - `status`
   - `endReason`
   - `duration`
   - `endTime`
3. `CallRecordMessageFactory` 生成 `CALL_RECORD=209`
4. `MessageStorageService` 落消息、分配 `sequence/messageId`
5. 回填 `record_message_id`
6. 更新会话最近消息预览与排序
7. fanout：
   - 通话结束 `CALL_SIGNAL(HANGUP/REJECT/TIMEOUT)`
   - 新消息事件 / 会话更新事件

###### AP.2 Flutter 聊天页刷新规则

1. 若当前正停留在对应 `chatId` 聊天页：
   - 收到 `CALL_RECORD` 新消息后插入时间线
   - 若当前窗口包含尾部，直接追加
   - 若不在尾部，增加“有新消息”提示
2. 聊天页不根据本地结束按钮自行造一条假记录

###### AP.3 Flutter 会话列表刷新规则

1. 会话列表收到会话更新事件后：
   - 更新最近消息预览
   - 更新最近时间
   - 更新排序
2. 预览文案统一用后端 `CALL_RECORD` 对应 preview 口径

###### AP.4 Flutter 通话记录页刷新规则

1. 通话记录页若当前打开：
   - 可在收到结束态后触发一次轻量 refresh
   - 或在收到 `CALL_RECORD` 后将该记录插入顶部
2. 最终列表仍以 `/system/im/call/records` 返回为准

###### AP.5 一致性原则

1. 聊天页、会话列表、通话记录页三处的 `status/endReason/duration` 必须同源
2. 不允许聊天页显示“未接来电”而记录页显示“已取消通话”
3. 若收到 WS 结束事件但尚未收到 `CALL_RECORD`，页面可先结束通话 UI，但消息列表和会话预览必须等最终记录消息

##### AQ. 当前这一轮继续后的结论

1. 通话专题当前已经补到异常语义、媒体房间生命周期、三端一致性刷新
2. 统一文档中的通话专题目前已具备较完整的后端实施约束与 Flutter 消费约束
3. 后续若继续深推通话专题，建议转向：
   - `CALL_SIGNAL` / `CALL_RECORD` protobuf 与 Java DTO 精细字段冻结
   - `RtcRoomRecycleJob` / `PushDeviceCleanupJob` 任务清单
   - 通话专题的多端异常场景矩阵

##### AR. `CALL_SIGNAL` / `CALL_RECORD` proto 与 Java DTO 精细字段冻结

冻结目标：

1. proto、Java DTO、Flutter 消费字段三层同义
2. 字段一旦进入统一文档冻结区，后续只允许补充，不允许随意改名改义
3. 所有跨端长整型主键统一按字符串口径消费

###### AR.1 `CallSignalMessage` proto 字段冻结

```protobuf
message CallSignalMessage {
  string callId = 1;
  int32 callType = 2;
  int32 signalType = 3;
  int64 callerId = 4;
  int64 calleeId = 5;
  string rejectReason = 6;
  string extraData = 7;
}
```

字段语义冻结：

| 字段 | 类型 | 语义 | 备注 |
|---|---|---|---|
| `callId` | `string` | 通话主键 | 与 `rtcRoomId` 逻辑关联 |
| `callType` | `int32` | `1=voice 2=video` | 不允许传中文 |
| `signalType` | `int32` | `1-11` 信令子类型 | 由服务端状态机解释 |
| `callerId` | `int64` | 主叫用户ID | 服务端可覆盖校验 |
| `calleeId` | `int64` | 被叫用户ID | 服务端可覆盖校验 |
| `rejectReason` | `string` | 拒绝原因码 | 不建议传展示文案 |
| `extraData` | `string` | JSON 扩展载荷 | SDP/ICE/STATE_SYNC 等 |

约束：

1. 不在 `CallSignalMessage` 中直接追加 `tenantId/deviceId`
2. `tenantId/deviceId` 一律来自 session 上下文
3. `extraData` 必须是可解析 JSON，不允许自由拼接字符串

###### AR.2 `CallRecordMessage` proto 字段冻结

```protobuf
message CallRecordMessage {
  string callId = 1;
  int32 callType = 2;
  int32 duration = 3;
  int32 status = 4;
  string endReason = 5;
  int64 callerId = 6;
  int64 calleeId = 7;
  int64 startTimestamp = 8;
  int64 endTimestamp = 9;
  int64 chatId = 10;
}
```

字段语义冻结：

| 字段 | 类型 | 语义 |
|---|---|---|
| `callId` | `string` | 通话主键 |
| `callType` | `int32` | 通话类型 |
| `duration` | `int32` | 通话秒数 |
| `status` | `int32` | 记录状态码，需与枚举对齐 |
| `endReason` | `string` | 细粒度结束原因 |
| `callerId/calleeId` | `int64` | 双方用户ID |
| `startTimestamp/endTimestamp` | `int64` | 时间戳毫秒 |
| `chatId` | `int64` | 所属会话ID |

###### AR.3 Java DTO 建议冻结清单

建议最小 DTO 集合：

- `CallCreateCommand`
- `CallAnswerCommand`
- `CallRejectCommand`
- `CallHangupCommand`
- `CallTimeoutCommand`
- `CallConnectCommand`
- `CallCreateResult`
- `CallAnswerResult`
- `ImCallEndResult`
- `CallStateSnapshot`
- `RtcCredentialBundle`

关键字段要求：

1. DTO 中凡是用户、会话、消息主键，Java 内部可用 `Long/String`，对外出参必须保持与 REST/Flutter 文档一致
2. `CallStateSnapshot` 必须至少包含：
   - `callId/state/status/endReason/callType`
   - `callerId/calleeId`
   - `acceptedDeviceId`
   - `chatId`
   - `startTime/connectedAt/endTime`
3. `RtcCredentialBundle` 必须至少包含：
   - `rtcRoomId`
   - `publisherToken/subscriberToken`
   - `expireAt`
   - `acceptedDeviceId`

##### AS. 通话专题 Job 清单

设计目标：

1. 定时任务只负责“补偿、回收、清理、巡检”
2. 不把核心状态裁决散落到多个 Job 中
3. 所有 Job 都必须具备分布式锁、日志和指标

建议 Job 清单：

| Job | 状态 | 职责 | 关键输入 |
|---|---|---|---|
| `ImCallTimeoutJob` | `proposed_required` | 处理 `RINGING/CONNECTING` 超时 | `im_call_record` |
| `RtcRoomRecycleJob` | `proposed_required` | 回收已结束通话的 Janus 房间 | `im_call_record` + RTC 房间映射 |
| `PushDeviceCleanupJob` | `proposed_required` | 清理失效或长期不活跃推送设备 | `im_push_device` |
| `CallEventArchiveJob` | `proposed_recommended` | 归档 `im_call_event` | `im_call_event` |
| `CallMetricsAuditJob` | `proposed_optional` | 日级汇总接通率/超时率/异常率 | 监控表或日志聚合 |

###### AS.1 `RtcRoomRecycleJob`

职责：

1. 扫描 `ENDED` 且超过回收窗口的通话
2. 调用 `RtcCredentialService/JanusFacade` 销毁房间
3. 更新房间状态为 `RECYCLED`

最低日志字段：

- `callId`
- `rtcRoomId`
- `tenantId`
- `recycleReason`
- `costMs`

###### AS.2 `PushDeviceCleanupJob`

职责：

1. 标记 `90` 天未活跃设备为 `invalid`
2. 清理 `180` 天以上 `invalid/logout` 设备
3. 对厂商返回的硬失效设备做二次校验与清理

最低日志字段：

- `tenantId`
- `deviceId`
- `userId`
- `statusBefore`
- `statusAfter`

###### AS.3 `CallEventArchiveJob`

职责：

1. 按月归档 `im_call_event`
2. 保证在线表仅保留高频排查窗口
3. 归档后删除原在线数据

前提：

1. 目标归档表已创建
2. 分批迁移，不做全表事务

##### AT. 多端异常场景矩阵

设计目标：

1. 把多端、多状态、弱网、重复提交场景系统化写清楚
2. 明确每个场景下服务端权威结果与 Flutter 页面结果
3. 后续实现时必须以矩阵为验收依据

| 场景 | 服务端权威行为 | Flutter 结果 |
|---|---|---|
| 被叫双端同时点接听 | CAS 只允许一个 `acceptedDeviceId` 成功 | 成功端进 `/call/session`，另一端收到 `BUSY/HANGUP` 退出 |
| 主叫重复点发起 | 按 `clientMessageId` 幂等返回同一 `callId` | 不重复创建两路拨出页 |
| 被叫离线后推送唤醒，但通话已结束 | `GET /call/detail` 返回 `ENDED` | 不展示来电页 |
| 主叫挂断后，被叫晚到 `ANSWER` | 返回 `CALL_STATE_INVALID` 或 `TIMEOUT` | 被叫端直接结束 |
| 会中一端短暂断网后重连 | `STATE_SYNC` 或 `GET /call/active` 返回活跃态 | 恢复 `/call/session`，不重建新通话 |
| 被叫非 `acceptedDeviceId` 设备尝试拉取凭证 | 返回 `CALL_RTC_CREDENTIAL_DENIED` | 不进入媒体连接 |
| 聊天页已打开，通话结束消息稍后到达 | 先有结束态，后有 `CALL_RECORD` | 通话 UI 先结束，聊天消息稍后插入 |
| 会话列表先收到结束信令、后收到记录消息 | 仅在 `CALL_RECORD` 到达后更新最终预览 | 预览不提前猜测 |
| Janus 房间已回收但客户端还在请求续期 | 返回 `CALL_ROOM_NOT_FOUND` 或 `CALL_STATE_INVALID` | 会中页结束并提示重试失败 |
| 推送设备 token 失效 | 标记 `im_push_device.status=invalid` | 不影响当前在线端，后续不再推送该设备 |

矩阵执行规则：

1. 服务端行为优先于端侧推断
2. 同场景若 REST 与 WS 结果冲突，以服务端最新 `state + status` 为准
3. 页面不得因为旧本地状态阻断新恢复逻辑

##### AU. 当前这一轮继续后的结论

1. 通话专题的协议字段、后台 Job、异常矩阵已经继续补齐
2. 当前统一文档中的通话专题，已基本具备从后端协议到 Flutter 消费的闭环约束
3. 后续若继续深推通话专题，更合适的方向是：
   - `extraData` JSON 子结构逐项冻结
   - Call 相关枚举全集与状态码全集
   - 通话专题和主消息链路的接口联调清单

##### AV. `extraData` JSON 子结构逐项冻结

冻结目标：

1. `extraData` 必须按 `signalType` 绑定固定 JSON 结构
2. 同一 `signalType` 不允许在不同端使用不同字段名
3. 端侧与服务端都必须先按 `signalType` 再解析 `extraData`

###### AV.1 `SDP_OFFER(7)` / `SDP_ANSWER(8)`

建议结构：

```json
{
  "sdp": "v=0\r\no=- 46117...",
  "type": "offer",
  "rtcRoomId": "room_c_202605020001",
  "deviceId": "ios_abc123"
}
```

字段说明：

- `sdp`：WebRTC SDP 原文
- `type`：`offer/answer`
- `rtcRoomId`：媒体房间标识
- `deviceId`：当前发送设备

###### AV.2 `ICE_CANDIDATE(9)`

建议结构：

```json
{
  "candidate": "candidate:842163049 1 udp ...",
  "sdpMid": "0",
  "sdpMLineIndex": 0,
  "rtcRoomId": "room_c_202605020001",
  "deviceId": "ios_abc123"
}
```

###### AV.3 `STATE_SYNC(10)`

建议结构：

```json
{
  "state": "RINGING",
  "status": "MISSED",
  "endReason": null,
  "callType": 1,
  "callerId": "10001",
  "calleeId": "10002",
  "chatId": "90001",
  "acceptedDeviceId": null,
  "startTime": 1770000000000,
  "connectedAt": null,
  "endTime": null
}
```

###### AV.4 `ANSWER(2)` connected 确认扩展

建议结构：

```json
{
  "connected": true,
  "rtcRoomId": "room_c_202605020001",
  "deviceId": "ios_abc123",
  "ts": 1770000060000
}
```

用途：

1. 端侧 ICE 连通后回传 connected 确认
2. 服务端据此推进 `CONNECTING -> CONNECTED`

###### AV.5 解析规则

1. `CALL/REJECT/HANGUP/BUSY/TIMEOUT` 默认允许空 `extraData`
2. `SDP/ICE/STATE_SYNC` 不允许空 `extraData`
3. `extraData` JSON 解析失败时：
   - 服务端记录 `CALL_SIGNAL_UNSUPPORTED` 或解析异常日志
   - 端侧不应崩溃，应终止本次媒体协商

##### AW. Call 相关枚举全集与状态码全集

###### AW.1 `ImCallTypeEnum`

| code | name | 说明 |
|---:|---|---|
| `1` | `VOICE` | 语音通话 |
| `2` | `VIDEO` | 视频通话 |

###### AW.2 `ImCallStateEnum`

| code | name | 说明 |
|---:|---|---|
| `0` | `INIT` | 已建记录，未响铃 |
| `1` | `RINGING` | 已进入响铃 |
| `2` | `CONNECTING` | 已接听，媒体协商中 |
| `3` | `CONNECTED` | 媒体已连通 |
| `4` | `ENDED` | 通话已结束 |

###### AW.3 `ImCallStatusEnum`

| code | name | 说明 |
|---:|---|---|
| `1` | `MISSED` | 未接听 |
| `2` | `ANSWERED` | 已接通并结束 |
| `3` | `REJECTED` | 已拒绝 |
| `4` | `BUSY` | 忙线 |
| `5` | `CANCELLED` | 已取消 |

###### AW.4 `ImCallEndReasonEnum`

| code | name | 说明 |
|---|---|---|
| `CALLEE_REJECTED` | `CALLEE_REJECTED` | 被叫拒绝 |
| `CALLER_CANCELLED` | `CALLER_CANCELLED` | 主叫取消 |
| `NO_ANSWER_TIMEOUT` | `NO_ANSWER_TIMEOUT` | 响铃超时 |
| `RTC_CONNECT_TIMEOUT` | `RTC_CONNECT_TIMEOUT` | 建连超时 |
| `NORMAL_HANGUP` | `NORMAL_HANGUP` | 正常挂断 |
| `CALLEE_OFFLINE` | `CALLEE_OFFLINE` | 被叫不在线 |
| `OTHER_DEVICE_ACCEPTED` | `OTHER_DEVICE_ACCEPTED` | 其它设备已接听 |
| `ROOM_RECYCLED` | `ROOM_RECYCLED` | 房间已回收 |

###### AW.5 `ImCallSignalTypeEnum`

| code | name | 说明 |
|---:|---|---|
| `1` | `CALL` | 发起呼叫 |
| `2` | `ANSWER` | 接听 |
| `3` | `REJECT` | 拒绝 |
| `4` | `HANGUP` | 挂断/取消/停止响铃 |
| `5` | `BUSY` | 忙线 |
| `6` | `SWITCH_CAMERA` | 切换摄像头 |
| `7` | `SDP_OFFER` | offer |
| `8` | `SDP_ANSWER` | answer |
| `9` | `ICE_CANDIDATE` | ICE candidate |
| `10` | `STATE_SYNC` | 状态恢复 |
| `11` | `TIMEOUT` | 超时结束 |

###### AW.6 端侧映射规则

1. Flutter 所有状态判断优先用枚举 code/name
2. 不将中文展示文案反向映射回枚举
3. `CALL_RECORD.status` 对应 `ImCallStatusEnum.code`
4. `CALL_RECORD.endReason` 对应 `ImCallEndReasonEnum.code`

##### AX. 通话专题和主消息链路的接口联调清单

设计目标：

1. 明确“通话控制面”与“主消息链路”交界点
2. 后续真正联调时按链路逐项打勾，不做散点式试错
3. 当前只补联调清单，不实际启动服务

联调主线分层：

1. REST 查询面
2. WS 控制面
3. 主消息存储链路
4. 会话预览刷新链路
5. Flutter 页面消费链路

###### AX.1 REST 查询面清单

- `GET /system/im/call/records`
- `GET /system/im/call/records-between`
- `GET /system/im/call/detail`
- `GET /system/im/call/turn-config`
- `GET /system/im/call/rtc-credential`
- `GET /system/im/call/active`
- `POST /system/im/push/register-cid`
- `POST /system/im/push/unregister-cid`

核对项：

1. 入参字段名与统一文档一致
2. 出参核心字段完整
3. 主键全部按字符串口径输出

###### AX.2 WS 控制面清单

- `CALL_SIGNAL(CALL)`
- `CALL_SIGNAL(ANSWER)`
- `CALL_SIGNAL(REJECT)`
- `CALL_SIGNAL(HANGUP)`
- `CALL_SIGNAL(BUSY)`
- `CALL_SIGNAL(SDP_OFFER/SDP_ANSWER/ICE_CANDIDATE)`
- `CALL_SIGNAL(STATE_SYNC)`
- `CALL_SIGNAL(TIMEOUT)`

核对项：

1. `signalType` 与枚举码一致
2. `extraData` 结构与统一文档冻结结构一致
3. `senderId/tenantId/timestamp` 由服务端覆盖

###### AX.3 主消息链路清单

- `CALL_RECORD=209` proto
- `MessageType.CALL_RECORD(209)` Java 枚举
- `CallRecordMessageFactory`
- `MessageStorageService` 落库
- 会话最近消息预览更新

核对项：

1. 只有结束后才生成 `CALL_RECORD`
2. `CALL_RECORD` 必须拿到 `sequence/messageId`
3. 聊天页与会话列表预览文案一致

###### AX.4 Flutter 页面消费清单

- `/call/incoming`
- `/call/outgoing`
- `/call/session`
- 聊天页 `CALL_RECORD` 气泡
- 会话列表 preview
- 通话记录页列表

核对项：

1. 路由恢复按 `call.active/call.detail`
2. 凭证拉取受 `acceptedDeviceId` 约束
3. 页面结束态、记录态、预览态保持同源

##### AY. 当前这一轮继续后的结论

1. 通话专题的 `extraData`、枚举全集、联调清单已经补齐
2. 当前统一文档中的通话专题，已经从控制面、查询面、消息面、治理面延伸到接口联调面
3. 后续若继续深推通话专题，更合理的方向是：
   - Flutter `features/im/call` 现有目录与这些文档字段逐文件对照
   - 其余页面模块的真实接口补录继续推进

##### AZ. Flutter `features/im/call` 目录逐文件对照结论

截至 `2026-05-02` 当前仓库实况，`shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/call` 已形成完整骨架，但与统一文档冻结协议仍存在一批确定偏差。

###### AZ.1 当前目录结构结论

当前已存在以下层次：

1. `presentation/pages`
   - `incoming_call_page.dart`
   - `outgoing_call_page.dart`
   - `call_session_page.dart`
2. `presentation/controllers`
   - `call_controller.dart`
   - `call_media_controller.dart`
   - `call_coordinator.dart`
   - `active_call_registry.dart`
3. `presentation/providers`
   - `call_providers.dart`
4. `domain/repositories`
   - `call_repository.dart`
5. `domain/entities`
   - `call_invite_result.dart`
   - `active_call_state_result.dart`
   - `call_socket_event.dart`
   - `call_participant_profile.dart`
   - `rtc_room_bundle.dart`
6. `infrastructure/datasources`
   - `call_remote_data_source.dart`
   - `call_socket_data_source.dart`
7. `infrastructure/repositories`
   - `call_repository_impl.dart`
   - `mock_call_repository.dart`
8. `infrastructure/dtos`
   - `call_session_dto.dart`
   - `call_signal_event_dto.dart`
9. `infrastructure/mappers`
   - `call_dto_mapper.dart`
   - `call_socket_payload_resolver.dart`

结论：

- 目录完整度已足以承接真实后端接线
- 当前阻塞不在目录缺失，而在“默认实现、字段口径、接口命名”仍停留旧方案

###### AZ.2 已确认的当前代码级偏差

1. `call_providers.dart`
   - `callRepositoryModeProvider` 默认仍返回 `CallRepositoryMode.mock`
   - 说明通话页面默认不会走真实后端
2. `mock_call_repository.dart`
   - 仍主动发本地 `accepted/cancelled/rejected/ended` 假事件
   - 说明当前链路默认仍为本地闭环
3. `call_remote_data_source.dart`
   - 当前 REST 命名仍是：
     - `POST /system/im/call/create-invite`
     - `POST /system/im/call/accept`
     - `POST /system/im/call/reject`
     - `POST /system/im/call/cancel`
     - `POST /system/im/call/hangup`
     - `GET /system/im/call/state`
   - 与统一文档当前主推的：
     - `GET /system/im/call/detail`
     - `GET /system/im/call/active`
     - `GET /system/im/call/rtc-credential`
     - `GET /system/im/call/turn-config`
     并不一致
4. `call_session_dto.dart`
   - 当前仍解析：
     - `callSessionId`
     - `callType=audio/video`
     - `status=ringing/connected/...`
     - `rtcRoom.turnUsername/turnCredential/token`
   - 与统一文档冻结的：
     - `callId`
     - `callType=1/2`
     - `state/status/endReason` 分层
     - `publisherToken/subscriberToken/expireAt`
     口径不一致
5. `call_dto_mapper.dart`
   - 当前仍把 `audio/video` 字符串映射到 `CallType`
   - `pageStatus` 直接由单个 `status` 字符串推导
   - 与统一文档要求的：
     - `state` 控制页面阶段
     - `status/endReason` 控制记录语义
     存在混用
6. `call_socket_payload_resolver.dart`
   - 当前仍解析：
     - `title`
     - `callerProfile/calleeProfile`
     - `rtcRoom/roomBundle/payload`
     - `roomId/publisherId/janusUrl/turnUsername/turnCredential/token`
   - 这仍是旧“页面直接吃媒体包”的结构
   - 与统一文档要求的：
     - `CALL_SIGNAL.extraData` 只承载按 `signalType` 冻结的 JSON 子结构
     - RTC 凭证应通过 `GET /system/im/call/rtc-credential`
     不一致
7. `call_controller.dart`
   - 当前 `accept()` 成功后会直接本地 `prepare media + openCallSession + pageStatus=connected`
   - 当前 `onStateSync()` 仍走旧 `syncState(callSessionId)`
   - 说明 controller 仍偏“前端主导状态推进”
   - 与统一文档“服务端权威状态机 + REST 恢复态 + RTC 凭证单独拉取”仍有差距

###### AZ.3 当前最需要的后续代码整改方向

1. 第一优先级：
   - 移除默认 `CallRepositoryMode.mock`
   - 把 provider 默认切到真实 repository 前，必须先补齐真实接口字段
2. 第二优先级：
   - 把 `call_remote_data_source.dart` 从旧 `/create-invite/accept/reject/cancel/hangup/state` 方案迁到统一文档冻结接口组
3. 第三优先级：
   - 拆分 `CallSessionDto` 当前混合结构
   - 改为：
     - `AppImCallDetailRespVO`
     - `AppImActiveCallRespVO`
     - `AppImCallRtcCredentialRespVO`
     - `AppImCallTurnConfigRespVO`
4. 第四优先级：
   - `call_controller.dart` 改为“服务端状态驱动 + 页面只消费”
   - 不再在 `accept()` 成功后直接假定本地已连通
5. 第五优先级：
   - `call_socket_payload_resolver.dart` 收口到统一文档已冻结的 `extraData` 结构
   - 废弃当前 `roomBundle/payload/token` 混合解析方式

##### BA. 通话专题当前代码与统一文档的阶段结论

1. `features/im/call` 目录已经具备企业级分层骨架
2. 当前真实差距不在 UI 页面数量，而在：
   - 默认 mock 仍启用
   - 旧 REST 命名仍在
   - DTO 仍是旧字符串口径
   - controller 仍有前端主导状态推进痕迹
3. 因此后续若恢复代码推进，通话专题不应先改页面，而应先按本节的五项整改方向收口

##### BB. 页面级真实接口补录当前阶段结论

截至当前统一文档状态：

1. 第一批页面的“接口路径级补录”已基本完成，尤其：
   - 登录 / 我的 / 通讯录 / 会话 / 聊天
   - 群设置 / 文件预览上传
   - 搜索 / 收藏 / 贴纸
   - 升级检查
2. 因此后续“页面级真实接口补录”不应再停留在只补路径
3. 更值得继续推进的是：
   - 每个页面的核心字段消费口径
   - 页面状态判断与接口字段的绑定关系
   - 仓库内残留 mock 数据与真实字段之间的替换优先级

当前下一批建议优先级：

1. `contact/group/profile` 残留 mock 与真实字段消费口径对照
2. `favorite/sticker/search` 页面级核心字段消费补录
3. `settings/upgrade` 页真实出参字段与弹窗/行为对照

##### BC. 下一批页面字段补录建议范围

建议后续按下面顺序继续，而不是重复补同一批接口路径：

1. 收藏页：
   - `favoriteId/messageId/messageType/title/summary/sourceChatId/sourceSenderId/createdTime`
   - 收藏列表、收藏详情、收藏转发如何消费这些字段
2. 贴纸页：
   - `stickerId/name/url/thumbnailUrl/order/recentUsedAt/collected`
   - 贴纸面板、贴纸管理、最近使用如何消费这些字段
3. 搜索页：
   - `tab/type/highlight/snippet/targetId/chatId/messageId/sortKey`
   - 全局搜索不同 tab 的结果页如何路由
4. 升级页：
   - `hasUpgrade/versionCode/versionName/forceUpgrade/downloadUrl/changelog`
   - 设置页升级提示、强更弹窗、忽略版本策略

结论：

- 页面级补录主线继续保持 `in_progress`
- 但下一阶段主任务已经从“补接口路径”转到“补字段消费口径 + 清理残留 mock 优先级”

##### BD. `contact / group / profile` 当前字段消费与 mock 对照

截至 `2026-05-02` 当前仓库实况：

###### BD.1 contacts 当前结论

当前已接真实接口：

- `/system/im/contact/list`
- `/system/user/get`
- `/system/im/contact/list-by-dept`
- `/system/dept/my-dept-tree`
- `/system/dept/org-tree`
- `/system/im/group/list`
- `/system/im/contact/search`
- `/system/im/conversation/get-by-target`

当前已确认字段消费口径：

1. `ContactsRepositoryImpl`
   - `ContactDto.nickname(兼容 remarkName/userName/realName/name) -> ContactDirectoryItem.name`
   - `ContactDto.departmentName(兼容 deptName/departmentName/department) -> ContactDirectoryItem.departmentName`
   - `ContactDto.avatarUrl(兼容 avatarUrl/avatar) -> ContactDirectoryItem.avatarUrl`
   - `ContactDto.postName(兼容 postName/positionName) -> ContactDirectoryItem.postName`
   - `chatId` 当前未从真实接口回填，先置空
2. `ContactProfileDto`
   - `nickname/mobile/email/avatarUrl/departmentName/postName`
   - 兼容 `remarkName/userName/realName/name/phone/avatarUrl/departmentName/positionName`
   - 已映射到联系人详情页真实资料与头像
3. 搜索页当前逻辑：
   - 联系人搜索走 `/system/im/contact/search`
   - 部门搜索仍是本地对 `org-tree` 名称做 contains 过滤
   - 部门 DTO 已兼容 `deptId/departmentId/deptName/departmentName/memberNum/userCount`，并支持字符串数值人数
4. `GroupSummaryDto`
   - 兼容 `groupId/groupName/avatarUrl/avatar/memberNum`
   - 群列表继续消费真实 `groupId/memberCount/avatarUrl`
5. `DirectConversationRef`
   - `targetId` 优先使用 `/system/im/conversation/get-by-target` 回包真实值
   - 仅在回包缺失时回退发起入参 `userId`
6. `ConversationDto`
   - `conversationType` 兼容 `group/direct/single/private/1/2`
   - `updatedAt/unreadCount/isPinned/isMuted` 兼容字符串数值、布尔数值与 `topStatus/muteStatus`
   - `lastMessageType/lastMessageStatus` 兼容 `location/contactCard/pending/success/error`
   - `chatId/title` 兼容 `conversationId/id/name`
7. `ConversationSyncResponseDto`
   - 增量同步结果兼容 `items/list/records`
   - `cursorVersion` 兼容 `version`
   - `hasMore` 兼容 `more` 与布尔/数值口径
8. `ConversationRemoteDataSource.fetchConversationList()`
   - 会话主列表结果兼容裸数组与 `list/records/items` 容器结构

当前残留 mock：

1. `features/contacts/presentation/data/contacts_mock_data.dart` 已删除：`completed`
2. 相关 mock 列表与查找辅助已退场：`completed`

结论：

1. contacts 已进入“接口已接一部分、展示模型仍混有 mock 字段”阶段
2. 下一步应优先把：
   - `chatId`
   - `email`
   - `officeLocation`
   的真实来源与页面是否还需要这些字段明确下来

###### BD.2 group_settings 当前结论

当前已确认的正向进展：

1. 群成员页页面层已按 `member.roleCode` 渲染角色
2. 页面不再以中文“群主/管理员/成员”反推逻辑
3. 这与统一文档“角色判断基于服务端数值字段”的规则一致

当前仍存在的残留问题：

1. `group_qr_code_page.dart` 历史 `_MockQrPainter` 已退场，当前已消费真实邀请码/二维码链路：`completed`
2. 群历史页英文占位提示已清理：`completed`
3. l10n 历史 mock key 已清理：`completed`

结论：

1. group settings 主体字段判断方向基本已对
2. 当前更需要清理的是：
   - mock 交互文案
   - 假二维码画布
   - 占位说明性文案

###### BD.3 profile 当前结论

当前已接真实接口：

- `/system/user/get-profile`

当前已确认字段消费口径：

1. `UserProfileDto`
   - 消费当前用户资料基础信息
2. `settings_page/theme/language`
   - 已经属于 profile 子域页面
   - 当前更多是本地设置消费，不是高优先真实接口缺口

结论：

1. profile 主资料页已不再是优先问题
2. 后续只需增量查漏，不再回退到 mock 主线

##### BE. `favorite / sticker / search / upgrade` 字段消费口径补录

###### BE.1 收藏页建议字段消费口径

建议核心字段：

- `favoriteId`
- `messageId`
- `messageType`
- `title`
- `summary`
- `sourceChatId`
- `sourceSenderId`
- `createdTime`

页面消费规则：

1. 收藏列表：
   - `title/summary/messageType/createdTime`
2. 收藏详情：
   - `messageType` 决定详情展示组件
   - `sourceChatId/sourceSenderId` 决定来源信息
3. 收藏转发：
   - 只以 `favoriteId/targetChatId` 为写口
   - 不在页面本地拼收藏原文消息体

###### BE.2 贴纸页建议字段消费口径

建议核心字段：

- `stickerId`
- `name`
- `url`
- `thumbnailUrl`
- `order`
- `recentUsedAt`
- `collected`

页面消费规则：

1. 贴纸面板：
   - `thumbnailUrl/url`
2. 管理排序：
   - `order`
3. 最近使用：
   - `recentUsedAt`
4. 删除与收藏状态：
   - `stickerId/collected`

补充说明：

1. 当前 Flutter 仓库里贴纸更多还挂在 chat 上传/面板语义下
2. 后续若单独起贴纸 feature，也必须以本节字段口径为准

###### BE.3 搜索页建议字段消费口径

建议核心字段：

- `tab`
- `type`
- `highlight`
- `snippet`
- `targetId`
- `chatId`
- `messageId`
- `sortKey`

页面消费规则：

1. 全局搜索 tabs：
   - `tab/type`
2. 命中摘要：
   - `highlight/snippet`
3. 跳转路由：
   - 联系人/群/会话 -> `targetId/chatId`
   - 消息命中 -> `chatId/messageId`
4. 排序：
   - `sortKey`

###### BE.4 升级页建议字段消费口径

建议核心字段：

- `hasUpgrade`
- `versionCode`
- `versionName`
- `forceUpgrade`
- `downloadUrl`
- `changelog`

页面消费规则：

1. 设置页升级提示：
   - `hasUpgrade/versionName`
2. 强更弹窗：
   - `forceUpgrade`
3. 下载动作：
   - `downloadUrl`
4. 更新说明：
   - `changelog`

##### BF. 当前这一轮页面补录推进结论

1. 页面级补录主线已经从“路径清单”进入“字段消费与 mock 对照”阶段
2. 当前优先级已进一步收敛为：
   - contacts 残留 mock 与真实字段来源收口
   - group settings 残留 mock 文案/假画布清理
   - favorite/sticker/search/upgrade 四类页面字段消费冻结
3. 后续若继续文档推进，应优先把：
   - contacts 页面哪些地方仍在直接吃 mock 数据
   - group settings 哪些页面仍是占位说明
   写成更细的页面级差距清单

##### BG. `upgrade` 专题后端服务闭环设计补充

补充结论：

1. `upgrade` 不能只停留在 `/system/app-upgrade/check` 与 `/report-event` 两条接口路径
2. 当前 Flutter/uni-app x 客户端已形成稳定请求契约，但统一文档里还缺“平台后端如何实现”的系统设计
3. 后续应把 `upgrade` 视为独立平台治理专题，类似通话专题一样补齐后端实施闭环

###### BG.1 模块归属与服务边界

建议后端落点：

- 模块：`shengyu-module-platform/shengyu-module-platform-biz`
- App 端 Controller：
  - `com.shengyu.module.platform.controller.app.appupgrade.AppUpgradeController`
- Platform 管理端 Controller：
  - `PlatformAppProductController`
  - `PlatformAppPackageController`
  - `PlatformAppReleaseController`
  - `PlatformAppChannelReleaseController`
  - `PlatformAppUpgradeLogController`

职责分层：

1. `AppUpgradeController`
   - 面向 App 客户端
   - 只提供：
     - `/system/app-upgrade/check`
     - `/system/app-upgrade/report-event`
2. 平台管理端
   - 负责应用、安装包、发布单、渠道分发、升级日志治理
3. `shengyu-module-infra`
   - 提供安装包文件底座、预签名 URL、下载资源

###### BG.2 推荐核心数据模型

建议最小数据模型：

1. `platform_app_product`
   - 应用定义
   - 核心字段：
     - `app_code`
     - `app_name`
     - `status`
2. `platform_app_package`
   - 安装包或商店包记录
   - 核心字段：
     - `package_id`
     - `app_code`
     - `platform`
     - `version_name`
     - `version_code`
     - `file_id`
     - `download_url`
     - `store_url`
     - `market_url`
     - `web_url`
     - `asset_status`
3. `platform_app_release`
   - 发布单
   - 核心字段：
     - `release_id`
     - `app_code`
     - `platform`
     - `channel`
     - `release_notes`
     - `force_update`
     - `gray_strategy`
     - `min_support_version_code`
     - `publish_status`
     - `publish_start_time`
     - `publish_end_time`
4. `platform_app_channel_release`
   - 渠道/市场侧分发状态
   - 核心字段：
     - `channel_release_id`
     - `release_id`
     - `channel`
     - `distribute_status`
     - `visible_scope`
5. `platform_app_upgrade_log`
   - 客户端升级事件日志
   - 核心字段：
     - `app_code`
     - `platform`
     - `device_id`
     - `client_version`
     - `client_version_code`
     - `event_type`
     - `result_code`
     - `extra_json`

###### BG.3 `AppUpgradeController` 接口冻结

建议接口：

```java
@Tag(name = "App 端 - 升级中心")
@RestController
@RequestMapping("/system/app-upgrade")
public class AppUpgradeController {

    @PostMapping("/check")
    public CommonResult<AppUpgradeCheckRespVO> check(
            @Valid @RequestBody AppUpgradeCheckReqVO reqVO) { ... }

    @PostMapping("/report-event")
    public CommonResult<Boolean> reportEvent(
            @Valid @RequestBody AppUpgradeReportEventReqVO reqVO) { ... }
}
```

###### BG.4 ReqVO / RespVO 冻结

`AppUpgradeCheckReqVO` 建议字段：

- `appCode`
- `platform`
- `channel`
- `clientVersion`
- `clientVersionCode`
- `deviceId`
- `deviceType`
- `osName`
- `osVersion`
- `manufacturer`
- `model`
- `harmonyApiVersion`
- `harmonyDisplayVersion`

`AppUpgradeCheckRespVO` 建议字段：

- `resultCode`
- `title`
- `content`
- `releaseNotes`
- `latestVersion`
- `latestVersionCode`
- `forceUpdate`
- `action`
- `downloadUrl`
- `storeUrl`
- `marketUrl`
- `webUrl`
- `publishTime`
- `releaseId`
- `packageId`
- `channelReleaseId`

`AppUpgradeReportEventReqVO` 建议字段：

- `appCode`
- `platform`
- `eventType`
- `clientVersion`
- `clientVersionCode`
- `deviceId`
- `payload`

###### BG.5 `check()` 服务端处理流程

`AppUpgradeService.check(reqVO)` 建议步骤：

1. 校验 `appCode + platform + channel`
2. 查询当前应用是否启用
3. 查询当前平台/渠道可见的候选发布单
4. 过滤无效发布单：
   - `publish_status != PUBLISHED`
   - 不在时间窗
   - 包资产未就绪
   - 渠道分发状态不可用
5. 按租户可见性、灰度规则、设备类型规则继续过滤
6. 与 `clientVersionCode` 比较：
   - 无更高版本 -> `NO_UPDATE`
   - 有高版本且非强更 -> `OPTIONAL_UPDATE`
   - 有高版本且强更 -> `FORCE_UPDATE`
   - 当前版本已被封禁或低于最低支持版本 -> `BLOCKED`
7. 生成动作：
   - Android：优先 `OPEN_URL`
   - iOS：优先 `OPEN_STORE`
   - Harmony：优先 `OPEN_APP_GALLERY`
   - Web：`REFRESH_WEB`
8. 组装 `AppUpgradeCheckRespVO`

###### BG.6 `reportEvent()` 服务端处理流程

`AppUpgradeService.reportEvent(reqVO)` 建议步骤：

1. 基础字段校验
2. 解析 `payload`
3. 写入 `platform_app_upgrade_log`
4. 若有 `releaseId/packageId/channelReleaseId/resultCode`
   - 一并回填到日志
5. 异步汇总日统计表或监控指标

###### BG.7 推荐枚举全集

`AppPlatformEnum`：

- `ANDROID`
- `IOS`
- `HARMONY`
- `WEB`

`AppUpgradeResultCodeEnum`：

- `NO_UPDATE`
- `OPTIONAL_UPDATE`
- `FORCE_UPDATE`
- `BLOCKED`

`AppUpgradeActionEnum`：

- `NONE`
- `OPEN_URL`
- `OPEN_STORE`
- `OPEN_APP_GALLERY`
- `REFRESH_WEB`

`AppUpgradeEventTypeEnum`：

- `CHECK`
- `SHOW_DIALOG`
- `CLICK_UPDATE`
- `CLICK_CANCEL`
- `OPEN_STORE`
- `OPEN_APP_GALLERY`
- `DOWNLOAD_START`
- `DOWNLOAD_SUCCESS`
- `DOWNLOAD_FAIL`
- `INSTALL_START`
- `INSTALL_FAIL`

###### BG.8 与 Flutter/uni-app x 客户端的字段对照

当前客户端已明确消费：

1. `resultCode`
2. `title`
3. `content/releaseNotes`
4. `latestVersion/latestVersionCode`
5. `forceUpdate`
6. `action`
7. `downloadUrl/storeUrl/marketUrl/webUrl`

页面行为绑定：

1. 设置页手动检查更新：
   - `check()`
2. 启动静默检查：
   - `check('silent')`
3. 升级弹窗展示：
   - `SHOW_DIALOG`
4. 点击升级：
   - `CLICK_UPDATE`
5. 跳商店/应用市场/下载地址：
   - `OPEN_STORE/OPEN_APP_GALLERY`

###### BG.9 推荐 Job 与统计清单

建议增加：

1. `AppUpgradeLogArchiveJob`
   - 归档 `platform_app_upgrade_log`
2. `AppUpgradeDailyStatJob`
   - 汇总 `CHECK/SHOW_DIALOG/CLICK_UPDATE/...`
3. `AppReleaseWindowRefreshJob`
   - 刷新已到时间窗的发布单状态

###### BG.10 当前专题实施顺序建议

建议开发顺序：

1. 先建表：
   - `platform_app_product`
   - `platform_app_package`
   - `platform_app_release`
   - `platform_app_channel_release`
   - `platform_app_upgrade_log`
2. 再做平台管理端 CRUD 与发布状态机
3. 再做 `AppUpgradeController.check`
4. 再做 `report-event`
5. 最后补日志统计、归档、灰度扩展

结论：

- `upgrade` 专题当前已从“只有接口路径”升级到“具备后端服务闭环设计”
- 后续若继续推进升级专题，应优先补 SQL/VO 示例 JSON/发布状态机细则

##### BH. `contacts` 页面 mock 使用点清单

当前已确认 mock 使用点：

1. 历史 `contacts_mock_data.dart` 使用点已清理：`completed`

当前差距说明：

1. contacts repository 已经开始走真接口
2. 但页面展示模型历史上预留了：
   - `chatId`
   - `phoneMasked`
   - `email`
   - `officeLocation`
   这些字段
3. 这些字段并未在当前 repository 映射中全部获得真实来源

后续清理顺序建议：

1. 先确认页面是否真的还需要 `phoneMasked/email/officeLocation`
2. 再明确这些字段是否来自：
   - `/system/user/get`
   - 或不应在联系人主列表展示
3. `contacts_mock_data.dart` 消费点移除已完成，后续只做字段语义收口

##### BI. `group settings` 占位页差距清单

当前已确认占位或残留点：

1. `group_qr_code_page.dart`
   - 历史 `_MockQrPainter` 已退场：`completed`
2. `group_settings_page.dart`
   - 历史 `groupHistoryLocalHint` 已清理：`completed`
3. `group_chat_history_page.dart`
   - 历史占位说明已清理：`completed`
4. l10n 历史 mock key 已清理：`completed`

后续清理顺序建议：

1. 先把占位说明页列入 `blocked` 或“待真实接口/能力接入”
2. 再统一移除 mock 文案键
3. 最后视真实能力决定：
   - 群二维码是否改为真实邀请码/二维码链路
   - 群聊天历史是否接 `/system/im/message/search` 与跳锚点

##### BJ. 当前这一轮继续后的结论

1. 页面补录主线已继续细化到：
   - `upgrade` 后端服务闭环
   - `contacts` mock 使用点
   - `group settings` 占位页差距
2. 当前统一文档已能直接指导：
   - 升级专题后端有序开发
   - 页面级 mock 清理优先级
3. 后续若继续文档推进，最合适的下一步是：
   - 升级专题 SQL/状态机/示例 JSON 进一步冻结
   - contacts 页面逐页真实字段消费差距继续拆细

##### BK. `upgrade` 专题 SQL / 状态机 / 示例 JSON 冻结

###### BK.1 升级日志表 SQL 冻结

建议沿用并冻结升级事件日志表：

- `platform_app_upgrade_log`

关键字段冻结：

- `app_code`
- `platform`
- `channel`
- `tenant_id`
- `user_id`
- `device_id`
- `device_type`
- `os_version`
- `manufacturer`
- `model`
- `current_version_name`
- `current_version_code`
- `release_id`
- `package_id`
- `channel_release_id`
- `event_type`
- `success`
- `message`
- `extra_json`
- `create_time`

关键索引冻结：

- `idx_app_platform_time (app_code, platform, create_time)`
- `idx_tenant_user (tenant_id, user_id)`
- `idx_release_event (release_id, event_type)`

`extra_json` 最低建议字段：

- `trigger`
- `resultCode`
- `latestVersion`
- `action`
- `targetUrl`
- `releaseId`
- `packageId`
- `channelReleaseId`

###### BK.2 升级发布状态机冻结

建议最小状态机：

`package` 资产状态：

- `DRAFT`
- `READY`
- `DISABLED`

`release` 发布单状态：

- `DRAFT`
- `PENDING_PUBLISH`
- `PUBLISHED`
- `OFFLINE`
- `ROLLED_BACK`

`channel release` 渠道分发状态：

- `WAITING_REVIEW`
- `OPEN_TEST`
- `PHASED_RELEASE`
- `OFFICIAL_RELEASE`
- `REJECTED`
- `STOPPED`

状态推进规则：

1. 只有 `READY` 包资产可创建发布单
2. 发布单从 `DRAFT -> PENDING_PUBLISH -> PUBLISHED`
3. 已发布发布单允许：
   - `OFFLINE`
   - `ROLLED_BACK`
4. `check()` 仅可命中：
   - `release.publish_status = PUBLISHED`
   - 且渠道状态满足可分发

###### BK.3 `check` 示例 JSON

请求示例：

```json
{
  "appCode": "shengyu-im-mobile",
  "platform": "ANDROID",
  "channel": "stable",
  "clientVersion": "1.3.2",
  "clientVersionCode": 132,
  "deviceId": "android_123456",
  "deviceType": 1,
  "osName": "Android",
  "osVersion": "14",
  "manufacturer": "Xiaomi",
  "model": "23127PN0CC"
}
```

无更新响应示例：

```json
{
  "resultCode": "NO_UPDATE",
  "title": "",
  "content": "",
  "releaseNotes": "",
  "latestVersion": "1.3.2",
  "latestVersionCode": 132,
  "forceUpdate": false,
  "action": "NONE",
  "downloadUrl": "",
  "storeUrl": "",
  "marketUrl": "",
  "webUrl": ""
}
```

可选更新响应示例：

```json
{
  "resultCode": "OPTIONAL_UPDATE",
  "title": "发现新版本",
  "content": "建议升级到最新版本以获得更稳定体验。",
  "releaseNotes": "1. 修复若干问题\n2. 优化性能",
  "latestVersion": "1.4.0",
  "latestVersionCode": 140,
  "forceUpdate": false,
  "action": "OPEN_URL",
  "downloadUrl": "https://download.example.com/shengyu-im-1.4.0.apk",
  "publishTime": "2026-05-02 09:00:00",
  "releaseId": "2001",
  "packageId": "3001",
  "channelReleaseId": "4001"
}
```

强更响应示例：

```json
{
  "resultCode": "FORCE_UPDATE",
  "title": "版本升级",
  "content": "当前版本已停止支持，请立即升级。",
  "releaseNotes": "1. 安全修复\n2. 兼容性更新",
  "latestVersion": "2.0.0",
  "latestVersionCode": 200,
  "forceUpdate": true,
  "action": "OPEN_APP_GALLERY",
  "marketUrl": "appmarket://details?id=com.shengyu.im",
  "publishTime": "2026-05-02 09:00:00",
  "releaseId": "2002",
  "packageId": "3002",
  "channelReleaseId": "4002"
}
```

###### BK.4 `report-event` 示例 JSON

请求示例：

```json
{
  "appCode": "shengyu-im-mobile",
  "platform": "ANDROID",
  "eventType": "CHECK",
  "clientVersion": "1.3.2",
  "clientVersionCode": 132,
  "deviceId": "android_123456",
  "payload": {
    "trigger": "manual",
    "resultCode": "OPTIONAL_UPDATE",
    "latestVersion": "1.4.0",
    "releaseId": "2001",
    "packageId": "3001",
    "channelReleaseId": "4001"
  }
}
```

###### BK.5 当前阶段结论

1. `upgrade` 专题已具备：
   - 数据模型
   - SQL 主表
   - 状态机
   - ReqVO/RespVO
   - 示例 JSON
2. 后续若继续推进升级专题，下一步优先补：
   - 灰度发布命中规则
   - 平台管理端 CRUD 与审核流

##### BL. `upgrade` 专题平台端统一发布体系设计

设计定位：

1. `upgrade` 的发布与分发统一由平台端 `platform` 管理
2. IM 通讯 App 是租户端使用者，但升级包、发布单、审核流、分发状态都属于平台治理能力
3. 统一文档后续应把 `upgrade` 视为“平台升级中心专题”，而不是租户业务页附属能力

###### BL.1 平台端统一职责

平台端需要统一管理：

1. 应用产品
2. 多端安装包资产
3. 发布单与时间窗
4. 灰度与可见范围
5. 外部分发渠道状态
6. 客户端升级日志与统计

统一发布流程建议：

1. 创建应用产品 `appCode`
2. 上传或登记各平台安装包 / 商店构建
3. 生成平台包记录 `platform_app_package`
4. 创建发布单 `platform_app_release`
5. 绑定渠道分发记录 `platform_app_channel_release`
6. 经过审核或时间窗进入 `PUBLISHED`
7. 客户端 `check()` 命中发布单并执行端侧升级动作

###### BL.2 各平台推荐技术方案

统一原则：

1. 平台端只负责“是否升级、升级到哪个版本、走什么动作”
2. 各终端真正执行升级动作时，遵循对应平台的官方分发规则

Android：

1. 主方案分两类：
   - 应用市场分发：Google Play / 厂商市场
   - 企业直装分发：APK 下载 URL
2. 若走 Google Play 体系，可支持 In-app Updates
3. 若走企业直装，平台端返回 `OPEN_URL`

iOS：

1. 主方案：App Store Connect 版本发布
2. 平台端不直接下发 IPA 安装
3. 客户端只做：
   - 检查更新
   - 弹窗
   - 跳 App Store

HarmonyOS：

1. 主方案：AppGallery Connect / AppGallery 分发
2. 平台端需要记录渠道侧分发状态
3. 客户端动作优先 `OPEN_APP_GALLERY`

Web：

1. 主方案：Web 构建版本发布
2. 客户端动作：
   - `REFRESH_WEB`
3. 若使用 PWA / service worker，平台端只管理构建版本与发布窗口，不管理浏览器缓存细节

Windows：

1. 主方案建议：`MSIX + App Installer`
2. 平台端管理：
   - `.msix/.msixbundle`
   - `.appinstaller`
   - 更新 URI
3. 客户端动作：
   - `OPEN_URL`
   - 或由 App Installer 自动更新

macOS：

1. 若上架 Mac App Store：
   - 走 App Store 版本发布
2. 若企业自分发：
   - 建议单独采用 macOS 自更新框架
   - 平台端仍统一管理版本、下载地址、发布单
3. 当前统一文档建议：
   - 首期优先纳入 App Store 口径
   - 非商店自更新列为增强方案

###### BL.3 平台端发布资产模型与平台映射

建议每个平台包都明确一套资产类型：

| 平台 | 包资产主类型 | 平台端主动作 | 客户端动作 |
|---|---|---|---|
| Android | `APK/AAB` | 包资产 + 下载地址或市场记录 | `OPEN_URL` / 市场升级 |
| iOS | `App Store Build` | 版本记录 + `storeUrl` | `OPEN_STORE` |
| HarmonyOS | `AppGallery Release` | 渠道分发记录 + `marketUrl` | `OPEN_APP_GALLERY` |
| Web | `Build Artifact` | 构建版本 + 发布时间窗 | `REFRESH_WEB` |
| Windows | `MSIX/AppInstaller` | 包资产 + `appinstaller` URI | `OPEN_URL` / 自动更新 |
| macOS | `Store Build` 或 `DMG/ZIP` | 商店记录或下载资产 | `OPEN_STORE` / `OPEN_URL` |

###### BL.4 平台端发布操作流建议

平台运营后台建议提供以下页面：

1. 应用产品管理
2. 安装包管理
3. 发布单管理
4. 渠道分发管理
5. 升级日志查询
6. 升级统计看板

后台操作流建议：

1. 录入产品：
   - `appCode/appName/platforms`
2. 上传包：
   - Android APK/AAB
   - Windows MSIX
   - Web build
   - 记录 iOS/Harmony 商店构建信息
3. 填写发布单：
   - `versionName/versionCode/releaseNotes/forceUpdate`
   - `publishStartTime/publishEndTime`
   - `visibleScope`
4. 绑定渠道信息：
   - `storeUrl/marketUrl/appinstallerUrl/webUrl`
5. 提交审核或直接发布
6. 观测客户端事件回流

###### BL.5 平台端与客户端的边界冻结

平台端负责：

1. 版本治理
2. 发布状态
3. 渠道分发状态
4. 灰度匹配
5. 升级动作决策

客户端负责：

1. 采集当前端信息
2. 请求 `check`
3. 按 `action` 执行端上升级
4. 回传事件日志

客户端禁止：

1. 自己比较版本并绕过平台结果
2. 自己拼商店 URL 或下载 URL
3. 自己决定强更/可选更新

###### BL.6 平台端各平台技术路线冻结建议

当前统一文档建议冻结为：

1. Android：
   - 首选支持市场分发
   - 企业包可回退 `OPEN_URL`
2. iOS：
   - 只走 App Store
3. HarmonyOS：
   - 只走 AppGallery
4. Web：
   - 走构建版本 + `REFRESH_WEB`
5. Windows：
   - 走 `MSIX + App Installer`
6. macOS：
   - 首期按 App Store 管理
   - 非商店自更新作为后续增强

结论：

- 这样可以把“多端升级发布治理”统一收进平台端，而不是分散在各客户端自行处理
- 后续所有多端升级开发，都应先围绕平台端发布中心展开

##### BM. `upgrade` 专题灰度命中规则补充

灰度命中目标：

1. 平台端决定“谁能看到哪个发布单”
2. 客户端只上传环境信息，不参与灰度决策

建议命中维度：

1. `ALL`
2. `TENANT`
3. `USER`
4. `CHANNEL`
5. `DEVICE_TYPE`
6. `PERCENT`

命中顺序建议：

1. 先筛：
   - `appCode`
   - `platform`
   - `channel`
2. 再筛：
   - `publish_status=PUBLISHED`
   - 时间窗有效
3. 再筛灰度：
   - 租户
   - 用户
   - 设备类型
   - 百分比
4. 最后按：
   - 优先级
   - 版本号
   - 强更优先级
   取最终命中发布单

百分比灰度建议：

1. 对 `deviceId` 或 `userId` 做稳定 hash
2. 使用固定 hash 百分桶
3. 同一设备在发布有效期内命中结果必须稳定

###### BM.1 Harmony / Store 渠道补充约束

1. Harmony 命中发布单后，还必须校验渠道分发状态满足：
   - `OPEN_TEST`
   - `PHASED_RELEASE`
   - `OFFICIAL_RELEASE`
2. iOS/App Store phased release 可作为平台端渠道状态的一种外显记录
3. Windows / Web / APK 直装场景可不需要外部商店状态，但必须校验资产与 URL 可用

##### BN. `upgrade` 专题平台管理端 CRUD 与审核流补充

平台端建议最小页面集合：

1. 应用产品管理页
2. 安装包管理页
3. 发布单管理页
4. 渠道分发管理页
5. 升级日志页
6. 升级统计页

###### BN.1 应用产品管理

建议核心字段：

- `appCode`
- `appName`
- `appType`
- `enabled`
- `supportedPlatforms`
- `defaultChannel`

平台操作：

1. 创建产品
2. 启停产品
3. 配置支持平台
4. 配置默认渠道

###### BN.2 安装包管理

建议核心字段：

- `packageId`
- `appCode`
- `platform`
- `versionName`
- `versionCode`
- `buildVersion`
- `assetStatus`
- `fileId`
- `downloadUrl`
- `storeUrl`
- `marketUrl`
- `webUrl`

平台操作：

1. 上传包或登记外部商店构建
2. 变更资产状态
3. 关闭无效包
4. 校验版本重复与主键冲突

###### BN.3 发布单管理

建议核心字段：

- `releaseId`
- `appCode`
- `platform`
- `channel`
- `releaseNotes`
- `forceUpdate`
- `minSupportVersionCode`
- `grayStrategy`
- `publishStatus`
- `publishStartTime`
- `publishEndTime`

平台操作：

1. 草稿保存
2. 提交发布
3. 定时发布
4. 强更开关
5. 下线
6. 回滚

###### BN.4 渠道分发管理

建议核心字段：

- `channelReleaseId`
- `releaseId`
- `channelType`
- `externalStatus`
- `reviewStatus`
- `visibleScope`
- `storeUrl`
- `marketUrl`

平台操作：

1. 绑定外部分发记录
2. 更新外部审核状态
3. 设置 phased/staged rollout
4. 暂停/恢复渠道放量

###### BN.5 审核流建议

建议最小审核流：

1. `DRAFT`
2. `REVIEWING`
3. `APPROVED`
4. `REJECTED`

处理规则：

1. 强更发布单建议必须经过审核
2. 跨平台统一版本更新建议必须记录审核备注
3. 审核通过后才允许进入 `PENDING_PUBLISH`

##### BO. `upgrade` 专题渠道状态细则补充

###### BO.1 Android

若走 Google Play：

1. 平台端记录 Play 发布轨道或 rollout 状态
2. 可选支持 In-app Updates
3. `action` 仍由平台端决定是：
   - `OPEN_STORE`
   - 或保留企业包 `OPEN_URL`

若走企业直装：

1. 平台端必须确保 APK 下载 URL 可用
2. 包资产必须具备摘要/版本校验信息

###### BO.2 iOS

1. 平台端记录 App Store 版本与 phased release 状态
2. 客户端不做应用内安装
3. 若 App Store phased release 未放量到全部用户：
   - 平台端渠道状态必须单独记录
   - `check()` 命中结果要与平台发布策略一致

###### BO.3 HarmonyOS

1. 平台端记录 AppGallery Connect / AppGallery 渠道状态
2. 支持 phased release / suspend / resume / update
3. 客户端升级动作默认 `OPEN_APP_GALLERY`

###### BO.4 Web

1. 平台端记录构建版本号与发布时间窗
2. `check()` 只返回：
   - `NO_UPDATE`
   - `OPTIONAL_UPDATE`
   - `FORCE_UPDATE`
   - `BLOCKED`
3. 客户端动作固定 `REFRESH_WEB`

###### BO.5 Windows

1. 平台端记录：
   - `msix/msixbundle`
   - `appinstaller` 地址
2. 客户端更新优先遵循 App Installer 自动更新机制
3. 平台端仍通过 `check()` 提供版本治理结果

###### BO.6 macOS

1. 首期优先按 Mac App Store 管理
2. 若后续做非商店自更新：
   - 平台端需管理下载资产与签名版本
   - 客户端再接自更新框架
3. 当前文档保持该项为增强专题，不作为首期主线

##### BP. 平台侧多端升级技术路线与官方约束补充

结合当前官方资料，统一文档建议如下冻结：

1. Android
   - Google 官方支持 Play In-app Updates
   - Play Console 支持 staged rollout / prepare and roll out release
2. iOS
   - App Store Connect 支持 phased release
   - 客户端只能跳转 App Store，不走自安装
3. HarmonyOS
   - AppGallery Connect 支持 phased release，并支持暂停、恢复、更新
4. Windows
   - Microsoft 官方支持 `MSIX + App Installer` 自动更新与修复
5. Web
   - Flutter 官方 Web 部署能力可作为 Web 版本发布底座
   - 平台端负责版本决策，浏览器缓存/刷新策略由 Web 构建方案配合
6. macOS
   - 非商店自更新可参考 Sparkle 一类方案
   - 但统一文档首期仍建议优先 App Store 口径

###### BP.1 当前推荐冻结主方案

首期主方案建议：

1. Android：
   - 市场分发 + 企业包 URL 兜底
2. iOS：
   - App Store Connect
3. HarmonyOS：
   - AppGallery Connect
4. Web：
   - Flutter Web 构建发布
5. Windows：
   - MSIX + App Installer
6. macOS：
   - Mac App Store

###### BP.2 官方技术依据索引

后续平台端升级中心开发，优先参考以下官方资料：

1. Android Play In-app Updates
   - `https://developer.android.com/guide/playcore/in-app-updates`
2. Apple App Store phased release
   - `https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases`
3. Huawei AppGallery Connect phased release
   - `https://developer.huawei.com/consumer/en/agconnect/phased-release/`
4. Microsoft MSIX App Installer
   - `https://learn.microsoft.com/en-us/windows/msix/app-installer/app-installer-root`
5. Flutter Web deployment
   - `https://docs.flutter.dev/deployment/web`

说明：

1. 平台端统一文档以这些官方能力为外部约束边界
2. 客户端动作模型仍以本统一文档冻结口径为准

##### BQ. `contacts` 差距字段真实来源补充

###### BQ.1 `contacts_page.dart`

真实来源补充结论：

1. 联系人主列表应主要消费 `/system/im/contact/list`
2. 点击“发送消息”时，再懒取 `/system/im/conversation/get-by-target`
3. `email/phone/officeLocation` 不建议继续挂在联系人主列表主模型

###### BQ.2 `my_groups_page.dart`

真实来源补充结论：

1. 群列表主数据来自 `/system/im/group/list`
2. 若补群头像，应直接消费接口返回 `avatarUrl`
3. 若补群详情跳转，应进一步接 `/system/im/group/get`

###### BQ.3 `my_department_page.dart`

真实来源补充结论：

1. 部门树来自 `/system/dept/my-dept-tree`
2. 成员列表来自 `/system/im/contact/list-by-dept`
3. 若页面要展示岗位/电话，建议改为：
   - 列表只展示岗位
   - 电话放联系人详情页

###### BQ.4 `org_browser_page.dart`

真实来源补充结论：

1. 组织结构页主树来自 `/system/dept/org-tree`
2. 若点击部门进入成员页，沿用 `deptId -> /system/dept/dept-members` 或 `/system/im/contact/list-by-dept`

###### BQ.5 `contact_search_result_page.dart`

真实来源补充结论：

1. 联系人结果主来源：
   - `/system/im/contact/search`
2. 部门结果当前只是 `org-tree` 本地过滤
3. 若后续做真部门搜索，建议单独补：
   - `/system/dept/search`
   - 或在现有搜索聚合接口中补部门结果集

##### BR. 当前这一轮继续后的结论

1. `upgrade` 专题已补到平台管理端 CRUD、审核流、渠道状态细则和多平台官方技术路线
2. `contacts` 差距字段的真实来源也已继续明确
3. 后续若继续文档推进，建议优先：
   - `upgrade` 平台端菜单/API/权限点清单
   - `group settings` 占位页的真实接口替换方案

##### BS. `shengyu-ui-platform-vue3` 升级控制台设计补充

补充结论：

1. `upgrade` 的平台控制台前端明确落在：
   - `shengyu-ui/shengyu-ui-platform-vue3`
2. 后续升级中心开工，不应在租户端 Flutter/uni-app x 后台页面做平台治理能力
3. 统一文档需要把平台端前端的页面结构、API 目录、权限点、联调顺序一并冻结

###### BS.1 建议新增 API 目录

建议在：

- `src/api/system/appManage/`

新增文件：

- `product.ts`
- `package.ts`
- `release.ts`
- `channelRelease.ts`
- `upgradeLog.ts`

职责建议：

1. `product.ts`
   - 应用产品 CRUD
2. `package.ts`
   - 安装包资产 CRUD
   - 启停包状态
3. `release.ts`
   - 发布单 CRUD
   - 发布 / 下线 / 回滚
4. `channelRelease.ts`
   - 外部分发记录 CRUD
   - 同步渠道状态
5. `upgradeLog.ts`
   - 升级日志分页
   - 升级统计摘要

###### BS.2 建议新增页面目录

建议在：

- `src/views/system/appManage/`

新增页面：

- `product/index.vue`
- `product/ProductForm.vue`
- `package/index.vue`
- `package/PackageForm.vue`
- `release/index.vue`
- `release/ReleaseForm.vue`
- `channelRelease/index.vue`
- `channelRelease/ChannelReleaseForm.vue`
- `upgradeLog/index.vue`

页面风格建议对齐现有：

- `src/views/system/tenant/index.vue`
- `src/views/infra/file/index.vue`

###### BS.3 平台端菜单建议

建议平台端菜单树：

- 系统管理
  - 应用中心
    - 应用管理
    - 安装包管理
    - 发布管理
    - 渠道分发管理
    - 升级统计

说明：

1. 首期可以先加开发路由
2. 最终菜单仍由平台菜单管理动态配置

###### BS.4 平台端权限点冻结

建议权限点：

- `system:app-product:query`
- `system:app-product:create`
- `system:app-product:update`
- `system:app-product:update-status`
- `system:app-package:query`
- `system:app-package:create`
- `system:app-package:update`
- `system:app-package:enable`
- `system:app-package:disable`
- `system:app-release:query`
- `system:app-release:create`
- `system:app-release:update`
- `system:app-release:publish`
- `system:app-release:offline`
- `system:app-release:rollback`
- `system:app-channel-release:query`
- `system:app-channel-release:create`
- `system:app-channel-release:update`
- `system:app-channel-release:sync-status`
- `system:app-upgrade-log:query`

###### BS.5 平台端页面职责冻结

`应用管理页`：

1. 管理 `appCode/appName/defaultPlatform/enabled`
2. 查看支持的平台集合

`安装包管理页`：

1. 上传 Android APK/AAB
2. 录入 iOS Store URL
3. 录入 HarmonyOS AppGallery 信息
4. 录入 Web 构建版本
5. 录入 Windows `MSIX/AppInstaller`
6. 查看版本号、构建号、文件摘要、状态

`发布管理页`：

1. 选择应用与包资产
2. 配置：
   - `releaseNotes`
   - `forceUpdate`
   - `minSupportVersionCode`
   - `grayStrategy`
   - `publishStartTime/publishEndTime`
3. 执行：
   - 发布
   - 下线
   - 回滚

`渠道分发管理页`：

1. 维护外部商店 / 市场状态
2. 查看：
   - `OPEN_TEST`
   - `PHASED_RELEASE`
   - `OFFICIAL_RELEASE`
   - `REJECTED`
   - `STOPPED`
3. 手动同步状态

`升级统计页`：

1. 分平台查看：
   - `CHECK`
   - `SHOW_DIALOG`
   - `CLICK_UPDATE`
   - `DOWNLOAD_*`
   - `OPEN_STORE`
   - `OPEN_APP_GALLERY`
2. 查看命中率、失败分布、平台分布

###### BS.6 平台端页面筛选项建议

`应用管理页` 筛选：

- `appCode`
- `appName`
- `enabled`

`安装包管理页` 筛选：

- `appCode`
- `platform`
- `versionName`
- `versionCode`
- `assetStatus`

`发布管理页` 筛选：

- `appCode`
- `platform`
- `channel`
- `publishStatus`
- `forceUpdate`
- `publishTimeRange`

`渠道分发管理页` 筛选：

- `appCode`
- `platform`
- `channelType`
- `externalStatus`

`升级统计页` / `upgradeLog` 筛选：

- `appCode`
- `platform`
- `eventType`
- `clientVersion`
- `tenantId`
- `deviceId`
- `createTimeRange`

###### BS.7 平台端联调顺序建议

建议顺序：

1. 先建 `src/api/system/appManage/*`
2. 先做 `product/index.vue`
3. 再做 `package/index.vue`
4. 再做 `release/index.vue`
5. 再做 `channelRelease/index.vue`
6. 最后做 `upgradeLog/index.vue`

理由：

1. `product/package/release` 是上游主链路
2. `channelRelease` 依赖发布单
3. `upgradeLog` 依赖客户端事件回流

###### BS.8 平台端当前阶段完成定义

当前平台端若达到以下条件，可视为“后期能开工”的体系化状态：

1. 页面目录、API 目录、权限点、菜单名全部冻结
2. 表单字段与平台后端 VO 已对齐
3. 列表筛选项、操作按钮、状态流转全部明确
4. 与客户端 `/check`、`/report-event` 关系清晰

##### BT. `upgrade` 平台端页面与后端 API 对照

| 页面 | API 文件 | 后端接口组 | 主要动作 |
|---|---|---|---|
| 应用管理 | `product.ts` | `/platform-api/system/app-product/*` | 查询、新增、编辑、启停 |
| 安装包管理 | `package.ts` | `/platform-api/system/app-package/*` | 上传/登记、启停、详情 |
| 发布管理 | `release.ts` | `/platform-api/system/app-release/*` | 创建、发布、下线、回滚 |
| 渠道分发管理 | `channelRelease.ts` | `/platform-api/system/app-channel-release/*` | 维护渠道状态、同步 |
| 升级统计 | `upgradeLog.ts` | `/platform-api/system/app-upgrade-log/*` | 日志分页、摘要统计 |

##### BU. 当前这一轮继续后的结论

1. `upgrade` 专题已补到平台端前端 `shengyu-ui-platform-vue3` 可开工的粒度
2. 当前统一文档对升级中心已覆盖：
   - 平台后端
   - 客户端检查更新
   - 多平台技术路线
   - 平台端前端控制台
3. 后续若继续文档推进，建议优先：
   - `upgrade` 平台端各页面表单字段与列表列定义
   - `group settings` 占位页真实接口替换方案

##### BV. `upgrade` 平台端页面表单字段与列表列定义

###### BV.1 `product/index.vue` 与 `ProductForm.vue`

列表列建议：

- `appCode`
- `appName`
- `appType`
- `supportedPlatforms`
- `defaultChannel`
- `enabled`
- `createTime`

表单字段建议：

- `appCode`
- `appName`
- `appType`
- `supportedPlatforms`
- `defaultPlatform`
- `defaultChannel`
- `enabled`
- `remark`

###### BV.2 `package/index.vue` 与 `PackageForm.vue`

列表列建议：

- `packageId`
- `appCode`
- `platform`
- `versionName`
- `versionCode`
- `buildVersion`
- `distributionMode`
- `assetStatus`
- `fileSize`
- `fileMd5`
- `fileSha256`
- `createTime`

表单字段建议：

- `appCode`
- `platform`
- `channel`
- `versionName`
- `versionCode`
- `buildVersion`
- `distributionMode`
- `fileId`
- `downloadUrl`
- `storeUrl`
- `marketUrl`
- `webUrl`
- `packageName`
- `marketAppId`
- `assetStatus`
- `remark`

###### BV.3 `release/index.vue` 与 `ReleaseForm.vue`

列表列建议：

- `releaseId`
- `appCode`
- `platform`
- `channel`
- `versionName`
- `versionCode`
- `forceUpdate`
- `publishStatus`
- `grayStrategyType`
- `publishStartTime`
- `publishEndTime`
- `createTime`

表单字段建议：

- `appCode`
- `platform`
- `channel`
- `packageId`
- `releaseTitle`
- `releaseNotes`
- `forceUpdate`
- `minSupportVersionCode`
- `blockUse`
- `grayStrategyType`
- `grayValue`
- `publishStartTime`
- `publishEndTime`
- `priority`
- `remark`

###### BV.4 `channelRelease/index.vue` 与 `ChannelReleaseForm.vue`

列表列建议：

- `channelReleaseId`
- `releaseId`
- `appCode`
- `platform`
- `channelType`
- `externalStatus`
- `reviewStatus`
- `storeUrl`
- `marketUrl`
- `syncTime`

表单字段建议：

- `releaseId`
- `channelType`
- `distributionMode`
- `externalStatus`
- `reviewStatus`
- `storeUrl`
- `marketUrl`
- `marketAppId`
- `openTesting`
- `phasedReleasePercent`
- `remark`

###### BV.5 `upgradeLog/index.vue`

列表列建议：

- `appCode`
- `platform`
- `channel`
- `tenantId`
- `userId`
- `deviceId`
- `currentVersionName`
- `currentVersionCode`
- `eventType`
- `success`
- `message`
- `createTime`

查询项建议：

- `appCode`
- `platform`
- `eventType`
- `tenantId`
- `deviceId`
- `currentVersionName`
- `createTimeRange`

摘要卡片建议：

- `checkCount`
- `hitUpdateCount`
- `showDialogCount`
- `clickUpdateCount`
- `downloadSuccessRate`
- `openStoreCount`
- `openAppGalleryCount`

##### BW. `group settings` 真实接口替换方案细化

###### BW.1 `group_qr_code_page.dart`

当前状态：

- 使用 `_MockQrPainter`
- 保存 / 分享按钮无真实行为

建议替换方案：

1. 数据来源：
   - `/system/im/group/invite/get?groupId=...`
   - `/system/im/group/invite/generate`
2. 页面消费字段：
   - `inviteCode`
   - `expireAt`
   - `maxUseCount`
   - `currentUseCount`
   - `qrCodeUrl` 或后端可还原文本
3. 按钮行为：
   - 保存二维码图片
   - 分享邀请码或二维码链接

###### BW.2 `group_announcement_page.dart`

当前状态：

- 本地 `_announcement` 字符串
- 编辑弹窗只写本地状态
- 仍显示 `groupAnnouncementLocalHint`

建议替换方案：

1. 读取来源：
   - `/system/im/group/get?id=...` 中 `notice`
2. 编辑写口：
   - `/system/im/group/notice/update`
3. 页面消费字段：
   - `groupId`
   - `notice`
   - `ownerUserId/myRole`
4. 权限规则：
   - 仅群主/管理员可编辑

###### BW.3 `group_files_page.dart`

当前状态：

- 本地 `files` 常量数组
- 搜索栏是静态骨架
- 页面仍显示 `groupFilesLocalHint`

建议替换方案：

1. 列表来源：
   - `/system/im/group/file/list`
2. 上传写口：
   - `/system/im/group/file/upload`
3. 删除写口：
   - `/system/im/group/file/delete?id=...`
4. 下载记录写口：
   - `/system/im/group/file/download?id=...`
5. 页面消费字段：
   - `fileId`
   - `fileName`
   - `fileSize`
   - `fileType`
   - `uploaderName`
   - `uploadTime`

###### BW.4 `group_chat_history_page.dart`

当前状态：

- 本地 `records` 常量数组
- 搜索 / 筛选仅 UI 占位
- 仍显示 `groupHistoryLocalHint`

建议替换方案：

1. 搜索主接口：
   - `/system/im/message/search`
2. 跳转锚点：
   - 使用 `chatId/messageId`
   - 聊天页走 anchor 模式打开
3. 筛选维度：
   - 文件
   - 图片
   - 链接
   - 时间范围
4. 页面消费字段：
   - `messageId`
   - `chatId`
   - `senderName`
   - `snippet`
   - `messageType`
   - `sendTime`

###### BW.5 `group_settings_page.dart`

当前状态：

- 主页已经承接不少真实字段，但仍混有占位跳转说明

建议替换顺序：

1. 先替换二维码页
2. 再替换公告页
3. 再替换群文件页
4. 最后替换群聊记录页

原因：

1. 二维码与公告有明确单接口写口
2. 群文件已有独立列表上传链路
3. 群聊记录页依赖聊天搜索和锚点联动，复杂度最高

##### BX. 当前这一轮继续后的结论

1. `upgrade` 平台端控制台已经补到页面级字段和列表列定义
2. `group settings` 各占位页的真实接口替换路径也已明确
3. 后续若继续文档推进，优先建议：
   - `upgrade` 平台端各页面操作按钮与状态流转矩阵
   - `group settings` provider/controller 级字段与接口对照

##### BY. `upgrade` 平台端操作按钮与状态流转矩阵

###### BY.1 应用管理页按钮矩阵

| 状态 | 可用按钮 | 说明 |
|---|---|---|
| `enabled=true` | 编辑、停用 | 停用后客户端不再命中 |
| `enabled=false` | 编辑、启用 | 启用后恢复可创建包/发布单 |

###### BY.2 安装包管理页按钮矩阵

| 资产状态 | 可用按钮 | 说明 |
|---|---|---|
| `DRAFT` | 编辑、上传/重传、置为 READY、停用 | 草稿包不可创建发布单 |
| `READY` | 查看、禁用 | 可被发布单引用 |
| `DISABLED` | 启用、查看 | 禁用包不再允许新发布单引用 |

###### BY.3 发布管理页按钮矩阵

| 发布状态 | 可用按钮 | 说明 |
|---|---|---|
| `DRAFT` | 编辑、提交审核、删除 | 草稿阶段可反复修改 |
| `REVIEWING` | 查看、撤回审核 | 等待审核 |
| `APPROVED` | 发布 | 进入 `PENDING_PUBLISH` / `PUBLISHED` |
| `REJECTED` | 编辑、重新提交审核 | 修正后重提 |
| `PUBLISHED` | 下线、回滚、查看 | 已对客户端可见 |
| `OFFLINE` | 查看、重新发布 | 已停止分发 |
| `ROLLED_BACK` | 查看 | 已回滚，不能直接复用 |

###### BY.4 渠道分发管理页按钮矩阵

| 渠道状态 | 可用按钮 | 说明 |
|---|---|---|
| `WAITING_REVIEW` | 同步状态、编辑 | 等待外部审核 |
| `OPEN_TEST` | 同步状态、暂停 | 开放测试阶段 |
| `PHASED_RELEASE` | 同步状态、调整比例、暂停 | 分阶段放量 |
| `OFFICIAL_RELEASE` | 同步状态、停发 | 正式发布 |
| `REJECTED` | 编辑、重新提交 | 外部审核拒绝 |
| `STOPPED` | 恢复、同步状态 | 渠道放量已暂停 |

###### BY.5 升级日志页按钮矩阵

| 页面区块 | 可用按钮 | 说明 |
|---|---|---|
| 查询表格 | 查询、重置、导出 | 导出日志分析 |
| 摘要卡片 | 切平台 / 时间范围 | 观察升级效果 |
| 单行日志 | 查看详情 | 展开 `extra_json` |

##### BZ. `group settings` provider / controller / 接口对照

###### BZ.1 当前 provider 层结论

当前已存在：

1. `groupSettingsRemoteDataSourceProvider`
2. `groupSettingsRepositoryProvider`
3. `groupSettingsControllerProvider`
4. `groupMembersControllerProvider`

说明：

1. `group settings` 已具备完整 provider 装配骨架
2. 当前问题不在装配缺失，而在 controller 与页面能力还没完全串到真实接口

###### BZ.2 `GroupSettingsController` 当前字段与接口对照

| State 字段 | 当前来源 | 接口来源 | 当前状态 |
|---|---|---|---|
| `groupName` | `getGroupSettings()` | `/system/im/group/get` | `connected` |
| `memberCount` | `getGroupSettings()` | `/system/im/group/get` | `connected` |
| `ownerUserId` | `getGroupSettings()` | `/system/im/group/get` | `connected` |
| `noDisturb` | `getGroupSettings()` + `updateNoDisturb()` | `/system/im/conversation/get-by-target` + `/system/im/conversation/update` | `connected` |
| `pinned` | `getGroupSettings()` + `updatePinned()` | `/system/im/conversation/get-by-target` + `/system/im/conversation/update` | `connected` |
| `muteAll` | `getGroupSettings()` + `updateMuteAll()` | `/system/im/group/get` + `/system/im/group/mute-all` | `connected` |
| `allowMemberInvite` | `getGroupSettings()` + `updateGroupManageOptions()` | `/system/im/group/get` + `/system/im/group/update` | `connected` |
| `needApproval` | `getGroupSettings()` + `updateGroupManageOptions()` | `/system/im/group/get` + `/system/im/group/update` | `connected` |
| `myNickname` | `getGroupSettings()` + `updateMyNickname()` | `/system/im/group/get` + `/system/im/group/member/set-nickname` | `connected` |
| `pendingRequestCount` | `getPendingJoinRequestCount()` | `/system/im/group/join-request/pending-count` | `connected` |
| `members preview` | `getGroupMembers()` | `/system/im/group/member/list` | `connected` |

当前差距：

1. `group settings` 主开关项当前已全部具备真实读写口
2. 后续仅在后端新增额外群管理字段时，再补 controller/state 映射

###### BZ.3 `GroupMembersController` 当前字段与接口对照

| 能力 | 当前状态 | 接口建议 |
|---|---|---|
| 搜索关键字 | 本地过滤 | `/system/im/group/member/list` + keyword 扩展或本地过滤 |
| 管理动作入口 | 详情页触发真实写口 | 无需额外 controller 选中态 |
| 单成员移除 | 已接真实写口 | `/system/im/group/member/remove` |
| 选中成员 / 批量移除 | 当前主路径未启用 | 若未来恢复，仍必须复用 `/system/im/group/member/remove` |

当前差距：

1. 当前页面主链路已不再依赖历史 `removeSelected()` 本地删数组方案
2. 若未来恢复批量移除 UI，也只能在真实接口基础上做批处理，不允许回退本地假删除

###### BZ.4 RemoteDataSource 当前已接真实接口

当前已确认：

- `/system/im/group/get`
- `/system/im/group/member/list`
- `/system/im/group/join-request/pending-count`
- `/system/im/group/invite/get`
- `/system/im/group/update`
- `/system/im/group/notice/update`
- `/system/im/group/member/set-nickname`
- `/system/im/group/mute-all`

说明：

1. datasource 已经比页面层更靠近真实能力
2. 后续页面替换的优先级应先补 controller 消费，不必再重新设计 datasource

###### BZ.5 下一步整改优先级

1. 给 `updateNoDisturb()` 接真实会话设置写口
2. 给 `updatePinned()` 接真实会话置顶写口
3. 给 `removeSelected()` 接 `/system/im/group/member/remove`
4. 给公告页接 `/system/im/group/get.notice` 与 `/notice/update`
5. 给二维码页接 `/system/im/group/invite/get` 与 `/generate`

##### CA. 当前这一轮继续后的结论

1. `upgrade` 平台端页面的操作按钮与状态流转已经可直接指导前后端联动开发
2. `group settings` 的 provider/controller 与真实接口差距也已明确到方法级
3. 后续若继续文档推进，优先建议：
   - `upgrade` 平台端页面字段级交互流程图
   - `group settings` 剩余写口与页面动作的逐页接线顺序

##### CB. `upgrade` 平台端页面字段级交互流程图

###### CB.1 应用管理页交互流

1. 进入页面
   - 调 `GET /platform-api/system/app-product/page`
2. 点击新增
   - 打开 `ProductForm`
   - 填：
     - `appCode`
     - `appName`
     - `appType`
     - `supportedPlatforms`
     - `defaultPlatform`
     - `defaultChannel`
3. 点击保存
   - `POST /platform-api/system/app-product/create`
4. 点击启停
   - `PUT /platform-api/system/app-product/update-status`
5. 列表刷新

###### CB.2 安装包管理页交互流

1. 进入页面
   - 调 `GET /platform-api/system/app-package/page`
2. 点击新增包
   - 打开 `PackageForm`
   - 填包元数据
   - 上传文件或录入外部 URL
3. 点击保存
   - `POST /platform-api/system/app-package/create`
4. 点击启用/禁用
   - `PUT /platform-api/system/app-package/enable`
   - `PUT /platform-api/system/app-package/disable`
5. 列表刷新

###### CB.3 发布管理页交互流

1. 进入页面
   - 调 `GET /platform-api/system/app-release/page`
2. 点击新建发布
   - 打开 `ReleaseForm`
   - 选择：
     - `appCode`
     - `packageId`
     - `platform`
     - `channel`
   - 填：
     - `releaseTitle`
     - `releaseNotes`
     - `forceUpdate`
     - `minSupportVersionCode`
     - `grayStrategy`
     - `publishStartTime/publishEndTime`
3. 点击保存
   - `POST /platform-api/system/app-release/create`
4. 点击发布 / 下线 / 回滚
   - `PUT /platform-api/system/app-release/publish`
   - `PUT /platform-api/system/app-release/offline`
   - `PUT /platform-api/system/app-release/rollback`
5. 列表刷新

###### CB.4 渠道分发管理页交互流

1. 进入页面
   - 调 `GET /platform-api/system/app-channel-release/page`
2. 点击新增渠道分发
   - 选择 `releaseId`
   - 填 `channelType/storeUrl/marketUrl/openTesting/phasedReleasePercent`
3. 点击保存
   - `POST /platform-api/system/app-channel-release/create`
4. 点击同步状态
   - `PUT /platform-api/system/app-channel-release/sync-status`
5. 列表刷新

###### CB.5 升级日志页交互流

1. 进入页面
   - 调 `GET /platform-api/system/app-upgrade-log/page`
   - 调 `GET /platform-api/system/app-upgrade-log/summary`
2. 修改筛选条件
   - 重新请求 page + summary
3. 点击详情
   - 展开 `extra_json`
4. 点击导出
   - 走平台导出能力

##### CC. `group settings` 逐页接线顺序

###### CC.1 现状补充

当前 state 级残留：

1. `GroupSettingsState.myNickname` 早期默认 `'马化腾'` 的 mock 残留已清理
2. `GroupMembersState.members` 早期本地默认成员数组已清理

说明：

1. 这两处历史 mock 残留当前均已从代码层移除：`completed`
2. 后续主要只做字段一致性复核，不再重复建设同类 state 占位

###### CC.2 建议接线顺序

第 1 步：`group_settings_page.dart` 主设置页

1. `pinned` 已接到真实会话设置写口：`completed`
2. `noDisturb` 已接到真实会话设置写口：`completed`
3. 保持：
   - `groupName`
   - `muteAll`
   - `myNickname`
   - `pendingRequestCount`
   的已接能力

第 2 步：`group_members_page.dart`

1. `GroupMembersController` 改为通过 repository 拉真实成员
2. 移除 `GroupMembersState.members` 默认 mock 数组
3. `removeSelected()` 改为先调：
   - `/system/im/group/member/remove`
   再刷新列表

第 3 步：`group_announcement_page.dart`

1. 打开页先读 `/system/im/group/get.notice`
2. 编辑后调 `/system/im/group/notice/update`
3. 成功后刷新主设置页快照

第 4 步：`group_qr_code_page.dart`

1. 打开页先读：
   - `/system/im/group/invite/get`
2. 无有效邀请码时可调：
   - `/system/im/group/invite/generate`
3. 替换 `_MockQrPainter`

第 5 步：`group_files_page.dart`

1. 打开页读 `/system/im/group/file/list`
2. 文件打开走：
   - 文件预览统一策略
3. 若支持删除：
   - `/system/im/group/file/delete?id=...`

第 6 步：`group_chat_history_page.dart`

1. 这是复杂度最高的一页
2. 打开页接：
   - `/system/im/message/search`
3. 点击结果跳聊天锚点：
   - `chatId + messageId`

###### CC.3 provider / repository 调整顺序

建议顺序：

1. 先扩 `GroupSettingsRepository`
2. 再补 `RemoteDataSource`
3. 再改 `Controller`
4. 最后改页面

原因：

1. 先把数据访问层统一收口
2. 避免页面直接粘接口

##### CD. 当前这一轮继续后的结论

1. `upgrade` 平台端控制台已经补到字段级交互流程图
2. `group settings` 已经补到逐页接线顺序和 provider/controller 收口顺序
3. 后续若继续文档推进，优先建议：
   - `upgrade` 平台端导出/审核/同步状态等边界操作细则
   - `group settings` repository/datasource 方法清单冻结

##### CE. `upgrade` 边界操作细则

###### CE.1 发布操作边界

`发布` 前必须满足：

1. `package.assetStatus = READY`
2. `release.publishStatus in (APPROVED, PENDING_PUBLISH)`
3. 若 `forceUpdate=true`，必须填写：
   - `minSupportVersionCode`
   - `releaseNotes`
4. 若 `distributionMode` 依赖外部市场：
   - 渠道分发记录已存在

`发布` 后限制：

1. 不允许直接修改：
   - `packageId`
   - `platform`
   - `versionCode`
2. 只允许：
   - 下线
   - 回滚
   - 查看

###### CE.2 下线操作边界

1. 仅 `PUBLISHED` 状态可下线
2. 下线后客户端不再命中新版本
3. 历史升级日志仍保留，不做物理删除

###### CE.3 回滚操作边界

1. 仅 `PUBLISHED` 状态可回滚
2. 回滚后必须恢复到上一个有效发布单
3. 不能出现客户端 `check()` 无可用发布单的空窗

###### CE.4 渠道状态同步边界

1. 同步状态失败不能阻断页面查看
2. 但必须记录：
   - `syncStatus`
   - `syncMessage`
   - `syncTime`
3. 后续应尽量走真实同步，而不是长期人工维护市场状态

###### CE.5 导出与统计边界

1. 日志导出只导出当前筛选结果
2. 摘要统计默认按时间范围聚合
3. 客户端升级日志与平台操作审计日志分开

##### CF. `group settings` repository / datasource 方法清单冻结

###### CF.1 Repository 建议最小方法集合

当前已存在并建议保留：

- `getGroupSettings(groupId)`
- `getGroupMembers(groupId)`
- `getGroupInviteInfo(groupId)`
- `updateGroupName(groupId, groupName)`
- `updateGroupNotice(groupId, notice)`
- `updateMyNickname(groupId, nickname)`
- `updateMuteAll(groupId, muted)`

建议补齐：

- `updateConversationPinned(chatId, pinned)`
- `updateConversationNoDisturb(chatId, noDisturb)`
- `removeGroupMembers(groupId, memberUserIds)`
- `generateGroupInvite(groupId, expireHours, maxUseCount)`
- `getGroupFiles(groupId, pageNo, pageSize, keyword?)`
- `deleteGroupFile(fileId)`
- `searchGroupMessages(chatId, keyword, filters...)`

###### CF.2 RemoteDataSource 建议最小方法集合

当前已存在并建议保留：

- `getGroup(groupId)`
- `getGroupMembers(groupId)`
- `getPendingJoinRequestCount(groupId)`
- `getGroupInviteCode(groupId)`
- `updateGroupName(groupId, groupName)`
- `updateGroupNotice(groupId, notice)`
- `updateMyNickname(groupId, nickname)`
- `updateMuteAll(groupId, muted)`

建议补齐：

- `updateConversationPinned(chatId, pinned)`
  - 接口建议：`/system/im/conversation/update`
- `updateConversationNoDisturb(chatId, noDisturb)`
  - 接口建议：`/system/im/conversation/update`
- `removeGroupMembers(groupId, memberUserIds)`
  - 接口建议：`/system/im/group/member/remove`
- `generateGroupInvite(groupId, expireHours, maxUseCount)`
  - 接口建议：`/system/im/group/invite/generate`
- `getGroupFiles(groupId, pageNo, pageSize, keyword?)`
  - 接口建议：`/system/im/group/file/list`
- `deleteGroupFile(fileId)`
  - 接口建议：`/system/im/group/file/delete?id=...`
- `searchGroupMessages(chatId, keyword, filters...)`
  - 接口建议：`/system/im/message/search`

###### CF.3 DTO 字段冻结补充

`GroupInfoDto` 当前已承接：

- `groupId`
- `groupName`
- `ownerUserId`
- `memberCount`
- `notice`
- `noDisturb`
- `pinned`
- `muteAll`
- `allowMemberInvite`
- `needApproval`
- `myNickname`

`GroupInviteInfoDto` 当前已承接：

- `groupId`
- `inviteCode`
- `expireAt`
- `needApproval`

建议后续补：

- `maxUseCount`
- `currentUseCount`
- `qrCodeUrl`

`GroupMemberDto` 当前已承接：

- `userId`
- `userName`
- `nickname`
- `role`
- `avatarUrl`
- `isMuted`

建议后续补：

- `joinTime`
- `muteEndTime`

###### CF.4 接线执行顺序

建议顺序：

1. 先补 `conversation.update` 两个写口：
   - `pinned`
   - `noDisturb`
2. 再补成员移除接口
3. 再补二维码生成接口
4. 再补群文件列表/删除
5. 最后补群聊天记录搜索

##### CG. 当前这一轮继续后的结论

1. `upgrade` 边界操作细则已经补清
2. `group settings` repository / datasource 方法清单已冻结到接口级
3. 后续若继续文档推进，优先建议：
   - `upgrade` 平台端页面校验规则与错误提示口径
   - `group settings` DTO/State/页面字段三层对照

##### BN. `contacts` 差距字段真实来源补充

###### BN.1 `contacts_page.dart`

字段差距与建议来源：

| 字段 | 当前状态 | 建议来源 | 说明 |
|---|---|---|---|
| `chatId` | 缺失 | `/system/im/conversation/get-by-target` | 点击发消息时再懒取，不建议列表预拉 |
| `phoneMasked` | 当前用 `postName` 顶替 | 不建议列表展示 | 若保留，应来自 `/system/user/get` 的手机号脱敏 |
| `email` | 缺失 | `/system/user/get` | 更适合详情页，不建议主列表直出 |
| `officeLocation` | 缺失 | 当前无明确接口 | 无真实来源前不建议继续保留 |

###### BN.2 `my_groups_page.dart`

字段差距与建议来源：

| 字段 | 当前状态 | 建议来源 | 说明 |
|---|---|---|---|
| `avatarUrl` | 已消费 | `/system/im/group/list` | 群列表头像已真实显示；失败时回退本地图标 |
| `groupId` 跳转 | 已接 | `RouteNames.groupSettings` + `GroupContextArgs(groupId)` | 已可进入真实群设置页 |

###### BN.3 `my_department_page.dart`

字段差距与建议来源：

| 字段 | 当前状态 | 建议来源 | 说明 |
|---|---|---|---|
| 成员副标题 | 用 `postName/departmentName` 混代 | `/system/user/get` 的 `postName/mobile` | 当前代码已按岗位优先回退部门；若未来要展示电话，需后端稳定返回手机号脱敏字段 |
| `activeDept` | 已支持显式切换 | `/system/dept/my-dept-tree` | 已支持 `initialDeptId` 与顶部部门 chip 切换；无选中态时才回退首个部门 |

###### BN.4 `org_browser_page.dart`

字段差距与建议来源：

| 字段 | 当前状态 | 建议来源 | 说明 |
|---|---|---|---|
| `deptId` 路由消费 | 已接 | `/system/dept/org-tree` 自带 `deptId` | 已支持点部门进入成员页 |

###### BN.5 `contact_search_result_page.dart`

字段差距与建议来源：

| 字段 | 当前状态 | 建议来源 | 说明 |
|---|---|---|---|
| 联系人点击跳转 | 已接 | `searchContacts` 返回 `userId` | 已进入联系人详情页 |
| 部门点击跳转 | 已接 | `org-tree` / 未来部门搜索接口 `deptId` | 已进入部门页 |
| `chatId` | 缺失 | `/system/im/conversation/get-by-target` | 从联系人结果发消息时再懒取 |

##### BO. 当前这一轮继续后的结论

1. `upgrade` 专题当前已经补到“平台端统一发布治理 + 多平台技术路线 + 灰度命中规则”
2. `contacts` 页面差距已经继续细化到“每个缺字段建议来自哪个真实接口”
3. 后续若继续文档推进，优先建议：
   - `upgrade` 平台管理端 CRUD / 审核流 / 渠道状态细则
   - `group settings` 占位页逐页真实能力替换方案

##### BL. `contacts` 页面逐页字段差距清单

###### BL.1 `contacts_page.dart`

当前真实消费：

- `name`
- `departmentName`
- `userId`

当前差距：

1. 顶部快捷入口已接真实路由：
   - 我的群组
   - 我的关注
   - 组织结构
   - 我的部门
2. 联系人主列表当前已展示真实头像（失败时回退首字母头像），但仍未展示：
   - `chatId`
   - `email`
   - `officeLocation`
3. 搜索入口当前仍是本地 sheet 交互，但结果页路由与真实搜索结果已接通

###### BL.2 `my_groups_page.dart`

当前真实消费：

- `groupId`
- `name`
- `memberCount`
- `avatarUrl`

当前差距：

1. 页面当前已展示：
   - 群名
   - 人数
   - 真实群头像（失败时回退本地图标）
2. 当前主跳转已走真实 `groupId -> group settings`
3. 后续若继续下钻，再考虑是否需要从“我的群组”直接进入群会话页

###### BL.3 `my_department_page.dart`

当前真实消费：

- `deptId`
- `deptName`
- 成员列表按真实 `deptId` 拉取
- 顶部部门切换已驱动真实成员重拉

当前差距：

1. 成员副标题当前仍以 `postName/departmentName` 混代
2. 若后续要精确区分“岗位/电话/部门”，仍需先明确后端稳定字段来源

###### BL.4 `org_browser_page.dart`

当前真实消费：

- `deptId`
- `name`
- `memberCount`

当前差距：

1. 当前已支持点部门进入 `my_department_page.dart`
2. 后续仅在需要展示更多组织层级字段时，再补充二级摘要信息

###### BL.5 `contact_search_result_page.dart`

当前真实消费：

- 联系人结果点击进入联系人详情
- 部门结果点击进入部门页
- `userId/deptId/departmentName`

当前差距：

1. 联系人结果当前仍未直接提供“发消息”快捷动作
2. `chatId` 仍维持按 `/system/im/conversation/get-by-target` 懒取的口径，不建议结果列表预拉

##### BM. 当前这一轮继续后的结论

1. `upgrade` 专题已进一步冻结到 SQL / 状态机 / 示例 JSON 粒度
2. `contacts` 页面差距已经拆到逐页级别
3. 后续若继续文档推进，更合适的下一步是：
   - 升级专题补灰度命中规则与平台管理端状态机细则
   - contacts 页面每个差距点补“应来自哪个真实接口字段”

##### BN2. `upgrade` 平台端页面校验规则与错误提示口径

###### BN2.1 `product/index.vue`

表单校验：

1. `appCode`：必填，`[a-z0-9._-]{2,64}`，创建后不可修改
2. `appName`：必填，长度 `2-50`
3. `tenantScopeType`：必填，必须使用后端字典值
4. `defaultUpgradeStrategy`：必填，必须使用后端枚举值

错误提示口径：

- `appCode` 重复：提示“应用编码已存在”
- 存在关联发布记录禁止删除：提示“当前产品存在关联发布记录，不允许删除”
- 有字段级错误时优先展示服务端字段消息，没有时再落通用 toast

###### BN2.2 `package/index.vue`

表单校验：

1. `productId`：必填
2. `platform`：必填，创建后不可修改
3. `versionName`：必填，建议格式 `1.2.3`
4. `versionCode`：必填，正整数
5. `distributionMode` 对应的资源字段必须齐全：
   - 直装包：`fileUrl/fileSize/fileSha256`
   - 应用市场：`marketPackageId`
   - Web：`webManifestUrl` 或等价资源地址

错误提示口径：

- 平台与包类型不匹配：提示“当前平台与安装包类型不匹配”
- `versionCode` 冲突：提示“该平台版本号已存在”
- 上传未完成：提示“安装包资源未就绪，请先完成上传”

###### BN2.3 `release/index.vue`

表单校验：

1. `packageId`：必填，且包状态必须为 `READY`
2. `releaseScopeType`：必填
3. `releaseNotes`：必填，`forceUpdate=true` 时不允许为空
4. `minSupportVersionCode`：强更时必填，且必须小于当前 `versionCode`
5. `grayRuleJson`：灰度发布时必填，且必须是合法 JSON
6. `effectiveTimeRange`：定时发布时必填

错误提示口径：

- 升级说明缺失：提示“请填写升级说明”
- 强更范围错误：提示“最低支持版本必须小于当前发布版本”
- 灰度规则非法：提示“灰度规则格式错误”
- 已发布单据修改核心版本字段：提示“已发布版本不允许修改核心信息”

###### BN2.4 `channelRelease/index.vue`

表单校验：

1. `releaseId`：必填
2. `channelCode`：必填
3. `distributionStatus`：只允许按状态机流转
4. 外部市场渠道必须补：
   - `marketTrack`
   - `marketReleaseId` 或等价外部单号
5. `rolloutPercent`：灰度范围 `1-100`

错误提示口径：

- 渠道重复：提示“该发布单已存在相同渠道记录”
- 市场单号缺失：提示“请先补充渠道发布凭证”
- 非法回退：提示“当前渠道状态不允许回退”

###### BN2.5 `upgradeLog/index.vue`

筛选校验：

1. `timeRange` 最大跨度建议 `31` 天
2. `platform/eventType/resultCode` 只允许枚举值
3. 导出前必须至少带时间范围

错误提示口径：

- 时间跨度过大：提示“查询时间范围不能超过31天”
- 无筛选直接导出：提示“请先选择导出范围”
- 摘要接口失败不阻断列表展示，只提示“统计数据加载失败”

###### BN2.6 页面统一错误处理约束

1. 平台端表单页统一区分三类错误：
   - 字段校验错误：字段下提示
   - 状态机错误：toast + 保留当前表单
   - 外部渠道同步错误：toast + 展示 `syncMessage`
2. 页面禁止通过“已发布/待审核”等中文文案反推逻辑，必须基于：
   - `publishStatus`
   - `distributionStatus`
   - `auditStatus`
3. 删除、下线、回滚前必须以后端最新详情二次确认为准，不能只依赖列表旧值

##### BO2. `group settings` DTO / State / 页面字段三层对照

###### BO2.1 `GroupSettingsSnapshot -> GroupSettingsState -> GroupSettingsPage`

| 服务端/DTO 字段 | Domain 实体字段 | State 字段 | 页面消费位置 | 备注 |
|---|---|---|---|---|
| `/system/im/group/get` `id/groupId` | `groupId` | 路由参数持有 | 全页基础上下文 | 当前 `State` 未单列 `groupId`，由 `args.groupId` 承接 |
| `/system/im/group/get` `groupName` | `groupName` | `groupName` | 标题、群名称设置项、二级页标题 | 已真实接线 |
| `/system/im/group/get` `ownerUserId` | `ownerUserId` | `ownerUserId` | 群主标识、成员操作权限 | 后续应结合当前登录用户决定是否显示移除入口 |
| `/system/im/group/get` `memberCount` | `memberCount` | `memberCount` | 群资料卡“xx人” | 已真实接线 |
| `/system/im/group/get` `notice` | `notice` | `notice` | 群公告页正文、群设置页公告摘要 | 已入 `GroupSettingsState`，并配套 `PUT /system/im/group/notice/update` |
| `/system/im/conversation/get-by-target` `muteStatus` 或等价字段 | `noDisturb` | `noDisturb` | 消息免打扰开关 | 已通过 `/system/im/conversation/update` 接真实写口 |
| `/system/im/conversation/get-by-target` `topStatus` 或等价字段 | `pinned` | `pinned` | 置顶聊天开关 | 已通过 `/system/im/conversation/update` 接真实写口 |
| `/system/im/group/get` `muteAll` | `muteAll` | `muteAll` | 全员禁言开关 | 已具备真实写口 |
| `/system/im/group/get` `allowMemberInvite` | `allowMemberInvite` | `allowMemberInvite` | 允许成员邀请开关 | 已通过 `/system/im/group/update` 接真实写口 |
| `/system/im/group/get` `needApproval` | `needApproval` | `needApproval` | 入群需确认开关 | 已通过 `/system/im/group/update` 接真实写口 |
| `/system/im/group/get` `myNickname` | `myNickname` | `myNickname` | 我在本群昵称设置项 | 已具备真实写口；默认 mock 昵称已移除 |
| `/system/im/group/join-request/pending-count` 数值 | `pendingJoinRequestCount` | `pendingRequestCount` | 入群申请设置项右侧文案 | 已改单列数值字段，由页面负责格式化 |

###### BO2.2 `GroupMemberDto -> GroupMember -> GroupMemberPreviewItem / GroupMembersState`

| 服务端/DTO 字段 | Domain 实体字段 | State 字段 | 页面消费位置 | 备注 |
|---|---|---|---|---|
| `userId` | `userId` | `GroupMemberPreviewItem.id` | 成员预览、成员列表、移除动作 | 已真实接线 |
| `nickname` + `userName` | `nickname/userName` | `GroupMemberPreviewItem.name` | 成员昵称展示 | 当前已按“昵称优先，用户名兜底” |
| `role` | `role` | `roleCode` | 成员角色标识、权限判断 | 逻辑必须始终基于数值枚举 |
| `avatarUrl` | `avatarUrl` | `GroupMemberPreviewItem.avatarUrl` | 群设置首页成员预览、成员列表与成员详情头像展示 | 已真实接线；图片失败时回退本地首字母头像 |
| `isMuted` | `isMuted` | `GroupMemberPreviewItem.isMuted` | 成员禁言标识、详情页禁言按钮文案 | 已真实接线 |
| `joinTime` | `joinTime` | `GroupMemberPreviewItem.joinTime` | 成员详情入群时间展示 | 已真实接线，空值时页面展示未知 |
| `muteEndTime` | `muteEndTime` | `GroupMemberPreviewItem.muteEndTime` | 成员详情禁言截止时间展示 | 已真实接线；未返回时展示未知 |

约束：

1. `GroupMembersState.members` 不应继续保留默认 mock 数组
2. 成员移除动作必须统一走 `/system/im/group/member/remove`
3. 详情页或成员页移除成功后，必须回源刷新群成员列表与群设置快照
4. 页面角色文案“群主/管理员/成员”只允许做展示，不允许反向参与逻辑判断

###### BO2.2A `GroupJoinRequestItemDto -> GroupJoinRequestItem -> GroupJoinRequestsPage`

| 服务端/DTO 字段 | Domain 实体字段 | 页面消费位置 | 当前状态 |
|---|---|---|---|
| `applicantNickname` | `applicantNickname` | 申请人昵称、首字母回退头像 | 已真实接线；空值时回退未知成员文案 |
| `applicantAvatar` | `applicantAvatar` | 申请列表头像 | 已真实接线；兼容 `applicantAvatar/avatarUrl/avatar`，图片失败时回退首字母头像 |
| `status/createTime/handledTime/rejectReason` | 同名字段 | 待处理/已处理标签、申请时间、处理时间、拒绝结果 | 已真实接线；时间解析兼容字符串与毫秒值 |

###### BO2.3 `GroupInviteInfoDto -> GroupInviteInfo -> GroupQrCodePage`

| 服务端/DTO 字段 | Domain 实体字段 | 页面消费位置 | 当前状态 |
|---|---|---|---|
| `groupId` | `groupId` | 分享参数 | 已具备实体 |
| `inviteCode` | `inviteCode` | 二维码内容、分享链接拼装 | 已改为真实邀请码展示与复制，不再保留 mock QR |
| `expireAt` | `expireAt` | 有效期文案 | 已展示真实有效期 |
| `needApproval` | `needApproval` | 扫码入群审批提示 | 已真实消费 |
| `qrCodeUrl`（建议补） | `qrCodeUrl` | 直接渲染二维码图片 | 若后端返回 `qrCodeUrl/qrUrl/qrImageUrl` 则优先渲染；否则回退邀请码占位图 |

约束：

1. 若后端只返回 `inviteCode`，二维码生成可以在客户端做，但必须基于真实 `inviteCode`
2. 若后端未来返回 `qrCodeUrl/base64`，则优先消费服务端产物，不再自绘 mock 方块
3. `expireAt`、`needApproval` 解析需兼容时间字符串/毫秒值与布尔/数值口径

###### BO2.4 群公告 / 群文件 / 群聊天记录页字段口径

1. `group_announcement_page.dart`
   - 读：`/system/im/group/get` `notice`
   - 写：`PUT /system/im/group/notice/update`
   - 当前状态：`completed`
2. `group_files_page.dart`
   - 读：`GET /system/im/group/file/list`
   - 核心字段：`fileId/fileName/fileSize/uploadTime/uploaderName/fileExt/downloadUrl`
   - 删除：`DELETE /system/im/group/file/delete?id=...` 或等价接口
   - `fileSize/uploadTime/mimeType` 解析已兼容字符串数值、毫秒时间、`contentType`
   - 当前状态：`completed`
3. `group_chat_history_page.dart`
   - 读：`GET /system/im/message/search`
   - 核心字段：`messageId/senderId/senderName/messageType/previewText/sendTime`
   - 筛选项必须基于真实枚举字段，不基于“文件/图片/链接”中文标签判断
   - `messageType` 摘要兜底文案已补齐到 `image/file/location/contactCard/system/text`
   - 当前状态：`completed`

###### BO2.5 `State` 结构收敛建议

建议后续 `GroupSettingsState` 最小真实字段集合补成：

- `groupId`
- `groupName`
- `ownerUserId`
- `memberCount`
- `notice`
- `noDisturb`
- `pinned`
- `muteAll`
- `allowMemberInvite`
- `needApproval`
- `myNickname`
- `pendingJoinRequestCount`
- `memberPreviewItems`
- `error`

建议去掉或弱化的占位字段：

- `pendingRequestLabel`：已收敛为页面基于 `pendingRequestCount` 数值格式化：`completed`
- 默认 `groupName = '群聊设置'`
- 默认 `myNickname = '马化腾'`：已移除：`completed`

##### BO3. `favorite / global search` DTO / State / 页面字段对照

###### BO3.1 `FavoriteItemDto -> FavoriteItem -> FavoritesPage`

当前 Flutter 文件：

- `lib/features/im/favorite/infrastructure/dtos/favorite_item_dto.dart`
- `lib/features/im/favorite/domain/entities/favorite_item.dart`
- `lib/features/im/favorite/presentation/controllers/favorites_controller.dart`
- `lib/features/im/favorite/presentation/pages/favorites_page.dart`

接口依据：

- `GET /system/im/favorite/list`
- `GET /system/im/favorite/search`
- `DELETE /system/im/favorite/remove`

字段对照：

| 服务端/DTO 字段 | Domain 实体字段 | State / 页面消费位置 | 当前口径 |
|---|---|---|---|
| `favoriteId` / `id` | `favoriteId` | 删除收藏、打开详情、后续转发写口 | 已真实接线 |
| `messageId` / `sourceMessageId` | `messageId` | 点击收藏项后跳聊天锚点 | 已真实接线 |
| `sourceChatId` / `chatId` | `chatId` | `RouteNames.chat` 跳转入参 | 已真实接线 |
| `conversationType` / `sourceConversationType` / `chatType` | `conversationType` | 直聊/群聊路由类型、卡片图标色块 | 已真实接线；兼容 `group/direct/single/private/1/2`，逻辑基于枚举，不基于中文文案 |
| `title` / `conversationName` / `sourceChatName` / `sourceConversationName` / `chatName` | `title` | 列表主标题、聊天页标题 | 已真实接线 |
| `summary` / `contentSummary` / `messageSummary` / `previewText` / `content` | `summary` | 列表摘要文本 | 已真实接线 |
| `senderName` / `sourceSenderName` / `senderNickname` | `senderName` | 列表副标题元信息 | 已真实接线 |
| `messageType` / `type` | `messageType` | 列表类型标签、后续详情页组件分流 | 当前只做展示，未进入详情组件分流 |
| `status` / `messageStatus` / `sourceMessageStatus` | `status` | 收藏失效态标签、阻止打开失效收藏 | 已接轻量消费；识别删除/撤回/不可用状态 |
| `createdTime` / `createTime` / `createdAt` / `favoriteTime` | `createdAt` | 列表时间显示 `MM-dd HH:mm` | 已真实接线；兼容时间字符串与毫秒值 |

页面消费规则：

1. 收藏列表页：
   - 默认走 `GET /system/im/favorite/list`
   - 有关键字时切到 `GET /system/im/favorite/search`
   - `tab` 只作为搜索条件，不作为本地假筛选
2. 点击收藏项：
   - 必须同时依赖 `chatId + messageId`
   - 页面进入聊天页时使用 `anchorMessageId/highlightedMessageId`
3. 删除收藏：
   - 写口只使用 `favoriteId`
   - 当前实现为成功后本地移除列表项，后续若补收藏详情页，详情页被删后应统一回退

当前明确差距：

1. Flutter 当前只落了收藏列表页，`favorite/detail` 与 `favorite/resend` 还未建真实页面：`pending`
2. `status` 已驱动“原消息已删除/已撤回/不可打开”等轻量失败态：`completed`
3. 收藏搜索与列表接口当前都只消费 `list` 数组，未消费总数/分页总页数；当前维持滚动列表口径：`accepted_current_scope`

###### BO3.2 `MessageSearchItemDto -> MessageSearchItem -> SearchChatHistoryPage`

当前 Flutter 文件：

- `lib/features/im/search/infrastructure/dtos/message_search_item_dto.dart`
- `lib/features/im/search/domain/entities/message_search_item.dart`
- `lib/features/im/search/presentation/pages/search_chat_history_page.dart`
- `lib/features/im/chat/infrastructure/datasources/message_remote_data_source.dart`

接口依据：

- `GET /system/im/message/search`

字段对照：

| 服务端/DTO 字段 | Domain 实体字段 | 页面消费位置 | 当前口径 |
|---|---|---|---|
| `id` / `messageId` | `id` / `messageId` | 列表 key、跳聊天锚点 | 已真实接线 |
| `chatId` / `sourceChatId` | `chatId` | 跳聊天页主入参 | 已真实接线 |
| `sequence` / `sortKey` | `sequence` | `anchorSequence`，用于更稳定跳锚点 | 已真实接线 |
| `conversationName` / `chatName` / `title` / `sourceChatName` / `targetName` | `conversationName` | 列表标题、聊天页标题 | 已真实接线；不再错误回退到发送人名称 |
| `senderName` / `senderNickname` / `nickname` | `senderName` | 元信息展示 | 已真实接线 |
| `content` / `snippet` | `content/snippet` | 命中摘要文本 | 已优先消费服务端 `snippet`，缺失时回退 `content` 与本地高亮 |
| `messageType` | `messageType` | 摘要兜底文案分流 | 已真实接线 |
| `timestamp` / `sendTime` / `createTime` | `timestamp` | 右上角时间展示 | 已真实接线；兼容时间字符串与毫秒值 |
| `conversationType` | `conversationType` | 直聊/群聊路由分流 | 已真实接线 |
| `targetId` / `receiverId` | `targetId` | 直聊目标用户或群聊兜底 target | 已真实接线 |
| `groupId` / `targetGroupId` | `groupId` | 群聊路由 targetId 优先值 | 已真实接线 |
| `highlight` | `highlight` | 命中片段展示兜底 | 已接字段透传；当前页面优先 `snippet`，无 `snippet` 时可回退 `highlight` |

页面消费规则：

1. 全局搜索页当前只以 `keyword/pageNo/pageSize` 为主参数，请求 `GET /system/im/message/search`
2. 页面跳转聊天锚点优先级：
   - `chatId`
   - `sequence`
   - `messageId`
3. 群聊判断当前基于 `conversationType == 2` 或 `groupId` 非空
4. `messageType` 只用于摘要兜底文案，不能反向决定消息权限或会话归属

当前明确差距：

1. 当前 Flutter 已接入 `snippet/highlight` 字段透传，页面优先消费服务端命中片段，仍保留本地关键词高亮作为兜底：`completed`
2. 当前全局搜索页未暴露 `category/tab/startTime/endTime` 等进阶筛选：`accepted_current_scope`
3. 若后端后续把 `conversationType` 改为枚举字符串，DTO 层必须先做统一映射，再进入页面逻辑：`frozen_rule`

##### BP2. 当前这一轮继续后的结论

1. `upgrade` 平台端页面已经补到字段级表单校验与错误提示口径
2. `group settings` 已补到 DTO/Entity/State/页面消费四层对照
3. `favorite / global search` 已补到 DTO/Entity/页面消费与当前差距对照
4. 后续若继续文档推进，优先建议：
   - `contacts/group settings/upgrade` 页面动作级前置校验与失败分支补录
   - 音视频通话专题补服务端接口目录、信令命令与中间件职责的最终汇总表

##### BQ2. `contacts / group settings / upgrade` 页面动作级前置校验与失败分支

###### BQ2.1 `contacts` 页面动作级规则

| 页面动作 | 接口依据 | 前置校验 | 失败分支 | 页面收口 |
|---|---|---|---|---|
| 联系人发消息 | `/system/im/conversation/get-by-target` | 必须拿到 `targetId`，`conversationType=single` | 接口失败或返回空 `chatId` | toast 后停留当前页，不允许本地伪造会话 |
| 联系人详情关注/取消关注 | `/system/im/contact/setting/update` | 需先有 `contactId`；按钮状态以详情接口真实字段为准 | `contactId` 无效、权限不足、关系不存在 | 回滚 toggle，刷新详情 |
| 我的部门切换部门 | `/system/dept/my-dept-tree` `/system/im/contact/list-by-dept` | 必须使用真实 `deptId`，不允许永远默认首个部门 | `deptId` 失效或部门已删除 | 清空成员列表，提示“部门信息已变化”，要求重新选择 |
| 组织架构点部门进入成员页 | `/system/dept/org-tree` `/system/dept/dept-members` | 必须存在真实 `deptId` | 部门无权限或无成员 | 进入空态，不使用本地假成员填充 |
| 搜索结果联系人发消息 | `/system/im/conversation/get-by-target` | 必须由搜索结果真实 `userId` 发起 | `userId` 为空、会话创建失败 | toast，保留搜索结果列表 |
| 我的群组进入群会话/群详情 | `/system/im/group/get` `/system/im/conversation/get-by-target` | 必须存在真实 `groupId`；群会话需用 `conversationType=group` | 群已解散、当前用户已退群 | 刷新列表并移除失效项 |

约束：

1. `contacts` 域页面任何跳转动作，都必须依赖真实 `userId/deptId/groupId/chatId`
2. 失败时优先刷新来源列表，不允许继续使用 `contacts_mock_data.dart` 兜底
3. 页面逻辑禁止根据“已关注/未关注”“我的部门”等中文标签反推接口参数

###### BQ2.2 `group settings` 页面动作级规则

| 页面动作 | 接口依据 | 前置校验 | 失败分支 | 页面收口 |
|---|---|---|---|---|
| 免打扰开关 | `/system/im/conversation/update` | 必须先拿到真实 `chatId`；状态来自会话详情 | 写入失败 | toggle 回滚，toast 提示 |
| 置顶聊天开关 | `/system/im/conversation/update` | 必须先拿到真实 `chatId` | 写入失败 | toggle 回滚，列表和详情都以服务端返回为准 |
| 全员禁言开关 | `/system/im/group/mute-all` | 当前用户必须具备 `myRole in (1,2)` 或等价权限字段 | 权限不足、群已解散 | 回滚 toggle，刷新群详情 |
| 修改群名称 | `/system/im/group/update` | 非空、长度合法；当前用户必须有修改权限 | 名称重复、长度超限、权限不足 | 保留编辑框内容，提示服务端消息 |
| 修改我在本群昵称 | `/system/im/group/member/set-nickname` | 非空、长度合法 | 写入失败 | 保留输入，不改本地 state |
| 群公告编辑保存 | `/system/im/group/notice/update` | 必须存在真实 `groupId`；当前用户具备公告修改权限 | 权限不足、群不存在 | 回退到服务端最新 `notice` |
| 移除群成员 | `/system/im/group/member/remove` | 当前用户需为群主/管理员；目标成员不能是群主；必须有真实 `memberUserId` | 权限不足、成员已不在群、角色冲突 | 清空选择集并重新拉成员列表 |
| 生成群邀请码/二维码 | `/system/im/group/invite/generate` | 需真实 `groupId`；若后端要求，当前用户需有邀请权限 | 权限不足、群已关闭邀请 | 停留当前页，提示后不渲染本地假二维码 |
| 处理入群申请 | `/system/im/group/join-request/approve` `/reject` | 必须有真实 `requestId`；当前用户需是审批人 | 请求已被他端处理、权限不足 | 刷新申请列表和待处理数 |
| 删除群文件 | `/system/im/group/file/delete` | 当前用户需具备文件管理权限；必须有真实 `fileId` | 文件已删除、无权限 | 刷新文件列表，不本地静默删除 |

约束：

1. `group settings` 所有写动作失败后，优先以“回滚本地 UI + 重新刷新详情/列表”为统一收口
2. 角色判断必须基于：
   - `myRole`
   - `member.role`
   - 或服务端显式权限字段
3. 二维码页、公告页、文件页、聊天记录页后续接真实功能时，不允许保留本地占位结果覆盖真实失败态

###### BQ2.3 `upgrade` 平台端页面动作级规则

| 页面动作 | 接口依据 | 前置校验 | 失败分支 | 页面收口 |
|---|---|---|---|---|
| 创建产品 | `POST /platform-api/system/app-upgrade-product/create` | `appCode/appName` 合法且未重复 | 编码冲突、租户范围非法 | 保留表单并定位字段错误 |
| 创建安装包 | `POST /platform-api/system/app-upgrade-package/create` | 资源必须上传完成；`platform/distributionMode/versionCode` 合法 | 资源未就绪、版本冲突 | 不清空上传结果，等待修正后重试 |
| 提交发布单审核 | `POST /platform-api/system/app-upgrade-release/submit-audit` | 发布单状态必须是 `DRAFT` 或等价待提审态 | 已提审、状态冲突 | 刷新详情，按钮按最新状态重绘 |
| 审核通过/驳回 | `POST /platform-api/system/app-upgrade-release/audit` | 当前操作人必须有审核权限；必须带 `auditStatus` 和意见 | 已被他人处理、权限不足 | 刷新列表和详情，不本地猜状态 |
| 发布渠道 | `POST /platform-api/system/app-upgrade-channel-release/publish` | 关联发布单必须 `APPROVED`；包资源就绪；外部渠道凭证完整 | 渠道重复、市场凭证缺失、状态冲突 | 保持渠道表单，展示 `syncMessage` |
| 下线渠道 | `POST /platform-api/system/app-upgrade-channel-release/offline` | 当前状态必须为 `PUBLISHED` | 已下线、状态冲突 | 刷新渠道详情和主发布单状态 |
| 回滚发布 | `POST /platform-api/system/app-upgrade-release/rollback` | 必须存在上一个有效发布单 | 无可回滚目标、状态冲突 | 刷新详情并提示，不本地切版本 |
| 同步市场状态 | `POST /platform-api/system/app-upgrade-channel-release/sync-status` | 必须存在外部市场发布单号 | 外部接口失败、市场状态未知 | 不阻断页面查看，只更新 `syncStatus/syncMessage` |
| 导出升级日志 | `GET /platform-api/system/app-upgrade-log/export` | 必须带筛选条件，至少有时间范围 | 参数非法、导出超限 | 保持筛选条件，提示用户缩小范围 |

约束：

1. `upgrade` 平台端所有操作按钮可用性必须基于真实状态字段，不允许本地拍脑袋启禁用
2. 涉及审核、发布、下线、回滚的动作，执行成功后必须重新拉详情，不允许只改表格行局部值
3. 外部市场类失败统一归到“同步失败但页面可继续查看”，不要误判为主业务失败

###### BQ2.4 `contacts / group settings / upgrade` 空态 / 权限态 / 并发态口径

`contacts`：

| 场景 | 后端依据 | 页面处理 |
|---|---|---|
| 联系人主列表为空 | `/system/im/contact/list` 空数组 | 展示真实空态，不回退 `contacts_mock_data.dart` |
| 我的群组为空 | `/system/im/group/list` 空数组 | 展示“暂无群组”空态，不显示 `--` 占位文本 |
| 我的部门无部门树 | `/system/dept/my-dept-tree` 空数组 | 展示部门空态，隐藏成员列表区域 |
| 部门存在但无成员 | `/system/im/contact/list-by-dept` 或 `/system/dept/dept-members` 空数组 | 进入成员空态，不伪造部门成员 |
| 联系人详情无权查看 | `get-profile/user-get` 返回权限错误 | 停留来源页或详情页错误态，不拼旧资料字段 |
| 发起单聊时会话创建失败 | `/system/im/conversation/get-by-target` 返回空 `chatId` 或错误码 | toast，保留当前联系人/搜索结果页 |
| 搜索结果在查看期间失效 | `/system/im/contact/search` 重拉后联系人不存在 | 保留搜索页，提示“结果已变化” |
| 他端已删好友/拉黑 | 联系人详情或发消息接口返回关系失效 | 刷新联系人列表，移除失效项或降级只读展示 |

`group settings`：

| 场景 | 后端依据 | 页面处理 |
|---|---|---|
| 群详情返回空或群已解散 | `/system/im/group/get` 空结果或业务错误码 | 退出群设置链路并刷新来源列表 |
| 群成员列表为空 | `/system/im/group/member/list` 空数组 | 展示真实空态，不保留默认成员预览 |
| 群申请列表为空 | `/system/im/group/join-request/list` 空数组 | 展示空态，待处理数以 `/pending-count` 为准 |
| 公告为空 | `/system/im/group/get.notice` 为空 | 展示“暂无公告”空态，不显示本地提示文案 |
| 群文件为空 | `/system/im/group/file/list` 空数组 | 展示文件空态，不保留本地常量数组 |
| 群聊天记录搜索为空 | `/system/im/message/search` 空数组 | 展示搜索空态，不展示占位记录 |
| 当前用户失去管理权限 | `myRole` 或显式权限字段变化 | 立即收起管理按钮，刷新详情与成员页 |
| 同一申请被他端先处理 | `/approve` `/reject` 返回状态冲突或重拉列表缺项 | 刷新申请列表与待处理数，不保留旧项 |
| 同一成员被他端先移除 | `/member/remove` 返回成员不存在 | 重拉成员列表并清空当前勾选 |
| 邀请码在他端已刷新 | `/invite/get` 与当前页 `inviteCode` 不一致 | 页面以最新邀请码覆盖，不继续显示旧二维码 |

`upgrade`：

| 场景 | 后端依据 | 页面处理 |
|---|---|---|
| 列表为空 | 各 `page` 接口返回空列表 | 展示真实空态，保留筛选条件 |
| 详情不存在 | `get?id=...` 返回空或已删除 | 关闭详情抽屉/返回列表，并刷新列表页 |
| 当前操作人无权限 | 平台权限点或接口返回权限错误 | 按钮禁用或点击后 toast，不本地猜测成功 |
| 发布单被他人先提审/审核 | `submit-audit/audit` 返回状态冲突 | 刷新详情与列表，按钮按最新状态重绘 |
| 渠道已被他端发布/下线 | `publish/offline` 返回状态冲突 | 刷新渠道列表与发布单详情 |
| 回滚目标已变化 | `rollback` 返回无有效目标或目标已变更 | 刷新详情并提示，不本地切换版本显示 |
| 市场同步超时或失败 | `sync-status` 返回 `syncStatus/syncMessage` 异常 | 保留详情页可读状态，仅标记同步失败 |
| 导出任务超限 | `export` 返回参数或范围错误 | 保留筛选条件，提示缩小时间范围 |

统一约束：

1. 三类页面都必须区分：
   - 空态
   - 权限态
   - 并发态
   - 请求失败态
2. 空态不等于失败态；失败态不允许被空态 UI 吃掉
3. 并发冲突统一以“刷新列表/详情并重绘按钮”为第一收口，不本地硬顶旧状态
4. 所有权限态都必须依赖真实字段或错误码，不允许通过中文按钮文案推断
5. 当前 Flutter 里仍存在的 `contacts_mock_data.dart`、`--` 占位文本、群页本地说明文案，后续都应按本节口径逐步替换

##### BR2. 音视频通话专题接口目录总表

###### BR2.1 App 端 REST 接口目录

| 接口 | 方法 | 作用 | 核心入参 | 核心出参 | 状态 |
|---|---|---|---|---|---|
| `/system/im/call/records` | `GET` | 当前用户通话记录分页 | `pageNo/pageSize/callType/status` | 记录列表、分页信息 | `proposed_required` |
| `/system/im/call/records-between` | `GET` | 当前用户与目标用户之间通话记录 | `targetUserId/pageNo/pageSize` | 双人通话记录列表 | `proposed_required` |
| `/system/im/call/detail` | `GET` | 断线恢复、推送回跳详情 | `callId` | `callId/state/callerId/calleeId/chatId/acceptedDeviceId` | `proposed_required` |
| `/system/im/call/turn-config` | `GET` | 获取 RTC 全局配置 | 无 | `rtcEnabled/stunServers/turnServers/janusWsUrl` | `proposed_required` |
| `/system/im/call/rtc-credential` | `GET` | 获取房间与 RTC 凭证 | `callId` | `rtcRoomId/token/expireAt/acceptedDeviceId` | `proposed_required` |
| `/system/im/call/active` | `GET` | 应用恢复时查询活跃通话 | 无 | `hasActiveCall/callId/state/entryModeSuggested` | `proposed_required` |

说明：

1. Phase 1 通话控制动作仍以 WS `CALL_SIGNAL` 为主，不额外设计一组与之并行的 REST 写接口
2. REST 主要承担：
   - 查询
   - 恢复
   - 凭证获取
   - 记录分页

###### BR2.2 WebSocket 信令命令目录

| `signalType` | 发起方 | 作用 | 核心字段 | 服务端处理主入口 |
|---|---|---|---|---|
| `CALL` | 主叫端 | 发起呼叫 | `callId/callType/calleeId/chatId` | `handleCall` |
| `ANSWER` | 被叫端 | 接听呼叫 | `callId/deviceId` | `handleAnswer` |
| `REJECT` | 被叫端 | 拒绝呼叫 | `callId/reason` | `handleReject` |
| `HANGUP` | 任一端 | 主动挂断 | `callId/deviceId` | `handleHangup` |
| `BUSY` | 服务端或被叫端 | 忙线裁决 | `callId` | `handleBusy` |
| `TIMEOUT` | 服务端 Job | 响铃/连接超时结束 | `callId/timeoutStage` | `handleTimeout` |
| `STATE_SYNC` | 服务端 | 多端/重连状态同步 | `callId/state/acceptedDeviceId` | `queryState + pushState` |
| `SDP_OFFER` | 主叫/应答端 | WebRTC offer 交换 | `callId/sdp` | `forwardCallSignal` |
| `SDP_ANSWER` | 对端 | WebRTC answer 交换 | `callId/sdp` | `forwardCallSignal` |
| `ICE_CANDIDATE` | 双端 | ICE 候选交换 | `callId/candidate/sdpMid/sdpMLineIndex` | `forwardCallSignal` |

约束：

1. `CALL/ANSWER/REJECT/HANGUP/BUSY/TIMEOUT/STATE_SYNC` 必须进入服务端状态机
2. `SDP_OFFER/SDP_ANSWER/ICE_CANDIDATE` 只做信令转发与权限校验，不改最终业务状态
3. `CALL_RECORD=209` 不属于动作命令，而是结束后由服务端生成的消息记录结果

##### BS2. 音视频通话专题中间件与服务职责汇总表

| 组件 | 职责 | 输入 | 输出 | 备注 |
|---|---|---|---|---|
| `CallSignalMessageProcessor` | WS 通话信令总入口 | `CALL_SIGNAL(206)` | 分发到具体 service | 只做解析、鉴权、路由 |
| `CallSignalService` | 通话状态机主服务 | `CALL/ANSWER/REJECT/HANGUP/BUSY/TIMEOUT` | 状态推进结果、事件落库 | 核心控制面 |
| `CallStateSyncService` | 查询与下发最新状态 | `callId/userId` | `CallStateSnapshot`、`STATE_SYNC` | 多端恢复核心 |
| `RtcCredentialService` | 房间/凭证发放 | `callId/userId` | `rtcRoomId/token/expireAt` | 必须校验参与者身份 |
| `CallPushService` | 离线推送与厂商通道适配 | 来电/未接听事件 | Push payload | 不拥有最终状态机裁决 |
| `CallRecordMessageFactory` | 生成 `CALL_RECORD=209` | 结束态通话记录 | `ImMessage` 记录消息 | 仅结束时调用 |
| `ImCallTimeoutJob` | 超时扫描 | 活跃通话记录 | 触发 `TIMEOUT` | 响铃/连接中都需覆盖 |
| `ImCallEventService` | 事件流水落库 | 任意关键通话事件 | `im_call_event` | 流程记录与排障 |
| `JanusGatewayAdapter` | Janus 房间/句柄适配 | 房间创建、销毁、attach | 网关调用结果 | 屏蔽底层网关差异 |
| `MessageStorageService` | 持久化消息链路 | `CALL_RECORD` | 会话预览、聊天消息 | 不处理瞬态信令 |

职责边界：

1. Processor 不直接写数据库
2. `CallSignalService` 不直接关心 Flutter 页面路由
3. `RtcCredentialService` 不裁决谁赢得接听，只消费状态机结果
4. `CallPushService` 只负责触达，不负责把推送成功当作接通成功
5. `MessageStorageService` 只接最终记录消息，不接瞬态通话信令

##### BT2. 当前这一轮继续后的结论

1. `contacts / group settings / upgrade` 三类页面的动作级前置校验与失败分支已补齐
2. `contacts / group settings / upgrade` 三类页面的空态 / 权限态 / 并发态口径也已补齐
3. 通话专题已收敛成：
   - App 端 REST 接口目录
   - WS 信令命令目录
   - 中间件/服务职责汇总表
4. 后续若继续文档推进，优先建议：
   - 通话专题补“接口入参/出参示例 JSON + 状态机迁移表最终版”
   - `contacts / group settings / upgrade` 继续回到代码层清理 mock / 占位态

##### BU2. 通话专题接口入参 / 出参示例 JSON 最终版

###### BU2.1 `GET /system/im/call/detail?callId=...`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "callId": "call_202605020001",
    "callType": 2,
    "state": "CONNECTING",
    "status": 2,
    "endReason": null,
    "chatId": "chat_873214",
    "callerId": "10001",
    "calleeId": "10002",
    "acceptedDeviceId": "ios-iphone15pm-001",
    "isCurrentUserCaller": false,
    "isCurrentUserCallee": true,
    "entryModeSuggested": "session",
    "startTime": 1777693200000,
    "answerTime": 1777693208000,
    "endTime": null,
    "durationSeconds": 0,
    "rtcEnabled": true,
    "signalOnlyMode": false
  },
  "msg": ""
}
```

页面消费约束：

1. `state=RINGING` 时再结合当前用户视角进入 `/call/incoming` 或 `/call/outgoing`
2. `state in (CONNECTING, CONNECTED)` 时进入 `/call/session`
3. `state=ENDED` 时不再展示来电页，只展示结束态或回退聊天

###### BU2.2 `GET /system/im/call/active`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "hasActiveCall": true,
    "callId": "call_202605020001",
    "callType": 2,
    "state": "RINGING",
    "chatId": "chat_873214",
    "acceptedDeviceId": null,
    "entryModeSuggested": "incoming",
    "callerId": "10001",
    "calleeId": "10002"
  },
  "msg": ""
}
```

空态示例：

```json
{
  "code": 0,
  "data": {
    "hasActiveCall": false,
    "callId": null,
    "callType": null,
    "state": null,
    "chatId": null,
    "acceptedDeviceId": null,
    "entryModeSuggested": null,
    "callerId": null,
    "calleeId": null
  },
  "msg": ""
}
```

###### BU2.3 `GET /system/im/call/rtc-credential?callId=...`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "callId": "call_202605020001",
    "rtcRoomId": "room_call_202605020001",
    "publisherToken": "janus_pub_token_xxx",
    "subscriberToken": "janus_sub_token_xxx",
    "janusWsUrl": "wss://rtc.example.com/janus",
    "janusHttpUrl": "https://rtc.example.com/janus",
    "stunServers": [
      "stun:stun.l.google.com:19302"
    ],
    "turnServers": [
      {
        "url": "turn:turn.example.com:3478?transport=udp",
        "username": "u_10002_abc",
        "credential": "cred_xxx",
        "credentialType": "password"
      }
    ],
    "acceptedDeviceId": "ios-iphone15pm-001",
    "expireAt": 1777696800000,
    "caller": false,
    "callee": true
  },
  "msg": ""
}
```

信令降级示例：

```json
{
  "code": 0,
  "data": {
    "callId": "call_202605020001",
    "rtcRoomId": null,
    "publisherToken": null,
    "subscriberToken": null,
    "janusWsUrl": null,
    "janusHttpUrl": null,
    "stunServers": [],
    "turnServers": [],
    "acceptedDeviceId": "ios-iphone15pm-001",
    "expireAt": null,
    "caller": false,
    "callee": true,
    "signalOnlyMode": true
  },
  "msg": ""
}
```

###### BU2.4 `GET /system/im/call/records`

ReqVO 示例：

```json
{
  "pageNo": 1,
  "pageSize": 20,
  "callType": 2,
  "status": 2
}
```

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "callId": "call_202605020001",
        "chatId": "chat_873214",
        "callType": 2,
        "status": 2,
        "endReason": "NORMAL_HANGUP",
        "callerId": "10001",
        "calleeId": "10002",
        "durationSeconds": 312,
        "startTime": 1777693200000,
        "endTime": 1777693512000,
        "recordMessageId": "987654321001"
      }
    ],
    "total": 1
  },
  "msg": ""
}
```

###### BU2.5 `GET /system/im/call/records-between`

ReqVO 示例：

```json
{
  "targetUserId": "10002",
  "pageNo": 1,
  "pageSize": 20
}
```

RespVO 沿用 `AppImCallRecordRespVO`，不重复定义。

###### BU2.6 `GET /system/im/call/turn-config`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "rtcEnabled": true,
    "signalOnlyMode": false,
    "ringingTimeoutSeconds": 45,
    "connectingTimeoutSeconds": 30,
    "stunServers": [
      "stun:stun.l.google.com:19302"
    ],
    "turnServers": [
      {
        "url": "turn:turn.example.com:3478?transport=udp",
        "username": "turn_user",
        "credential": "turn_cred",
        "credentialType": "password"
      }
    ],
    "janusWsUrl": "wss://rtc.example.com/janus",
    "janusHttpUrl": "https://rtc.example.com/janus"
  },
  "msg": ""
}
```

##### BV2. 通话状态机迁移表最终版

###### BV2.1 状态迁移总表

| 当前状态 | 触发事件 | 前置校验 | 下一个状态 | 结束状态/附加处理 |
|---|---|---|---|---|
| `INIT` | `CALL` | 会话合法、未忙线、功能开启 | `RINGING` | 创建/更新 `im_call_record` |
| `RINGING` | `ANSWER` | 当前用户为被叫；CAS 抢占 `acceptedDeviceId` 成功 | `CONNECTING` | 失败设备收到 `BUSY/OTHER_DEVICE_ACCEPTED` |
| `RINGING` | `REJECT` | 当前用户为被叫 | `ENDED` | `status=REJECTED` |
| `RINGING` | `HANGUP` | 当前用户为主叫 | `ENDED` | `status=CANCELLED` |
| `RINGING` | `TIMEOUT` | 超时 Job 命中 | `ENDED` | `status=MISSED` |
| `CONNECTING` | `markConnected/STATE_SYNC(CONNECTED)` | 当前设备等于 `acceptedDeviceId` | `CONNECTED` | 可补发 `STATE_SYNC` |
| `CONNECTING` | `HANGUP` | 主被叫任一方主动结束 | `ENDED` | `status=ANSWERED or CANCELLED` 依结束方与时机判定 |
| `CONNECTING` | `TIMEOUT` | 建连超时 | `ENDED` | `endReason=RTC_CONNECT_TIMEOUT` |
| `CONNECTED` | `HANGUP` | 主被叫任一方主动结束 | `ENDED` | `status=ANSWERED` |
| `CONNECTED` | `STATE_SYNC` | 重连恢复 | `CONNECTED` | 只同步，不改最终状态 |
| `ENDED` | 任意重复动作 | 幂等校验 | `ENDED` | 返回已结束快照，不重复生成 `CALL_RECORD` |

###### BV2.2 明确禁止的非法迁移

| 非法场景 | 原因 | 服务端处理 |
|---|---|---|
| `INIT -> CONNECTED` | 跳过响铃/接听/建连过程 | 返回 `CALL_STATE_INVALID` |
| `RINGING -> CONNECTED` | 未经接听直接接通 | 返回 `CALL_STATE_INVALID` |
| 非 `acceptedDeviceId` 设备执行 `markConnected` | 多端裁决冲突 | 返回 `CALL_ACCEPT_DEVICE_CONFLICT` |
| `ENDED -> CONNECTING/CONNECTED` | 已结束通话不可恢复为活跃态 | 返回 `CALL_STATE_INVALID` |
| 任意非参与人发送 `ANSWER/HANGUP` | 非法用户操作 | 返回 `CALL_PERMISSION_DENIED` |

###### BV2.3 `status` / `endReason` 落表规则

| 结束触发 | `status` | `endReason` |
|---|---|---|
| 被叫拒绝 | `REJECTED` | `CALLEE_REJECTED` |
| 主叫取消 | `CANCELLED` | `CALLER_CANCELLED` |
| 响铃超时 | `MISSED` | `NO_ANSWER_TIMEOUT` |
| 建连超时 | `MISSED` 或 `CANCELLED` | `RTC_CONNECT_TIMEOUT` |
| 接通后挂断 | `ANSWERED` | `NORMAL_HANGUP` |
| 其它设备已接听导致当前设备退出 | 不改单条主记录 `status` | `OTHER_DEVICE_ACCEPTED` 仅用于设备端结束理由 |
| 房间回收异常结束 | `ANSWERED` 或按最终态兜底 | `ROOM_RECYCLED` |

##### BW2. 通话页面空态 / 权限态 / 并发态口径

###### BW2.1 页面空态口径

| 页面 | 空态触发条件 | 页面表现 |
|---|---|---|
| `/call/incoming` | `GET /call/detail` 返回 `ENDED` 或记录不存在 | 不展示来电 UI，回退上一页或聊天页 |
| `/call/outgoing` | `GET /call/detail` 返回空或 `ENDED` | 结束拨出等待态，提示“通话已结束” |
| `/call/session` | `GET /call/rtc-credential` 返回空媒体凭证且 `signalOnlyMode=true` | 进入信令模式提示，不建媒体连接 |
| 通话记录页 | `/system/im/call/records` 空列表 | 展示空态，不伪造测试记录 |

###### BW2.2 页面权限态口径

| 场景 | 后端依据 | 页面处理 |
|---|---|---|
| 当前用户不是 `callerId/calleeId` 却查 `call/detail` | `CALL_PERMISSION_DENIED` | 直接拦截并退出通话页 |
| 非参与人拿 `rtc-credential` | `CALL_RTC_CREDENTIAL_DENIED` | 不进入媒体页，结束当前通话路由 |
| 音视频能力未开启 | `CALL_FEATURE_DISABLED` | 拨打侧不进入通话页；恢复侧直接结束 |
| 当前设备不是 `acceptedDeviceId` 却尝试建连 | 详情或凭证接口返回不匹配 | 页面只展示结束/被其它设备接听，不建连 |

###### BW2.3 页面并发态口径

| 并发场景 | 权威判断 | 页面处理 |
|---|---|---|
| 被叫双端同时点接听 | 服务端 CAS 只允许一个 `acceptedDeviceId` | 成功设备进 `/call/session`，其它设备退出 |
| 主叫已取消，但被叫推送晚到 | `GET /call/detail` 返回 `ENDED` | 不展示来电页 |
| 会中断网重连 | `GET /call/active` 或 `STATE_SYNC` 返回活跃态 | 恢复原 `callId`，不得新建通话 |
| 结束信令已到，`CALL_RECORD` 还没到 | 以结束态和后续记录消息分层 | 通话 UI 先结束，聊天记录稍后插入 |
| 重复收到 `HANGUP/TIMEOUT` | `ENDED` 幂等 | 页面只消费首个结束态，不重复 toast |

###### BW2.4 Flutter 页面统一收口规则

1. `/call/incoming`、`/call/outgoing`、`/call/session` 三页都必须以服务端 `call.detail/call.active` 结果做最终确认
2. 任何页面只要拿到：
   - `CALL_STATE_INVALID`
   - `CALL_PERMISSION_DENIED`
   - `CALL_ACCEPT_DEVICE_CONFLICT`
   - `CALL_FEATURE_DISABLED`
   都直接进入结束/退出分支
3. 页面不根据本地按钮点击结果判定成功，必须等：
   - `CALL_SIGNAL` 服务端回执
   - 或 `GET /system/im/call/detail`
4. 若页面已退出通话路由，后续迟到的 `STATE_SYNC/ICE/SDP` 事件只能忽略，不允许再次唤起已结束通话

##### BX2. 当前这一轮继续后的结论

1. 通话专题已补到接口示例 JSON 最终版
2. 通话业务状态机已收敛为可执行的迁移表
3. 通话页空态、权限态、并发态口径已冻结
4. 后续若继续文档推进，优先建议：
   - `contacts / group settings / upgrade` 补空态/权限态/并发态口径
   - 通话专题补“controller/usecase/repository 文件级落地顺序”

##### BY2. `contacts / group settings / upgrade` 空态 / 权限态 / 并发态口径

###### BY2.1 `contacts` 页面空态 / 权限态 / 并发态

| 页面/场景 | 类型 | 触发条件 | 页面处理 |
|---|---|---|---|
| 通讯录主页联系人列表 | 空态 | `/system/im/contact/list` 返回空列表 | 展示空态，不回退 `contacts_mock_data.dart` |
| 我的群组 | 空态 | `/system/im/group/list` 返回空列表 | 展示“暂无群组”，不填本地假群 |
| 我的部门 | 空态 | `/system/dept/my-dept-tree` 空树或当前部门无成员 | 左侧树/顶部部门可为空，成员区展示空态 |
| 组织架构 | 空态 | `/system/dept/org-tree` 无节点 | 展示空组织空态 |
| 联系人详情 | 空态 | `/system/im/contact/get` 返回空或关系已删除 | 回退上一页并提示“联系人不存在” |
| 联系人详情发消息 | 权限态 | `get-by-target` 返回无权限或对方被禁用 | toast 后停留详情页 |
| 联系人设置关注/取消关注 | 权限态 | `/contact/setting/update` 返回权限不足 | 回滚开关并刷新详情 |
| 部门成员分页 | 权限态 | `/list-by-dept-page` 返回无部门查看权限 | 展示无权限空态，不混入旧数据 |
| 搜索结果跳转时数据失效 | 并发态 | 搜索结果中的 `userId/deptId/groupId` 已失效 | 重新刷新搜索结果并提示“结果已更新” |
| 群已解散但我的群组列表未刷新 | 并发态 | 点进群详情时 `/group/get` 返回不存在 | 列表移除该项并刷新 |

收口规则：

1. `contacts` 域所有空态都优先真实空结果，不允许再用 mock 视觉占坑
2. 权限不足与数据不存在必须分开展示：
   - 权限不足：无权限态
   - 数据不存在：空态/回退
3. 并发失效时优先刷新来源列表，而不是在详情页硬撑旧数据

###### BY2.2 `group settings` 页面空态 / 权限态 / 并发态

| 页面/场景 | 类型 | 触发条件 | 页面处理 |
|---|---|---|---|
| 群成员页 | 空态 | `/group/member/list` 返回空列表 | 展示空态，不保留默认成员数组 |
| 群公告页 | 空态 | `notice` 为空 | 展示“暂无公告”型空态，不写本地公告文本 |
| 群文件页 | 空态 | `/group/file/list` 返回空列表 | 展示空态，不填示例文件 |
| 群聊天记录页 | 空态 | `/message/search` 无结果 | 展示空态，不填示例记录 |
| 群二维码页 | 空态 | `/group/invite/get` 无有效邀请码 | 展示“暂无有效邀请码”，不渲染 mock QR |
| 修改群资料 | 权限态 | 当前用户非群主/管理员且后端拒绝 | 回滚本地编辑，提示权限不足 |
| 移除成员 | 权限态 | 当前用户不是群主/管理员或目标成员不可移除 | 清空选择态并刷新成员列表 |
| 处理入群申请 | 权限态 | 当前用户不再是审批人 | 刷新待处理数和申请列表 |
| 群已解散 | 并发态 | 任一页面操作时 `/group/get` 或写口返回群不存在 | 全部相关页回退并刷新来源列表 |
| 成员已被他端移除 | 并发态 | 删除成员时返回成员不存在 | 重新拉成员列表 |
| 邀请码已过期 | 并发态 | 扫码页或二维码页拿到过期结果 | 刷新邀请码，不继续展示旧码 |

收口规则：

1. `group settings` 域页面只要真实接口返回空，就直接进入空态，不再用占位内容覆盖
2. 并发冲突优先刷新：
   - 群详情
   - 成员列表
   - 待处理申请数
3. 对“群已解散/当前用户已退群”这类终局态，直接退出相关页面，不做局部修补

###### BY2.3 `upgrade` 平台端空态 / 权限态 / 并发态

| 页面/场景 | 类型 | 触发条件 | 页面处理 |
|---|---|---|---|
| 产品列表/安装包列表/发布单列表 | 空态 | 分页接口返回空列表 | 展示标准空态，不自动造测试数据 |
| 升级日志页 | 空态 | `page` 返回空记录，`summary` 可为空 | 列表空态；摘要失败不阻断列表 |
| 渠道发布详情 | 空态 | 对应发布单已删除或不存在 | 返回列表页并提示 |
| 产品/包/发布单编辑 | 权限态 | 当前操作人无查看或编辑权限 | 页面进入即展示无权限态 |
| 审核/发布/下线/回滚 | 权限态 | 按钮点击后后端返回权限不足 | 保留当前详情，提示权限不足 |
| 同步市场状态 | 权限态 | 当前用户无同步权限 | 不更新本地状态，只 toast |
| 发布单被他人先审核 | 并发态 | 审核动作返回状态冲突 | 立即刷新详情，以后端最新状态覆盖 |
| 渠道已被他人下线/回滚 | 并发态 | 操作时返回状态冲突 | 刷新渠道详情和主发布单状态 |
| 日志导出条件过期 | 并发态 | 导出时筛选条件对应数据已归档/超限 | 保留筛选条件，提示调整范围 |

收口规则：

1. `upgrade` 平台端空态不等于失败态，空列表和请求失败要严格区分
2. 权限态优先走页面级无权限展示，其次才是按钮点击后的 toast
3. 并发态统一策略是“刷新详情/列表，用最新状态覆盖本地界面”

##### BZ2. 通话专题 `controller / usecase / repository` 文件级落地顺序

###### BZ2.1 目标

目标不是立即改代码，而是把恢复代码推进时的最小安全顺序冻结下来，避免直接去改页面或并行乱改。

###### BZ2.2 第一批：domain contract 与 DTO 重构先行

优先文件：

1. `features/im/call/domain/repositories/call_repository.dart`
2. `features/im/call/infrastructure/dtos/call_session_dto.dart`
3. `features/im/call/infrastructure/dtos/call_signal_event_dto.dart`
4. `features/im/call/infrastructure/mappers/call_dto_mapper.dart`

本批目标：

1. 从旧：
   - `callSessionId`
   - `audio/video`
   - `ringing/connected`
   迁到统一文档冻结口径：
   - `callId`
   - `callType=1/2`
   - `state/status/endReason`
2. 把单一旧 `CallSessionDto` 拆分成以下响应模型语义：
   - `call/detail`
   - `call/active`
   - `call/rtc-credential`
   - `call/turn-config`
3. repository contract 先收口真实查询能力，再谈页面切换

###### BZ2.3 第二批：remote/socket datasource 收口

优先文件：

1. `features/im/call/infrastructure/datasources/call_remote_data_source.dart`
2. `features/im/call/infrastructure/datasources/call_socket_data_source.dart`
3. `features/im/call/infrastructure/mappers/call_socket_payload_resolver.dart`

本批目标：

1. `call_remote_data_source.dart` 迁到统一文档冻结接口组：
   - `GET /system/im/call/detail`
   - `GET /system/im/call/active`
   - `GET /system/im/call/rtc-credential`
   - `GET /system/im/call/turn-config`
2. Phase 1 保持 WS 为动作控制面，不再叠一套 REST 动作口
3. `call_socket_payload_resolver.dart` 只解析：
   - `signalType`
   - `callId`
   - `extraData`
   - 服务端回执状态
4. 移除旧：
   - `roomBundle`
   - `turnUsername`
   - `turnCredential`
   - `token`
   直接从 socket 灌页面的做法

###### BZ2.4 第三批：repository impl 与 mock 退场

优先文件：

1. `features/im/call/infrastructure/repositories/call_repository_impl.dart`
2. `features/im/call/infrastructure/repositories/mock_call_repository.dart`
3. `features/im/call/presentation/providers/call_providers.dart`

本批目标：

1. `call_repository_impl.dart` 只暴露统一文档定义的真实语义方法
2. `mock_call_repository.dart` 不再继续扩充事件；后续仅保留归档参考或彻底退场
3. `call_providers.dart` 切真实 repository 前，必须满足：
   - DTO 已收口
   - datasource 已迁到新接口
   - controller 不再依赖本地假推进

###### BZ2.5 第四批：usecase 层收口

优先文件：

1. `application/usecases/create_call_invite_use_case.dart`
2. `application/usecases/accept_call_use_case.dart`
3. `application/usecases/reject_call_use_case.dart`
4. `application/usecases/cancel_call_use_case.dart`
5. `application/usecases/hangup_call_use_case.dart`
6. `application/usecases/sync_active_call_state_use_case.dart`

本批目标：

1. 保留动作 usecase，但其成功语义必须改为：
   - “服务端已受理/已回执”
   - 不是“页面本地可直接进入 connected”
2. `sync_active_call_state_use_case.dart` 优先对接：
   - `GET /system/im/call/active`
   - `GET /system/im/call/detail`
3. 后续若新增 usecase，建议顺序：
   - `GetCallDetailUseCase`
   - `GetRtcCredentialUseCase`
   - `GetTurnConfigUseCase`

###### BZ2.6 第五批：presentation controller 收口

优先文件：

1. `presentation/controllers/call_controller.dart`
2. `presentation/controllers/call_media_controller.dart`
3. `presentation/controllers/call_coordinator.dart`
4. `presentation/controllers/active_call_registry.dart`

本批目标：

1. `call_controller.dart` 改成：
   - 服务端状态驱动
   - 页面只消费 `CallState`
   - 不在 `accept()` 后直接假定已连通
2. `call_media_controller.dart` 只在：
   - `state in (CONNECTING, CONNECTED)`
   - 且当前设备等于 `acceptedDeviceId`
   时才尝试建媒体连接
3. `call_coordinator.dart` 负责路由恢复与页面切换，不拥有业务真状态
4. `active_call_registry.dart` 只缓存当前活跃 `callId`，不自己造状态

###### BZ2.7 第六批：页面最后改

最后处理文件：

1. `presentation/pages/incoming_call_page.dart`
2. `presentation/pages/outgoing_call_page.dart`
3. `presentation/pages/call_session_page.dart`
4. `presentation/states/call_state.dart`
5. `presentation/states/call_media_state.dart`

本批目标：

1. 页面只消费已经收口后的 state
2. 所有页面显隐、按钮可用、结束态文案均基于真实字段：
   - `state`
   - `status`
   - `endReason`
   - `acceptedDeviceId`
3. 页面绝不直接吃 raw socket payload 或 RTC 凭证原始 JSON

###### BZ2.8 文件级执行总顺序

执行顺序冻结为：

1. `domain/repository contract + dto + mapper`
2. `remote/socket datasource`
3. `repository impl + provider/mock 退场`
4. `usecase`
5. `controller/coordinator`
6. `page/state`

禁止顺序：

1. 先改页面后补接口
2. 先切 provider 到真实模式，再补 DTO
3. 让 `mock_call_repository.dart` 与真实 repository 长期并行主导逻辑

##### CA2. 当前这一轮继续后的结论

1. `contacts / group settings / upgrade` 的空态、权限态、并发态口径已补齐
2. 通话专题已补到 `controller/usecase/repository` 文件级落地顺序
3. 后续若继续文档推进，优先建议：
   - `contacts / group settings / upgrade` 再补“controller/state/repository 文件级实施顺序”
   - 通话专题再补“后端 controller/service/processor/job 落地顺序总表”

##### CA3. 当前 Flutter 通话实现与统一协议差异收口表

###### CA3.1 `call_session_dto.dart` / `call_signal_event_dto.dart` 当前差异

当前文件：

- `features/im/call/infrastructure/dtos/call_session_dto.dart`
- `features/im/call/infrastructure/dtos/call_signal_event_dto.dart`

当前实现差异：

| 当前实现 | 统一文档冻结口径 | 差异说明 | 后续处理 |
|---|---|---|---|
| `CallSessionDto.callSessionId` | `callId` | 主键仍沿用旧字段名 | Phase 1 先兼容映射，Phase 2 统一收口为 `callId` |
| 单一 `CallSessionDto` 同时承接 invite/state/rtcRoom | `detail/active/rtc-credential/turn-config` 分离 | DTO 语义过宽 | 拆分为四类响应 DTO |
| `callType='audio'/'video'` | `callType=1/2` 或明确枚举值 | 与统一协议数值语义不一致 | mapper 层先兼容双写映射 |
| `status='connecting'` 等页面化字符串 | `state/status/endReason` 三元组 | 业务状态与展示状态混合 | DTO 层补 `state/status/endReason` |
| `CallSignalEventDto.type/callSessionId/payload` | `signalType/callId/extraData` | 事件载荷命名仍偏旧 | 新协议下统一转成 `signalType/callId/extraData` |

约束：

1. DTO 改造必须先于 controller/page 改造
2. 不允许继续扩 `CallSessionDto` 去兼容更多 REST 查询面
3. `rtc-credential` 与 `turn-config` 不再回灌到旧 `CallSessionDto`

###### CA3.2 `call_remote_data_source.dart` 当前差异

当前文件：

- `features/im/call/infrastructure/datasources/call_remote_data_source.dart`

当前实现差异：

| 当前接口 | 统一文档冻结接口 | 差异说明 | 后续处理 |
|---|---|---|---|
| `POST /system/im/call/create-invite` | WS `CALL_SIGNAL(CALL)` 为主；REST 以查询面为主 | 仍保留旧动作口 | Phase 1 兼容保留；不再继续扩 |
| `POST /system/im/call/accept` | WS `CALL_SIGNAL(ANSWER)` | 动作控制面仍偏 REST | 后续迁到 socket datasource 主导 |
| `POST /system/im/call/reject/cancel/hangup` | WS `CALL_SIGNAL(REJECT/CANCEL/HANGUP)` | 同上 | 同上 |
| `GET /system/im/call/state` | `GET /system/im/call/active` + `GET /system/im/call/detail` | 查询面仍未拆 | 拆为 active/detail 两条恢复查询 |

收口规则：

1. 新增能力优先补：
   - `getActiveCall()`
   - `getCallDetail()`
   - `getRtcCredential()`
   - `getTurnConfig()`
2. 旧 REST 动作口只做兼容壳，不作为后续主线
3. Flutter 页面恢复与路由判断，只允许基于 `active/detail` 查询面

###### CA3.3 `call_socket_payload_resolver.dart` 当前差异

当前文件：

- `features/im/call/infrastructure/mappers/call_socket_payload_resolver.dart`

当前实现差异：

| 当前解析字段 | 统一文档冻结口径 | 差异说明 | 后续处理 |
|---|---|---|---|
| `title` | 可保留轻量展示字段 | 可接受 | 保持 |
| `acceptedDeviceId` | 必须保留 | 与多端裁决强相关 | 保持 |
| `callerProfile/calleeProfile` | 可保留轻量 profile 字段 | 可接受 | 保持 |
| `roomBundle/rtcRoom/janusUrl/turnCredential/token` | 不应再从 socket 长期承接媒体凭证 | 与独立 `rtc-credential` 查询面冲突 | 后续移除解析与页面透传 |

收口规则：

1. socket payload resolver 最终只负责：
   - `signalType`
   - `callId`
   - `acceptedDeviceId`
   - 轻量 profile
   - 必要展示字段
2. 媒体凭证统一走 `GET /system/im/call/rtc-credential`
3. `call_controller.dart` 不再依赖 socket 直接塞 `roomBundle`

###### CA3.4 推荐推进顺序补充

在现有 `BZ2` 文件级顺序基础上，再补一条执行优先级：

1. 先拆 `dto`
2. 再拆 `remote datasource`
3. 再收 `socket payload resolver`
4. 最后才允许 controller 去切新恢复态与凭证查询面

##### CB2. `contacts` controller / state / repository 文件级实施顺序

###### CB2.1 第一批：repository contract 与 DTO/mapper 收口

优先文件：

1. `features/contacts/domain/repositories/contacts_repository.dart`
2. `features/contacts/infrastructure/dtos/contact_dto.dart`
3. `features/contacts/infrastructure/dtos/contact_profile_dto.dart`
4. `features/contacts/infrastructure/dtos/department_summary_dto.dart`
5. `features/contacts/infrastructure/dtos/group_summary_dto.dart`
6. `features/contacts/infrastructure/repositories/contacts_repository_impl.dart`

本批目标：

1. 明确每个页面真实消费字段来源：
   - 联系人列表
   - 联系人详情
   - 我的群组
   - 我的部门
   - 搜索结果
2. 把当前仍混用 mock 的展示字段逐步从 repository 层切掉
3. `chatId`、`deptId`、`groupId`、`userId` 统一为真实跳转主键

###### CB2.2 第二批：remote datasource 收口

优先文件：

1. `features/contacts/infrastructure/datasources/contacts_remote_data_source.dart`

本批目标：

1. 确认以下接口在 datasource 中具备稳定方法：
   - `/system/im/contact/list`
   - `/system/im/contact/get`
   - `/system/im/contact/search`
   - `/system/im/contact/list-by-dept`
   - `/system/dept/my-dept-tree`
   - `/system/dept/org-tree`
   - `/system/im/group/list`
   - `/system/im/conversation/get-by-target`
2. 若某页仍缺方法，优先补 datasource，不让 controller 直接拼请求

###### CB2.3 第三批：state 与 controller 收口

优先文件：

1. `features/contacts/presentation/states/contacts_page_state.dart`
2. `features/contacts/presentation/controllers/contacts_page_controller.dart`
3. `features/contacts/presentation/providers/contacts_providers.dart`

本批目标：

1. `ContactsPageState` 只保留真实页面需要的字段
2. controller 负责：
   - 拉真实列表
   - 切换分组/部门
   - 触发联系人详情和发消息跳转所需的真实主键准备
3. provider 层不再给页面透传 mock 数据源

###### CB2.4 第四批：移除 mock 依赖

优先文件：

1. `features/contacts/presentation/data/contacts_mock_data.dart`：已删除
2. `features/contacts/presentation/models/contact_directory_item.dart`

本批目标：

1. 把仍在页面侧直接消费 `contacts_mock_data.dart` 的入口全部挪走：已完成
2. `contact_directory_item.dart` 若仍承担假字段展示职责，应改成真实展示模型或退场

###### CB2.5 第五批：页面最后改

最后处理文件：

1. `presentation/pages/contacts_page.dart`
2. `presentation/pages/contact_profile_page.dart`
3. `presentation/pages/my_groups_page.dart`
4. `presentation/pages/my_department_page.dart`
5. `presentation/pages/org_browser_page.dart`
6. `presentation/pages/contact_search_result_page.dart`

执行原则：

1. 页面只消费 controller/state
2. 页面不再本地拼联系人、部门、群组假数据
3. 所有跳转都以真实 `userId/deptId/groupId/chatId` 驱动

##### CC2. `group settings` controller / state / repository 文件级实施顺序

###### CC2.1 第一批：repository contract 扩口

优先文件：

1. `features/im/group_settings/domain/repositories/group_settings_repository.dart`
2. `features/im/group_settings/infrastructure/repositories/group_settings_repository_impl.dart`

本批目标：

1. 先把文档里已冻结的方法补齐到 contract：
   - `updateConversationPinned`
   - `updateConversationNoDisturb`
   - `removeGroupMembers`
   - `generateGroupInvite`
   - `getGroupFiles`
   - `deleteGroupFile`
   - `searchGroupMessages`
2. repository impl 只负责拼装实体，不让页面自己组合接口结果

###### CC2.2 第二批：datasource 与 mapper 收口

优先文件：

1. `features/im/group_settings/infrastructure/datasources/group_settings_remote_data_source.dart`
2. `features/im/group_settings/infrastructure/mappers/group_settings_dto_mapper.dart`
3. `features/im/group_settings/infrastructure/dtos/group_info_dto.dart`
4. `features/im/group_settings/infrastructure/dtos/group_invite_info_dto.dart`
5. `features/im/group_settings/infrastructure/dtos/group_member_dto.dart`

本批目标：

1. 让 datasource 具备完整真实读写方法
2. DTO/mapper 明确：
   - `notice`
   - `inviteCode/expireAt`
   - `member.role/avatarUrl/isMuted`
   - `joinTime/muteEndTime`
3. 不让页面再依赖 `_MockQrPainter`、本地公告文本、示例文件记录

###### CC2.3 第三批：state 收口

优先文件：

1. `presentation/states/group_settings_state.dart`
2. `presentation/states/group_members_state.dart`

本批目标：

1. 去掉显式 mock 默认值：
   - `myNickname = '马化腾'`：已完成
   - 默认成员数组：已完成
2. 把 `pendingRequestLabel` 这类展示型字段改为“数值 + 页面格式化”：已完成
3. state 只保留真实可回放字段，不存本地假内容：当前已成立

###### CC2.4 第四批：controller 收口

优先文件：

1. `presentation/controllers/group_settings_controller.dart`
2. `presentation/controllers/group_members_controller.dart`
3. `presentation/providers/group_settings_providers.dart`

本批目标：

1. `updateNoDisturb()` 与 `updatePinned()` 接真实写口
2. `removeSelected()` 走真实成员移除接口再刷新
3. provider 保持装配层，不承担本地假逻辑

###### CC2.5 第五批：页面最后改

最后处理文件：

1. `presentation/pages/group_settings_page.dart`
2. `presentation/pages/group_members_page.dart`
3. `presentation/pages/group_announcement_page.dart`
4. `presentation/pages/group_qr_code_page.dart`
5. `presentation/pages/group_files_page.dart`
6. `presentation/pages/group_chat_history_page.dart`
7. `presentation/pages/group_member_detail_page.dart`
8. `presentation/pages/group_setting_detail_page.dart`

执行原则：

1. 主设置页先改，再改二级页
2. 二级页先读真实接口，再替换占位文案/占位列表
3. 页面失败态统一回到真实空态或刷新态，不保留本地假结果

##### CD2. `upgrade` 平台端 controller / state / repository 文件级实施顺序

说明：

平台端为 Vue3 工程，本节中的 `controller/state/repository` 对应为：

- API 层：`src/api/system/appManage/*`
- 页面组合逻辑层：`index.vue` / `*Form.vue`
- 页面状态：表单模型、筛选模型、表格状态、详情抽屉状态

###### CD2.1 第一批：API 文件先落

优先文件：

1. `src/api/system/appManage/product.ts`
2. `src/api/system/appManage/package.ts`
3. `src/api/system/appManage/release.ts`
4. `src/api/system/appManage/channelRelease.ts`
5. `src/api/system/appManage/upgradeLog.ts`

本批目标：

1. 固化与后端的请求函数
2. 所有页面先通过 API 文件访问后端
3. 不在 `index.vue` 中直接写 axios 调用

###### CD2.2 第二批：列表页状态模型先行

优先页面：

1. `src/views/system/appManage/product/index.vue`
2. `src/views/system/appManage/package/index.vue`
3. `src/views/system/appManage/release/index.vue`
4. `src/views/system/appManage/channelRelease/index.vue`
5. `src/views/system/appManage/upgradeLog/index.vue`

本批目标：

1. 先收口每页的：
   - 筛选条件
   - 分页状态
   - loading 状态
   - 当前选中行/详情态
2. 空态、权限态、并发态处理统一内聚到页面组合逻辑中

###### CD2.3 第三批：表单组件再落

优先文件：

1. `product/ProductForm.vue`
2. `package/PackageForm.vue`
3. `release/ReleaseForm.vue`
4. `channelRelease/ChannelReleaseForm.vue`

本批目标：

1. 表单只消费统一 API 层
2. 校验、错误提示、提交状态统一收口
3. 不在各表单重复实现状态机判断

###### CD2.4 第四批：列表动作与详情刷新

本批目标：

1. 启停、审核、发布、下线、回滚、同步状态、导出等动作都统一走：
   - 调 API
   - 成功后刷新详情/列表
   - 失败后保留当前筛选与表单
2. 不做本地假状态切换

###### CD2.5 文件级执行总顺序

执行顺序冻结为：

1. `api/system/appManage/*`
2. `index.vue` 列表状态与筛选
3. `*Form.vue` 表单提交与校验
4. 列表动作/详情刷新/并发态收口

##### CE2. 通话后端 `controller / service / processor / job` 落地顺序总表

###### CE2.1 第一批：枚举 / DO / SQL 先冻结

优先项：

1. `ImCallStateEnum`
2. `ImCallStatusEnum`
3. `ImCallEndReasonEnum`
4. `ImCallSignalTypeEnum`
5. `ImCallRecordDO` 字段扩展
6. `im_call_event` 表与索引

原因：

1. 没有状态枚举和持久化字段，后续 controller/service 都会反复返工

###### CE2.2 第二批：App 查询面 controller 与 ReqVO/RespVO

优先文件：

1. `controller/app/im/AppImCallController.java`
2. `vo/call/AppImCallRecordsReqVO.java`
3. `vo/call/AppImCallRecordsBetweenReqVO.java`
4. `vo/call/AppImCallRecordRespVO.java`
5. `vo/call/AppImCallDetailRespVO.java`
6. `vo/call/AppImCallTurnConfigRespVO.java`
7. `vo/call/AppImCallRtcCredentialRespVO.java`
8. `vo/call/AppImActiveCallRespVO.java`

原因：

1. 先打查询面，Flutter 恢复链路才能有权威入口
2. 这一步不依赖完整通话动作落地

###### CE2.3 第三批：控制面 service

优先文件：

1. `service/im/CallSignalService.java`
2. `service/im/CallSignalServiceImpl.java`
3. `service/im/dto/CallAnswerResult.java`
4. `service/im/dto/ImCallEndResult.java`
5. `service/im/dto/CallStateSnapshot.java`
6. `service/im/CallStateSyncService.java`
7. `service/im/RtcCredentialService.java`

本批目标：

1. 先把状态机推进、接听裁决、结束裁决、恢复态查询做实
2. `RtcCredentialService` 只消费状态机结果，不反向控制状态机

###### CE2.4 第四批：WS processor

优先文件：

1. `processor/impl/CallSignalMessageProcessor.java`
2. `processor/MessageProcessorFactory` 注册位
3. `NettyAutoConfiguration` 注册位

本批目标：

1. 建立 `CALL_SIGNAL(206)` 的统一入口
2. Processor 只负责：
   - 解析
   - session 覆盖
   - 鉴权
   - 分发到 service

###### CE2.5 第五批：记录消息与消息链路

优先文件：

1. `service/im/CallRecordMessageFactory.java`
2. 主消息存储链路接入点

本批目标：

1. 通话结束后生成 `CALL_RECORD=209`
2. 会话预览、聊天页、通话记录页统一吃记录消息，不吃瞬态信令

###### CE2.6 第六批：job 与回收治理

优先文件：

1. `job/im/ImCallTimeoutJob.java`
2. Janus 房间回收/失效治理相关 service

本批目标：

1. 覆盖：
   - `RINGING` 超时
   - `CONNECTING` 超时
2. 把超时结束、房间回收、异常结束补成闭环

###### CE2.7 后端总执行顺序

执行顺序冻结为：

1. `Enum/DO/SQL`
2. `ReqVO/RespVO + AppImCallController`
3. `CallSignalService/CallStateSyncService/RtcCredentialService`
4. `CallSignalMessageProcessor`
5. `CallRecordMessageFactory + 主消息链路`
6. `ImCallTimeoutJob + 房间回收治理`

禁止顺序：

1. 先上 Processor 再补 service
2. 先做 job 再冻结状态机
3. 先把 RTC 凭证直接塞 socket，再补查询面

###### CE2.8 文件级落地顺序验收总表

| 阶段 | 先落文件 | 完成定义 | 前置依赖 |
|---|---|---|---|
| `P0` | `ImCallStateEnum` / `ImCallStatusEnum` / `ImCallEndReasonEnum` / `ImCallSignalTypeEnum` / `ImCallRecordDO` / `im_call_event` | 状态枚举、结束原因、信令类型、主记录字段、事件表结构全部冻结，后续 service / processor / job 不再各自发明状态字面量 | 无 |
| `P1` | `AppImCallController.java` + `AppImCallRecordsReqVO.java` + `AppImCallRecordsBetweenReqVO.java` + `AppImCallRecordRespVO.java` + `AppImCallDetailRespVO.java` + `AppImCallTurnConfigRespVO.java` + `AppImCallRtcCredentialRespVO.java` + `AppImActiveCallRespVO.java` | Flutter 恢复态、记录页、详情页、RTC 配置查询全部有统一 REST 出口；查询面不推进状态机 | `P0` |
| `P2` | `CallSignalService.java` + `CallSignalServiceImpl.java` + `CallAnswerResult.java` + `ImCallEndResult.java` + `CallStateSnapshot.java` + `CallStateSyncService.java` + `RtcCredentialService.java` | `CALL/ANSWER/HANGUP/TIMEOUT/STATE_SYNC` 的主状态机、接听裁决、恢复态快照、RTC 凭证发放全部落到 service 层，不再散落 controller / processor | `P0-P1` |
| `P3` | `CallSignalMessageProcessor.java` + `MessageProcessorFactory` + `NettyAutoConfiguration` | `CALL_SIGNAL(206)` 已有唯一 WS 入口，processor 仅解析/鉴权/覆盖 session/转发，不拥有业务终裁权 | `P2` |
| `P4` | `CallRecordMessageFactory.java` + 主消息存储链路接入点 | 通话结束后稳定生成 `CALL_RECORD=209`，会话预览、聊天页、记录页统一消费记录消息而非瞬态信令 | `P2-P3` |
| `P5` | `ImCallTimeoutJob.java` + `JanusGatewayAdapter` 或等价治理层 | `RINGING/CONNECTING` 超时扫描、结束态闭环、房间回收、失败补偿链路全部成立 | `P2-P4` |

验收规则：

1. 若 `P2` 未完成，不允许以“先接通再补状态机”的方式提前落 `P3-P5`
2. 若 `P4` 未完成，聊天页和会话预览不得直接消费 `CALL_SIGNAL(206)` 作为记录展示依据
3. 若 `P5` 未完成，`CONNECTING` 超时与 Janus 异常回收只能标记为 `blocked`，不能宣称通话后端闭环已完成

##### CF2. 当前这一轮继续后的结论

1. `contacts / group settings / upgrade` 已补到各自的文件级实施顺序
2. 通话后端已补到 `controller / service / processor / job` 落地顺序总表
3. 后续若继续文档推进，优先建议：
   - `contacts / group settings / upgrade` 再补“页面级任务优先级清单”
   - 通话专题再补“后端文件清单与类职责冻结表”

##### CG2. `contacts / group settings / upgrade` 页面级任务优先级清单

###### CG2.1 `contacts` 页面级优先级

| 优先级 | 页面 | 原因 | 完成定义 |
|---|---|---|---|
| `P0` | `contacts_page.dart` | 一级页主入口，且当前仍混有 mock 展示模型 | 联系人主列表、快捷入口、搜索入口全部只吃真实数据 |
| `P0` | `contact_profile_page.dart` | 发消息、关注、资料查看都依赖它 | 详情字段、关注动作、发消息取 `chatId` 全部真实 |
| `P1` | `my_groups_page.dart` | 群跳转主入口，依赖真实 `groupId/chatId` | 群列表、群详情跳转、群会话跳转都真实 |
| `P1` | `my_department_page.dart` | 部门树和成员页是通讯录核心链路 | 部门切换、成员列表、空态/权限态真实 |
| `P1` | `contact_search_result_page.dart` | 搜索是跨联系人/部门/群的重要入口 | 结果项真实跳转，不残留本地筛选假逻辑 |
| `P2` | `org_browser_page.dart` | 目前是树摘要页，可放在主链路后补 | 部门树点击、成员跳转、空态真实 |

执行顺序建议：

1. `contacts_page.dart`
2. `contact_profile_page.dart`
3. `my_groups_page.dart`
4. `my_department_page.dart`
5. `contact_search_result_page.dart`
6. `org_browser_page.dart`

###### CG2.2 `group settings` 页面级优先级

| 优先级 | 页面 | 原因 | 完成定义 |
|---|---|---|---|
| `P0` | `group_settings_page.dart` | 主设置页承接大部分真实字段和写动作 | `pinned/noDisturb/muteAll/groupName/myNickname` 全部真实 |
| `P0` | `group_members_page.dart` | 当前仍有默认成员数组和本地移除逻辑 | 成员列表、移除成员、角色显示全部真实 |
| `P1` | `group_announcement_page.dart` | 公告是高频真实能力，当前仍是本地文本 | 读写公告都走真实接口 |
| `P1` | `group_qr_code_page.dart` | 邀请码/二维码链路真实价值高 | 邀请码获取/生成真实，移除 mock QR |
| `P2` | `group_files_page.dart` | 依赖文件列表与文件预览策略 | 文件列表/删除真实，打开走统一文件预览 |
| `P2` | `group_chat_history_page.dart` | 复杂度高，依赖消息搜索与跳锚点 | 搜索结果、筛选、跳消息真实 |
| `P3` | `group_member_detail_page.dart` | 依赖成员详情字段补齐后更适合推进 | 成员详情只展示真实字段 |
| `P3` | `group_setting_detail_page.dart` | 容器型过渡页，业务价值最低 | 仅保留真实导航与详情承载 |

执行顺序建议：

1. `group_settings_page.dart`
2. `group_members_page.dart`
3. `group_announcement_page.dart`
4. `group_qr_code_page.dart`
5. `group_files_page.dart`
6. `group_chat_history_page.dart`
7. `group_member_detail_page.dart`
8. `group_setting_detail_page.dart`

###### CG2.3 `upgrade` 平台端页面级优先级

| 优先级 | 页面 | 原因 | 完成定义 |
|---|---|---|---|
| `P0` | `product/index.vue` | 升级中心最上游主数据 | 产品列表、创建、启停、权限控制真实 |
| `P0` | `package/index.vue` | 安装包资产是发布单前置 | 包列表、上传/登记、启停真实 |
| `P0` | `release/index.vue` | 发布、下线、回滚的主控制台 | 发布单创建、审核、发布动作真实 |
| `P1` | `channelRelease/index.vue` | 依赖发布单，但影响市场同步 | 渠道记录、同步状态、并发态真实 |
| `P2` | `upgradeLog/index.vue` | 依赖客户端事件回流，适合主链路后补 | 日志分页、摘要、导出真实 |

执行顺序建议：

1. `product/index.vue`
2. `package/index.vue`
3. `release/index.vue`
4. `channelRelease/index.vue`
5. `upgradeLog/index.vue`

###### CG2.4 跨模块统一优先级规则

1. 先做“入口页/主链路页”，后做“详情页/附属页”
2. 先做“真实读链路”，后做“真实写链路”
3. 先做“当前已有接口支撑”的页面，后做“仍需补接口或补字段”的页面
4. 当前阶段不为低优先级页追加 mock 或临时桥接

##### CH2. 通话后端文件清单与类职责冻结表

###### CH2.1 查询面与 VO 层

| 文件 | 层级 | 职责冻结 | 禁止事项 |
|---|---|---|---|
| `controller/app/im/AppImCallController.java` | Controller | 只承接 app 查询面 REST：记录、详情、活跃态、RTC 配置/凭证 | 不直接推进状态机 |
| `vo/call/AppImCallRecordsReqVO.java` | ReqVO | 通话记录分页入参 | 不混入鉴权字段 |
| `vo/call/AppImCallRecordsBetweenReqVO.java` | ReqVO | 双人记录查询入参 | 不允许前端传当前用户主键 |
| `vo/call/AppImCallRecordRespVO.java` | RespVO | 通话记录列表返回 | 不承载瞬态信令字段 |
| `vo/call/AppImCallDetailRespVO.java` | RespVO | 通话详情与恢复态返回 | 不直接塞 RTC 原始包 |
| `vo/call/AppImCallTurnConfigRespVO.java` | RespVO | RTC 全局配置返回 | 不暴露不必要服务端内部字段 |
| `vo/call/AppImCallRtcCredentialRespVO.java` | RespVO | 单次 RTC 凭证返回 | 不负责业务裁决 |
| `vo/call/AppImActiveCallRespVO.java` | RespVO | 活跃通话恢复态返回 | 不与详情 VO 混成一个大对象 |

###### CH2.2 控制面 service 层

| 文件 | 层级 | 职责冻结 | 禁止事项 |
|---|---|---|---|
| `service/im/CallSignalService.java` | Service | 定义 `CALL/ANSWER/REJECT/HANGUP/BUSY/TIMEOUT` 主控制接口 | 不关注 Flutter 路由 |
| `service/im/CallSignalServiceImpl.java` | ServiceImpl | 状态机推进、裁决、事件落库、结束链路触发 | 不直接拼 REST 返回 VO |
| `service/im/CallStateSyncService.java` | Service | 查询/组装 `CallStateSnapshot`，支持 `STATE_SYNC` | 不直接分发 WebSocket 原始包 |
| `service/im/RtcCredentialService.java` | Service | 校验参与者身份并发放房间/凭证 | 不反向修改接听裁决 |
| `service/im/CallRecordMessageFactory.java` | Service | 将结束态转换成 `CALL_RECORD=209` 消息体 | 不负责持久化瞬态信令 |

###### CH2.3 DTO / Snapshot / Result 层

| 文件 | 层级 | 职责冻结 | 禁止事项 |
|---|---|---|---|
| `service/im/dto/CallAnswerResult.java` | DTO | 接听裁决结果 | 不给前端直接透出 |
| `service/im/dto/ImCallEndResult.java` | DTO | 结束裁决结果 | 不承载页面展示文案 |
| `service/im/dto/CallStateSnapshot.java` | DTO | 服务端权威恢复态快照 | 不混入消息记录摘要字段以外的 UI 装饰内容 |

###### CH2.4 Processor 与注册层

| 文件 | 层级 | 职责冻结 | 禁止事项 |
|---|---|---|---|
| `processor/impl/CallSignalMessageProcessor.java` | Processor | `CALL_SIGNAL(206)` 唯一入口；解析、session 覆盖、鉴权、分发 | 不自己执行业务状态迁移 |
| `core/processor/MessageProcessorFactory.java` | Factory | 注册 `CALL_SIGNAL` 对应 processor | 不写业务 if/else 裁决 |
| `config/NettyAutoConfiguration.java` | Config | 把 processor 注册进 Netty 消息链路 | 不承担任何通话业务逻辑 |

###### CH2.5 持久化 / Job / 治理层

| 文件 | 层级 | 职责冻结 | 禁止事项 |
|---|---|---|---|
| `dataobject/im/ImCallRecordDO.java` | DO | 通话主记录持久化模型 | 不承担枚举解释逻辑 |
| `dataobject/im/ImCallEventDO.java` 或等价事件 DO | DO | 事件流水与流程记录 | 不做主状态判断 |
| `job/im/ImCallTimeoutJob.java` | Job | 扫描 `RINGING/CONNECTING` 超时并委托 `handleTimeout()` | 不直接改消息链路 |
| `service/im/JanusGatewayAdapter.java` 或等价适配层 | Adapter | Janus 房间/句柄/销毁适配 | 不决定业务最终状态 |

###### CH2.6 后端类职责统一规则

1. Controller 只管入参校验、鉴权入口、调用 service、返回 VO
2. Service 才拥有业务真状态机
3. Processor 只做消息入口分发，不做业务真裁决
4. Job 只负责扫描与触发，不复制一套结束逻辑
5. DTO/VO/DO 三层不得混用：
   - DO 面向存储
   - DTO 面向服务内部编排
   - VO 面向对外接口

##### CI2. 当前这一轮继续后的结论

1. `contacts / group settings / upgrade` 页面级任务优先级清单已补齐
2. 通话后端文件清单与类职责冻结表已补齐
3. 后续若继续文档推进，优先建议：
   - `contacts / group settings / upgrade` 再补“跨页面联动与刷新规则清单”
   - 通话专题再补“后端异常场景处理顺序与日志/监控字段冻结”

##### CJ2. `contacts / group settings / upgrade` 跨页面联动与刷新规则清单

###### CJ2.1 `contacts` 跨页面联动

| 触发页面/动作 | 需要刷新的页面 | 刷新依据 | 说明 |
|---|---|---|---|
| `contact_profile_page` 关注/取消关注 | `contacts_page`、星标联系人页 | `/system/im/contact/setting/update` 成功回执 | 不本地猜关注态 |
| `contact_profile_page` 发消息建会话成功 | 会话列表页、聊天页 | `/system/im/conversation/get-by-target` 返回 `chatId` | 会话不存在时再创建或拉取 |
| `my_groups_page` 进入群详情后发现群已失效 | 我的群组页 | `/system/im/group/get` 返回不存在 | 返回列表并移除失效项 |
| `my_department_page` 切换部门 | 同页成员列表、联系人详情回跳态 | `deptId` 切换 | 不保留旧部门成员缓存误展示 |
| 搜索结果页点击联系人/部门/群 | 来源搜索结果页、目标详情页 | 真实 `userId/deptId/groupId` | 若目标失效，回源页刷新结果 |

联动规则：

1. `contacts` 域优先按“来源列表刷新”收口
2. 联系人详情页不独立维护长期本地副本，修改后回源列表重新取数
3. 发消息成功后的会话跳转以真实 `chatId` 为唯一依据

###### CJ2.2 `group settings` 跨页面联动

| 触发页面/动作 | 需要刷新的页面 | 刷新依据 | 说明 |
|---|---|---|---|
| `group_settings_page` 修改群名 | 群设置主页、我的群组页、会话列表、聊天页标题 | `/system/im/group/update` 成功回执 | 统一以后端新群名为准 |
| `group_settings_page` 开关 `pinned/noDisturb/muteAll` | 群设置主页、会话列表对应项 | 真实写口成功回执 | 不仅改详情页局部开关 |
| `group_members_page` 移除成员 | 群成员页、主设置页成员预览、成员数量 | `/system/im/group/member/remove` 成功后重新拉成员列表与群详情 | 若影响当前用户自身则直接退群页 |
| `group_announcement_page` 保存公告 | 主设置页、聊天页群公告入口 | `/system/im/group/notice/update` 成功后拉群详情 | 不保留旧公告摘要 |
| `group_qr_code_page` 生成/刷新邀请码 | 二维码页、主设置页邀请入口状态 | `/system/im/group/invite/get` 或 `/generate` | 过期码一律刷新，不复用旧码 |
| `group_files_page` 删除文件 | 文件页、聊天文件入口 | `/system/im/group/file/delete` 成功后重新拉文件列表 | 不本地静默删一条 |
| `group_chat_history_page` 跳聊天锚点 | 聊天页 | `chatId + messageId` | 聊天页负责按真实消息详情定位 |

联动规则：

1. 群设置域优先按“主设置页快照 + 子页局部列表”双刷新
2. 涉及群资料变更时，会话列表和聊天页标题也必须刷新
3. 若群已解散或当前用户已退群，所有相关页统一退出，不继续做局部联动

###### CJ2.3 `upgrade` 平台端跨页面联动

| 触发页面/动作 | 需要刷新的页面 | 刷新依据 | 说明 |
|---|---|---|---|
| `product/index.vue` 新增/启停产品 | 产品列表、安装包页筛选项、发布页筛选项 | 产品接口成功回执 | 上游主数据变化要同步筛选源 |
| `package/index.vue` 新增/启停安装包 | 安装包列表、发布页可选包列表 | 安装包接口成功回执 | 包状态决定能否出现在发布单中 |
| `release/index.vue` 创建/发布/下线/回滚 | 发布单列表、渠道分发页、升级日志筛选条件 | 发布单状态成功回执 | 渠道页必须感知最新发布状态 |
| `channelRelease/index.vue` 同步市场状态 | 渠道列表、发布单详情 | `sync-status` 成功或失败结果 | 失败也要更新 `syncMessage` |
| `upgradeLog/index.vue` 修改筛选条件 | 日志列表、摘要统计 | 同一筛选条件 | page 与 summary 始终同源 |

联动规则：

1. `upgrade` 平台端一律按“上游主数据变化带动下游筛选源刷新”处理
2. 列表动作成功后必须重新拉：
   - 当前列表
   - 关联详情
   - 下游可选项
3. 不允许只更新单个表格单元格就认为联动完成

##### CK2. 通话后端异常场景处理顺序与运行日志 / 监控字段冻结

###### CK2.1 异常场景处理顺序

| 异常场景 | 处理顺序 | 结果要求 |
|---|---|---|
| 被叫双端同时接听 | `CallSignalMessageProcessor` 收包 -> `CallSignalService.handleAnswer()` CAS 抢占 -> 成功端写 `acceptedDeviceId` -> 失败端回 `CALL_ACCEPT_DEVICE_CONFLICT/BUSY` | 只允许一个设备进入 `CONNECTING/CONNECTED` |
| 主叫已取消，但被叫离线推送晚到 | 推送点击后先查 `GET /call/detail` -> 若 `state=ENDED` 直接结束 | 不展示来电页 |
| `RINGING` 超时 | `ImCallTimeoutJob` 扫描 -> 委托 `handleTimeout()` -> 广播结束 -> 生成 `CALL_RECORD` | 状态与记录同时闭环 |
| `CONNECTING` 超时 | `ImCallTimeoutJob` 扫描 -> `handleTimeout()` -> 回收房间/凭证 -> 生成结束记录 | 不留悬挂活跃态 |
| 非参与者获取详情/凭证 | Controller 鉴权 -> 返回 `CALL_PERMISSION_DENIED` 或 `CALL_RTC_CREDENTIAL_DENIED` | 不下发任何敏感通话数据 |
| WS 收到无法识别的 `signalType` | Processor 拒绝 -> 记录最小异常字段 -> 不推进状态机 | 不污染主状态 |
| Janus 房间不存在或已回收 | `RtcCredentialService` / 网关适配层发现异常 -> 返回 `CALL_ROOM_NOT_FOUND` 或触发结束态 | 页面不继续建连 |
| 结束信令已下发但 `CALL_RECORD` 生成失败 | 先确保主状态 `ENDED` 落库 -> 记录错误 -> 异步补偿生成记录消息 | 不影响通话终态 |

###### CK2.2 非功能性边界收口

1. 本专题不再继续展开日志字段、监控指标、审计查询后台设计
2. `im_call_event` 若保留，仅作为内部流程回放参考，不再作为独立功能任务推进
3. 后续其它专题同样只补接口流程链路与页面刷新规则，不再复制日志字段模板

##### CL2. 当前这一轮继续后的结论

1. `contacts / group settings / upgrade` 跨页面联动与刷新规则清单已补齐
2. 通话后端异常场景处理顺序与运行日志/监控字段已冻结
3. 文档已明确“后续专题不扩审计类功能，只补接口流程链路与页面规则”
4. 后续若继续文档推进，优先建议：
   - 其余专题继续按本口径补“后端接口流程链路 + 页面联动刷新规则”
   - 通话专题再补“后端接口时序图级清单”

##### CL3. 通话专题后端接口时序图级清单

###### CL3.1 主叫发起 `CALL`

参与方：

- Flutter 呼叫页
- `WS /ws`
- `CallSignalMessageProcessor`
- `CallSignalService`
- `CallStateSyncService`
- 推送通道

时序顺序：

1. Flutter 发送 `CALL_SIGNAL(206)`：
   - `signalType=CALL`
   - `callId`
   - `callType`
   - `chatId`
   - `calleeId`
2. `CallSignalMessageProcessor` 完成：
   - session 鉴权
   - `userId/deviceId/tenantId` 覆盖
   - 基础字段校验
3. `CallSignalService.handleCall()`：
   - 校验通话功能开关
   - 校验当前用户是否忙线
   - 创建或幂等获取 `im_call_record`
   - 初始状态落为 `RINGING`
4. `CallStateSyncService` 生成首个状态快照：
   - `state=RINGING`
   - `status=INITIATED`
   - `acceptedDeviceId=null`
5. 服务端回主叫 WS 回执：
   - `success=true`
   - 当前 `CallStateSnapshot`
6. 服务端给被叫在线设备推：
   - `callInvite`
   - 必要最小字段：`callId/chatId/callerId/callType`
7. 若被叫离线或无活动前台：
   - 进入离线推送
   - 但主状态仍仅以 `im_call_record` 为准

冻结规则：

1. `CALL` 成功只代表“服务端已进入响铃态”，不代表已建媒体连接
2. 本阶段不创建 Janus 房间，不下发 RTC 凭证
3. 同一 `callId` 重复 `CALL` 必须走幂等，不重复创建主记录

###### CL3.2 被叫接听 `ANSWER`

参与方：

- Flutter 来电页
- `WS /ws`
- `CallSignalMessageProcessor`
- `CallSignalService`
- `RtcCredentialService`
- `JanusGatewayAdapter`

时序顺序：

1. 被叫设备发送 `CALL_SIGNAL(206)`：
   - `signalType=ANSWER`
   - `callId`
2. `CallSignalMessageProcessor` 解析并补齐会话字段
3. `CallSignalService.handleAnswer()`：
   - 校验当前用户必须是被叫参与人
   - 校验主状态必须仍为 `RINGING`
   - CAS 抢占 `acceptedDeviceId`
4. 抢占成功后：
   - 主状态转 `CONNECTING`
   - 写入 `acceptedDeviceId/acceptedAt`
5. 抢占失败的其它设备：
   - 回 `CALL_ACCEPT_DEVICE_CONFLICT` 或 `BUSY`
   - 仅退出，不修改主状态
6. `RtcCredentialService` 检查或准备 RTC 资源：
   - 若无可复用房间，则创建逻辑房间记录
   - 按需向 `JanusGatewayAdapter` 申请房间/句柄/临时 token
7. 服务端分别通知主叫端、接听成功端：
   - `callAccepted`
   - `callStateSync(state=CONNECTING, acceptedDeviceId=...)`
8. 接听成功设备再通过 REST 拉：
   - `GET /system/im/call/detail`
   - `GET /system/im/call/rtc-credential`
9. Flutter 仅在：
   - `state=CONNECTING`
   - 且当前设备等于 `acceptedDeviceId`
   时进入媒体建连

冻结规则：

1. RTC 凭证下发必须晚于 `acceptedDeviceId` 裁决成功
2. 非接听成功设备不得获取有效 RTC 凭证
3. `ANSWER` 成功语义是“允许建连”，不是“已经 CONNECTED”

###### CL3.3 会中建连成功与挂断 `HANGUP`

参与方：

- Flutter 会中页
- `WS /ws`
- `CallSignalMessageProcessor`
- `CallSignalService`
- `CallRecordMessageFactory`
- 消息主链路

时序顺序：

1. 接听成功设备建媒体成功后，上报：
   - `CALL_SIGNAL(206)`
   - `signalType=STATE_SYNC`
   - `state=CONNECTED`
2. `CallSignalService.handleStateSync()`：
   - 校验当前设备必须是 `acceptedDeviceId`
   - 把主状态转为 `CONNECTED`
   - 写入 `connectedAt`
3. 服务端广播：
   - `callStateSync(state=CONNECTED)`
4. 任一参与人挂断时发送：
   - `signalType=HANGUP`
   - `callId`
   - 可带 `hangupReason`
5. `CallSignalService.handleHangup()`：
   - 校验当前状态为 `RINGING/CONNECTING/CONNECTED`
   - 原子落为 `ENDED`
   - 计算 `status/endReason/durationSeconds`
6. 若存在 RTC 房间：
   - 调 `RtcCredentialService` / `JanusGatewayAdapter` 做回收标记
7. 广播结束事件：
   - `callEnded`
   - `callStateSync(state=ENDED, status, endReason)`
8. `CallRecordMessageFactory` 生成 `CALL_RECORD=209`
9. 主消息链路入库后：
   - 会话预览刷新
   - 聊天页插入通话记录消息
   - 通话记录页可查

冻结规则：

1. `CALL_RECORD` 是结束后的记录消息，不承载瞬态信令
2. 先保证主状态 `ENDED`，再生成记录消息
3. `HANGUP` 重复到达必须幂等

###### CL3.4 恢复态查询 `detail / active / rtc-credential`

参与方：

- Flutter 启动壳/通话页恢复逻辑
- `AppImCallController`
- `CallStateSyncService`
- `RtcCredentialService`

时序顺序：

1. Flutter 前台恢复、重连或推送点击后，先查：
   - `GET /system/im/call/active`
2. 若存在活跃通话：
   - 再查 `GET /system/im/call/detail?callId=...`
3. `AppImCallController` 委托 `CallStateSyncService` 返回权威快照：
   - `callId`
   - `state/status/endReason`
   - `acceptedDeviceId`
   - `callerId/calleeId`
4. 只有当：
   - `state in (CONNECTING, CONNECTED)`
   - 当前设备等于 `acceptedDeviceId`
   才允许继续拉 `GET /system/im/call/rtc-credential`
5. `RtcCredentialService` 校验：
   - 房间未失效
   - 凭证未过期
   - 当前设备有资格建连
6. 返回：
   - Janus 地址
   - 临时 token
   - TURN 配置
   - 过期时间
7. 若 `active/detail` 已是 `ENDED`：
   - Flutter 直接退出通话页
   - 不再请求媒体凭证

冻结规则：

1. `active` 只回答“当前是否存在活跃通话”
2. `detail` 只回答“该 `callId` 的完整权威状态”
3. `rtc-credential` 只负责单次媒体建连授权

###### CL3.5 超时与房间回收 `TIMEOUT / RECYCLE`

参与方：

- `ImCallTimeoutJob`
- `CallSignalService`
- `RtcCredentialService`
- `JanusGatewayAdapter`
- `CallRecordMessageFactory`

时序顺序：

1. `ImCallTimeoutJob` 周期扫描：
   - `RINGING` 超过响铃阈值
   - `CONNECTING` 超过建连阈值
2. 命中记录后委托 `CallSignalService.handleTimeout()`
3. `handleTimeout()`：
   - 原子改主状态为 `ENDED`
   - 写 `status/endReason`
4. 若存在媒体资源：
   - 调 `RtcCredentialService` 标记失效
   - 调 `JanusGatewayAdapter` 回收房间/句柄
5. 广播：
   - `callEnded`
   - `callStateSync(state=ENDED, endReason=...)`
6. 生成 `CALL_RECORD=209`
7. 若消息生成失败：
   - 记录补偿任务
   - 不回滚主状态

冻结规则：

1. 超时结束与主动挂断走同一主状态闭环
2. 房间回收失败不允许阻塞主状态结束
3. `im_call_record` 是终态权威，Janus 房间只是派生资源

##### CL4. `upgrade` 客户端检查链路与平台端发布命中链路补充

###### CL4.1 端侧手动检查更新

参与方：

- Flutter 设置页
- `POST /system/app-upgrade/check`
- 平台升级命中服务

时序顺序：

1. 设置页点击“检查更新”
2. Flutter 提交 `AppUpgradeCheckReqVO`：
   - `appCode`
   - `platform`
   - `channel`
   - `tenantId`
   - `versionName/versionCode/buildNo`
   - `deviceId`
3. `AppUpgradeController.check()`：
   - 校验产品是否启用
   - 校验平台是否受支持
   - 查询可用发布单
   - 套用灰度命中规则
4. 命中后组装 `AppUpgradeCheckRespVO`
5. Flutter 仅根据真实返回决定：
   - 不弹窗
   - 建议升级
   - 强制升级
   - 打开市场/下载页/浏览器
6. 用户操作后再调：
   - `POST /system/app-upgrade/report-event`

冻结规则：

1. 设置页不本地比较版本号做最终裁决
2. 是否强更、跳什么动作，全部以 `check()` 返回为准
3. 上报失败不阻断真实升级动作

###### CL4.2 平台端发布单命中到客户端

参与方：

- `shengyu-ui-platform-vue3`
- 平台升级后台
- `AppUpgradeController.check()`
- Flutter 端

时序顺序：

1. 平台端完成：
   - 产品创建
   - 安装包登记
   - 发布单审核
   - 渠道发布
2. 后端把已发布资产固化到：
   - 产品
   - 安装包
   - 发布单
   - 渠道分发表
3. Flutter 触发 `check()`
4. 升级命中服务按顺序筛选：
   - `appCode/platform`
   - `tenantScope`
   - `channel`
   - `status=PUBLISHED`
   - 灰度命中
   - 版本号是否高于当前端
5. 命中后返回：
   - `upgradeType`
   - `action`
   - `downloadUrl/marketUrl`
   - `title/content`
   - `versionName/versionCode`
6. Flutter 执行动作：
   - `OPEN_URL`
   - `OPEN_APP_STORE`
   - `OPEN_PLAY_STORE`
   - `OPEN_APP_GALLERY`
   - `HOT_UPDATE`（仅当平台与端能力已明确支持）

冻结规则：

1. 平台端负责发布治理，Flutter 端只负责消费命中结果
2. 客户端不自行拼渠道命中规则
3. `HOT_UPDATE` 必须单独受平台能力和端能力双重约束

###### CL4.3 升级事件回流链路

参与方：

- Flutter 升级弹窗/升级动作
- `POST /system/app-upgrade/report-event`
- 平台升级日志页

时序顺序：

1. Flutter 在关键动作点上报：
   - `POPUP_SHOWN`
   - `CLICK_UPGRADE`
   - `CLICK_LATER`
   - `DOWNLOAD_STARTED`
   - `DOWNLOAD_FAILED`
   - `INSTALL_STARTED`
   - `UPGRADE_SUCCEEDED`
2. `AppUpgradeController.reportEvent()`：
   - 记录发布单主键
   - 记录平台/渠道/设备
   - 记录事件时间与结果
3. 后端写入 `platform_app_upgrade_log`
4. 平台端 `upgradeLog/index.vue`：
   - 分页查询日志
   - 聚合摘要
   - 按筛选条件联动刷新

冻结规则：

1. 事件回流只服务升级主功能，不单独扩展审计子系统
2. 日志统计结果只以服务端已入库事件为准
3. 未上报成功的事件不本地假计入平台摘要

##### CL5. 当前这一轮继续后的结论

1. 通话专题已补到后端接口时序图级清单，可直接指导 `CALL/ANSWER/HANGUP/RECOVER/TIMEOUT` 五条主链路开发
2. `upgrade` 已补到“客户端检查更新 -> 平台发布命中 -> 事件回流”的真实实现链路
3. 当前统一文档对两大缺失后端专题已进一步从“接口/类清单”推进到“场景时序级”
4. 后续若继续文档推进，优先建议：
   - 通话专题继续补“缺失后端类与 SQL 补丁落库顺序”
   - `upgrade` 继续补“平台端 API 返回示例 JSON 与页面消费字段对照”

##### CL6. 通话专题缺失后端类与 SQL 补丁落库顺序

###### CL6.1 SQL / DO 第一批补丁

执行顺序：

1. 扩 `im_call_record`
2. 新增或校准 `im_call_event`
3. 补充 RTC 房间映射表

建议字段：

`im_call_record` 补齐：

- `call_id`
- `chat_id`
- `call_type`
- `state`
- `status`
- `end_reason`
- `caller_id`
- `callee_id`
- `accepted_device_id`
- `rtc_room_id`
- `started_at`
- `accepted_at`
- `connected_at`
- `ended_at`
- `duration_seconds`
- `tenant_id`

`im_call_event` 最小保留字段：

- `id`
- `call_id`
- `signal_type`
- `from_user_id`
- `from_device_id`
- `event_time`
- `payload_json`

`im_call_rtc_room` 建议字段：

- `id`
- `call_id`
- `rtc_room_id`
- `janus_room_id`
- `room_status`
- `credential_expire_at`
- `recycle_status`
- `tenant_id`

索引顺序：

1. `im_call_record.uk_call_id`
2. `im_call_record.idx_callee_state`
3. `im_call_record.idx_chat_started_at`
4. `im_call_event.idx_call_time`
5. `im_call_rtc_room.uk_call_id`

###### CL6.2 Java 类落库顺序

第一批必须先落：

1. `dal/dataobject/im/ImCallRecordDO.java`
2. `dal/dataobject/im/ImCallEventDO.java`
3. `dal/dataobject/im/ImCallRtcRoomDO.java`
4. `dal/mysql/im/ImCallRecordMapper.java`
5. `dal/mysql/im/ImCallEventMapper.java`
6. `dal/mysql/im/ImCallRtcRoomMapper.java`

第二批紧接着落：

1. `enums/im/ImCallStateEnum.java`
2. `enums/im/ImCallStatusEnum.java`
3. `enums/im/ImCallEndReasonEnum.java`
4. `enums/im/ImCallSignalTypeEnum.java`

第三批再落：

1. `service/im/dto/CallStateSnapshot.java`
2. `service/im/dto/CallAnswerResult.java`
3. `service/im/dto/ImCallEndResult.java`
4. `service/im/dto/RtcRoomBinding.java`

冻结规则：

1. DO 与枚举必须先于 service 落地
2. `RtcRoomBinding` 只承接媒体资源映射，不承接业务主状态
3. `payload_json` 仅用于最小流程回放，不扩独立日志产品能力

###### CL6.3 与 controller/service 的补丁依赖关系

依赖顺序：

1. SQL/DO/Mapper 就位
2. `AppImCallController` 查询面落地
3. `CallSignalService` 控制面落地
4. `RtcCredentialService` 接媒体适配层
5. `CallSignalMessageProcessor` 注册
6. `ImCallTimeoutJob` 上线

禁止顺序：

1. 先写 Processor 再补 Mapper
2. 先接 Janus 再冻结 `rtc_room_id/janus_room_id`
3. 先让 Flutter 真连媒体，再补 `acceptedDeviceId` 裁决字段

##### CL7. `upgrade` 平台端 API 返回示例 JSON 与页面消费字段对照

###### CL7.1 `product/index.vue`

建议列表接口：

- `GET /platform-api/system/app-upgrade-product/page`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "id": "prod_im_app",
        "appCode": "im-app",
        "appName": "ShengYu IM",
        "tenantMode": 1,
        "status": 0,
        "platforms": ["ANDROID", "IOS", "WEB", "WINDOWS", "MACOS"],
        "remark": "IM 主产品"
      }
    ],
    "total": 1
  },
  "msg": ""
}
```

页面消费字段：

| 页面字段 | RespVO 字段 | 说明 |
|---|---|---|
| 产品编码 | `appCode` | 唯一主筛选键 |
| 产品名称 | `appName` | 列表与表单同源 |
| 状态开关 | `status` | 只基于状态码显隐按钮 |
| 支持平台 | `platforms` | 控制下游安装包平台选项 |

###### CL7.2 `package/index.vue`

建议列表接口：

- `GET /platform-api/system/app-upgrade-package/page`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "id": "pkg_android_210",
        "productId": "prod_im_app",
        "platform": "ANDROID",
        "distributionMode": "OPEN_URL",
        "versionName": "2.1.0",
        "versionCode": 210,
        "buildNo": "20260502.1",
        "fileId": "184001",
        "downloadUrl": "https://cdn.example.com/im-2.1.0.apk",
        "status": 0
      }
    ],
    "total": 1
  },
  "msg": ""
}
```

页面消费字段：

| 页面字段 | RespVO 字段 | 说明 |
|---|---|---|
| 平台 | `platform` | 控制平台标签和筛选 |
| 分发方式 | `distributionMode` | 影响发布动作选项 |
| 版本号 | `versionName/versionCode` | 列表展示与发布单校验同源 |
| 下载地址 | `downloadUrl` | 仅 `OPEN_URL` 等模式需要 |
| 状态 | `status` | 决定能否被发布单引用 |

###### CL7.3 `release/index.vue`

建议详情接口：

- `GET /platform-api/system/app-upgrade-release/get?id=...`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "id": "rel_20260502001",
    "productId": "prod_im_app",
    "packageId": "pkg_android_210",
    "platform": "ANDROID",
    "versionName": "2.1.0",
    "versionCode": 210,
    "grayRuleType": "TENANT_PERCENT",
    "grayRuleValue": "20",
    "upgradeType": "SUGGESTED",
    "action": "OPEN_URL",
    "status": "APPROVED",
    "title": "发现新版本",
    "content": "修复已知问题并提升稳定性。"
  },
  "msg": ""
}
```

页面消费字段：

| 页面字段 | RespVO 字段 | 说明 |
|---|---|---|
| 发布状态 | `status` | 控制提交审核/审核/回滚按钮 |
| 灰度规则 | `grayRuleType/grayRuleValue` | 仅显示真实命中规则 |
| 升级类型 | `upgradeType` | 决定强更/建议升级展示 |
| 动作 | `action` | 决定客户端跳商店还是下载 |
| 弹窗文案 | `title/content` | 与客户端 `check()` 返回同源 |

###### CL7.4 `channelRelease/index.vue`

建议列表接口：

- `GET /platform-api/system/app-upgrade-channel-release/page`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "list": [
      {
        "id": "cr_android_huawei_001",
        "releaseId": "rel_20260502001",
        "channel": "HUAWEI_APP_GALLERY",
        "externalVersion": "2.1.0",
        "publishStatus": "PUBLISHED",
        "syncStatus": "SUCCESS",
        "syncMessage": "market synced",
        "publishedAt": 1777699200000
      }
    ],
    "total": 1
  },
  "msg": ""
}
```

页面消费字段：

| 页面字段 | RespVO 字段 | 说明 |
|---|---|---|
| 渠道 | `channel` | 控制渠道标签 |
| 发布状态 | `publishStatus` | 控制下线/同步按钮 |
| 同步状态 | `syncStatus` | 控制状态色与重试入口 |
| 同步说明 | `syncMessage` | 失败信息只显示服务端文本 |
| 发布时间 | `publishedAt` | 列表排序与详情展示同源 |

###### CL7.5 `upgradeLog/index.vue`

建议摘要接口：

- `GET /platform-api/system/app-upgrade-log/summary`

RespVO 示例：

```json
{
  "code": 0,
  "data": {
    "popupShownCount": 1200,
    "clickUpgradeCount": 420,
    "downloadStartedCount": 390,
    "upgradeSucceededCount": 260,
    "latestEventTime": 1777702800000
  },
  "msg": ""
}
```
页面消费字段：

| 页面字段 | RespVO 字段 | 说明 |
|---|---|---|
| 弹窗曝光 | `popupShownCount` | 摘要卡片真实值 |
| 点击升级 | `clickUpgradeCount` | 漏斗第二步 |
| 下载启动 | `downloadStartedCount` | 下载链路观察值 |
| 升级成功 | `upgradeSucceededCount` | 最终转化 |
| 最近事件时间 | `latestEventTime` | 列表与摘要时间感知一致 |

##### CL8. 当前这一轮继续后的结论

1. 通话专题已补到“SQL/DO/Mapper/Enum/DTO”的缺失后端落库顺序
2. `upgrade` 平台端已补到 API 返回示例 JSON 与页面消费字段对照
3. 当前统一文档已经能同时指导：
   - 通话后端数据库与类落地
   - 升级平台端 API 与前端页面字段对接
4. 后续若继续文档推进，优先建议：
   - 通话专题继续补“WS proto 与 `extraData` 子结构到后端 DTO 的逐字段映射”
   - `upgrade` 继续补“平台端创建/审核/发布/回滚四条操作链的请求示例 JSON”

##### CL9. 通话 WS proto 与 `extraData` -> 后端 DTO 逐字段映射

###### CL9.1 proto 主体字段映射

老项目现有 `CallSignalMessage` 字段：

- `callId`
- `callType`
- `signalType`
- `callerId`
- `calleeId`
- `rejectReason`
- `extraData`

后端接收 DTO 建议：

`AppImCallSignalReqDTO`

| proto 字段 | DTO 字段 | 类型建议 | 说明 |
|---|---|---|---|
| `callId` | `callId` | `String` | 全链路主键 |
| `callType` | `callType` | `Integer` | `1=audio, 2=video` |
| `signalType` | `signalType` | `Integer/Enum` | 映射 `ImCallSignalTypeEnum` |
| `callerId` | 不直接信任客户端值 | `String` | 以 session `userId` 为准，proto 值仅做排错参考 |
| `calleeId` | `calleeId` | `String` | `CALL` 场景必要 |
| `rejectReason` | `rejectReason` | `String` | 仅 `REJECT` 场景消费 |
| `extraData` | `extraDataJson` | `String` | 原样保留，再二次解析到子 DTO |

冻结规则：

1. `callerId` 最终以登录态 session 覆盖，不允许客户端伪造
2. `callId/signalType` 必须先通过基础校验，再进入 `extraData` 解析
3. `extraData` 允许为空字符串，但业务层必须按 `signalType` 判断是否必填

###### CL9.2 `signalType` -> 子 DTO 映射建议

| `signalType` | 后端子 DTO | 说明 |
|---|---|---|
| `CALL` | `CallInviteExtraDTO` | 发起呼叫的目标与上下文 |
| `ANSWER` | `CallAnswerExtraDTO` | 接听设备信息 |
| `REJECT` | `CallRejectExtraDTO` | 拒接原因 |
| `CANCEL` | `CallCancelExtraDTO` | 主叫取消原因 |
| `HANGUP` | `CallHangupExtraDTO` | 结束原因、时长摘要 |
| `STATE_SYNC` | `CallStateSyncExtraDTO` | `CONNECTING/CONNECTED` 等状态同步 |
| `RTC_OFFER` | `CallRtcOfferExtraDTO` | SDP offer 载荷 |
| `RTC_ANSWER` | `CallRtcAnswerExtraDTO` | SDP answer 载荷 |
| `ICE_CANDIDATE` | `CallIceCandidateExtraDTO` | ICE 候选 |
| `PING` 或等价保活 | `CallPingExtraDTO` | 可选，若保留则仅作链路保活 |

###### CL9.3 `CALL` 场景 `extraData` 建议结构

建议 JSON：

```json
{
  "chatId": "chat_873214",
  "targetUserId": "10002",
  "deviceId": "ios_abc001",
  "clientSeq": "call_invite_001",
  "source": "chat",
  "timeoutSeconds": 45
}
```

映射到 `CallInviteExtraDTO`：

| JSON 字段 | DTO 字段 | 说明 |
|---|---|---|
| `chatId` | `chatId` | 关联会话主键 |
| `targetUserId` | `targetUserId` | 与 `calleeId` 同源校验 |
| `deviceId` | `deviceId` | 发起端设备 |
| `clientSeq` | `clientSeq` | 幂等辅助键 |
| `source` | `source` | 来源页，如 `chat/contact/group` |
| `timeoutSeconds` | `timeoutSeconds` | 客户端建议值，服务端可覆盖 |

###### CL9.4 `ANSWER / REJECT / HANGUP` 场景 `extraData`

`ANSWER`：

```json
{
  "deviceId": "android_xyz002",
  "clientSeq": "answer_001"
}
```

`REJECT`：

```json
{
  "deviceId": "android_xyz002",
  "reasonCode": "USER_REJECT",
  "clientSeq": "reject_001"
}
```

`HANGUP`：

```json
{
  "deviceId": "ios_abc001",
  "reasonCode": "NORMAL_HANGUP",
  "clientDurationSeconds": 312,
  "clientSeq": "hangup_001"
}
```

映射规则：

1. `deviceId` 可参与多端裁决，但最终以 session 设备为准
2. `reasonCode` 仅作输入建议，最终 `endReason` 由服务端状态机裁定
3. `clientDurationSeconds` 只能做参考，不直接作为落表权威值

###### CL9.5 `STATE_SYNC / RTC_OFFER / RTC_ANSWER / ICE_CANDIDATE` 场景 `extraData`

`STATE_SYNC`：

```json
{
  "state": "CONNECTED",
  "deviceId": "android_xyz002",
  "connectedAt": 1777693512000
}
```

`RTC_OFFER`：

```json
{
  "sdp": "v=0...",
  "sdpType": "offer",
  "deviceId": "android_xyz002"
}
```

`RTC_ANSWER`：

```json
{
  "sdp": "v=0...",
  "sdpType": "answer",
  "deviceId": "ios_abc001"
}
```

`ICE_CANDIDATE`：

```json
{
  "candidate": "candidate:1 1 udp ...",
  "sdpMid": "0",
  "sdpMLineIndex": 0,
  "deviceId": "android_xyz002"
}
```

消费边界：

1. `STATE_SYNC` 只允许推进有限状态，不允许越级改终态
2. `RTC_OFFER/RTC_ANSWER/ICE_CANDIDATE` 不落 `im_call_record` 主字段
3. 媒体协商原始载荷可以短期透传，但不建议长期完整落库

###### CL9.6 Processor 到 service 的解析顺序

固定顺序：

1. 解 proto
2. 校验 `callId/signalType`
3. session 覆盖 `userId/deviceId/tenantId`
4. 解析 `extraData` 到对应子 DTO
5. 组装 `CallSignalCommand`
6. 分发给 `CallSignalService`

禁止顺序：

1. 不先校验 `signalType` 就盲解析 `extraData`
2. 不以 proto 的 `callerId` 直接裁决权限
3. 不把 `RTC_OFFER/ICE` 原始字段直接塞进 `AppImCallDetailRespVO`

##### CL10. `upgrade` 平台端创建 / 审核 / 发布 / 回滚请求示例 JSON

###### CL10.1 创建产品 `POST /platform-api/system/app-upgrade-product/create`

ReqVO 示例：

```json
{
  "appCode": "im-app",
  "appName": "ShengYu IM",
  "tenantMode": 1,
  "platforms": ["ANDROID", "IOS", "WEB", "WINDOWS", "MACOS"],
  "remark": "IM 主产品"
}
```

页面消费要点：

1. `product/index.vue` 表单提交只发真实字段
2. `appCode` 冲突时以后端字段错误为准

###### CL10.2 审核发布单 `POST /platform-api/system/app-upgrade-release/audit`

ReqVO 示例：

```json
{
  "id": "rel_20260502001",
  "auditStatus": "APPROVED",
  "auditRemark": "版本内容与渠道配置通过"
}
```

页面消费要点：

1. `release/index.vue` 审核动作必须基于当前真实 `status`
2. 审核后刷新列表与详情，不本地切状态

###### CL10.3 发布渠道 `POST /platform-api/system/app-upgrade-channel-release/publish`

ReqVO 示例：

```json
{
  "releaseId": "rel_20260502001",
  "channel": "HUAWEI_APP_GALLERY",
  "track": "production",
  "grayPercent": 20,
  "marketPackageName": "cn.shengyu.im",
  "remark": "华为正式渠道发布"
}
```

页面消费要点：

1. `channelRelease/index.vue` 只提交渠道必需字段
2. 发布失败时保留表单并展示 `syncMessage/errorMessage`

###### CL10.4 回滚发布单 `POST /platform-api/system/app-upgrade-release/rollback`

ReqVO 示例：

```json
{
  "id": "rel_20260502001",
  "rollbackTargetReleaseId": "rel_20260418003",
  "reason": "2.1.0 渠道崩溃率异常，回滚到上一稳定版本"
}
```

页面消费要点：

1. 回滚目标必须来自后端可回滚列表，不本地猜最近版本
2. 回滚成功后同时刷新：
   - `release/index.vue`
   - `channelRelease/index.vue`
   - `upgradeLog/index.vue` 筛选源

##### CL11. 当前这一轮继续后的结论

1. 通话专题已补到 proto 主字段与 `extraData` 子结构到后端 DTO 的逐字段映射
2. `upgrade` 平台端已补到创建/审核/发布/回滚四条主操作链的请求示例 JSON
3. 当前统一文档已经能继续指导：
   - 通话 WS 控制面 processor/service DTO 设计
   - 平台升级中心表单提交流程与后端请求结构
4. 后续若继续文档推进，优先建议：
   - 通话专题继续补“WS 回执包 / `callStateSync` / `callEnded` 下发字段示例”
   - `upgrade` 继续补“平台端详情页/抽屉页字段刷新顺序与成功回执消费口径”

##### CL12. 通话 WS 回执包 / `callStateSync` / `callEnded` 下发字段示例

###### CL12.1 `CALL_SIGNAL` 服务端动作回执包建议

适用场景：

- `CALL`
- `ANSWER`
- `REJECT`
- `HANGUP`
- `STATE_SYNC`

回执包建议最小结构：

```json
{
  "messageType": 206,
  "success": true,
  "code": "0",
  "message": "ok",
  "body": {
    "callId": "call_202605020001",
    "signalType": "ANSWER",
    "serverTime": 1777693400000,
    "snapshot": {
      "callId": "call_202605020001",
      "state": "CONNECTING",
      "status": "ANSWERED",
      "endReason": null,
      "callerId": "10001",
      "calleeId": "10002",
      "acceptedDeviceId": "android_xyz002"
    }
  }
}
```

字段消费口径：

| 字段 | Flutter 消费点 | 说明 |
|---|---|---|
| `success/code/message` | controller 动作结果 | 仅判断服务端是否受理 |
| `body.callId` | 当前通话主键校验 | 迟到回包需按 `callId` 丢弃 |
| `body.signalType` | 调试与幂等判定 | 不直接驱动 UI 最终态 |
| `body.serverTime` | 状态时间基准 | 仅用于辅助排序/排错 |
| `body.snapshot` | `CallState` 合并入口 | 最终 UI 仍以 snapshot 为准 |

冻结规则：

1. 动作回执包不承载 SDP/ICE 原始大字段
2. 回执失败也应尽量带最小 `callId/code/message`
3. Flutter 不应仅凭 `success=true` 就切到 `CONNECTED`

###### CL12.2 `callInvite` 下发事件示例

```json
{
  "event": "callInvite",
  "data": {
    "callId": "call_202605020001",
    "callType": 2,
    "callerId": "10001",
    "calleeId": "10002",
    "chatId": "chat_873214",
    "state": "RINGING",
    "acceptedDeviceId": null,
    "title": "语音/视频通话",
    "serverTime": 1777693200000
  }
}
```

消费规则：

1. `/call/incoming` 先以此事件建最小来电壳
2. 随后必须补 `GET /system/im/call/detail`
3. 若详情已是 `ENDED`，直接退出，不展示来电页

###### CL12.3 `callStateSync` 下发事件示例

```json
{
  "event": "callStateSync",
  "data": {
    "callId": "call_202605020001",
    "state": "CONNECTED",
    "status": "ANSWERED",
    "endReason": null,
    "callerId": "10001",
    "calleeId": "10002",
    "acceptedDeviceId": "android_xyz002",
    "connectedAt": 1777693512000,
    "durationSeconds": 0
  }
}
```

字段消费口径：

| 字段 | Flutter 消费点 | 说明 |
|---|---|---|
| `state` | `CallState.state` | 页面主状态切换唯一权威字段 |
| `status` | 结束前后辅助标签 | 不替代 `state` |
| `endReason` | 结束态说明 | 仅 `ENDED` 时重点消费 |
| `acceptedDeviceId` | `call_media_controller` | 判断当前设备是否允许建媒体 |
| `connectedAt` | 会中计时器起点 | 本地计时基于真实接通时间 |
| `durationSeconds` | 恢复态显示 | 仅恢复/结束时可直接消费 |

冻结规则：

1. `callStateSync` 可以反复下发，但 `state` 不允许非法回退
2. Flutter 若收到非当前 `callId` 的同步包必须忽略
3. `acceptedDeviceId` 变化时要优先中断错误设备的媒体建连

###### CL12.4 `callEnded` 下发事件示例

```json
{
  "event": "callEnded",
  "data": {
    "callId": "call_202605020001",
    "state": "ENDED",
    "status": "ANSWERED",
    "endReason": "NORMAL_HANGUP",
    "durationSeconds": 312,
    "recordMessageId": "987654321001",
    "endedAt": 1777693824000
  }
}
```

字段消费口径：

| 字段 | Flutter 消费点 | 说明 |
|---|---|---|
| `state=ENDED` | 通话页退出分支 | 收到即结束页面主流程 |
| `status/endReason` | 结束文案 | 用于“已取消/已拒绝/未接听/已结束” |
| `durationSeconds` | 记录卡片/结束页 | 不再从本地计时器反推 |
| `recordMessageId` | 聊天页定位 | 后续 `CALL_RECORD` 到达可做锚点关联 |
| `endedAt` | 恢复态终止判断 | 防止迟到事件再次唤起页面 |

冻结规则：

1. `callEnded` 是终局事件，消费后页面不得再回到会中态
2. `recordMessageId` 可为空，不能为空时才做聊天页联动
3. `callEnded` 与 `callStateSync(state=ENDED)` 可以并存，但最终只消费一次结束逻辑

###### CL12.5 `callAccepted / callRejected / callBusy / callCancelled` 轻事件建议

这些事件可作为轻提示事件保留，建议最小结构统一：

```json
{
  "event": "callAccepted",
  "data": {
    "callId": "call_202605020001",
    "operatorUserId": "10002",
    "operatorDeviceId": "android_xyz002",
    "serverTime": 1777693400000
  }
}
```

消费边界：

1. 轻事件只做提示，不单独决定最终通话态
2. 真正的页面态切换仍应等：
   - `callStateSync`
   - 或 `GET /system/im/call/detail`

##### CL13. `upgrade` 详情页 / 抽屉页字段刷新顺序与成功回执消费口径

###### CL13.1 `product/index.vue` 新建/编辑后的刷新顺序

成功回执后固定顺序：

1. 关闭 `ProductForm.vue`
2. 刷新产品列表
3. 刷新安装包页筛选源
4. 刷新发布单页筛选源

消费口径：

| 回执字段 | 页面消费点 | 说明 |
|---|---|---|
| `id` | 当前行主键 | 列表重载后高亮可选 |
| `status` | 状态列/按钮显隐 | 只以服务端状态重绘 |
| `platforms` | 下游筛选源 | 影响 package/release 表单选项 |

###### CL13.2 `release/index.vue` 详情抽屉刷新顺序

适用动作：

- 创建发布单
- 提交审核
- 审核通过/驳回
- 回滚

成功回执后固定顺序：

1. 刷新当前详情抽屉 `get(id)`
2. 刷新发布单列表 `page`
3. 若状态影响渠道分发：
   - 刷新 `channelRelease/index.vue` 当前筛选源
4. 若状态影响日志：
   - 刷新 `upgradeLog/index.vue` 的发布单筛选候选

消费口径：

| 回执字段 | 页面消费点 | 说明 |
|---|---|---|
| `id` | 详情抽屉重新查询 | 不直接拿提交回包覆盖整页 |
| `status` | 审核/回滚按钮显隐 | 仅用于触发重查后的按钮重绘 |
| `packageId` | 渠道页联动筛选 | 包变更需带动下游 |

###### CL13.3 `channelRelease/index.vue` 抽屉/行级动作刷新顺序

适用动作：

- 发布渠道
- 下线渠道
- 同步市场状态

成功回执后固定顺序：

1. 刷新渠道列表当前页
2. 刷新当前渠道详情抽屉
3. 刷新关联发布单详情摘要
4. 若 `syncStatus/syncMessage` 变化，刷新当前行展示

消费口径：

| 回执字段 | 页面消费点 | 说明 |
|---|---|---|
| `publishStatus` | 行级按钮显隐 | 控制继续发布/下线 |
| `syncStatus` | 状态标签 | `SUCCESS/FAILED/PENDING` |
| `syncMessage` | 错误说明区域 | 只展示真实返回文案 |
| `publishedAt` | 时间列/详情抽屉 | 与列表详情同源 |

###### CL13.4 `upgradeLog/index.vue` 成功回执消费口径

适用动作：

- 修改筛选条件
- 导出
- 上游专题动作成功后联动刷新

刷新顺序：

1. 先刷 `summary`
2. 再刷 `page`
3. 保持两者使用同一筛选模型快照

消费口径：

| 回执字段 | 页面消费点 | 说明 |
|---|---|---|
| `popupShownCount` | 摘要卡片 | 曝光总量 |
| `clickUpgradeCount` | 摘要卡片 | 点击升级转化 |
| `upgradeSucceededCount` | 摘要卡片 | 最终成功数 |
| `list[*].eventType` | 日志列表 | 事件类型标签 |
| `list[*].releaseId` | 日志详情跳转 | 关联发布单入口 |

###### CL13.5 统一成功回执消费规则

1. 平台端所有表单/抽屉动作成功后，都先重查详情，再重查列表
2. 不允许把表单提交回包直接当作最终详情态长期持有
3. 任何影响下游筛选项的成功动作，都必须连带刷新下游筛选源
4. `upgradeLog/index.vue` 只消费真实事件回流结果，不从操作成功本地猜测摘要数字

##### CL14. 当前这一轮继续后的结论

1. 通话专题已补到 WS 动作回执包与 `callInvite/callStateSync/callEnded` 下发字段示例
2. `upgrade` 已补到详情页/抽屉页的刷新顺序与成功回执消费口径
3. 当前统一文档已经能进一步指导：
   - 通话端到端 WS 下发事件消费
   - 平台升级中心页面动作后的真实刷新顺序
4. 后续若继续文档推进，优先建议：
   - 通话专题继续补“错误码到 Flutter 页面动作分支映射表”
   - `upgrade` 继续补“列表筛选模型与详情抽屉共享字段冻结表”

##### CL15. 通话错误码 -> Flutter 页面动作分支映射表

###### CL15.1 主映射表

| 错误码常量 | 典型出现位置 | Flutter 页面/控制器分支 | 页面动作 |
|---|---|---|---|
| `CALL_RECORD_NOT_EXISTS` | `GET /call/detail` `GET /call/active` `GET /call/records/*` | `incoming/outgoing/session/record` 查询失败分支 | 退出通话页；记录页进空态 |
| `CALL_PERMISSION_DENIED` | `detail/active/rtc-credential` 或 WS 动作回执 | 权限失败分支 | 立即退出通话路由，不重试 |
| `CALL_ALREADY_IN_PROGRESS` | 主叫 `CALL` 回执 | `outgoing` 忙线分支 | 结束拨出页，提示对方忙线 |
| `CALL_STATE_INVALID` | `ANSWER/HANGUP/STATE_SYNC` 回执、`detail` 恢复查询 | 非法状态分支 | 结束当前页并停止后续媒体动作 |
| `CALL_FEATURE_DISABLED` | `CALL` 回执、`active/detail` 查询 | 功能关闭分支 | 不进入通话页；恢复流程直接终止 |
| `CALL_CALLEE_OFFLINE` | 主叫 `CALL` 回执 | 主叫拨出异常分支 | 结束拨出页，提示对方不在线 |
| `CALL_ACCEPT_DEVICE_CONFLICT` | 被叫多端 `ANSWER`、非接听设备 `STATE_SYNC` | 多端冲突分支 | 当前设备退出，不再尝试建连 |
| `CALL_RTC_CREDENTIAL_DENIED` | `GET /call/rtc-credential` | 媒体授权失败分支 | 不建媒体，切到结束态 |
| `CALL_RTC_CREDENTIAL_EXPIRED` | `GET /call/rtc-credential` 或续期 | 凭证过期分支 | 允许一次重拉；失败则结束 |
| `CALL_PUSH_DEVICE_INVALID` | 服务端推送侧、少量回执透出 | 仅提示分支 | 不影响当前主状态，不本地改通话态 |
| `CALL_SIGNAL_UNSUPPORTED` | WS `CALL_SIGNAL` 回执 | 信令兼容失败分支 | 当前动作失败，页面保持原状态或结束 |
| `CALL_ROOM_NOT_FOUND` | `GET /call/rtc-credential` / 建连中 | 房间失效分支 | 立即结束会中页，停止 WebRTC 重试 |

###### CL15.2 页面维度分支冻结

`/call/incoming`：

1. 收到：
   - `CALL_PERMISSION_DENIED`
   - `CALL_STATE_INVALID`
   - `CALL_FEATURE_DISABLED`
   直接关闭来电页
2. 收到 `CALL_ACCEPT_DEVICE_CONFLICT`：
   - 说明其它设备已接听
   - 当前设备直接退出来电页

`/call/outgoing`：

1. 收到 `CALL_ALREADY_IN_PROGRESS`：
   - 提示忙线
   - 结束拨出页
2. 收到 `CALL_CALLEE_OFFLINE`：
   - 提示对方不在线
   - 结束拨出页
3. 收到 `CALL_STATE_INVALID`：
   - 说明通话已结束或已取消
   - 当前页直接退出

`/call/session`：

1. 收到 `CALL_RTC_CREDENTIAL_DENIED`：
   - 不建媒体
   - 进入结束态
2. 收到 `CALL_RTC_CREDENTIAL_EXPIRED`：
   - 最多允许一次重新拉取 `rtc-credential`
   - 仍失败则结束
3. 收到 `CALL_ROOM_NOT_FOUND`：
   - 立即停止媒体层
   - 退出会中页

###### CL15.3 Controller / Coordinator 使用规则

1. `call_controller.dart` 只根据：
   - 错误码
   - `callId`
   - `state/status/endReason`
   决定分支
2. `call_media_controller.dart` 不解析中文错误文案
3. `call_coordinator.dart` 只负责路由跳转：
   - 进入页
   - 退出页
   - 恢复页
   不自己判定业务合法性

###### CL15.4 禁止规则

1. 禁止用 toast 中文文案如“房间不存在”“对方忙线”做 if 判断
2. 禁止对 `CALL_PUSH_DEVICE_INVALID` 这类非主链错误直接结束已接通页面
3. 禁止在 `CALL_RTC_CREDENTIAL_EXPIRED` 时无限重试拉凭证

##### CL16. `upgrade` 列表筛选模型与详情抽屉共享字段冻结表

###### CL16.1 `product/index.vue`

列表筛选模型：

- `keyword`
- `status`
- `platform`

详情抽屉/表单共享字段：

- `id`
- `appCode`
- `appName`
- `tenantMode`
- `platforms`
- `status`
- `remark`

冻结规则：

1. 列表筛选只保留轻量检索字段
2. 详情抽屉与表单共用主数据字段，不重复定义第二套命名

###### CL16.2 `package/index.vue`

列表筛选模型：

- `productId`
- `platform`
- `status`
- `distributionMode`
- `versionKeyword`

详情抽屉/表单共享字段：

- `id`
- `productId`
- `platform`
- `distributionMode`
- `versionName`
- `versionCode`
- `buildNo`
- `fileId`
- `downloadUrl`
- `status`

冻结规则：

1. `productId/platform` 同时用于列表筛选和详情回源
2. `versionName/versionCode/buildNo` 在列表与详情必须一套字段口径

###### CL16.3 `release/index.vue`

列表筛选模型：

- `productId`
- `platform`
- `status`
- `upgradeType`
- `versionKeyword`

详情抽屉/表单共享字段：

- `id`
- `productId`
- `packageId`
- `platform`
- `versionName`
- `versionCode`
- `grayRuleType`
- `grayRuleValue`
- `upgradeType`
- `action`
- `status`
- `title`
- `content`

冻结规则：

1. 列表页的 `status` 与详情抽屉的 `status` 必须同源
2. 详情抽屉修改成功后，列表不本地 patch，统一重查

###### CL16.4 `channelRelease/index.vue`

列表筛选模型：

- `releaseId`
- `channel`
- `publishStatus`
- `syncStatus`

详情抽屉/表单共享字段：

- `id`
- `releaseId`
- `channel`
- `externalVersion`
- `publishStatus`
- `syncStatus`
- `syncMessage`
- `publishedAt`

冻结规则：

1. `releaseId` 是上下游联动主键
2. `publishStatus/syncStatus` 同时控制列表状态标签和详情动作按钮

###### CL16.5 `upgradeLog/index.vue`

列表筛选模型：

- `productId`
- `releaseId`
- `platform`
- `channel`
- `eventType`
- `timeRange`

详情抽屉/日志查看共享字段：

- `id`
- `productId`
- `releaseId`
- `platform`
- `channel`
- `deviceId`
- `eventType`
- `eventResult`
- `eventTime`
- `eventMessage`

冻结规则：

1. `timeRange` 只属于筛选模型，不进入详情对象
2. `releaseId/platform/channel` 同时用于列表过滤、摘要聚合、日志详情跳转

###### CL16.6 跨页面共享字段总规则

1. 筛选模型字段只保留：
   - 主键
   - 状态
   - 平台/渠道
   - 时间范围
   - 关键字
2. 详情抽屉字段保留完整展示与动作所需字段
3. 同一业务字段在列表/详情/表单三处必须同名同义
4. 影响下游页面筛选源的字段变化后，必须刷新下游筛选模型候选集

##### CL17. 当前这一轮继续后的结论

1. 通话专题已补到错误码 -> Flutter 页面动作分支映射表
2. `upgrade` 已补到列表筛选模型与详情抽屉共享字段冻结表
3. 当前统一文档已经能继续指导：
   - 通话错误态到页面退出/重试/拒绝建连的稳定分支
   - 平台升级中心列表/详情/表单之间的字段一致性
4. 后续若继续文档推进，优先建议：
   - 通话专题继续补“Flutter call 现有代码与统一文档冻结字段差异清单”
   - `upgrade` 继续补“平台端 API 目录与页面文件的一一对应实施清单”

##### CL18. Flutter `call` 现有代码与统一文档冻结字段差异清单

###### CL18.1 repository contract 差异

当前文件：

- `lib/features/im/call/domain/repositories/call_repository.dart`

现状差异：

| 当前代码 | 统一文档冻结口径 | 差异说明 |
|---|---|---|
| `callSessionId` | `callId` | 主键命名未收口 |
| `createInvite/accept/reject/cancel/hangup` 走 REST | Phase 1 以 `WS CALL_SIGNAL(206)` 控制面为主 | 动作链路方向不一致 |
| `syncState(callSessionId)` | `getActive/getDetail/getRtcCredential/getTurnConfig` | 查询面粒度偏粗 |

整改顺序：

1. contract 先从 `callSessionId` 迁到 `callId`
2. 动作语义改成“服务端受理/回执”，不是页面本地推进
3. 查询面拆成：
   - `getActiveCall()`
   - `getCallDetail(callId)`
   - `getRtcCredential(callId)`
   - `getTurnConfig()`

###### CL18.2 DTO 差异

当前文件：

- `infrastructure/dtos/call_session_dto.dart`
- `infrastructure/dtos/call_signal_event_dto.dart`

现状差异：

| 当前代码 | 统一文档冻结口径 | 差异说明 |
|---|---|---|
| `CallSessionDto.callSessionId` | `callId` | 主键命名旧 |
| `callType: 'audio'/'video'` 字符串 | `callType=1/2` | 枚举口径不同 |
| `status: 'connecting'` 等字符串 | `state/status/endReason` 分层 | 状态维度未拆开 |
| `rtcRoom` / `roomBundle` 直接挂 DTO | `rtc-credential` 独立响应 | 媒体数据与业务详情耦合 |
| `CallSignalEventDto.type/callSessionId/payload` | `signalType/callId/extraData` | 未与 proto 字段对齐 |

整改顺序：

1. 保留旧 DTO 过渡期兼容层
2. 新增冻结口径 DTO：
   - `call_detail_dto.dart`
   - `active_call_dto.dart`
   - `rtc_credential_dto.dart`
   - `turn_config_dto.dart`
3. `CallSignalEventDto` 改成贴 proto 字段：
   - `signalType`
   - `callId`
   - `extraDataJson`

###### CL18.3 datasource 差异

当前文件：

- `infrastructure/datasources/call_remote_data_source.dart`

现状差异：

| 当前接口 | 统一文档冻结口径 | 差异说明 |
|---|---|---|
| `POST /system/im/call/create-invite` | `WS CALL_SIGNAL(CALL)` | 控制面入口不同 |
| `POST /system/im/call/accept` | `WS CALL_SIGNAL(ANSWER)` | 接听动作不应独立 REST 主导 |
| `POST /system/im/call/reject/cancel/hangup` | `WS CALL_SIGNAL(REJECT/CANCEL/HANGUP)` | 同上 |
| `GET /system/im/call/state` | `GET /call/active` + `GET /call/detail` | 查询面未拆分 |

建议实施：

1. Phase 1 保留旧 REST 仅作兼容壳，不继续扩
2. 新增：
   - `sendCallSignal()`
   - `getActiveCall()`
   - `getCallDetail()`
   - `getRtcCredential()`
   - `getTurnConfig()`
3. `call_socket_data_source.dart` 负责 WS 动作与事件订阅，不再让 remote datasource 承担状态推进

###### CL18.3A socket datasource 差异

当前文件：

- `infrastructure/datasources/call_socket_data_source.dart`

现状差异：

| 当前实现 | 统一文档冻结口径 | 差异说明 |
|---|---|---|
| 仅监听 `systemNotify` 并把 `payload` 拍平 | `CALL_SIGNAL` 应具备明确 `signalType/callId/extraData` | 当前仍是弱结构解析 |
| 只负责事件订阅，不承担动作发送 | socket datasource 应同时承接 WS 动作发送 + 事件订阅 | 控制面职责尚未闭环 |
| 兼容 `callSessionId/sessionId` | 统一到 `callId` | 事件主键口径仍旧 |

建议实施：

1. `call_socket_data_source.dart` 新增 `sendCallSignal()` 系列方法：
   - `call()`
   - `answer()`
   - `reject()`
   - `cancel()`
   - `hangup()`
2. 事件解析优先收口为：
   - `signalType`
   - `callId`
   - `extraData`
   - `requestId/ackCode`（若服务端补）
3. 不再在 datasource 层拍平媒体凭证字段给页面

###### CL18.4 state / page 差异

当前文件：

- `presentation/states/call_state.dart`
- `presentation/pages/incoming_call_page.dart`
- `presentation/pages/outgoing_call_page.dart`
- `presentation/pages/call_session_page.dart`

现状差异：

| 当前状态字段 | 统一文档冻结口径 | 差异说明 |
|---|---|---|
| `callSessionId` | `callId` | 主键旧 |
| `pageStatus` | `state + status + endReason` | 页面态与业务态混合 |
| `hasAccepted/hasConnected` | 直接由服务端 `state` 推导 | 冗余布尔态较多 |
| `roomBundle` 进入全局 state | 媒体凭证应只在媒体控制器消费 | 状态过宽 |
| `CallEndReason` 本地枚举 | 应与服务端 `endReason` 映射 | 需建立统一映射表 |

建议实施：

1. `CallState` 主体只保留：
   - `callId`
   - `chatId`
   - `callType`
   - `state`
   - `status`
   - `endReason`
   - `acceptedDeviceId`
2. `roomBundle` 退到 `call_media_controller.dart`
3. 页面按钮启禁用只基于真实字段，不再依赖 `hasAccepted/hasConnected`

###### CL18.5 socket payload resolver 差异

当前文件：

- `infrastructure/mappers/call_socket_payload_resolver.dart`

现状差异：

1. 当前仍解析：
   - `title`
   - `acceptedDeviceId`
   - `callerProfile/calleeProfile`
   - `rtcRoom/roomBundle`
2. 当前代码会从 socket payload 直接解析 `roomBundle`
3. 与统一文档“RTC 凭证走独立查询面”冲突

整改要求：

1. resolver 只保留：
   - `signalType`
   - `callId`
   - `acceptedDeviceId`
   - 轻量 profile 字段
2. 不再从 socket 事件里长期承接：
   - `turnUsername`
   - `turnCredential`
   - `token`
   - `janusUrl`

###### CL18.6 provider 装配差异

当前文件：

- `presentation/providers/call_providers.dart`

现状差异：

| 当前实现 | 统一文档冻结口径 | 差异说明 |
|---|---|---|
| `CallRepositoryMode.mock/remote` 双分支，但两者都指向真实 impl | provider 层不再保留假模式开关 | 历史开关已失去实际意义 |
| `callRepositoryProvider` 仍承接旧 repository contract | provider 应只暴露新 contract | 上层仍被旧方法集绑定 |
| 页面派生 provider 仍以 `pageStatus` 为主 | 最终应以 `state/status/endReason/acceptedDeviceId` 为主 | 展示层尚未完全迁到协议字段 |

建议实施：

1. `CallRepositoryMode` 在完成 DTO/datasource 重构后退场
2. `callRepositoryProvider` 直接暴露新 contract，不再走模式开关
3. `callSessionStatusTextProvider / callFailureTextProvider / can*Provider` 最终改为消费：
   - `state`
   - `status`
   - `endReason`
   - `acceptedDeviceId`
   - `mediaState.rtcConnectionStatus`

##### CL19. `upgrade` 平台端 API 目录与页面文件一一对应实施清单

###### CL19.1 当前仓库现状结论

当前仓库中：

1. `shengyu-ui-platform-vue3` 下尚未发现统一文档规划中的升级中心 `api/views` 真实目录
2. 说明该专题当前仍处于“文档已冻结、代码目录待创建”的阶段
3. 因此实施清单要明确：
   - 哪些文件需要新建
   - 哪些页面/表单互相对应

###### CL19.2 建议新建 API 文件清单

建议目录：

- `src/api/system/appUpgrade/`

建议文件：

| 新建文件 | 对应后端域 | 责任 |
|---|---|---|
| `product.ts` | `app-upgrade-product` | 产品分页、创建、更新、启停 |
| `package.ts` | `app-upgrade-package` | 安装包分页、创建、更新、启停 |
| `release.ts` | `app-upgrade-release` | 发布单分页、详情、创建、审核、回滚 |
| `channelRelease.ts` | `app-upgrade-channel-release` | 渠道分页、发布、下线、同步 |
| `upgradeLog.ts` | `app-upgrade-log` | 日志分页、摘要、导出 |

###### CL19.3 建议新建页面目录清单

建议目录：

- `src/views/system/appUpgrade/`

建议页面：

| 新建页面/组件 | 作用 | 依赖 API |
|---|---|---|
| `product/index.vue` | 产品列表主页面 | `product.ts` |
| `product/ProductForm.vue` | 产品表单抽屉 | `product.ts` |
| `package/index.vue` | 安装包列表主页面 | `package.ts` |
| `package/PackageForm.vue` | 安装包表单抽屉 | `package.ts` |
| `release/index.vue` | 发布单列表 + 详情抽屉 | `release.ts` |
| `release/ReleaseForm.vue` | 发布单创建/编辑表单 | `release.ts` |
| `channelRelease/index.vue` | 渠道发布列表 + 同步/下线动作 | `channelRelease.ts` |
| `channelRelease/ChannelReleaseForm.vue` | 渠道发布表单/抽屉 | `channelRelease.ts` |
| `upgradeLog/index.vue` | 升级日志列表 + 摘要区 | `upgradeLog.ts` |

###### CL19.4 一一对应实施顺序

固定顺序：

1. `product.ts` -> `product/index.vue` -> `ProductForm.vue`
2. `package.ts` -> `package/index.vue` -> `PackageForm.vue`
3. `release.ts` -> `release/index.vue` -> `ReleaseForm.vue`
4. `channelRelease.ts` -> `channelRelease/index.vue` -> `ChannelReleaseForm.vue`
5. `upgradeLog.ts` -> `upgradeLog/index.vue`

原因：

1. 产品是最上游主数据
2. 安装包依赖产品
3. 发布单依赖安装包
4. 渠道依赖发布单
5. 日志依赖客户端事件回流

###### CL19.5 菜单/路由/权限补建顺序

建议补建：

1. 菜单目录：
   - 升级产品
   - 安装包
   - 发布单
   - 渠道发布
   - 升级日志
2. 路由按页面目录同序创建
3. 权限点按 API 文件同序补齐

冻结规则：

1. 未创建 API 文件前，不直接写页面中的请求代码
2. 未创建上游页面前，不跳做下游页面
3. `upgradeLog/index.vue` 不提前于客户端事件回流链路落地

##### CL20. 当前这一轮继续后的结论

1. 通话专题已补到 Flutter `call` 现有代码与统一文档冻结字段的差异清单
2. `upgrade` 已补到平台端 API 目录与页面文件的一一对应实施清单
3. 当前统一文档已经能继续指导：
   - 通话模块从旧 REST/roomBundle 口径迁到新 WS/查询面口径
   - 平台升级中心从零开始按目录和页面顺序落地
4. 后续若继续文档推进，优先建议：
   - 通话专题继续补“现有 Flutter call 文件逐个改造优先级与风险点”
   - `upgrade` 继续补“平台端菜单/路由/权限点文件级实施清单”

##### CL21. Flutter `call` 现有文件逐个改造优先级与风险点

###### CL21.1 `P0` 立即优先文件

| 文件 | 优先级 | 主要问题 | 主要风险 | 改造目标 |
|---|---|---|---|---|
| `presentation/providers/call_providers.dart` | `P0` | 默认 `CallRepositoryMode.mock` | 真链路永远进不去 | provider 默认切真实装配口径 |
| `presentation/controllers/call_controller.dart` | `P0` | `accept()` 后本地直接进 `connected` | 状态机与服务端分叉 | 改成服务端状态驱动 |
| `infrastructure/datasources/call_remote_data_source.dart` | `P0` | 仍以 REST 动作口为主 | 与文档冻结控制面冲突 | 收口到查询面，动作转 WS |
| `domain/repositories/call_repository.dart` | `P0` | contract 仍是 `callSessionId + REST action` | 后续所有层都被旧口径拖住 | 迁到 `callId + active/detail/credential/config + sendSignal` |

###### CL21.2 `P1` 高优先文件

| 文件 | 优先级 | 主要问题 | 主要风险 | 改造目标 |
|---|---|---|---|---|
| `infrastructure/dtos/call_session_dto.dart` | `P1` | `callSessionId/callType/status/rtcRoom` 混在一起 | DTO 层继续放大旧口径 | 拆成 `detail/active/credential/config` |
| `infrastructure/dtos/call_signal_event_dto.dart` | `P1` | 未贴 proto 字段 | socket 事件解析继续漂移 | 对齐 `callId/signalType/extraData` |
| `infrastructure/mappers/call_socket_payload_resolver.dart` | `P1` | 直接解析 `roomBundle/token/turnCredential` | socket 偷带媒体凭证 | 只保留轻量字段 |
| `infrastructure/repositories/call_repository_impl.dart` | `P1` | 继续包装旧 datasource | repository 无法成为统一收口层 | 改成新 contract 适配层 |

###### CL21.3 `P2` 中优先文件

| 文件 | 优先级 | 主要问题 | 主要风险 | 改造目标 |
|---|---|---|---|---|
| `presentation/controllers/call_media_controller.dart` | `P2` | `accept()` 后立即 `prepare()` | 非 `acceptedDeviceId` 设备误建连 | 只在 `CONNECTING/CONNECTED + acceptedDeviceId` 时建连 |
| `presentation/states/call_state.dart` | `P2` | `pageStatus/hasAccepted/hasConnected/roomBundle` 过宽 | 页面态和业务态耦合 | 压缩为真实核心字段 |
| `domain/entities/active_call_state_result.dart` | `P2` | 仍承接 `callSessionId/pageStatus/roomBundle` | 恢复态返回结构旧 | 对齐 `active/detail` 返回 |
| `presentation/controllers/call_coordinator.dart` | `P2` | 容易承担过多业务裁决 | 路由层被业务侵入 | 只保留进出路由与恢复 |

###### CL21.4 `P3` 收尾文件

| 文件 | 优先级 | 主要问题 | 主要风险 | 改造目标 |
|---|---|---|---|---|
| `presentation/pages/incoming_call_page.dart` | `P3` | 依赖旧 state 结构 | 页面显隐规则分散 | 改成只吃新 `CallState` |
| `presentation/pages/outgoing_call_page.dart` | `P3` | 本地等待态语义偏重 | 主叫页与服务端状态不同步 | 只展示真实 `RINGING/CONNECTING/ENDED` |
| `presentation/pages/call_session_page.dart` | `P3` | 媒体状态和业务状态交错 | 页面逻辑复杂且脆弱 | 页面只读 state，不直接判媒体凭证 |
| `infrastructure/repositories/mock_call_repository.dart` | `P3` | 继续并行主导逻辑风险大 | 长期双轨维护 | 降为归档/彻底退场 |

###### CL21.5 最大风险点清单

1. `call_controller.dart`
   - `accept()` 当前会直接：
     - 调 usecase
     - `prepare()` 媒体
     - 本地切 `connected`
   - 这是当前最危险的偏差点
2. `call_providers.dart`
   - 默认 `mock`
   - 即使后端准备好也不会走真链路
3. `call_remote_data_source.dart`
   - 仍围绕：
     - `create-invite`
     - `accept`
     - `reject`
     - `cancel`
     - `hangup`
   - 与统一文档 Phase 1 冲突最大
4. `call_socket_payload_resolver.dart`
   - 直接吃 `roomBundle/token/turnCredential`
   - 会让媒体凭证继续依赖 socket 载荷

###### CL21.6 建议实际改造顺序

固定顺序：

1. `call_repository.dart`
2. `call_remote_data_source.dart`
3. DTO / mapper / resolver
4. `call_repository_impl.dart`
5. `call_providers.dart`
6. `call_controller.dart`
7. `call_media_controller.dart`
8. page/state 收尾

禁止顺序：

1. 不先改页面再补 contract
2. 不先把 `mock` 切掉再补真实 DTO
3. 不在旧 `roomBundle` 口径上继续追加字段

##### CL22. `upgrade` 平台端菜单 / 路由 / 权限点文件级实施清单

###### CL22.1 菜单实施清单

建议目标：

- 在 `shengyu-ui-platform-vue3` 中新增升级中心主菜单组

建议菜单树：

1. `升级中心`
2. 子菜单：
   - `升级产品`
   - `安装包`
   - `发布单`
   - `渠道发布`
   - `升级日志`

文件级实施建议：

| 文件/位置 | 动作 | 说明 |
|---|---|---|
| 路由配置主入口文件 | 新增 `appUpgrade` 菜单组 | 统一承接升级中心子页 |
| 菜单元数据源 | 新增 5 个子菜单项 | 与页面路径保持同名同义 |
| 国际化资源文件 | 新增菜单标题 key | 稳定文案同步国际化 |

###### CL22.2 路由实施清单

建议页面路径：

| 页面 | 建议路由 |
|---|---|
| `product/index.vue` | `/system/app-upgrade/product` |
| `package/index.vue` | `/system/app-upgrade/package` |
| `release/index.vue` | `/system/app-upgrade/release` |
| `channelRelease/index.vue` | `/system/app-upgrade/channel-release` |
| `upgradeLog/index.vue` | `/system/app-upgrade/log` |

文件级实施建议：

| 文件/位置 | 动作 | 说明 |
|---|---|---|
| 路由模块文件 | 新增 5 条页面路由 | 与目录结构一一对应 |
| 权限守卫/元数据 | 增加 `permission` 元信息 | 页面级鉴权统一 |
| 面包屑元数据 | 增加 `title/activeMenu` | 抽屉页回跳同源 |

###### CL22.3 权限点实施清单

建议权限点分组：

| 页面/域 | 权限点 |
|---|---|
| `product` | `system:app-upgrade-product:query/create/update/enable/disable` |
| `package` | `system:app-upgrade-package:query/create/update/enable/disable` |
| `release` | `system:app-upgrade-release:query/create:submit-audit:audit:rollback` |
| `channelRelease` | `system:app-upgrade-channel-release:query:publish:offline:sync-status` |
| `upgradeLog` | `system:app-upgrade-log:query:summary:export` |

文件级实施建议：

| 文件/位置 | 动作 | 说明 |
|---|---|---|
| 权限常量文件或页面内 `v-hasPermi` 使用点 | 新增上述权限点 | 页面按钮显隐同源 |
| API 文件 | 注释/类型声明中标注对应权限域 | 便于联调时核对 |
| 菜单元数据 | 配置页面访问权限 | 路由和按钮两层一致 |

###### CL22.4 推荐实施顺序

固定顺序：

1. 菜单组主入口
2. `product` 页面路由 + 权限
3. `package` 页面路由 + 权限
4. `release` 页面路由 + 权限
5. `channelRelease` 页面路由 + 权限
6. `upgradeLog` 页面路由 + 权限

原因：

1. 与页面/数据主链顺序一致
2. 避免先暴露下游路由而上游主数据页未就绪

###### CL22.5 禁止规则

1. 不在页面文件创建前先挂无效菜单入口
2. 不只建路由不建权限点
3. 不让按钮权限与页面访问权限脱节

##### CL23. 当前这一轮继续后的结论

1. 通话专题已补到 Flutter `call` 现有文件逐个改造优先级与风险点
2. `upgrade` 已补到平台端菜单 / 路由 / 权限点文件级实施清单
3. 当前统一文档已经能继续指导：
   - Flutter 通话模块从 provider/controller 开始的真实改造顺序
   - 平台升级中心从菜单到路由到权限的建制落地顺序
4. 后续若继续文档推进，优先建议：
   - 通话专题继续补“现有 Flutter call 页面与 controller 的字段替换表”
   - `upgrade` 继续补“平台端升级中心目录创建后的文件骨架顺序”

##### CL24. Flutter `call` 页面 / controller 字段替换表

###### CL24.1 `call_controller.dart` 字段替换

| 当前字段/行为 | 替换为 | 说明 |
|---|---|---|
| `state.callSessionId` | `state.callId` | 全链路主键统一 |
| `initialize(args)` 直接塞 `pageStatus` | `initialize(args)` 先建最小壳，再拉 `active/detail` | 初始化以服务端为准 |
| `accept()` 后本地切 `connected` | `accept()` 只发动作，等 `callStateSync(CONNECTING/CONNECTED)` | 禁止本地越级推进 |
| `markConnected()` 本地显式推进 | 改成 `applyStateSync()` | 所有接通态来源统一 |
| `hasAccepted/hasConnected` | 删除，按 `state` 推导 | 减少冗余布尔 |
| `roomBundle` 进入 `CallState` | 迁到 `CallMediaState` 或媒体控制器缓存 | 业务态不承接媒体凭证 |

###### CL24.2 `incoming_call_page.dart` 字段替换

| 当前依赖 | 替换后依赖 | 说明 |
|---|---|---|
| `next.pageStatus == connected` 时跳转 | `next.state in (CONNECTING, CONNECTED)` 且设备合法时跳转 | 与服务端状态机一致 |
| `next.callSessionId` | `next.callId` | 路由参数统一 |
| `canAcceptIncomingCallProvider` 基于 `pageStatus==ringing` | 基于 `state==RINGING` | 页面按钮按真实状态启禁用 |
| `canRejectIncomingCallProvider` 基于 `pageStatus` | 基于 `state==RINGING || state==CONNECTING` 的服务端口径 | 避免本地猜测 |

页面动作替换：

1. 接听按钮：
   - 旧：点击即可能进入会中页
   - 新：点击只发 `ANSWER`，等服务端同步
2. 拒绝按钮：
   - 旧：本地 `pop`
   - 新：先等服务端回执/结束事件，再统一退出

###### CL24.3 `outgoing_call_page.dart` 字段替换

| 当前依赖 | 替换后依赖 | 说明 |
|---|---|---|
| `initialize() + startOutgoing()` 本地发起 | `initialize()` 后发送 `CALL_SIGNAL(CALL)` | 主叫链路统一 |
| `pageStatus==ringing` 文案 | `state==RINGING` 文案 | 与详情查询同源 |
| `canCancelOutgoingCallProvider` 基于 `pageStatus` | 基于 `state in (INIT,RINGING,CONNECTING)` | 取消按钮更贴真实状态 |

页面动作替换：

1. 取消按钮：
   - 旧：调 `cancel()` 后本地 `pop`
   - 新：调 `CANCEL`，等待 `callEnded` 或 `state=ENDED`

###### CL24.4 `call_session_page.dart` 字段替换

| 当前依赖 | 替换后依赖 | 说明 |
|---|---|---|
| `initState()` 里 `markConnected()` | 删除 | 不能页面自判接通 |
| `pageStatus==ended/failed` 退出 | `state==ENDED` 或错误码驱动退出 | 结束态统一 |
| `mediaState` 与 `pageStatus` 混合控制按钮 | `state + acceptedDeviceId + mediaState.rtcConnectionStatus` | 业务态和媒体态分层 |
| `isVideoEnabled` 同时看 `callType` 和 `cameraEnabled` | 以 `callType` 为主，媒体开关只影响本地摄像头状态 | 避免 UI 误导 |

页面动作替换：

1. `hangup()`：
   - 旧：本地置 `ending` 后立即回退
   - 新：发 `HANGUP`，收到 `callEnded/state=ENDED` 再退出
2. `bannerText/sessionStatusText`：
   - 改为直接消费：
     - `state`
     - `status`
     - `endReason`
     - `durationSeconds`

###### CL24.5 `call_providers.dart` 派生字段替换

| 当前 provider | 替换口径 | 说明 |
|---|---|---|
| `isCallConnectedProvider` 基于 `pageStatus==connected` | 基于 `state==CONNECTED` | 直接服务端态 |
| `isCallReconnectingProvider` 基于 `pageStatus==reconnecting` | 基于 `state==CONNECTING` + 媒体层 `reconnecting` | 业务层和媒体层组合 |
| `canToggleCallControlsProvider` 基于 `pageStatus` | 基于 `state in (CONNECTING, CONNECTED)` | 控件启禁用更稳定 |
| `isCallFinishedProvider` 基于 `ended/failed` | 基于 `state==ENDED` | 结束态唯一权威来源 |

冻结规则：

1. 页面不再直接调用 `markConnected()`
2. `callId/state/status/endReason` 是页面与 controller 的统一核心字段
3. 本地文案和 banner 只消费冻结字段，不再消费旧 `pageStatus` 推断文案

##### CL25. `upgrade` 平台端升级中心目录创建后的文件骨架顺序

###### CL25.1 第一批：目录与空文件骨架

先创建目录：

1. `src/api/system/appUpgrade/`
2. `src/views/system/appUpgrade/product/`
3. `src/views/system/appUpgrade/package/`
4. `src/views/system/appUpgrade/release/`
5. `src/views/system/appUpgrade/channelRelease/`
6. `src/views/system/appUpgrade/upgradeLog/`

第一批空文件骨架：

1. `src/api/system/appUpgrade/product.ts`
2. `src/api/system/appUpgrade/package.ts`
3. `src/api/system/appUpgrade/release.ts`
4. `src/api/system/appUpgrade/channelRelease.ts`
5. `src/api/system/appUpgrade/upgradeLog.ts`
6. `src/views/system/appUpgrade/product/index.vue`
7. `src/views/system/appUpgrade/product/ProductForm.vue`
8. `src/views/system/appUpgrade/package/index.vue`
9. `src/views/system/appUpgrade/package/PackageForm.vue`
10. `src/views/system/appUpgrade/release/index.vue`
11. `src/views/system/appUpgrade/release/ReleaseForm.vue`
12. `src/views/system/appUpgrade/channelRelease/index.vue`
13. `src/views/system/appUpgrade/channelRelease/ChannelReleaseForm.vue`
14. `src/views/system/appUpgrade/upgradeLog/index.vue`

###### CL25.2 第二批：API 类型与函数骨架

每个 API 文件先补：

1. 请求类型 `ReqVO`
2. 响应类型 `RespVO`
3. 分页函数
4. `create/update/get/page` 主函数
5. 额外动作函数：
   - `release.ts`: `submitAudit/audit/rollback`
   - `channelRelease.ts`: `publish/offline/syncStatus`
   - `upgradeLog.ts`: `summary/export`

冻结规则：

1. 先有类型，再有页面消费
2. 所有页面只从 API 文件拿函数，不内联请求

###### CL25.3 第三批：页面最小骨架顺序

固定顺序：

1. `product/index.vue`
2. `ProductForm.vue`
3. `package/index.vue`
4. `PackageForm.vue`
5. `release/index.vue`
6. `ReleaseForm.vue`
7. `channelRelease/index.vue`
8. `ChannelReleaseForm.vue`
9. `upgradeLog/index.vue`

每个页面首批只补：

1. 筛选模型
2. 表格列骨架
3. loading 状态
4. 抽屉显隐状态
5. 调用对应 API 的最小 `page/get`

###### CL25.4 第四批：菜单 / 路由 / 权限接线顺序

固定顺序：

1. 菜单组入口
2. `product`
3. `package`
4. `release`
5. `channelRelease`
6. `upgradeLog`

接线要求：

1. 页面文件存在后再挂路由
2. 路由存在后再挂菜单
3. 菜单存在时必须同步有权限点

###### CL25.5 第五批：表单与动作收尾

最后再补：

1. 表单校验规则
2. 审核/发布/回滚/同步状态动作
3. 摘要统计和导出
4. 详情抽屉刷新联动

禁止顺序：

1. 不先做 `upgradeLog` 再做 `product`
2. 不先接动作按钮再补 API 类型
3. 不在目录未创建完成时跨目录散落文件

##### CL26. 当前这一轮继续后的结论

1. 通话专题已补到 Flutter `call` 页面 / controller 字段替换表
2. `upgrade` 已补到目录创建后的文件骨架顺序
3. 当前统一文档已经进一步接近代码落地前的完整执行手册
4. 后续若继续文档推进，优先建议：
   - 通话专题继续补“CallState / CallMediaState / provider 派生值最终冻结表”
   - `upgrade` 继续补“每个 API 文件的方法签名与返回类型冻结表”

##### CL27. 通话 `CallState / CallMediaState / provider` 派生值最终冻结表

###### CL27.1 `CallState` 最终冻结字段

`CallState` 建议最终只保留：

| 字段 | 类型建议 | 说明 |
|---|---|---|
| `callId` | `String` | 通话主键 |
| `chatId` | `String` | 关联会话主键 |
| `callType` | `CallType` | `audio/video` 展示与媒体能力 |
| `entryMode` | `CallEntryMode` | `incoming/outgoing/restore` |
| `title` | `String?` | 页面展示标题 |
| `state` | `String/Enum` | `INIT/RINGING/CONNECTING/CONNECTED/ENDED` |
| `status` | `String/Enum?` | `ANSWERED/REJECTED/CANCELLED/MISSED` 等 |
| `endReason` | `String/Enum?` | 结束原因 |
| `elapsedSeconds` | `int` | 仅显示/恢复时用 |
| `callerProfile` | `CallParticipantProfile?` | 主叫轻量资料 |
| `calleeProfile` | `CallParticipantProfile?` | 被叫轻量资料 |
| `acceptedDeviceId` | `String?` | 多端裁决结果 |
| `error` | `AppError?` | 当前动作错误 |
| `mediaState` | `CallMediaState` | 媒体态独立封装 |

必须删除或下沉的旧字段：

- `callSessionId`
- `pageStatus`
- `hasAccepted`
- `hasConnected`
- `isIncoming`
- `isOutgoing`
- `roomBundle`

冻结规则：

1. 页面态由 `entryMode + state + error` 推导，不再单独存 `pageStatus`
2. 业务主状态只以服务端 `state/status/endReason` 为准
3. RTC 房间/凭证不进入 `CallState` 顶层

###### CL27.2 `CallMediaState` 最终冻结字段

`CallMediaState` 保留：

| 字段 | 说明 |
|---|---|
| `microphoneEnabled` | 本地麦克风开关 |
| `cameraEnabled` | 本地摄像头开关 |
| `speakerEnabled` | 扬声器/听筒切换 |
| `frontCamera` | 前后摄切换 |
| `localTrackReady` | 本地采集轨是否已准备 |
| `remoteTrackReady` | 远端媒体轨是否已就绪 |
| `rtcConnectionStatus` | `idle/preparing/joining/connected/reconnecting/disconnected` |

允许新增但只放媒体层的字段：

- `credentialExpireAt`
- `lastRtcErrorCode`
- `lastRtcErrorMessage`

冻结规则：

1. `CallMediaState` 不承接业务主状态
2. 媒体失败只通过：
   - `rtcConnectionStatus`
   - `lastRtcErrorCode`
   反馈给 controller
3. 是否退出通话页仍由 `CallState.state/endReason/error` 裁决

###### CL27.3 provider 派生值最终冻结

| provider | 最终来源 | 说明 |
|---|---|---|
| `activeCallStateProvider` | `callControllerProvider` | 唯一页面主 state 来源 |
| `callElapsedSecondsProvider` | `state.elapsedSeconds` | 不本地另算第二份 |
| `isCallConnectedProvider` | `state.state == CONNECTED` | 不再看 `pageStatus` |
| `isCallVideoEnabledProvider` | `state.callType == video` | `cameraEnabled` 只影响本地控制按钮 |
| `isCallReconnectingProvider` | `mediaState.rtcConnectionStatus == reconnecting` | 纯媒体态 |
| `canToggleCallControlsProvider` | `state.state in (CONNECTING, CONNECTED)` | 页面工具按钮启禁用 |
| `canSwitchCallCameraProvider` | `isCallVideoEnabled && canToggleCallControls` | 仅视频通话可切 |
| `isCallFinishedProvider` | `state.state == ENDED` | 终局态唯一判断 |
| `canAcceptIncomingCallProvider` | `entryMode == incoming && state.state == RINGING` | 接听按钮条件 |
| `canRejectIncomingCallProvider` | `entryMode == incoming && state.state == RINGING` | 拒接按钮条件 |
| `canCancelOutgoingCallProvider` | `entryMode == outgoing && state.state in (INIT,RINGING,CONNECTING)` | 取消按钮条件 |

###### CL27.4 文案派生最终口径

`callSessionStatusTextProvider`：

1. `state == ENDED`：
   - 直接按 `endReason/status` 映射结束文案
2. `error != null`：
   - 进入错误文案分支
3. `state == CONNECTED`：
   - 展示 `mm:ss`
4. `state == CONNECTING`：
   - 展示“连接中”
5. `state == RINGING`：
   - incoming 展示“来电中”
   - outgoing 展示“等待接听”

冻结规则：

1. 文案派生只消费最终冻结字段
2. 不再从 `pageStatus` 推导文案

##### CL28. `upgrade` 每个 API 文件的方法签名与返回类型冻结表

###### CL28.1 `product.ts`

建议导出：

```ts
export interface AppUpgradeProductPageReqVO {}
export interface AppUpgradeProductRespVO {}
export function getAppUpgradeProductPage(params: AppUpgradeProductPageReqVO): Promise<PageResult<AppUpgradeProductRespVO>>
export function getAppUpgradeProduct(id: string): Promise<AppUpgradeProductRespVO>
export function createAppUpgradeProduct(data: AppUpgradeProductCreateReqVO): Promise<string>
export function updateAppUpgradeProduct(data: AppUpgradeProductUpdateReqVO): Promise<void>
export function enableAppUpgradeProduct(id: string): Promise<void>
export function disableAppUpgradeProduct(id: string): Promise<void>
```

###### CL28.2 `package.ts`

```ts
export interface AppUpgradePackagePageReqVO {}
export interface AppUpgradePackageRespVO {}
export function getAppUpgradePackagePage(params: AppUpgradePackagePageReqVO): Promise<PageResult<AppUpgradePackageRespVO>>
export function getAppUpgradePackage(id: string): Promise<AppUpgradePackageRespVO>
export function createAppUpgradePackage(data: AppUpgradePackageCreateReqVO): Promise<string>
export function updateAppUpgradePackage(data: AppUpgradePackageUpdateReqVO): Promise<void>
export function enableAppUpgradePackage(id: string): Promise<void>
export function disableAppUpgradePackage(id: string): Promise<void>
```

###### CL28.3 `release.ts`

```ts
export interface AppUpgradeReleasePageReqVO {}
export interface AppUpgradeReleaseRespVO {}
export function getAppUpgradeReleasePage(params: AppUpgradeReleasePageReqVO): Promise<PageResult<AppUpgradeReleaseRespVO>>
export function getAppUpgradeRelease(id: string): Promise<AppUpgradeReleaseRespVO>
export function createAppUpgradeRelease(data: AppUpgradeReleaseCreateReqVO): Promise<string>
export function updateAppUpgradeRelease(data: AppUpgradeReleaseUpdateReqVO): Promise<void>
export function submitAppUpgradeReleaseAudit(id: string): Promise<void>
export function auditAppUpgradeRelease(data: AppUpgradeReleaseAuditReqVO): Promise<void>
export function rollbackAppUpgradeRelease(data: AppUpgradeReleaseRollbackReqVO): Promise<void>
```

###### CL28.4 `channelRelease.ts`

```ts
export interface AppUpgradeChannelReleasePageReqVO {}
export interface AppUpgradeChannelReleaseRespVO {}
export function getAppUpgradeChannelReleasePage(params: AppUpgradeChannelReleasePageReqVO): Promise<PageResult<AppUpgradeChannelReleaseRespVO>>
export function getAppUpgradeChannelRelease(id: string): Promise<AppUpgradeChannelReleaseRespVO>
export function publishAppUpgradeChannelRelease(data: AppUpgradeChannelReleasePublishReqVO): Promise<void>
export function offlineAppUpgradeChannelRelease(data: AppUpgradeChannelReleaseOfflineReqVO): Promise<void>
export function syncAppUpgradeChannelReleaseStatus(data: AppUpgradeChannelReleaseSyncReqVO): Promise<void>
```

###### CL28.5 `upgradeLog.ts`

```ts
export interface AppUpgradeLogPageReqVO {}
export interface AppUpgradeLogRespVO {}
export interface AppUpgradeLogSummaryRespVO {}
export function getAppUpgradeLogPage(params: AppUpgradeLogPageReqVO): Promise<PageResult<AppUpgradeLogRespVO>>
export function getAppUpgradeLogSummary(params: AppUpgradeLogPageReqVO): Promise<AppUpgradeLogSummaryRespVO>
export function exportAppUpgradeLog(params: AppUpgradeLogPageReqVO): Promise<Blob>
```

###### CL28.6 返回类型统一规则

1. 列表统一返回 `Promise<PageResult<RespVO>>`
2. 详情统一返回 `Promise<RespVO>`
3. `create` 统一返回新主键：`Promise<string>`
4. `update/enable/disable/audit/publish/offline/sync` 统一返回 `Promise<void>`
5. `export` 统一返回 `Promise<Blob>`

###### CL28.7 命名统一规则

1. 文件名与域名一致：
   - `product.ts`
   - `package.ts`
   - `release.ts`
   - `channelRelease.ts`
   - `upgradeLog.ts`
2. 方法名前缀统一：
   - `get*Page`
   - `get*`
   - `create*`
   - `update*`
3. 不在页面内自定义第二套别名函数

##### CL29. 当前这一轮继续后的结论

1. 通话专题已补到 `CallState / CallMediaState / provider` 派生值最终冻结表
2. `upgrade` 已补到每个 API 文件的方法签名与返回类型冻结表
3. 当前统一文档已经进一步接近“代码可直接按表落地”的状态
4. 后续若继续文档推进，优先建议：
   - 再做一轮全篇查漏，确认是否还有未收口的专题空洞
   - 若主线已闭环，再切回代码推进

##### CL30. 统一文档全篇查漏与最终闭环确认

###### CL30.1 本轮全篇查漏结论

本轮系统性扫描后，当前统一文档的结论是：

1. 除音视频通话与 `upgrade` 这两个复杂专题外，其余主线功能页已经基本完成：
   - 真实接口路径
   - 核心入参/出参
   - 页面消费口径
   - 联动刷新规则
2. 音视频通话专题已经完成到：
   - 后端控制面/查询面/状态机/时序图
   - Flutter 端 contract/DTO/state/provider/controller/page 替换口径
   - 错误码、WS 下发包、字段冻结表
3. `upgrade` 专题已经完成到：
   - 平台端发布治理体系
   - API 目录/页面目录/菜单/路由/权限/方法签名/返回类型
   - 页面筛选模型、详情抽屉、回执消费、文件骨架顺序

###### CL30.2 仍然存在但不再视为主线缺口的内容

以下内容仍会在文档中出现，但属于历史对照或归档痕迹，不再视为执行主线未补齐：

1. 早期章节中出现的旧术语：
   - `callSessionId`
   - `roomBundle`
   - 旧 REST 动作口
2. 这些旧术语保留的作用仅是：
   - 说明旧实现/旧设计口径
   - 为后续代码改造提供差异对照
3. 当前真正执行口径应以后续冻结章节为准，特别是：
   - `CL24`
   - `CL27`
   - `CL28`

###### CL30.3 当前仍属“真实缺口但已被完整记录”的项目

以下不再属于“文档漏项”，而是“代码/后端尚未实现”：

1. Flutter `call` 模块当前仓库代码仍未迁到新口径
2. `shengyu-ui-platform-vue3` 中升级中心目录仍未真正创建
3. 通话后端控制面、查询面、RTC 凭证链路在服务端也仍属待实现项

说明：

1. 这些是实施缺口，不是文档缺口
2. 统一文档当前已经把它们的：
   - 目录
   - 类
   - 字段
   - 时序
   - 页面消费规则
   全部补到可执行粒度

###### CL30.4 是否达到“统一文档可作为唯一执行文档”的结论

结论：`达到`

理由：

1. 当前统一文档已经完整覆盖旧 Flutter IM 设计文档体系的主执行信息
2. 新开对话时，继续按：
   - `系统性阅读sql/flutter-doc/IM-Flutter统一任务文档-v1.0.md文档继续稳步推进`
   即可续接
3. 当前不再需要新增平行专题文档来指导主线开发

###### CL30.5 是否达到“可以恢复实际代码落地”的结论

结论：`达到`

恢复代码推进时建议顺序：

1. 先继续已有真实接口页面主线
2. 再按统一文档顺序改造 Flutter `call`
3. 再创建 `upgrade` 平台端目录/API/页面骨架

##### CL31. 当前统一文档最终闭环结论

1. 当前统一文档主线内容已可视为“补齐完成”
2. 后续继续工作时，文档主任务不再是大面积补录，而是：
   - 小范围查漏
   - 代码落地后按实现进展做状态更新
3. 因此从本节之后，统一文档可以从“设计补录主导”切换到“实施落地主导”

##### CM2. `favorite / sticker / search / file preview` 后端接口流程链路与页面联动刷新规则

###### CM2.1 `favorite` 接口流程链路

核心接口：

- `POST /system/im/favorite/add`
- `DELETE /system/im/favorite/remove`
- `GET /system/im/favorite/list`
- `GET /system/im/favorite/search`
- `GET /system/im/favorite/detail`
- `POST /system/im/favorite/resend`

流程链路要点：

1. `add/remove` 只围绕收藏功能本身组织链路
2. `resend` 需要记录：
   - `favoriteId`
   - `targetChatId`
3. `detail/search/list` 只保留接口调用顺序与页面消费关系

###### CM2.2 `favorite` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 聊天页收藏消息成功 | 收藏列表页、消息菜单收藏态 | `/favorite/add` 成功回执 | 不本地假增列表项 |
| 收藏详情取消收藏 | 收藏列表页、详情页、原消息菜单状态 | `/favorite/remove` 成功回执 | 详情页若当前项被删则回退列表 |
| 收藏转发成功 | 会话列表页、目标聊天页 | `/favorite/resend` 成功回执 | 以目标会话真实新消息为准 |
| 收藏搜索条件变化 | 收藏列表页、搜索结果页 | `list/search` 同源条件 | 两页排序和命中数保持同源 |

###### CM2.3 `sticker` 接口流程链路

核心接口：

- `GET /system/im/sticker/list`
- `POST /system/im/sticker/upload`
- `POST /system/im/sticker/collect`
- `DELETE /system/im/sticker/remove`
- `PUT/POST /system/im/sticker/sort`
- `POST/PUT /system/im/sticker/recent/use`

流程链路要点：

1. `recent/use` 只作为贴纸面板功能链路的一部分
2. `sort` 只关注排序变更后的页面顺序一致性
3. 上传失败只要求页面正确回到失败态

###### CM2.4 `sticker` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 上传贴纸成功 | 贴纸面板、贴纸管理页、最近使用区 | `/sticker/upload` 成功回执 | 新贴纸应进入主列表 |
| 从消息收藏贴纸 | 贴纸面板、原消息菜单状态 | `/sticker/collect` 成功回执 | 不重复收藏同一贴纸 |
| 删除贴纸 | 贴纸面板、贴纸管理页、最近使用区 | `/sticker/remove` 成功回执 | 若当前选中贴纸被删，面板应取消选中 |
| 调整排序 | 贴纸管理页、聊天贴纸面板 | `/sticker/sort` 成功回执 | 排序变更后两处顺序一致 |
| 记录最近使用 | 最近使用区 | `/sticker/recent/use` 成功回执 | 失败不阻断发送，但不本地长期假记忆 |

###### CM2.5 `search` 接口流程链路

核心接口：

- `GET /system/im/search/hot`
- `GET /system/im/search/global`
- `GET /system/im/contact/search`
- `GET /system/im/conversation/search`
- `GET /system/im/message/search`

流程链路要点：

1. 搜索只记录：
   - 查询关键字摘要
   - tab
   - 结果数量
   - 跳转目标主键
2. 不再展开搜索词埋点、日志、统计设计

###### CM2.6 `search` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 全局搜索关键词变化 | 搜索首页、结果页、热门搜索区 | `/search/global` 与 `/search/hot` | 热门区和结果区独立但同属搜索域 |
| 搜索命中消息跳聊天锚点 | 聊天页、搜索结果页 | `chatId/messageId` | 聊天页按真实消息详情定位 |
| 搜索命中联系人/群/会话 | 目标详情页、结果页 | `targetId/chatId` | 目标失效时回源页刷新结果 |
| 会话内搜索条件变化 | 聊天历史页、聊天页锚点态 | `/message/search` | 结果列表与聊天跳转必须同源 |

###### CM2.7 `file preview` 接口流程链路

核心接口：

- `GET /infra/file/open-strategy`
- `GET /infra/file/presigned-get-url`
- `GET /system/im/message/media`
- 群文件域联动：
  - `GET /system/im/group/file/list`
  - `POST /system/im/group/file/download?id=...`

流程链路要点：

1. `open-strategy` 是文件预览的权威入口
2. 下载、外部打开、预览失败都只按功能链路处理
3. 不再展开文件审计或日志中心设计

###### CM2.8 `file preview` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 聊天页点击文件打开 | 文件预览页、聊天页文件消息状态 | `/infra/file/open-strategy` | 预览页按真实策略决定内开/外开/下载 |
| 群文件页点击文件 | 文件预览页、群文件页 | `fileId` | 统一走文件预览，不各页自写打开逻辑 |
| 下载成功 | 文件预览页、群文件页下载态 | `download` 成功回执 | 只更新当前文件下载态 |
| 媒体列表点击图片/视频 | 文件预览页、聊天媒体列表 | `/message/media` + `fileId` | 媒体列表与预览页同源 |
| 打开策略失效 | 文件预览页、来源页 | `open-strategy` 返回失效/不可读 | 预览页提示后回源页，不保留旧链接重试 |

##### CN2. 当前这一轮继续后的结论

1. `favorite / sticker / search / file preview` 已补到后端接口流程链路与页面联动刷新规则
2. 文档主线继续保持为：
   - 真实接口流程链路
   - 页面联动刷新规则
   - 不扩非功能性子系统
3. 后续若继续文档推进，优先建议：
   - 会话 / 聊天 / 文件上传专题继续按同口径补“接口流程链路 + 联动刷新规则”
   - 通话专题继续补“后端接口时序图级清单”

##### CO2. `conversation / chat / file upload` 后端接口流程链路与页面联动刷新规则

###### CO2.1 `conversation` 接口流程链路

核心接口：

- `GET /system/im/conversation/list`
- `GET /system/im/conversation/search`
- `POST /system/im/conversation/create`
- `DELETE /system/im/conversation/delete`
- `PUT /system/im/conversation/update`
- `PUT /system/im/conversation/mark-read-seq`
- `GET /system/im/conversation/get-by-target`
- `GET /system/im/badge/get`

流程链路要点：

1. `mark-read-seq` 是会话读水位主链路，流程链路重点保留：
   - `chatId`
   - `lastReadSequence`
2. `conversation.update` 只记录真实开关字段变化：
   - `isPinned`
   - `noDisturb`
3. `badge.get` 只作为角标同步链路，不再展开统计/审计设计

###### CO2.2 `conversation` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 联系人/群详情发消息建会话成功 | 会话列表页、聊天页 | `/conversation/get-by-target` 返回 `chatId` | 会话列表应出现真实新会话 |
| 会话置顶/免打扰切换 | 会话列表页、群设置页/聊天设置页 | `/conversation/update` 成功回执 | 列表排序和详情开关同源 |
| 删除会话 | 会话列表页、聊天页 | `/conversation/delete` 成功回执 | 当前聊天页若对应被删，应回退列表 |
| 标记已读成功 | 会话列表页、聊天页、角标状态 | `/conversation/mark-read-seq` 成功回执 | 未读数与角标一起收敛 |
| 收到实时 `conversationHint` | 会话列表页 | 后续 `/conversation/sync` 或等价增量结果 | hint 只做提示，不直接造最终态 |
| 角标快照更新 | 会话列表页、一级页 badge | `/badge/get` 或等价实时合并 | 会话未读和菜单 badge 同步刷新 |

###### CO2.3 `chat` 接口流程链路

核心接口：

- `GET /system/im/message/window`
- `GET /system/im/message/history`
- `GET /system/im/message/pull`
- `POST /system/im/message/send`
- `GET /system/im/message/detail`
- `PUT /system/im/message/recall`
- `DELETE /system/im/message/delete`
- `DELETE /system/im/message/clear`
- `GET /system/im/message/search`
- `PUT /system/im/message/mark-read`
- `PUT /system/im/message/mark-voice-played`
- `PUT /system/im/message/mark-voice-played-batch`
- `GET /system/im/message/voice-played-status`
- `POST /system/im/message/forward`
- `GET /system/im/read-receipt/summary`
- `GET /system/im/read-receipt/detail`
- `WS /ws`

流程链路要点：

1. `window/history/pull` 重点记录窗口恢复主键：
   - `chatId`
   - `anchorMessageId`
   - `sequence`
2. `send/forward/recall/delete/clear` 重点关注消息主键与页面回写顺序
3. WebSocket 只作为实时消息功能链路的一部分

###### CO2.4 `chat` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 打开聊天 latest/anchor | 聊天页、会话列表选中态 | `/message/window` | latest 与 anchor 模式都以真实窗口结果为准 |
| 上拉历史/断线补偿 | 聊天页时间线 | `/message/history` `/message/pull` | 不本地凭时间戳乱拼消息 |
| 发送消息成功 | 聊天页、会话列表、角标状态 | `/message/send` 返回 `messageId/sequence` | 会话预览以服务端消息结果更新 |
| 撤回消息 | 聊天页、会话列表预览、收藏/转发相关态 | `/message/recall` 成功回执 | 预览文案和时间线要同源 |
| 删除单条消息 | 聊天页 | `/message/delete` 成功回执 | 不影响其它页面预览时需按服务端结果判断 |
| 清空聊天记录 | 聊天页、会话列表预览、媒体页 | `/message/clear` 成功回执 | 聊天时间线清空后预览一起收敛 |
| 会话内搜索跳锚点 | 聊天页、搜索结果页 | `/message/search` + `/message/detail` | 聊天页按真实 `messageId` 定位 |
| 标记消息已读/语音已播 | 聊天页、会话列表、已读回执页 | `mark-read/mark-voice-played` 成功回执 | 已读点与语音未听点同源 |
| 转发消息成功 | 目标聊天页、目标会话列表 | `/message/forward` 成功回执 | 不本地假插入目标会话 |
| 已读回执查询 | 聊天页、回执详情页 | `summary/detail` | 概览与详情必须同源 |

###### CO2.5 `file upload` 接口流程链路

核心接口：

- `POST /infra/file/upload`
- `POST /infra/file/upload-and-return-id`
- 群文件链路：
  - `POST /system/im/group/file/upload`
- 发送编排链路：
  - 上传成功后再进入 `/system/im/message/send`

流程链路要点：

1. 上传流程围绕：
   - 任务状态变化
   - 文件主键
   - 所属 chat/group
2. `upload-and-return-id` 适用于需要先拿 `fileId` 再发消息的链路
3. 文件上传与消息发送是两段功能流程，要在文档里分开表述

###### CO2.6 `file upload` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 图片/视频/文件/语音上传开始 | 聊天页上传态、发送态 | `ChatUploadCoordinator` 任务状态 | 页面只展示任务状态，不自写目录规则 |
| 上传成功并发送消息成功 | 聊天页、会话列表、媒体页/文件预览入口 | `upload` 成功 + `/message/send` 成功 | 会话预览只以最终消息结果刷新 |
| 上传失败 | 聊天页上传态 | `taskStatus=failed` | 不伪造成已发送消息 |
| 取消上传 | 聊天页上传态 | `taskStatus=cancelled` | 清理本地任务，不影响会话预览 |
| 群文件上传成功 | 群文件页、聊天页、文件预览入口 | `/group/file/upload` 成功回执 | 群文件列表和聊天消息入口要同源 |
| 媒体页打开上传产生的文件 | 媒体页、文件预览页 | 真实 `fileId` | 不直接使用临时本地路径跨页传递 |

##### CP2. 当前这一轮继续后的结论

1. `conversation / chat / file upload` 已补到后端接口流程链路与页面联动刷新规则
2. 当前“其余专题”主线已连续补齐：
   - `favorite / sticker / search / file preview`
   - `conversation / chat / file upload`
3. 后续若继续文档推进，优先建议：
   - 继续补“登录 / 我的 / 设置 / 资料”专题的接口流程链路与联动刷新规则
   - 通话专题继续补“后端接口时序图级清单”

##### CQ2. `login / profile / settings` 后端接口流程链路与页面联动刷新规则

###### CQ2.1 `login` 接口流程链路

核心接口：

- `POST /system/auth/login`
- `POST /system/auth/sms-login`
- `POST /system/auth/send-sms-code`
- `GET /system/auth/get-permission-info`
- `POST /system/auth/logout`
- `POST /system/auth/refresh-token`
- `POST /system/captcha/get`
- `POST /system/captcha/check`
- `GET /system/tenant/get-id-by-name`

流程链路要点：

1. 登录流程只保留真实接口顺序与页面状态变化
2. `refresh-token` 记录：
   - 旧 token 失效场景
   - 刷新成功后的链路恢复
3. 图形验证码链路只记录是否触发、校验结果，不长期保留明文输入

###### CQ2.2 `login` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 账号密码登录成功 | 应用启动壳、会话列表、我的页、权限态 | `/auth/login` + `/auth/get-permission-info` | 以 bootstrap 后的真实用户态为准 |
| 短信登录成功 | 同上 | `/sms-login` + `/get-permission-info` | 不绕过 bootstrap 直接进首页 |
| 刷新 token 成功 | 当前页面、网络层、WebSocket 重连态 | `/refresh-token` 成功回执 | 不要求页面整页重刷，但要更新链路凭证 |
| 登录失败触发验证码 | 登录页 | `/captcha/get` `/captcha/check` | 页面只展示真实验证码状态 |
| 登出成功 | 所有一级页、聊天页、会话页、我的页 | `/auth/logout` 成功回执 | 清空用户态并回登录页 |

###### CQ2.3 `profile / settings` 接口流程链路

核心接口：

- `GET /system/user/get-profile`
- `GET /system/user/get?id=...`
- `POST /system/user/avatar`
- `DELETE /system/user/avatar`
- `PUT /system/user/theme`
- `PUT /system/user/chat-bubble`
- `POST /system/app-upgrade/check`
- `POST /system/app-upgrade/report-event`

流程链路要点：

1. `get-profile` 与 `user/get` 只保留读取链路和页面消费关系
2. 头像上传/删除只保留功能链路，不扩文件审计
3. 主题/气泡偏好更新记录最终值，供设置恢复与排障
4. 升级检查/事件上报仍归入 `upgrade` 专题主链，但设置页侧保留入口过程字段

###### CQ2.4 `profile / settings` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 我的页进入/下拉刷新 | 我的页、设置页基础资料区 | `/system/user/get-profile` | 用户昵称、头像、部门等同源 |
| 更新头像成功 | 我的页、个人资料页、会话头像展示、联系人卡片中的本人头像 | `/system/user/avatar` 成功回执 | 头像相关展示统一刷新 |
| 清空头像成功 | 同上 | `/system/user/avatar` 删除成功回执 | 回退默认头像展示 |
| 修改主题成功 | 主题设置页、全局壳、聊天页、会话列表 | `/system/user/theme` 成功回执 | 主题切换以真实偏好和本地主题控制器同源 |
| 修改聊天气泡偏好成功 | 设置页、聊天页消息气泡 | `/system/user/chat-bubble` 成功回执 | 不只局部刷新当前聊天页 |
| 设置页手动检查更新 | 设置页、升级弹窗 | `/system/app-upgrade/check` | 仅以真实返回决定是否弹窗 |
| 升级弹窗动作上报 | 设置页、升级统计链路 | `/system/app-upgrade/report-event` | 上报失败不阻断用户动作，但不本地假成功 |
| 语言切换 | 语言设置页、全局壳、登录页、我的页 | 本地 locale controller + 稳定文案国际化结果 | 语言本身非后端接口主线，但切换后页面统一刷新 |

###### CQ2.5 `profile` 与其它页面联动规则

| 触发页面/动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 我的页头像更新 | 聊天页、会话列表、联系人详情中本人信息 | 真实头像 URL 新值 | 本人头像相关缓存要失效 |
| 主题设置更新 | 会话列表页、聊天页、设置页、文件预览页 | `themeMode` 新值 | 视觉状态统一切换 |
| 聊天气泡设置更新 | 聊天页、消息气泡组件 | `chatBubbleColor/chatBubbleMode` 新值 | 历史消息和新消息展示口径一致 |
| 登录后首次 bootstrap 完成 | 我的页、通讯录、会话列表 | `get-permission-info + get-profile` | 以完整用户态再开放主壳页面 |

##### CR2. 当前这一轮继续后的结论

1. `login / profile / settings` 已补到后端接口流程链路与页面联动刷新规则
2. 当前“其余专题”主线已继续补到：
   - `favorite / sticker / search / file preview`
   - `conversation / chat / file upload`
   - `login / profile / settings`
3. 后续若继续文档推进，优先建议：
   - 按同口径继续查漏剩余模块的接口流程链路与联动刷新规则
   - 通话专题继续补“后端接口时序图级清单”

##### CS2. `read receipt / forward / media / location` 后端接口流程链路与页面联动刷新规则

###### CS2.1 `read receipt` 接口流程链路

核心接口：

- `GET /system/im/read-receipt/summary`
- `GET /system/im/read-receipt/detail`
- `PUT /system/im/message/mark-read`
- `PUT /system/im/conversation/mark-read-seq`

流程链路要点：

1. `summary/detail` 记录消息主键和已读/未读查询维度
2. `mark-read` 与 `mark-read-seq` 分开记录：
   - 消息级已读
   - 会话级读水位
3. 不扩独立已读统计或审计子系统

###### CS2.2 `read receipt` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 打开已读回执概览 | 聊天页、回执概览区 | `/read-receipt/summary` | 只展示真实汇总值 |
| 打开已读/未读详情 | 回执详情页、聊天页回执入口 | `/read-receipt/detail` | 概览与详情计数同源 |
| 会话读水位推进 | 聊天页、会话列表、回执概览 | `/conversation/mark-read-seq` | 会话未读数与消息已读状态同步收口 |
| 消息级已读补报成功 | 聊天页、回执详情页 | `/message/mark-read` | 不本地猜测已读名单 |

###### CS2.3 `forward` 接口流程链路

核心接口：

- `POST /system/im/message/forward`
- `POST /system/im/favorite/resend`

流程链路要点：

1. 消息转发与收藏转发分开记录，但字段口径统一
2. 只保留目标会话主键、消息主键与页面回写顺序

###### CS2.4 `forward` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 聊天页转发消息成功 | 目标聊天页、目标会话列表、转发结果页 | `/message/forward` 成功回执 | 目标会话以真实新消息更新 |
| 收藏详情再转发成功 | 目标聊天页、目标会话列表、收藏详情页 | `/favorite/resend` 成功回执 | 收藏详情不本地假插入消息 |
| 目标会话失效 | 转发目标页、来源聊天页 | 转发接口返回失败 | 保留来源页，提示后刷新目标列表 |

###### CS2.5 `media` 接口流程链路

核心接口：

- `GET /system/im/message/media`
- `GET /infra/file/open-strategy`
- `GET /infra/file/presigned-get-url`

流程链路要点：

1. 媒体列表重点记录：
   - `chatId`
   - `fileType`
   - 分页参数
2. 打开媒体仍复用文件预览策略，不另起打开逻辑链路

###### CS2.6 `media` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 打开聊天媒体页 | 媒体列表页、聊天页 | `/message/media` | 媒体页只展示真实媒体记录 |
| 媒体项点击打开 | 媒体列表页、文件预览页 | `/infra/file/open-strategy` | 打开逻辑与文件预览同源 |
| 聊天记录清空 | 媒体列表页、聊天页 | `/message/clear` 成功回执 | 媒体列表需同步清空或重拉 |
| 新图片/视频发送成功 | 媒体列表页、聊天页 | 上传成功 + `/message/send` 成功 | 媒体页要能看到新记录 |

###### CS2.7 `location` 接口流程链路

核心接口：

- `GET /system/im/message/location-search`
- 位置消息最终发送仍进入：
  - `POST /system/im/message/send`

流程链路要点：

1. 位置能力只记录检索与发送过程字段
2. 位置消息最终仍以消息发送主链路为准，不另造发送闭环

###### CS2.8 `location` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 打开位置选择器 | 位置选择页、聊天页更多面板 | `/message/location-search` | 搜索结果只展示真实 POI |
| 发送位置消息成功 | 聊天页、会话列表、地图卡片消息气泡 | `/message/send` 成功回执 | 会话预览按真实消息更新 |
| 无法显示内嵌地图 | 聊天页位置气泡、外部打开入口 | 真实位置消息内容 | 降级为位置卡片，不伪造地图预览 |

##### CT2. 当前这一轮继续后的结论

1. `read receipt / forward / media / location` 已补到后端接口流程链路与页面联动刷新规则
2. 当前“其余专题”主线已进一步补齐聊天主链相关子域
3. 后续若继续文档推进，优先建议：
   - 继续做剩余模块查漏，重点核对是否还有未被真实接口流程链路覆盖的页面
   - 通话专题继续补“后端接口时序图级清单”

##### CU2. `direct settings / mention / contact card / message action` 接口流程链路与页面联动刷新规则

###### CU2.1 `direct settings` 接口流程链路

核心接口：

- `GET /system/user/get?id=...`
- `GET /system/im/conversation/get-by-target`
- `PUT /system/im/conversation/update`
- 联系人设置相关：
  - `GET /system/im/contact/get`
  - `PUT /system/im/contact/setting/update`

流程链路要点：

1. 单聊设置页的真实基础数据来自：
   - 目标用户资料
   - 当前单聊 `chatId`
   - 会话设置开关
2. `pinned/noDisturb` 仍统一走 `/conversation/update`
3. 若页面带“关注联系人”等能力，仍复用联系人设置接口，不在单聊设置页单开写口

###### CU2.2 `direct settings` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 单聊设置修改置顶/免打扰 | 单聊设置页、会话列表、聊天页标题区设置态 | `/conversation/update` 成功回执 | 与群设置里的会话设置保持同源 |
| 单聊设置更新联系人关注态 | 单聊设置页、联系人详情页、星标联系人页 | `/contact/setting/update` 成功回执 | 不本地猜关注状态 |
| 单聊设置页进入用户资料 | 联系人详情页、单聊设置页回跳态 | `userId` | 资料变更后回源页重新拉详情 |

###### CU2.3 `mention` 接口流程链路

核心接口：

- 群成员来源：
  - `GET /system/im/group/member/list`
- 发送消息仍进入：
  - `POST /system/im/message/send`

流程链路要点：

1. `mention-picker` 不单独创造消息接口
2. 选择 @ 成员后，最终要写入消息发送主链路：
   - 文本内容
   - `mentionUserIds`
3. 群成员候选集必须来自真实群成员列表，不本地拼接假成员

###### CU2.4 `mention` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 打开 @ 选择器 | `mention-picker`、聊天输入区 | `/group/member/list` | 候选成员以真实群成员为准 |
| 选中 @ 成员并发送成功 | 聊天页、目标成员通知态、消息气泡 | `/message/send` 成功回执 | 消息体中的 `mentionUserIds` 与气泡展示同源 |
| 群成员变更后再次打开 @ 选择器 | 选择器、聊天页 | 最新成员列表 | 不沿用旧缓存成员 |

###### CU2.5 `contact card` 接口流程链路

核心接口：

- 联系人候选来源：
  - `GET /system/im/contact/list`
  - `GET /system/im/contact/search`
- 名片消息最终发送：
  - `POST /system/im/message/send`

流程链路要点：

1. `contact-card-picker` 只负责选择联系人，不负责直接发消息
2. 名片消息最终仍走消息发送主链路
3. 名片内容必须基于真实联系人资料字段，不本地造卡片对象

###### CU2.6 `contact card` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 打开名片选择器 | 名片选择页、聊天页更多面板 | `/contact/list` 或 `/contact/search` | 候选联系人来自真实列表 |
| 发送名片成功 | 聊天页、会话列表、联系人详情页入口态 | `/message/send` 成功回执 | 会话预览按真实消息更新 |
| 联系人资料更新后再次发送名片 | 名片选择页、聊天页名片气泡 | 最新联系人资料 | 不复用过期本地卡片内容 |

###### CU2.7 `message action` 接口流程链路

核心接口：

- `PUT /system/im/message/recall`
- `DELETE /system/im/message/delete`
- `POST /system/im/favorite/add`
- `POST /system/im/message/forward`
- 依赖详情补拉：
  - `GET /system/im/message/detail`

流程链路要点：

1. 消息菜单只是动作入口，不拥有独立后端链路
2. 撤回、删除、收藏、转发都回到各自已确认的真实接口
3. 若页面需要先补消息详情，再打开动作面板，则以 `/message/detail` 为准

###### CU2.8 `message action` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 撤回消息 | 聊天页、会话列表预览、收藏相关态 | `/message/recall` 成功回执 | 时间线和预览文案同源 |
| 删除消息 | 聊天页 | `/message/delete` 成功回执 | 仅删除当前可见消息项，不乱改预览 |
| 收藏消息 | 聊天页菜单、收藏列表页 | `/favorite/add` 成功回执 | 菜单收藏态和收藏列表同源 |
| 转发消息 | 转发目标页、目标聊天页、目标会话列表 | `/message/forward` 成功回执 | 不本地假插入目标会话 |

##### CV2. 当前这一轮继续后的结论

1. `direct settings / mention / contact card / message action` 已补到接口流程链路与页面联动刷新规则
2. 当前“其余专题”主线已经覆盖大多数现成接口驱动的前端功能页
3. 后续若继续文档推进，优先建议：
   - 再做一轮统一查漏，确认是否仍有未覆盖的真实功能页
   - 通话专题继续补“后端接口时序图级清单”

##### CW2. `create group / group join / join requests` 接口流程链路与页面联动刷新规则

###### CW2.1 `create group` 接口流程链路

核心接口：

- `POST /system/im/group/create`
- `POST /system/im/group/member/add`
- 建群后会话跳转仍复用：
  - `GET /system/im/conversation/get-by-target`

流程链路要点：

1. 建群页本质上是“创建群 + 初始化成员”的功能链路
2. 建群成功后不本地伪造群详情或群会话，仍以真实 `groupId/chatId` 跳转
3. 若后续成员追加走单独接口，则仍复用 `group/member/add`

###### CW2.2 `create group` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 创建群成功 | 我的群组页、会话列表、聊天页、群设置页 | `/group/create` 成功回执 + 真实 `groupId/chatId` | 新群应在群列表与会话列表同时出现 |
| 建群后追加成员成功 | 群成员页、群设置页成员预览 | `/group/member/add` 成功回执 | 成员数量和预览同源更新 |
| 建群失败 | 创建群页、联系人选择态 | 创建接口失败回执 | 保留已选成员和表单内容，不本地清空 |

###### CW2.3 `group join` 接口流程链路

核心接口：

- `GET /system/im/group/invite/verify`
- `POST /system/im/group/invite/join`
- 若需要展示群基本信息：
  - `GET /system/im/group/get`

流程链路要点：

1. 扫码/邀请码入群必须先 `verify`，后 `join`
2. `verify` 负责确认：
   - 邀请码是否有效
   - 是否已过期
   - 是否需要审批
3. `join` 成功后，后续群详情和群会话仍以真实 `groupId/chatId` 拉取

###### CW2.4 `group join` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 校验邀请码成功 | 入群确认页、群信息卡片 | `/invite/verify` 成功回执 | 展示真实群信息与加入条件 |
| 邀请码已失效/过期 | 入群确认页、二维码页 | `/invite/verify` 失败回执 | 停留当前页并提示，不继续走 join |
| 入群成功 | 我的群组页、会话列表、群详情页 | `/invite/join` 成功回执 | 新群应进入我的群组与会话列表 |
| 入群进入审批态 | 入群确认页、我的群组页候选状态 | `join` 返回待审批结果 | 不本地直接认为已入群 |

###### CW2.5 `join requests` 接口流程链路

核心接口：

- `GET /system/im/group/join-request/list`
- `GET /system/im/group/join-request/pending-count`
- `GET /system/im/group/join-request/managed-pending-count`
- `PUT /system/im/group/join-request/approve`
- `PUT /system/im/group/join-request/reject`

流程链路要点：

1. 群申请页主链路是：
   - 拉申请列表
   - 拉待处理数
   - 审批/拒绝后回刷
2. `managed-pending-count` 用于“我管理的群申请总览”入口
3. 审批动作成功后必须重新取：
   - 当前列表
   - 当前群待处理数
   - 我管理的总待处理数

###### CW2.6 `join requests` 页面联动刷新规则

| 触发动作 | 需要刷新页面 | 刷新依据 | 说明 |
|---|---|---|---|
| 打开入群申请页 | 申请列表页、群设置页待处理数 | `list + pending-count` | 列表和数字同源 |
| 同意申请成功 | 申请列表页、群设置页、群成员页、总待处理入口 | `/approve` 成功回执 | 新成员应反映到成员数量和列表 |
| 拒绝申请成功 | 申请列表页、群设置页、总待处理入口 | `/reject` 成功回执 | 待处理数同步减少 |
| 他端已处理同一申请 | 申请列表页、群设置页待处理数 | 审批接口返回状态冲突或列表重拉结果 | 不保留旧申请项 |

##### CX2. 当前这一轮继续后的结论

1. `create group / group join / join requests` 已补到接口流程链路与页面联动刷新规则
2. 群域剩余真实功能页已进一步收口，不再只停留在群设置页
3. 后续若继续文档推进，优先建议：
   - 再做一轮统一查漏，确认是否仍有未覆盖的真实功能页
   - 通话专题继续补“后端接口时序图级清单”

##### CY2. 页面覆盖查漏结论

基于当前 Flutter 页面目录与统一文档已补内容，对现有页面做一轮覆盖核对后，结论如下。

###### CY2.1 已被真实接口链路覆盖的页面

以下页面已在统一文档中补到真实接口链路、页面联动规则、或状态收口规则：

1. `login_page.dart`
2. `conversation_list_page.dart`
3. `chat_page.dart`
4. `contacts_page.dart`
5. `contact_profile_page.dart`
6. `my_groups_page.dart`
7. `my_department_page.dart`
8. `org_browser_page.dart`
9. `contact_search_result_page.dart`
10. `profile_page.dart`
11. `settings_page.dart`
12. `theme_settings_page.dart`
13. `language_settings_page.dart`
14. `file_preview_page.dart`
15. `group_settings_page.dart`
16. `group_members_page.dart`
17. `group_announcement_page.dart`
18. `group_qr_code_page.dart`
19. `group_files_page.dart`
20. `group_chat_history_page.dart`

补充说明：

1. 路由级子域虽然未必都对应独立 `page.dart` 文件，例如：
   - `forward-target`
   - `mention-picker`
   - `contact-card-picker`
   - `location-picker`
   但其真实接口链路与联动规则也已纳入文档
2. `create-group / group-join / join-requests` 虽当前 Flutter 目录未必已拆成完整独立页面文件，但其真实接口链路已补进统一文档，后续可直接按文档推进

###### CY2.2 当前明确属于静态 / 本地设置消费的页面

以下页面当前不再作为“继续补真实后端接口链路”的重点：

1. `workbench_page.dart`
   - 维持静态一级入口页结论
2. `theme_settings_page.dart`
   - 主要属于本地主题消费与用户偏好写口结合
   - 不需要再扩额外后端专题
3. `language_settings_page.dart`
   - 主要属于本地语言切换与稳定文案国际化消费
   - 当前不是高优先真实接口缺口

###### CY2.3 当前保留为独立专题 / blocked 的页面

以下页面不纳入“其余专题接口链路查漏”主线，单独按既定专题推进：

1. `incoming_call_page.dart`
2. `outgoing_call_page.dart`
3. `call_session_page.dart`

原因：

1. 音视频通话后端控制面当前不属于“其余模块已有现成接口即可直接整合”的范畴
2. 已在文档中单独形成：
   - 接口目录
   - 状态机
   - 文件级落地顺序
   - 页面收口规则

###### CY2.4 当前仍可视为低优先补充页的页面

以下页面已被上级链路间接覆盖，但仍可在后续代码落地前做最后一轮字段查漏：

1. `group_member_detail_page.dart`
   - 主读写链路已真实接线，但仍适合做最后一轮字段与展示一致性核对

当前代码现状补充：

1. `group_member_detail_page.dart`
   - 当前已具备真实链路：
     - `joinTime` 已随群成员列表真实下发并展示
     - `avatarUrl` 已透传到成员列表与成员详情页，图片失败时回退首字母头像
     - `muteEndTime` 已进入 state，详情页可展示禁言截止时间
     - “发送消息”已通过 `/system/im/conversation/get-by-target` 懒取真实 `chatId`
     - “查看资料”已按真实 `userId` 跳到联系人详情页，再由详情页自行拉真实资料
     - “设置管理员 / 移除管理员 / 禁言 / 解除禁言 / 转让群主 / 移除成员”均已接真实写口
   - 当前仍保留的低优先缺口：
     - 当前未发现独立 `/group/member/detail` 一类后端读口
     - 因此成员详情页现阶段继续复用 `/system/im/group/member/list` 透传字段即可
     - 只有当后端新增独立成员详情字段（例如更完整资料、禁言操作者、禁言原因、角色变更审计）时，才值得再拆独立详情快照 / provider

最终定位：

1. `group_member_detail_page.dart`：保留为 `low_priority_real_page`
   - 当前“不新增独立详情 provider”结论：`completed`
2. `group_setting_detail_page.dart`：已下线，不再保留：`completed`

结论：

1. 当前统一文档已基本覆盖“除音视频通话与升级专题外”的主要真实功能页
2. 后续对这条主线不应再大面积扩写，而应以：
   - 页面落地前字段查漏
   - 现有链路一致性检查
   为主

##### CZ2. 当前这一轮继续后的结论

1. 已完成一轮基于页面目录的系统性覆盖查漏
2. 当前未发现除通话专题外仍大面积未纳入真实接口链路的核心页面
3. 后续若继续文档推进，优先建议：
   - 对低优先补充页做最后一轮字段查漏与定位确认
   - 通话专题继续补“后端接口时序图级清单”

---

## 29. 当前最推荐的下一批任务

任务状态标记说明：

- `pending`：已确认要做，但尚未开始
- `in_progress`：当前正在进行
- `blocked`：存在前置依赖，当前不适合继续深推
- `completed`：当前阶段已完成
- `archived_reference`：仅保留为归档参考，不再单独推进

续接输出要求：

1. 每次进入新一轮推进，先明确：
   - 当前任务状态
   - 当前正在进行的任务
   - 即将开始的任务
2. 若用户仅输入“继续”，默认按本节优先级顺序向下推进
3. 若遇到复杂专题存在前置依赖，应明确标记为 `blocked`，避免陷入无休止细改

当前阶段执行口径：

1. 当前阶段以“统一文档作为唯一执行入口 + 按状态稳步代码落地”为主：`in_progress`
2. 服务启动不作为当前任务主线，由用户手动执行：`completed`
3. 非必要 mock 交互、临时测试、额外演示链路一律不投入：`completed`
4. 新会话若用户输入 `系统性阅读sql/flutter-doc/IM-Flutter统一任务文档-v1.0.md文档继续稳步推进`，默认先读取本节状态，再直接从“即将开始的任务”首项继续：`completed`

统一文档推进优先顺序：

1. 页面级后端真实接口路径、核心入参/出参、页面消费字段系统补录：`in_progress`
2. 音视频通话专题后端控制面、REST/WS 协议、VO/DTO、推送与状态机补录：`in_progress`
3. 继续为其余真实功能模块补“接口路径 + 核心字段 + 页面消费口径”：`in_progress`
4. `workbench` 保持静态一级页结论，不再补实际接口：`completed`
5. 代码实现阶段已恢复，但仅沿文档已冻结优先级推进：`in_progress`

当前正在进行的任务：

- 页面级后端真实接口补录总任务：`in_progress`
- 音视频通话后端体系与底层协议设计补录：`in_progress`
- `call_providers.dart + call_controller.dart + outgoing_call_page.dart / incoming_call_page.dart / call_session_page.dart` 通话主链路切到真实仓储默认并下线伪接通骨架流转：`completed`
- `call_session_page.dart + call_controller.dart` RTC 远端流正式接入前，先收口连接态 / 重连态 / 失败态页面与状态机消费：`completed`
- 其余功能模块真实接口依据、VO 字段、页面消费口径查漏：`in_progress`
- `contacts_page.dart / my_groups_page.dart / my_department_page.dart / org_browser_page.dart + group_announcement_page.dart / group_qr_code_page.dart` 首批 mock / `--` 占位态清理：`completed`
- `group_settings_page.dart / group_files_page.dart / group_chat_history_page.dart / group_member_detail_page.dart / group_join_requests_page.dart` 第二批占位说明与 `--` 空态清理：`completed`
- `contacts / group settings` 未再使用的 mock / local hint 国际化 key 收缩：`completed`
- `group_setting_detail_page.dart` 占位骨架页下线，群设置二级页路由参数收缩：`completed`
- 统一文档全篇查漏与最终闭环确认：`completed`
- 代码落地恢复前的最终任务排序确认：`completed`
- 音视频通话专题“后端控制面 + service / processor / job 文件级落地顺序总表”与验收口径同步：`completed`
- `group_member_detail_page.dart` 低优先真实字段查漏与动作定位确认：`completed`
- `group_member_detail_page.dart` 头像 + `muteEndTime` 字段链路补齐：`completed`
- `group_member_detail_page.dart` 是否需要独立成员详情快照接口 / provider 结论冻结：当前不需要：`completed`
- `group_settings_page.dart` 主开关真实写口与状态映射旧结论清理：`completed`
- `group_qr_code_page.dart` 审批提示与二维码字段消费旧结论清理：`completed`
- `my_groups_page.dart` 群头像真实消费与 `groupId` 跳转旧结论清理：`completed`
- `contact_search_result_page.dart / org_browser_page.dart / my_department_page.dart` 跳转与路由消费旧结论清理：`completed`
- `contacts_page.dart / my_department_page.dart` 入口与部门切换旧结论清理：`completed`
- `ContactDirectoryItem.phoneMasked -> postName` 语义纠偏与部门成员副标题口径对齐：`completed`
- `SearchChatHistoryPage` 接入 `snippet/highlight` 命中片段消费：`completed`
- `FavoritesPage` 接入收藏失效态标签与不可打开保护：`completed`
- `GroupSettingsState.notice` 接入状态层并回显群公告摘要：`completed`
- `group_join_requests_page.dart` 接入 `applicantAvatar` 真实头像展示与失败回退：`completed`
- `group_settings / group_members` 状态层默认中文标题下沉到页面 l10n 回退：`completed`
- `group_files_page.dart` 按 `mimeType` 区分文件类型图标展示：`completed`
- `group_chat_history_page.dart` 的 `messageType` 解析补齐 `location/contactCard`：`completed`
- `group_settings_page.dart` 首页成员预览补齐 `avatarUrl` 真实头像消费：`completed`
- `group_settings_page.dart` 顶部“群主”标记改为基于当前登录用户与 `ownerUserId` 的真实关系判断：`completed`
- `GroupInviteInfoDto` 补齐 `id/expireTime/qrUrl/qrImageUrl` 与布尔数值兼容解析：`completed`
- `GroupJoinRequestItemDto` 补齐 `userId/avatarUrl/avatar/applyTime/updateTime/auditTime` 与毫秒时间兼容解析：`completed`
- `GroupFileItemDto` 补齐 `size/createTime/contentType` 与字符串数值/毫秒时间兼容解析：`completed`
- `ContactDto` 补齐 `userId/remarkName/userName/realName/avatarUrl/departmentName/positionName` 兼容解析：`completed`
- `MessageSearchItemDto` 补齐 `sourceChatId/sortKey/chatName/targetName/receiverId/targetGroupId` 与标题误回退修正：`completed`
- `ContactProfileDto` 补齐 `remarkName/userName/realName/phone/avatarUrl/departmentName/positionName` 兼容解析：`completed`
- `FavoriteItemDto` 补齐 `chatName/previewText/senderNickname/createdAt` 与时间字符串/毫秒值兼容解析：`completed`
- `FavoriteItemDto` 补齐 `sourceMessageStatus` 与 `direct/single/private` 会话类型兼容解析：`completed`
- `DepartmentSummaryDto` 补齐 `deptId/departmentId/deptName/memberNum/userCount` 兼容解析：`completed`
- `contact_search_result_page.dart` 部门结果副标题改用 `contactsCountPeople` 本地化人数文案：`completed`
- `my_department_page.dart` 顶部部门 chip 改用 `contactsCountPeople` 本地化人数文案：`completed`
- `contacts_page.dart` 联系人分组索引对空名称改为 `#` 回退，避免真实空昵称崩溃：`completed`
- `contacts_page.dart` 联系人头像配色对空名称回退默认色，避免 `codeUnitAt(0)` 崩溃：`completed`
- `GroupSummaryDto` 补齐 `groupId/groupName/avatarUrl/memberNum` 与字符串数值人数兼容解析：`completed`
- `DirectConversationRef.targetId` 改为优先消费会话回包真实值，缺失时再回退 `userId`：`completed`
- `ConversationDto` 补齐 `direct/single/private`、`topStatus/muteStatus` 与时间/计数字符串兼容解析：`completed`
- `ConversationDto` 补齐 `location/contactCard/pending/success/error` 的消息类型/状态兼容解析：`completed`
- `ConversationDto` 补齐 `conversationId/id/name` 的 `chatId/title` 兼容解析：`completed`
- `ConversationSyncResponseDto` 补齐 `items/list/records/version/more` 与布尔数值兼容解析：`completed`
- `ConversationRemoteDataSource.fetchConversationList()` 补齐裸数组与 `list/records/items` 容器兼容解析：`completed`
- `conversation_tile.dart` 会话标题对空白字符串回退 `chatId/?`，避免真实空标题崩溃：`completed`
- `search_chat_history_page.dart` 列表标题与跳转标题统一对空 `conversationName` 回退 `senderName/chatId`：`completed`
- `chat_settings_page.dart` 单聊设置页头像补齐 `profile.avatarUrl` 真实消费：`completed`
- `contact_card_message_bubble.dart` 联系人名片消息气泡补齐 `contactAvatar` 真实头像消费：`completed`
- `read_receipt_page.dart` 已消费回执明细 `avatar` 真实头像并统一空名称回退：`completed`
- `ReadReceiptDetailItemDto` 补齐 `id/nickname/name/avatar` 别名与毫秒时间兼容解析：`completed`
- `ReadReceiptSummaryDto` 补齐 `id/conversationId/sortKey` 与字符串计数兼容解析：`completed`
- `MessageRemoteDataSource` 的回执明细 / 媒体 / 历史列表补齐 `list/records/items` 容器兼容解析：`completed`
- `ChatHistoryItemDto` 补齐 `conversationId/sortKey/nickname/userName/createTime` 兼容解析：`completed`
- `ChatMediaItemDto` 补齐 `conversationId/attachmentId/userName/createTime` 与字符串文件大小兼容解析：`completed`
- `chat_page.dart` 转发目标选择底表对空会话标题/预览补齐 `chatId/-` 回退：`completed`
- `ConversationDto` 补齐 `previewText/content` 的最后一条消息预览兼容解析：`completed`
- `chat_page.dart` 转发成功提示对空会话标题补齐 `chatId` 回退：`completed`
- `MessageDto` 补齐 `id/conversationId/fromUserId/senderNickname/userName/messageType/messageStatus/sortKey` 与多时间字段兼容解析：`completed`
- `MessageWindowResponseDto` 补齐 `list/items/beforeHasMore/afterHasMore/anchorId` 与布尔数值兼容解析：`completed`
- `LocationSearchItemDto` 补齐 `id/title/poiName/addr/fullAddress/lat/lng/source` 与字符串经纬度兼容解析：`completed`
- `MessageRemoteDataSource.searchLocations()` 补齐 `pois/list/records/items` 容器兼容解析：`completed`
- `UploadAndCreateFileResponseDto` 补齐 `id/fileBizId/fileUrl/downloadUrl/fileName/originName/contentType/fileType/thumbnailFileId/coverFileId` 与字符串文件大小兼容解析：`completed`
- `FileOpenStrategyResponseDto` 补齐 `strategy/mimeType/fileType/previewLink/downloadLink/viewUrl/pdfUrl/convertedUrl/expireAt/isUnstable/openUrl/fileUrl` 与数值布尔兼容解析：`completed`
- `FileHttpDataSource.getPresignedGetUrl()` 补齐 `downloadUrl/presignedUrl` 回退读取：`completed`
- `FileOpenStrategyResponseDtoMapper` 在路由 `mimeType` 为空时回退消费服务端 `contentType`，并补齐 `viewer/convertedPdf` URL 回退：`completed`
- `file_preview_controller.dart` 的外部打开 / 下载 URL 回退链统一补齐到 `resolved/download/preview/converted/viewer`：`completed`
- `file_preview_body.dart` 页面展示 URL 回退链统一补齐到 `resolved/download/preview/converted/viewer`：`completed`
- `chat_media_page.dart` 在 `mimeType` 缺失时按常见视频扩展名兜底识别视频图标与预览 MIME：`completed`
- `file_message_bubble.dart` 文件名展示补齐 `fileName/content/l10n 文件` 非空回退：`completed`
- `chat_page.dart` 文件预览入口补齐文件名非空回退与图片/视频扩展名 MIME 兜底：`completed`
- `FilePreviewCapabilityService` 下载能力判定补齐 `convertedPdfUrl/viewerUrl` URL 可用性：`completed`
- `FileOpenCoordinator` 的 download-only / embedded URL 选择补齐到 `download/preview/converted/viewer` 回退链：`completed`
- `chat_media_controller.dart` 失败附件重传上传输入补齐文件名非空回退与图片/视频扩展名 MIME 兜底：`completed`
- `chat_media_controller.dart` 首次附件上传输入补齐文件名非空回退与图片/视频扩展名 MIME 兜底：`completed`
- `optimistic_message_factory.dart` 乐观图片/文件消息补齐文件名非空回退与图片/视频扩展名 MIME 兜底：`completed`
- `MessageDto` 补齐 `downloadUrl/filePath/thumbUrl/previewUrl/originName/contentType` 的附件字段兼容解析：`completed`
- `file_preview_page.dart` 标题对空文件名补齐 `filePreviewTitle` 回退：`completed`
- `file_preview_body.dart` 正文文件名抬头对空字符串补齐 `filePreviewTitle` 回退：`completed`
- `file_preview_page.dart` 外部打开按钮改为基于真实 URL 可用性启用，避免空操作入口：`completed`
- `file_preview_body.dart` 在无 URL 但有 `fallbackMessage` 时改为展示可读提示，避免正文空白：`completed`
- `file_preview_page.dart` 下载按钮改为基于 `capability.canDownload` 启用，避免不可下载时仍可点：`completed`
- `FilePreviewCapabilityService` 的 `canOpenExternal` 改为与真实 URL 可用性一致，页面不再重复独立判断：`completed`
- `chat_page.dart + file_preview_page.dart` 文件消息详情页“预览 / 下载 / 转发”多端方案与现有转发链路复用调研：`completed`
- `AppFileController.open-strategy` 按图片/视频/音频/文本/PDF/Office 返回真实多端预览策略与扩展字段（`renderStrategy/contentType/viewerUrl/convertedPdfUrl/expiresAt`）：`completed`
- `chat_page.dart` 关键消息类型判断从 `type.name` 字符串比较收口为 `MessageType` 枚举比较：`completed`
- `chat_page.dart / chat_media_controller.dart` 的群聊判断从 `conversationType.name` 字符串比较收口为 `ConversationType` 枚举比较：`completed`
- `chat_controller.dart` 失败文本消息重试判断从 `type.name` 字符串比较收口为 `MessageType` 枚举比较：`completed`
- `conversation_tile.dart` 会话头像占位改为基于最终展示标题驱动首字母与配色，避免空标题时仍固定吃 `chatId` 种子：`completed`
- `chat_timeline.dart` 来消息发送者名补齐 `senderName/senderId/chatId/?` 非空回退，避免真实空昵称导致头像与标题空白：`completed`
- `chat_history_page.dart` 历史消息发送者为空时由硬编码 `--` 改为本地化“未知用户”兜底：`completed`
- `favorites_page.dart` 收藏列表群聊判断从 `conversationType.name` 字符串比较收口为 `ConversationType` 枚举比较：`completed`
- `favorites_page.dart` 收藏项标题补齐 `title/senderName/chatId` 非空回退，并避免副标题重复展示同一发送者名：`completed`
- `contact_profile_page.dart` 联系人资料页姓名为空时改为本地化 `profileUnknownUser` 兜底，电话/邮箱/岗位空值统一改走本地化占位：`completed`
- `group_member_detail_page.dart` 群成员详情页成员名改为本地化 `profileUnknownUser` 兜底，群名空值统一改走本地化占位，并同步收口发消息入口/确认弹窗文案消费：`completed`
- `group_members_page.dart` 群成员列表页成员名改为本地化 `profileUnknownUser` 兜底，并同步收口头像与详情页路由传参消费：`completed`
- `chat_settings_page.dart` 单聊设置页展示名改为 `profile.name/title/chatId/profileUnknownUser` 非空回退，头像与资料跳转统一吃同一显示名：`completed`
- `chat_history_page.dart` 历史消息时间为空时由硬编码 `--` 改为本地化未知时间兜底：`completed`
- `chat_page.dart` 引用回复发送者名补齐 `senderName/senderId/chatId/?` 非空回退，避免真实空昵称时引用头部空白：`completed`
- `group_settings_page.dart` 首页成员预览姓名为空时改为本地化 `profileUnknownUser` 兜底，头像与名称展示统一吃同一显示名：`completed`
- `chat_history_page.dart / group_chat_history_page.dart` 历史消息发送者展示从 `isEmpty` 提升为 `trim().isEmpty` 判空，避免服务端空白字符串导致标题空白：`completed`
- `contact_profile_page.dart / group_member_detail_page.dart` 发消息入口对会话标题判空收紧为 `trim().isEmpty`，避免服务端空白标题直接透传到聊天页：`completed`
- `contacts_page.dart / star_contacts_page.dart` 联系人列表与星标联系人跳聊入口对会话标题判空收紧为 `trim().isEmpty`，避免服务端空白标题直接透传到聊天页：`completed`
- `group_member_detail_page.dart / group_members_page.dart / group_join_requests_page.dart` 头像 fallback 首字提取统一从 `substring(0, 1)` 收口到 `characters.first`，避免复合字符首字被截断：`completed`
- `conversation` 域实体 / DTO / repository / controller` 补齐会话列表页一比一复刻所需的 `targetAvatar/lastMessageSequence/lastReadSequence/lastMessageHasAtMe/groupMemberCount` 与删除会话 / 标记已读能力：`completed`
- `conversation_list_page.dart` 已按老项目 `pages/message/message.uvue` 首轮重构为“头部三操作 + 内嵌搜索 + 分类栏 + 置顶折叠区 + 普通会话区 + 长按菜单 + 下拉刷新”主结构：`completed`
- `conversation_tile.dart` 已按老项目会话卡片补齐头像图/群图标、@我、群人数、免打扰、置顶区样式与未读角标展示：`completed`
- `conversation_list_page.dart` 搜索动作已补齐关键词透传到全局聊天搜索页，菜单动作改为页内通知闭环回显：`completed`
- `conversation_tile.dart` 最后一条消息预览为空时已按消息类型回退到老页风格文案，不再直接显示 `-`：`completed`
- `conversation_list_page.dart + conversation_tile.dart` 会话菜单已从底部弹窗收口为按长按/右键指针位置弹出的上下文菜单，更贴近老页长按/桌面右键交互：`completed`
- `conversation_list_page.dart` 已补齐老页的前后台增量同步判定、手动下拉刷新冷却/新鲜数据跳过/失败退避、以及群移除 notice 从本地存储消费并触发列表刷新：`completed`
- `conversation_list_page.dart + conversation_tile.dart` 已补齐桌面端鼠标主键长按 450ms 打开菜单并抑制后续误点进入聊天，与老页 `suppressNextClickChatId` 行为对齐：`completed`
- `conversation_list_controller.dart` `load()/syncIncrementally()` 已改为返回 `AppError?`，页面层可在不破坏现有状态更新的前提下接入刷新退避与 `Retry-After` 处理：`completed`
- `conversation_tile.dart` 已补齐老页会话预览文本的换行压平、100 字截断、`[群公告更新]` 高亮、以及按老页 bracket token 规则切分预览文本：`completed`
- `扫一扫` 入口已接到真实 Flutter 页面与路由，页面不再停留在会话页内联提示，并已与老项目相同地导向“手动入群”链路：`completed`
- `scan_page.dart` 已正式接入 Flutter 原生扫码插件 `mobile_scanner`，补齐相机权限声明、扫码结果防重复触发、页面前后台启停控制、以及扫码页手电筒开关，避免老页重复回调/误跳转问题：`completed`
- `join_group_page.dart` 已按老项目 `join-group.uvue` 接入 `/system/im/group/invite/verify` 与 `/system/im/group/invite/join`，支持邀请码/邀请链接解析、校验、加入、已在群中查看群聊：`completed`
- `initiate_group_page.dart` 已按老项目 `initiate-group.uvue` 接入 `/system/im/group/create`，支持当前用户默认入选、联系人检索、多选成员、按老规则生成群名并创建群聊后直达聊天页：`completed`
- `contacts` 选人链路已补齐老项目跨页共享选择态：新增 `contactSelectionController`、`ContactPickerArgs/ContactDepartmentArgs/ContactGroupMembersArgs` 与 `contactsMyFollowing/contactsGroupMembers` 路由，主选人页与子页面共用同一份已选成员集合：`completed`
- `my_groups_page.dart / my_following_page.dart / org_browser_page.dart / my_department_page.dart / contact_group_members_page.dart` 已切到“浏览态 / 选择态”双模式，选择态下严格服务于老项目 `发起群聊` 流程，不再停留在独立浏览页逻辑：`completed`
- `initiate_group_page.dart` 已从简化单页多选改造为老项目模式的“搜索 + 四个分类入口 + 联系人主列表 + 底部已选统计”主壳，分类入口可继续进入我的群组 / 我的关注 / 组织架构 / 我的部门 完成跨页选人：`completed`
- `initiate_group_page.dart` 已补齐 `mode=add` 对应的 Flutter 参数化入口与 `/system/im/group/member/add` 接口调用，并在进入添加成员模式前按真实群资料 + 群成员角色校验是否允许继续邀请：`completed`
- `group_settings repository / datasource` 已补齐 `verifyInviteCode/joinGroupByInvite/createGroup/addGroupMembers` 真实接口封装，供会话页顶部动作与后续群成员添加链路复用：`completed`
- `select_contact_card_page.dart` 名片选择页头像切到 `avatarUrl` 真实消费并收口空名称首字母回退：`completed`
- `contacts` 域 `avatarUrl` 消费补齐到列表 / 搜索 / 部门 / 星标 / 详情页：`completed`
- `contacts_page / star_contacts_page` 搜索提示与空态硬编码文案收口到 l10n：`completed`
- `contacts/group settings` 历史 mock 残影旧结论清理：`completed`

即将开始的任务：

- `其余功能模块真实接口依据、VO 字段、页面消费口径查漏`：继续收敛到低优先补充页与字段一致性核对：`in_progress`
- `chat_page.dart + file_preview_page.dart + file_download_service.dart` 文件消息详情页按微信式交互补齐“预览 / 下载 / 转发”，并把下载/预览实现收口到多端能力抽象：`pending`
- `open-strategy` 的真实 `xlsx/pptx/docx` 返回体联调核验与 kkFileView/对象存储响应头一致性确认：`pending`
- 音视频通话专题“接口入参/出参示例 JSON + 状态机迁移表最终版”：`completed`
- 音视频通话专题补“当前 Flutter 实现与统一协议差异收口表”：`completed`
- 音视频通话专题补到 `repository contract + remote/socket datasource + provider` 差异收口：`completed`
- 音视频通话专题继续补“后端文件清单 / 类职责 / 时序图 / 异常处理”与底部状态一致性复核：`completed`
- 低优先真实页面继续做“仅在后端已具备字段时才补”的一致性复核：`in_progress`

当前下一步收敛范围补充：

1. `workbench` 页当前定义为静态一级入口页，不纳入真实接口补录范围
2. 后续所有真实功能页的状态判断、角色判断、权限判断，都必须以服务端真实接口字段为准，不允许再以中文展示文案作为逻辑条件
3. 后续新增真实功能任务，必须在文档中补录对应接口路径、核心入参、核心出参字段与页面消费方式
4. 当前文档已正式进入“页面级真实接口补录 + 通话后端体系补录并行阶段”，后续直到所有功能模块补齐前，都持续把这项系统级任务维持为 `in_progress`
5. 真正进入功能实现阶段时，涉及真实用户可见稳定文案的新增或替换，必须同步处理国际化；占位中文不强制国际化
6. 测试服务统一由用户手动启动，文档推进与后续代码推进均不默认代启服务

文档推进优先顺序：

1. 统一文档已基本闭环，下一步以查漏补缺与精简为主
2. 页面主线已基本覆盖，后续优先做低优先页字段查漏与一致性核对
3. 通话专题继续作为独立复杂专题单独深挖
4. 如继续工程推进，应以统一文档为唯一执行入口开始代码或后端协同落地
5. 源文档始终保留，不做物理删除

---

## 30. 归档保留规则

旧 Flutter IM 文档不删除，统一保留为归档参考。

执行规则：

1. 统一文档作为后续执行入口
2. 旧文档作为来源留档，不再承担主执行入口职责
3. 后续如果要标记废弃，只做文档状态标记，不做物理删除

---

## 31. 归档来源分组索引

为便于后续回看归档源文档，按批次保留以下分组索引。

### Batch 1

- `IM-Flutter主目录与阅读顺序-v1.0.md`
- `IM-Flutter开工顺序与进度看板-v1.0.md`
- `IM-Flutter第一阶段文件级实施清单-v1.0.md`
- `IM-Flutter第一阶段代码骨架模板-v1.0.md`
- `IM-Flutter索引总表-v1.0.md`

### Batch 2

- `IM-Flutter多端重构设计任务文档-v1.0.md`
- `IM-Flutter核心协议与事件契约-v1.0.md`
- `IM-Flutter架构与工程规范-v1.0.md`
- `IM-Flutter目录树与文件清单-v1.0.md`
- `IM-Flutter后端协同约束与接口整顿建议-v1.0.md`

### Batch 3

- `IM-Flutter核心状态机与时序设计-v1.0.md`
- `IM-Flutter数据模型与存储设计-v1.0.md`
- `IM-Flutter核心字段表-v1.0.md`
- `IM-FlutterUseCase与数据访问分层设计-v1.0.md`
- `IM-Flutter类命名与文件组织规范-v1.0.md`
- `IM-Flutter通用业务工具与基础规则-v1.0.md`
- `IM-Flutter核心基础能力代码模板-v1.0.md`
- `IM-Flutter消息类型与组件映射规范-v1.0.md`

### Batch 4

- `IM-Flutter页面实现蓝图-v1.0.md`
- `IM-Flutter页面与路由详细设计-v1.0.md`
- `IM-Flutter登录页详细设计-v1.0.md`
- `IM-Flutter会话列表详细设计-v1.0.md`
- `IM-Flutter聊天页详细设计-v1.0.md`
- `IM-Flutter聊天页平台能力接线图-v1.0.md`
- `IM-Flutter聊天页事件命令状态表-v1.0.md`
- `IM-Flutter会话页事件命令状态表-v1.0.md`
- `IM-Flutter会话角标Socket协同设计-v1.0.md`
- `IM-Flutter群设置通讯录搜索详细设计-v1.0.md`

### Batch 5

- `IM-Flutter视觉与交互设计规范-v1.0.md`
- `IM-Flutter主题模式设计-v1.0.md`
- `IM-Flutter国际化与语言设置设计-v1.0.md`
- `IM-Flutter功能覆盖与交互验收清单-v1.0.md`

### Batch 6

- `IM-Flutter文件上传与发送链路设计-v1.0.md`
- `IM-Flutter文件上传对象模板-v1.0.md`
- `IM-Flutter文件上传代码骨架模板-v1.0.md`
- `IM-Flutter文件预览与多格式渲染设计-v1.0.md`
- `IM-Flutter文件预览控制器与策略设计-v1.0.md`
- `IM-Flutter文件预览页面交互设计-v1.0.md`
- `IM-Flutter文件预览对象模板-v1.0.md`
- `IM-Flutter文件预览代码模板-v1.0.md`
- `IM-Flutter文件预览测试清单-v1.0.md`

### Batch 7

- `IM-Flutter音视频通话企业级设计-v1.0.md`
- `IM-Flutter通话控制器与状态设计-v1.0.md`
- `IM-Flutter通话事件命令状态表-v1.0.md`
- `IM-Flutter通话对象代码模板-v1.0.md`
- `IM-Flutter通话代码骨架模板-v1.0.md`
- `IM-Flutter通话测试清单-v1.0.md`

### Batch 8

- `IM-Flutter基础设施选型与抽象层治理-v1.0.md`
- `IM-Flutter多端平台兼容落地设计-v1.0.md`
- `IM-FlutterOpenHarmony-HarmonyOS插件兼容矩阵-v1.0.md`
- `IM-FlutterOpenHarmony-HarmonyOS适配缺口清单-v1.0.md`
- `IM-FlutterOpenHarmony适配器骨架模板-v1.0.md`
- `IM-FlutterOpenHarmony平台门槛清单-v1.0.md`
- `IM-FlutterHarmonyOS平台门槛清单-v1.0.md`
- `IM-Flutter移动端离线推送设计-v1.0.md`
- `IM-Flutter地图与位置能力设计-v1.0.md`

### Batch 9

- `IM-Flutter依赖与Pubspec建议-v1.0.md`
- `IM-FlutterPubspec草案-v1.0.md`
- `IM-Flutter首批类骨架与文件职责-v1.0.md`
- `IM-Flutter第一阶段测试清单-v1.0.md`
- `IM-Flutter对象代码模板-v1.0.md`
- `IM-Flutter开发任务拆解清单-v1.0.md`
- `IM-Flutter后端协同实施优先级清单-v1.0.md`
- `IM-Flutter新会话续接说明与推荐指令-v1.0.md`
