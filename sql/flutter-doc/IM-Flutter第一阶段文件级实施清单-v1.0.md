# IM Flutter 第一阶段文件级实施清单 v1.0

> 文档日期：2026-04-29  
> 文档定位：第一阶段实际开工的文件级施工顺序、依赖关系、完成定义  

---

## 1. 阶段目标

第一阶段只做最小企业级主链路：

- 启动与壳
- 鉴权与网络
- 路由
- WebSocket 骨架
- 会话列表
- 聊天页主状态机

---

## 2. 开工顺序

### Step 1：应用基线

先创建：

- `lib/main.dart`
- `lib/app/bootstrap/app_bootstrap.dart`
- `lib/app/router/app_router.dart`
- `lib/app/shell/app_shell.dart`
- `lib/app/theme/app_theme.dart`

DoD：

- App 能启动到空白壳

### Step 2：核心基础设施

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

### Step 3：路由参数与共享枚举

创建：

- `app/router/route_args/chat_entry_args.dart`
- `app/router/route_args/group_context_args.dart`
- `shared/enums/conversation_type.dart`
- `shared/enums/message_type.dart`
- `shared/enums/message_status.dart`

DoD：

- 聊天路由参数模型冻结

### Step 4：conversation domain contract

创建：

- `features/im/conversation/domain/entities/conversation.dart`
- `features/im/conversation/domain/entities/conversation_cursor_state.dart`
- `features/im/conversation/domain/repositories/conversation_repository.dart`

DoD：

- 会话域 contract 冻结

### Step 5：chat domain contract

创建：

- `features/im/chat/domain/entities/message.dart`
- `features/im/chat/domain/entities/message_extra.dart`
- `features/im/chat/domain/entities/quote_info.dart`
- `features/im/chat/domain/entities/chat_viewport_state.dart`
- `features/im/chat/domain/repositories/message_repository.dart`

DoD：

- 聊天域 contract 冻结

### Step 6：conversation application

创建：

- `load_conversation_list_use_case.dart`
- `sync_conversations_incrementally_use_case.dart`
- `conversation_sync_result.dart`
- `conversation_sync_coordinator.dart`

DoD：

- 会话同步主流程能编译

### Step 7：chat application

创建：

- `open_chat_use_case.dart`
- `load_chat_window_use_case.dart`
- `load_older_messages_use_case.dart`
- `send_message_use_case.dart`
- `mark_conversation_read_use_case.dart`
- `open_chat_command.dart`
- `open_chat_result.dart`

DoD：

- 聊天页主流程 usecase 能编译

### Step 8：remote datasource + dto

优先创建：

- `conversation_remote_data_source.dart`
- `message_remote_data_source.dart`
- `conversation_dto.dart`
- `message_dto.dart`
- `message_window_response_dto.dart`

DoD：

- HTTP 契约文件成型

### Step 9：repository impl + mapper

创建：

- `conversation_repository_impl.dart`
- `message_repository_impl.dart`
- `conversation_dto_mapper.dart`
- `message_dto_mapper.dart`

DoD：

- usecase 可连到真实 repository

### Step 10：presentation state + controller

创建：

- `conversation_list_state.dart`
- `conversation_list_controller.dart`
- `chat_page_state.dart`
- `chat_timeline_state.dart`
- `chat_controller.dart`
- `chat_timeline_controller.dart`
- `chat_composer_controller.dart`
- `chat_receipt_controller.dart`

DoD：

- 页面状态层可编译

### Step 11：page + widgets

创建：

- `conversation_list_page.dart`
- `chat_page.dart`
- `conversation_tile.dart`
- `chat_timeline.dart`
- `chat_composer.dart`
- `message_bubble_factory.dart`
- `text_message_bubble.dart`

DoD：

- 能跑通最小会话列表 + 聊天页

---

## 3. 并行边界

可并行：

- `conversation` 与 `chat` 的 presentation
- DTO 与 mapper
- shared widgets 与 theme

不要并行：

- refresh coordinator 与 auth interceptor 的主链路设计
- chat state contract 的变更

---

## 4. 第一阶段必须能完成的能力

1. 登录后进入主壳
2. 会话列表显示
3. 点击会话进入聊天页
4. 聊天页 latest 打开
5. 聊天页 anchor 打开
6. 文本消息发送
7. websocket 收消息
8. 已读水位推进

---

## 5. 第一阶段暂不要求

- 全部消息类型
- 群设置全量能力
- 收藏
- 全局搜索
- 文件预览细节

---

## 6. 每步校验要求

每完成一步都应检查：

- 是否引入越层依赖
- 是否破坏命名规范
- 是否新增不必要抽象
- 是否保留强类型契约

