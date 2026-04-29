# IM Flutter 首批类骨架与文件职责 v1.0

> 文档日期：2026-04-29  
> 文档定位：第一阶段关键文件的最小职责说明，以及建议先创建的类骨架清单  

---

## 1. 目标

把第一阶段文件级实施清单再下钻一层，直接说明：

- 每个关键文件最小该干什么
- 里面先创建什么类

---

## 2. 应用基线文件职责

### 2.1 `lib/main.dart`

最小职责：

- `runApp`
- 初始化 app bootstrap

首批类：

- `ShengyuImApp`

### 2.2 `app/bootstrap/app_bootstrap.dart`

最小职责：

- 应用级初始化入口
- 注入 router、theme、shell

首批类：

- `AppBootstrap`

### 2.3 `app/bootstrap/auth_bootstrap_coordinator.dart`

最小职责：

- 登录成功后的初始化编排

首批类：

- `AuthBootstrapCoordinator`

### 2.4 `app/router/app_router.dart`

最小职责：

- 注册所有 route
- 配置 shell route

首批类：

- `AppRouter`

### 2.5 `app/shell/app_shell.dart`

最小职责：

- 主壳容器
- 底部 tab 或双栏容器

首批类：

- `AppShell`

---

## 3. Core 文件职责

### 3.1 `core/auth/auth_session.dart`

最小职责：

- 描述当前登录会话

首批类：

- `AuthSession`

### 3.2 `core/auth/refresh_token_coordinator.dart`

最小职责：

- 401 refresh 单飞
- 请求等待与重放

首批类：

- `RefreshTokenCoordinator`

### 3.3 `core/network/dio_client.dart`

最小职责：

- 统一构建 Dio
- 注入拦截器

首批类：

- `DioClientFactory`

### 3.4 `core/websocket/im_socket_client.dart`

最小职责：

- connect / auth / reauth / reconnect

首批类：

- `ImSocketClient`

### 3.5 `core/storage/storage_key_registry.dart`

最小职责：

- 统一生成 storage key

首批类：

- `StorageKeyRegistry`

---

## 4. Conversation 首批骨架

### 4.1 `domain/entities/conversation.dart`

首批类：

- `Conversation`

### 4.2 `domain/repositories/conversation_repository.dart`

首批类：

- `ConversationRepository`

### 4.3 `application/usecases/load_conversation_list_use_case.dart`

首批类：

- `LoadConversationListUseCase`

### 4.4 `application/usecases/sync_conversations_incrementally_use_case.dart`

首批类：

- `SyncConversationsIncrementallyUseCase`

### 4.5 `presentation/controllers/conversation_list_controller.dart`

首批类：

- `ConversationListController`

### 4.6 `presentation/states/conversation_list_state.dart`

首批类：

- `ConversationListState`

### 4.7 `presentation/pages/conversation_list_page.dart`

首批类：

- `ConversationListPage`

---

## 5. Chat 首批骨架

### 5.1 `domain/entities/message.dart`

首批类：

- `Message`

### 5.2 `domain/entities/message_extra.dart`

首批类：

- `MessageExtra`

### 5.3 `domain/entities/quote_info.dart`

首批类：

- `QuoteInfo`

### 5.4 `domain/repositories/message_repository.dart`

首批类：

- `MessageRepository`

### 5.5 `application/usecases/open_chat_use_case.dart`

首批类：

- `OpenChatUseCase`

### 5.6 `application/usecases/load_chat_window_use_case.dart`

首批类：

- `LoadChatWindowUseCase`

### 5.7 `application/usecases/send_message_use_case.dart`

首批类：

- `SendMessageUseCase`

### 5.8 `presentation/controllers/chat_controller.dart`

首批类：

- `ChatController`

### 5.9 `presentation/controllers/chat_timeline_controller.dart`

首批类：

- `ChatTimelineController`

### 5.10 `presentation/controllers/chat_composer_controller.dart`

首批类：

- `ChatComposerController`

### 5.11 `presentation/states/chat_page_state.dart`

首批类：

- `ChatPageState`

### 5.12 `presentation/states/chat_timeline_state.dart`

首批类：

- `ChatTimelineState`

### 5.13 `presentation/pages/chat_page.dart`

首批类：

- `ChatPage`

### 5.14 `presentation/widgets/factories/message_bubble_factory.dart`

首批类：

- `MessageBubbleFactory`

---

## 6. DTO 与 Mapper 首批骨架

### 6.1 `conversation_dto.dart`

首批类：

- `ConversationDto`

### 6.2 `message_dto.dart`

首批类：

- `MessageDto`

### 6.3 `message_window_response_dto.dart`

首批类：

- `MessageWindowResponseDto`

### 6.4 `conversation_dto_mapper.dart`

首批类：

- `ConversationDtoMapper`

### 6.5 `message_dto_mapper.dart`

首批类：

- `MessageDtoMapper`

---

## 7. 第一阶段共享 UI 骨架

建议先创建：

- `AppLoadingView`
- `AppErrorView`
- `AppEmptyView`
- `AppAvatar`
- `AppBadge`
- `AppSearchBar`

原因：

- 这些组件会被会话列表和聊天页第一批复用

---

## 8. Provider 聚合文件

### 8.1 `conversation_providers.dart`

先暴露：

- `conversationRepositoryProvider`
- `conversationListControllerProvider`

### 8.2 `chat_providers.dart`

先暴露：

- `messageRepositoryProvider`
- `chatControllerProvider`
- `chatTimelineControllerProvider`

---

## 9. 编写顺序建议

先写：

1. entity
2. repository contract
3. usecase
4. state
5. controller
6. page
7. widget
8. dto / mapper / repository impl 联通

---

## 10. 第一阶段暂不创建的骨架

先不创建：

- 收藏详情页复杂组件
- 群二维码分享 UI
- 语音录制全量状态 UI
- 搜索全量分页 UI

避免第一阶段文件过多、主链路不清。

