# IM 聊天页面多实例数据错乱 Bug 修复方案

## 问题描述

**现象**：在与用户1聊天时，从聊天消息中点击分享的用户名片进入用户2的详情页，点击"发消息"按钮后，出现以下异常情况：
- 停留在用户1的消息页面
- 或显示上一个对话（用户1）的数据

**严重程度**：核心功能缺陷，严重影响用户体验

## 问题复现路径

```
1. 进入与用户1的聊天页面
   └─> 路由栈: [ConversationList, ChatPage(user1)]
   
2. 在聊天消息中点击用户2的名片
   └─> 路由栈: [ConversationList, ChatPage(user1), ContactProfilePage(user2)]
   
3. 点击"发消息"按钮
   └─> 路由栈: [ConversationList, ChatPage(user1), ContactProfilePage(user2), ChatPage(user2)]
```

**预期行为**：显示用户2的聊天页面
**实际行为**：显示用户1的数据或页面未切换

## 根本原因分析

### 1. Provider 作用域设计缺陷（核心问题）

在 `chat_providers.dart` 中，关键 Provider 的作用域设计存在问题：

```dart
// ❌ 问题代码：autoDispose 但不是 family-scoped
final chatControllerProvider =
    StateNotifierProvider.autoDispose<ChatController, ChatPageState>((ref) {
  // ...
});

final chatTimelineControllerProvider =
    StateNotifierProvider.autoDispose<ChatTimelineController, ChatTimelineState>((ref) {
  // ...
});
```

**问题分析**：
- `autoDispose` 只在没有监听器时自动销毁
- 当多个 ChatPage 实例同时存在于路由栈时，第一个 ChatPage 仍然持有 Provider 引用
- 第二个 ChatPage 读取的是**同一个 Provider 实例**，导致状态共享和覆盖
- 第二个 ChatPage 的 `initialize()` 调用会覆盖第一个的状态，造成数据错乱

### 2. 对比正确的实现

```dart
// ✅ 正确实现：family-scoped by chatId
final chatRealtimeBindingProvider = Provider.autoDispose.family<void, String>((ref, chatId) {
  // 每个 chatId 有独立的实例
});
```

### 3. 受影响的 Provider 清单

| Provider 名称 | 当前作用域 | 问题 | 修复方案 |
|---|---|---|---|
| `chatControllerProvider` | autoDispose | 多实例共享 | 改为 family(chatId) |
| `chatTimelineControllerProvider` | autoDispose | 多实例共享 | 改为 family(chatId) |
| `chatRealtimeBindingProvider` | autoDispose.family(chatId) | ✅ 正确 | 无需修改 |
| `chatReceiptLastVisibleChatIdProvider` | StateProvider | 全局单例 | 改为 family(chatId) |
| `chatRuntimeNoticeProvider` | autoDispose | 多实例共享 | 改为 family(chatId) |
| `chatRealtimeSignalProvider` | autoDispose | 多实例共享 | 改为 family(chatId) |
| `activeConversationServiceProvider` | StateNotifierProvider | 全局单例 | 需要重新设计 |

## 修复方案

### 方案概述

将所有与特定聊天会话相关的 Provider 改为 **family-scoped by chatId**，确保每个 ChatPage 实例拥有独立的状态空间。

### 详细修复步骤

#### 步骤 1：修改 chatControllerProvider 为 family-scoped ✅ 已完成

**文件**：`lib/features/im/chat/presentation/providers/chat_providers.dart`

**修改前**：
```dart
final chatControllerProvider =
    StateNotifierProvider.autoDispose<ChatController, ChatPageState>((ref) {
  final currentUserId = ref.read(authSessionProvider).userId;
  final controller = ChatController(
    ref.read(openChatUseCaseProvider),
    ref.read(sendMessageUseCaseProvider),
    ref.read(markConversationReadUseCaseProvider),
    ref.read(optimisticMessageFactoryProvider),
    createConversationPreviewFormatter(ref.read(appLocaleProvider)),
    ref.read(conversationListControllerProvider.notifier),
    ref.read(chatTimelineControllerProvider.notifier),  // ❌ 依赖非 family provider
    socketClient: ref.read(imSocketClientProvider),
    socketOutboundSender: ref.read(socketOutboundSenderProvider),
    unifiedCacheManager: ref.read(unifiedCacheManagerProvider),
    currentUserId: currentUserId,
  );
  final cacheQueue = ref.read(messageCacheQueueProvider);
  controller.setCacheQueue(cacheQueue);
  ref.read(messageCacheQueueInitBindingProvider(ref.read(sendMessageUseCaseProvider)));
  return controller;
});
```

**修改后**：
```dart
final chatControllerProvider =
    StateNotifierProvider.autoDispose.family<ChatController, ChatPageState, String>((ref, chatId) {
  final currentUserId = ref.read(authSessionProvider).userId;
  final controller = ChatController(
    ref.read(openChatUseCaseProvider),
    ref.read(sendMessageUseCaseProvider),
    ref.read(markConversationReadUseCaseProvider),
    ref.read(optimisticMessageFactoryProvider),
    createConversationPreviewFormatter(ref.read(appLocaleProvider)),
    ref.read(conversationListControllerProvider.notifier),
    ref.read(chatTimelineControllerProvider(chatId).notifier),  // ✅ 传入 chatId
    socketClient: ref.read(imSocketClientProvider),
    socketOutboundSender: ref.read(socketOutboundSenderProvider),
    unifiedCacheManager: ref.read(unifiedCacheManagerProvider),
    currentUserId: currentUserId,
  );
  final cacheQueue = ref.read(messageCacheQueueProvider);
  controller.setCacheQueue(cacheQueue);
  ref.read(messageCacheQueueInitBindingProvider(ref.read(sendMessageUseCaseProvider)));
  return controller;
});
```

#### 步骤 2：修改 chatTimelineControllerProvider 为 family-scoped ✅ 已完成

**修改前**：
```dart
final chatTimelineControllerProvider =
    StateNotifierProvider.autoDispose<ChatTimelineController, ChatTimelineState>((ref) {
  final currentUserId = ref.read(authSessionProvider).userId;
  return ChatTimelineController(
    ref.read(loadChatWindowUseCaseProvider),
    ref.read(loadOlderMessagesUseCaseProvider),
    unifiedCacheManager: ref.read(unifiedCacheManagerProvider),
    currentUserId: currentUserId,
  );
});
```

**修改后**：
```dart
final chatTimelineControllerProvider =
    StateNotifierProvider.autoDispose.family<ChatTimelineController, ChatTimelineState, String>((ref, chatId) {
  final currentUserId = ref.read(authSessionProvider).userId;
  return ChatTimelineController(
    ref.read(loadChatWindowUseCaseProvider),
    ref.read(loadOlderMessagesUseCaseProvider),
    unifiedCacheManager: ref.read(unifiedCacheManagerProvider),
    currentUserId: currentUserId,
  );
});
```

#### 步骤 3：修改 chatReceiptLastVisibleChatIdProvider 为 family-scoped ✅ 已完成

**修改前**：
```dart
final chatReceiptLastVisibleChatIdProvider = StateProvider<String?>((ref) {
  return null;
});
```

**修改后**：
```dart
final chatReceiptLastVisibleChatIdProvider = StateProvider.family<String?, String>((ref, chatId) {
  return null;
});
```

#### 步骤 4：修改 chatRuntimeNoticeProvider 为 family-scoped ✅ 已完成

**修改前**：
```dart
final chatRuntimeNoticeProvider = StateProvider.autoDispose<ChatRuntimeNotice?>((ref) {
  return null;
});
```

**修改后**：
```dart
final chatRuntimeNoticeProvider = StateProvider.autoDispose.family<ChatRuntimeNotice?, String>((ref, chatId) {
  return null;
});
```

#### 步骤 5：修改 chatRealtimeSignalProvider 为 family-scoped ✅ 已完成

**修改前**：
```dart
final chatRealtimeSignalProvider = StateProvider.autoDispose<ChatRealtimeSignal?>((ref) {
  return null;
});
```

**修改后**：
```dart
final chatRealtimeSignalProvider = StateProvider.autoDispose.family<ChatRealtimeSignal?, String>((ref, chatId) {
  return null;
});
```

#### 步骤 6：更新 chat_page.dart 中的所有 Provider 调用 ✅ 已完成

**文件**：`lib/features/im/chat/presentation/pages/chat_page.dart`

需要将所有 Provider 调用改为传入 `chatId` 参数：

```dart
// 在 build 方法中
@override
Widget build(BuildContext context) {
  final chatId = widget.args.chatId;  // 提取 chatId
  
  // ✅ 所有 provider 调用都传入 chatId
  ref.watch(chatRealtimeBindingProvider(chatId));
  
  ref.listen<ChatRuntimeNotice?>(chatRuntimeNoticeProvider(chatId), (prev, next) {
    if (next == null || next.chatId != chatId || !mounted) {
      return;
    }
    ref.read(chatRuntimeNoticeProvider(chatId).notifier).state = null;
    // ...
  });
  
  // ... 其他 provider 调用类似修改
}
```

**关键修改点**：

1. **initState 方法**：
```dart
@override
void initState() {
  super.initState();
  final chatId = widget.args.chatId;
  
  _timelineSubscription = ref.listenManual<ChatTimelineState>(
    chatTimelineControllerProvider(chatId),  // ✅ 传入 chatId
    (previous, next) {
      _handleTimelineStateChanged(previous, next);
    },
  );
  // ...
}
```

2. **_initializeChatPage 方法**：
```dart
Future<void> _initializeChatPage() async {
  final chatId = widget.args.chatId;
  await ref.read(chatControllerProvider(chatId).notifier).initialize(widget.args);
  ref.read(chatReceiptLastVisibleChatIdProvider(chatId).notifier).state = chatId;
  // ...
}
```

3. **_handleResumeFromBackground 方法**：
```dart
Future<void> _handleResumeFromBackground() async {
  final chatId = widget.args.chatId;
  // ...
  await ref
      .read(chatTimelineControllerProvider(chatId).notifier)
      .pullMessagesAfterReconnect(command: command);
}
```

#### 步骤 7：更新 chat_realtime_binding.dart 中的 Provider 调用 ✅ 已完成

**文件**：`lib/features/im/chat/presentation/providers/chat_realtime_binding.dart`

所有读取 `chatControllerProvider` 和 `chatTimelineControllerProvider` 的地方都需要传入 `chatId`：

```dart
void _handleChatSocketEvent(Ref ref, String chatId, ImSocketEvent event) {
  // ...
  
  // ✅ 传入 chatId
  final timelineController = ref.read(chatTimelineControllerProvider(chatId).notifier);
  final pageState = ref.read(chatControllerProvider(chatId));
  
  // ...
}

void _flushMessageBatch(Ref ref, String chatId) {
  // ...
  final timelineController = ref.read(chatTimelineControllerProvider(chatId).notifier);
  final pageState = ref.read(chatControllerProvider(chatId));
  // ...
}
```

#### 步骤 8：处理 ActiveConversationService 的特殊情况

`ActiveConversationService` 是全局单例，用于追踪当前活跃的对话（用于角标计算等）。这个设计是合理的，因为同一时刻用户只能查看一个对话。

**无需修改**，但需要确保：
- `activateChat()` 在 ChatPage.initState 中正确调用
- `deactivateChat()` 在 ChatPage.dispose 中正确调用
- 多个 ChatPage 实例时，后激活的会覆盖前一个的状态（这是预期行为）

### 步骤 9：更新 chat_providers.dart 中的其他 Provider 依赖 ✅ 已完成

**文件**：`lib/features/im/chat/presentation/providers/chat_providers.dart`

需要更新以下 Provider 中对 `chatTimelineControllerProvider` 的依赖：

#### 9.1 chatMediaControllerProvider

**修改前**（L194-207）：
```dart
final chatMediaControllerProvider =
    StateNotifierProvider.autoDispose<ChatMediaController, ChatMediaState>((
      ref,
    ) {
      return ChatMediaController(
        ref.read(mediaPickerServiceProvider),
        ref.read(chatUploadCoordinatorProvider),
        ref.read(optimisticMessageFactoryProvider),
        createConversationPreviewFormatter(ref.read(appLocaleProvider)),
        ref.read(conversationListControllerProvider.notifier),
        ref.read(chatTimelineControllerProvider.notifier),  // ❌ 缺少 chatId
        ref.read(groupSettingsRepositoryProvider),
      );
    });
```

**修改后**：
```dart
final chatMediaControllerProvider =
    StateNotifierProvider.autoDispose.family<ChatMediaController, ChatMediaState, String>((
      ref,
      chatId,
    ) {
      return ChatMediaController(
        ref.read(mediaPickerServiceProvider),
        ref.read(chatUploadCoordinatorProvider),
        ref.read(optimisticMessageFactoryProvider),
        createConversationPreviewFormatter(ref.read(appLocaleProvider)),
        ref.read(conversationListControllerProvider.notifier),
        ref.read(chatTimelineControllerProvider(chatId).notifier),  // ✅ 传入 chatId
        ref.read(groupSettingsRepositoryProvider),
      );
    });
```

#### 9.2 chatMessageActionControllerProvider

**修改前**（L214-220）：
```dart
final chatMessageActionControllerProvider =
    Provider.autoDispose<ChatMessageActionController>((ref) {
      return ChatMessageActionController(
        ref.read(messageRepositoryProvider),
        ref.read(chatTimelineControllerProvider.notifier),  // ❌ 缺少 chatId
      );
    });
```

**修改后**：
```dart
final chatMessageActionControllerProvider =
    Provider.autoDispose.family<ChatMessageActionController, String>((ref, chatId) {
      return ChatMessageActionController(
        ref.read(messageRepositoryProvider),
        ref.read(chatTimelineControllerProvider(chatId).notifier),  // ✅ 传入 chatId
      );
    });
```

### 步骤 10：更新 chat_settings_page.dart ✅ 已完成

**文件**：`lib/features/im/conversation/presentation/pages/chat_settings_page.dart`

所有对 `chatControllerProvider` 和 `chatTimelineControllerProvider` 的调用都需要传入 `chatId`。

**关键修改点**：
```dart
// 在 build 方法中提取 chatId
final chatId = widget.args.chatId;

// 修改所有 provider 调用
final pageState = ref.watch(chatControllerProvider(chatId));
final timelineState = ref.watch(chatTimelineControllerProvider(chatId));
```

### 步骤 11：更新 group_settings_page.dart ✅ 已完成

**文件**：`lib/features/im/group_settings/presentation/pages/group_settings_page.dart`

所有对 `chatControllerProvider` 和 `chatTimelineControllerProvider` 的调用都需要传入 `chatId`。

**关键修改点**：
```dart
// 在 build 方法中提取 chatId
final chatId = widget.args.chatId;

// 修改所有 provider 调用
final pageState = ref.watch(chatControllerProvider(chatId));
final timelineState = ref.watch(chatTimelineControllerProvider(chatId));
```

### 步骤 12：更新 session_cleanup_service.dart ✅ 已完成

**文件**：`lib/core/auth/session_cleanup_service.dart`

由于 Provider 现在是 family-scoped，不能直接 invalidate 单个实例。需要 invalidate 整个 provider family。

**修改前**（L76-77）：
```dart
_ref.invalidate(chatControllerProvider);
_ref.invalidate(chatTimelineControllerProvider);
```

**修改后**：
```dart
// family-scoped provider 需要 invalidate 整个 family
// Riverpod 会自动清理所有该 family 的实例
_ref.invalidate(chatControllerProvider);
_ref.invalidate(chatTimelineControllerProvider);
_ref.invalidate(chatMediaControllerProvider);
_ref.invalidate(chatMessageActionControllerProvider);
_ref.invalidate(chatRuntimeNoticeProvider);
_ref.invalidate(chatRealtimeSignalProvider);
_ref.invalidate(chatReceiptLastVisibleChatIdProvider);
```

**说明**：对于 family-scoped provider，调用 `ref.invalidate(provider)` 会清理该 family 下的所有实例，这是 Riverpod 的标准行为。

### 步骤 13：更新 tenant_switch_service.dart ✅ 已完成

**文件**：`lib/features/profile/domain/services/tenant_switch_service.dart`

与 `session_cleanup_service.dart` 类似，需要 invalidate 整个 provider family。

**修改前**（L265-266）：
```dart
ref.invalidate(chatControllerProvider);
ref.invalidate(chatTimelineControllerProvider);
```

**修改后**：
```dart
// family-scoped provider 需要 invalidate 整个 family
ref.invalidate(chatControllerProvider);
ref.invalidate(chatTimelineControllerProvider);
ref.invalidate(chatMediaControllerProvider);
ref.invalidate(chatMessageActionControllerProvider);
ref.invalidate(chatRuntimeNoticeProvider);
ref.invalidate(chatRealtimeSignalProvider);
ref.invalidate(chatReceiptLastVisibleChatIdProvider);
```

### 步骤 14：更新 chat_page.dart 中的所有 Provider 调用（详细清单） ✅ 已完成

**文件**：`lib/features/im/chat/presentation/pages/chat_page.dart`

根据代码分析，共有 **70 处**需要修改。以下是完整的修改清单：

#### 14.1 initState 方法（L187-192）

**修改前**：
```dart
_timelineSubscription = ref.listenManual<ChatTimelineState>(
  chatTimelineControllerProvider,
  (previous, next) {
    _handleTimelineStateChanged(previous, next);
  },
);
```

**修改后**：
```dart
final chatId = widget.args.chatId;
_timelineSubscription = ref.listenManual<ChatTimelineState>(
  chatTimelineControllerProvider(chatId),
  (previous, next) {
    _handleTimelineStateChanged(previous, next);
  },
);
```

#### 14.2 _handleResumeFromBackground 方法（L261-263）

**修改前**：
```dart
await ref
    .read(chatTimelineControllerProvider.notifier)
    .pullMessagesAfterReconnect(command: command);
```

**修改后**：
```dart
final chatId = widget.args.chatId;
await ref
    .read(chatTimelineControllerProvider(chatId).notifier)
    .pullMessagesAfterReconnect(command: command);
```

#### 14.3 _initializeChatPage 方法（L299-302）

**修改前**：
```dart
Future<void> _initializeChatPage() async {
  await ref.read(chatControllerProvider.notifier).initialize(widget.args);
  ref.read(chatReceiptLastVisibleChatIdProvider.notifier).state = widget.args.chatId;
  // ...
}
```

**修改后**：
```dart
Future<void> _initializeChatPage() async {
  final chatId = widget.args.chatId;
  await ref.read(chatControllerProvider(chatId).notifier).initialize(widget.args);
  ref.read(chatReceiptLastVisibleChatIdProvider(chatId).notifier).state = chatId;
  // ...
}
```

#### 14.4 build 方法中的 Provider 监听（L380-426）

**修改前**：
```dart
ref.watch(chatRealtimeBindingProvider(widget.args.chatId));
ref.listen<ChatRuntimeNotice?>(chatRuntimeNoticeProvider, (prev, next) {
  if (next == null || next.chatId != widget.args.chatId || !mounted) {
    return;
  }
  ref.read(chatRuntimeNoticeProvider.notifier).state = null;
  // ...
});
ref.listen<ChatRealtimeSignal?>(chatRealtimeSignalProvider, (prev, next) {
  if (next == null || next.chatId != widget.args.chatId || !mounted) {
    return;
  }
  ref.read(chatRealtimeSignalProvider.notifier).state = null;
  // ...
});

final pageStatus = ref.watch(chatControllerProvider.select((state) => state.pageStatus));
final pendingAction = ref.watch(chatControllerProvider.select((state) => state.pendingAction));
// ... 其他 chatControllerProvider 调用
final timelineMessages = ref.watch(chatTimelineControllerProvider.select((state) => state.messages));
// ... 其他 chatTimelineControllerProvider 调用
```

**修改后**：
```dart
final chatId = widget.args.chatId;  // 提取 chatId 到局部变量

ref.watch(chatRealtimeBindingProvider(chatId));
ref.listen<ChatRuntimeNotice?>(chatRuntimeNoticeProvider(chatId), (prev, next) {
  if (next == null || next.chatId != chatId || !mounted) {
    return;
  }
  ref.read(chatRuntimeNoticeProvider(chatId).notifier).state = null;
  // ...
});
ref.listen<ChatRealtimeSignal?>(chatRealtimeSignalProvider(chatId), (prev, next) {
  if (next == null || next.chatId != chatId || !mounted) {
    return;
  }
  ref.read(chatRealtimeSignalProvider(chatId).notifier).state = null;
  // ...
});

final pageStatus = ref.watch(chatControllerProvider(chatId).select((state) => state.pageStatus));
final pendingAction = ref.watch(chatControllerProvider(chatId).select((state) => state.pendingAction));
// ... 其他 chatControllerProvider(chatId) 调用
final timelineMessages = ref.watch(chatTimelineControllerProvider(chatId).select((state) => state.messages));
// ... 其他 chatTimelineControllerProvider(chatId) 调用
```

#### 14.5 消息发送相关方法（L587-673）

**修改前**：
```dart
final sent = await ref
    .read(chatControllerProvider.notifier)
    .sendText(trimmedValue, ...);
// ...
final error = ref.read(chatControllerProvider).error;
```

**修改后**：
```dart
final chatId = widget.args.chatId;
final sent = await ref
    .read(chatControllerProvider(chatId).notifier)
    .sendText(trimmedValue, ...);
// ...
final error = ref.read(chatControllerProvider(chatId)).error;
```

#### 14.6 其他所有 ref.read/ref.watch 调用

根据 Grep 搜索结果，以下行号都需要修改（共 70 处）：
- L188, L262, L300, L302, L381, L385, L405, L409
- L415-426 (build 方法中的 select 调用)
- L588, L599, L670, L673
- L781, L787, L799
- L1026, L1150, L2163, L2579, L2721, L2738
- L4123, L4125, L4228, L4254, L4342, L4379
- L4495, L4544, L4547, L4549, L4563, L4568
- L4607, L4621, L4622, L4640, L4701, L4741
- L4766, L4777, L4782, L4796
- L5112, L5244, L5254, L5258, L5293, L5297
- L5602, L5606, L5613, L5686, L5695, L5737
- L5928, L5934, L5977, L5983

**修改原则**：所有 `chatControllerProvider`、`chatTimelineControllerProvider`、`chatRuntimeNoticeProvider`、`chatRealtimeSignalProvider`、`chatReceiptLastVisibleChatIdProvider`、`chatMediaControllerProvider`、`chatMessageActionControllerProvider` 的调用都需要传入 `chatId` 参数。

### 步骤 15：更新 chat_realtime_binding.dart 中的所有 Provider 调用 ✅ 已完成

**文件**：`lib/features/im/chat/presentation/providers/chat_realtime_binding.dart`

根据代码分析，需要修改以下位置：

#### 15.1 _handleChatSocketEvent 方法中的调用

**修改前**（多处）：
```dart
ref.read(chatTimelineControllerProvider.notifier).applyReadReceipt(...);
ref.read(chatControllerProvider).entryArgs;
ref.read(chatRealtimeSignalProvider.notifier).state = ...;
```

**修改后**：
```dart
ref.read(chatTimelineControllerProvider(chatId).notifier).applyReadReceipt(...);
ref.read(chatControllerProvider(chatId)).entryArgs;
ref.read(chatRealtimeSignalProvider(chatId).notifier).state = ...;
```

#### 15.2 _isGroupLeftStatus 方法（L309-313）

**修改前**：
```dart
bool _isGroupLeftStatus(Ref ref) {
  final pageState = ref.read(chatControllerProvider);
  // ...
}
```

**修改后**：
```dart
bool _isGroupLeftStatus(Ref ref, String chatId) {
  final pageState = ref.read(chatControllerProvider(chatId));
  // ...
}
```

**调用处修改**：
```dart
// 修改前
if (_isGroupLeftStatus(ref)) {

// 修改后
if (_isGroupLeftStatus(ref, chatId)) {
```

#### 15.3 _belongsToCurrentConversation 方法（L315-357）

**修改前**：
```dart
bool _belongsToCurrentConversation(
  Ref ref,
  String currentChatId,
  Map<String, dynamic> raw,
) {
  // ...
  final entryArgs = ref.read(chatControllerProvider).entryArgs;
  // ...
}
```

**修改后**：
```dart
bool _belongsToCurrentConversation(
  Ref ref,
  String currentChatId,
  Map<String, dynamic> raw,
) {
  // ...
  final entryArgs = ref.read(chatControllerProvider(currentChatId)).entryArgs;
  // ...
}
```

#### 15.4 其他所有调用点

根据代码分析，以下位置都需要修改：
- L92-93: `chatTimelineControllerProvider.notifier` → `chatTimelineControllerProvider(chatId).notifier`
- L121: `chatRealtimeSignalProvider.notifier` → `chatRealtimeSignalProvider(chatId).notifier`
- L141-142: `chatTimelineControllerProvider.notifier` → `chatTimelineControllerProvider(chatId).notifier`
- L166-168: `chatTimelineControllerProvider.notifier` → `chatTimelineControllerProvider(chatId).notifier`
- L172: `chatControllerProvider` → `chatControllerProvider(chatId)`
- L219: `chatControllerProvider` → `chatControllerProvider(chatId)`
- L243-244: `chatTimelineControllerProvider.notifier` → `chatTimelineControllerProvider(chatId).notifier`
- L310: `chatControllerProvider` → `chatControllerProvider(chatId)`
- L336: `chatControllerProvider` → `chatControllerProvider(chatId)`
- L380: `chatRealtimeSignalProvider.notifier` → `chatRealtimeSignalProvider(chatId).notifier`

### 步骤 16：更新 chat_controller.dart 中的依赖注入 ✅ 已完成

**文件**：`lib/features/im/chat/presentation/controllers/chat_controller.dart`

`ChatController` 的构造函数中接收 `chatTimelineControllerProvider` 作为依赖，需要确保在创建时传入正确的 family-scoped 实例。

**修改说明**：
由于 `ChatController` 是通过 `chatControllerProvider(chatId)` 创建的，而 `chatControllerProvider` 内部已经修改为使用 `chatTimelineControllerProvider(chatId).notifier`，因此 `ChatController` 本身的代码不需要修改，只需要确保 Provider 定义正确即可。

### 步骤 17：更新其他 Controller 文件 ✅ 已完成

以下文件如果引用了相关 Provider，需要传入 chatId：

1. **chat_composer_controller.dart**：
   - 检查是否有对 `chatControllerProvider` 或 `chatTimelineControllerProvider` 的引用
   - 如有，需要修改为接收 chatId 参数

2. **chat_media_controller.dart**：
   - 由于 `chatMediaControllerProvider` 已改为 family-scoped，确保所有调用处都传入 chatId

3. **chat_message_action_controller.dart**：
   - 由于 `chatMessageActionControllerProvider` 已改为 family-scoped，确保所有调用处都传入 chatId

## 修复验证清单

### 实施状态

**✅ 代码实施已完成** (2026-07-08)
- 所有 7 个 Provider 已改为 family-scoped by chatId
- 所有 7 个文件的代码修改已完成
- 编译验证通过（flutter analyze 无错误）
- 共修改 70+ 处代码调用

### 功能验证（待手动测试）

- [ ] 从用户1聊天页 → 用户2名片 → 用户2详情页 → 点击"发消息" → 正确显示用户2聊天页
- [ ] 返回用户1聊天页时，用户1的消息数据完整无损
- [ ] 在用户2聊天页发送消息，正确显示在用户2的对话中
- [ ] 多次重复上述流程，每次都能正确切换
- [ ] WebSocket 消息正确路由到对应的聊天页面
- [ ] 已读回执正确更新到对应的对话
- [ ] 角标计数正确（进入聊天页时清除对应角标）

### 边界场景验证（待手动测试）

- [ ] 快速连续点击多个用户名片，每个聊天页都能正确显示
- [ ] 在聊天页 A 发送消息后，立即切换到聊天页 B，消息状态正确
- [ ] 后台收到用户2的新消息，用户2聊天页正确显示
- [ ] 网络断开重连后，各聊天页正确恢复消息

### 性能验证（待手动测试）

- [ ] 多个 ChatPage 实例不会导致内存泄漏
- [ ] Provider 正确销毁（通过 debugPrint 验证 onDispose 调用）
- [ ] 不会出现重复的 WebSocket 监听器

## 技术要点总结

### 核心原则

1. **Provider 作用域必须与 UI 实例一一对应**
   - 每个 ChatPage 实例需要独立的状态空间
   - 使用 `family` 参数确保不同 chatId 有独立的 Provider 实例

2. **autoDispose 不等于实例隔离**
   - `autoDispose` 只控制生命周期，不控制实例数量
   - 多个监听器同时存在时，共享同一个 Provider 实例

3. **路由栈中的多个页面会同时持有 Provider 引用**
   - push 新页面时，旧页面仍在栈中，不会 dispose
   - 必须使用 family-scoped 确保状态隔离

### 参考实现

项目中已有的正确实现：
```dart
// ✅ chatRealtimeBindingProvider 使用 family 参数
final chatRealtimeBindingProvider = Provider.autoDispose.family<void, String>((ref, chatId) {
  // 每个 chatId 独立的 WebSocket 监听
});
```

## 影响范围评估

### 修改文件清单（完整）

根据代码分析，共有 **7 个文件**需要修改，涉及 **70+ 处代码变更**：

| 序号 | 文件路径 | 修改类型 | 修改点数 | 优先级 |
|------|----------|----------|----------|--------|
| 1 | `lib/features/im/chat/presentation/providers/chat_providers.dart` | Provider 定义 | 7 处 | P0 |
| 2 | `lib/features/im/chat/presentation/pages/chat_page.dart` | Provider 调用 | 70 处 | P0 |
| 3 | `lib/features/im/chat/presentation/providers/chat_realtime_binding.dart` | Provider 调用 | 15 处 | P0 |
| 4 | `lib/features/im/conversation/presentation/pages/chat_settings_page.dart` | Provider 调用 | 待统计 | P1 |
| 5 | `lib/features/im/group_settings/presentation/pages/group_settings_page.dart` | Provider 调用 | 待统计 | P1 |
| 6 | `lib/core/auth/session_cleanup_service.dart` | Provider invalidate | 7 处 | P1 |
| 7 | `lib/features/profile/domain/services/tenant_switch_service.dart` | Provider invalidate | 7 处 | P1 |

### 需要修改的 Provider 清单

| Provider 名称 | 修改前 | 修改后 | 影响范围 |
|--------------|--------|--------|----------|
| `chatControllerProvider` | `autoDispose` | `autoDispose.family<String>` | chat_page, chat_realtime_binding, chat_settings_page, group_settings_page |
| `chatTimelineControllerProvider` | `autoDispose` | `autoDispose.family<String>` | chat_page, chat_realtime_binding, chat_providers, chat_settings_page, group_settings_page |
| `chatMediaControllerProvider` | `autoDispose` | `autoDispose.family<String>` | chat_page, chat_providers |
| `chatMessageActionControllerProvider` | `autoDispose` | `autoDispose.family<String>` | chat_page |
| `chatRuntimeNoticeProvider` | `autoDispose` | `autoDispose.family<String>` | chat_page, chat_realtime_binding |
| `chatRealtimeSignalProvider` | `autoDispose` | `autoDispose.family<String>` | chat_page, chat_realtime_binding |
| `chatReceiptLastVisibleChatIdProvider` | `StateProvider` | `StateProvider.family<String>` | chat_page |

### 风险评估

#### 高风险点

1. **核心聊天功能**：修改涉及消息发送、接收、显示等核心流程
2. **多实例并发**：需要确保多个 ChatPage 实例同时存在时状态隔离
3. **WebSocket 消息路由**：需要确保消息正确路由到对应的聊天页面
4. **Provider 依赖链**：多个 Provider 之间存在依赖关系，需要确保 family 参数正确传递

#### 中风险点

1. **会话列表页**：`chat_settings_page.dart` 和 `group_settings_page.dart` 中的 Provider 调用
2. **服务层 invalidate**：`session_cleanup_service.dart` 和 `tenant_switch_service.dart` 中的 Provider 清理逻辑
3. **内存管理**：family-scoped Provider 可能导致内存占用增加（每个 chatId 一个实例）

#### 缓解措施

1. **分步骤修改**：
   - 第一步：修改 Provider 定义（chat_providers.dart）
   - 第二步：修改核心页面（chat_page.dart, chat_realtime_binding.dart）
   - 第三步：修改辅助页面（chat_settings_page.dart, group_settings_page.dart）
   - 第四步：修改服务层（session_cleanup_service.dart, tenant_switch_service.dart）

2. **保留回滚能力**：
   - 使用 Git 分支管理，每个步骤单独提交
   - 保留原始代码注释，便于对比

3. **完整的回归测试**：
   - 单聊消息发送/接收
   - 群聊消息发送/接收
   - 多实例切换（用户名片跳转）
   - 后台重连消息恢复
   - 已读回执更新
   - 角标计数正确性

4. **性能监控**：
   - 监控内存使用情况
   - 验证 Provider 实例是否正确销毁
   - 检查 WebSocket 监听器是否重复注册

### 技术要点总结

#### 核心原则

1. **Provider 作用域必须与 UI 实例一一对应**
   - 每个 ChatPage 实例需要独立的状态空间
   - 使用 `family` 参数确保不同 chatId 有独立的 Provider 实例

2. **autoDispose 不等于实例隔离**
   - `autoDispose` 只控制生命周期，不控制实例数量
   - 多个监听器同时存在时，共享同一个 Provider 实例

3. **路由栈中的多个页面会同时持有 Provider 引用**
   - push 新页面时，旧页面仍在栈中，不会 dispose
   - 必须使用 family-scoped 确保状态隔离

#### 参考实现

项目中已有的正确实现：
```dart
// ✅ chatRealtimeBindingProvider 使用 family 参数
final chatRealtimeBindingProvider = Provider.autoDispose.family<void, String>((ref, chatId) {
  // 每个 chatId 独立的 WebSocket 监听
});
```

### 后续优化建议

1. **添加 Provider 作用域检查工具** ✅ 已完成
   - ✅ 已创建 `lib/core/debug/provider_scope_checker.dart`
   - ✅ 已在 `main.dart` 中集成 `ProviderScopeChecker`（仅 debug 模式）
   - ✅ 可监控 7 个关键 Provider 的创建、更新和销毁
   - 参考文档：`docs/provider-design-guidelines.md`

2. **建立 Provider 设计规范** ✅ 已完成
   - ✅ 已创建 `docs/provider-design-guidelines.md`
   - ✅ 文档化了 family-scoped 的使用场景和核心原则
   - ✅ 包含代码审查检查点和常见问题解答
   - ✅ 列出了需要 family-scoped 的 Provider 清单

3. **考虑路由级别的 Provider 注入** ✅ 已完成
   - ✅ 已在 `app_router.dart` 的 chat 路由中添加 `onExit` 钩子
   - ✅ 路由退出时主动清理 chatId 对应的 Provider 实例
   - ✅ 使用 `Future.microtask` 延迟清理，避免路由切换冲突
   - ✅ 包含错误处理，防止 container 已销毁时抛出异常

4. **内存优化** ✅ 已完成
   - ✅ 已在 `chat_page.dart` 的 `dispose` 方法中主动 invalidate Provider
   - ✅ 清理 7 个 family-scoped Provider 实例
   - ✅ 使用 `Future.microtask` 延迟执行，避免 widget 树构建冲突
   - ✅ 与路由级别的 onExit 清理形成双重保障

### 附录：相关代码位置

- ChatPage: `lib/features/im/chat/presentation/pages/chat_page.dart`
- ChatController: `lib/features/im/chat/presentation/controllers/chat_controller.dart`
- ChatProviders: `lib/features/im/chat/presentation/providers/chat_providers.dart`
- ChatRealtimeBinding: `lib/features/im/chat/presentation/providers/chat_realtime_binding.dart`
- ContactProfilePage: `lib/features/contacts/presentation/pages/contact_profile_page.dart`
- RouteConfig: `lib/app/router/app_router.dart` (L397-404)
- SessionCleanupService: `lib/core/auth/session_cleanup_service.dart`
- TenantSwitchService: `lib/features/profile/domain/services/tenant_switch_service.dart`

## 后续优化建议（全部已完成）

### 1. Provider 作用域检查工具 ✅ 已完成
- **实现文件**：`lib/core/debug/provider_scope_checker.dart`
- **集成位置**：`lib/main.dart`（仅 debug 模式启用）
- **功能**：
  - 监控 7 个关键 Provider 的创建、更新和销毁
  - 记录 Provider 生命周期和访问次数
  - 输出调试日志帮助排查共享问题
- **使用方式**：
  ```dart
  runApp(ProviderScope(
    observers: [
      if (kDebugMode) ProviderScopeChecker(),
    ],
    child: const MyApp(),
  ));
  ```

### 2. Provider 设计规范 ✅ 已完成
- **文档位置**：`docs/provider-design-guidelines.md`
- **核心内容**：
  - 4 条核心原则（作用域对应、autoDispose 不等于隔离、路由级清理、dispose 清理）
  - 需要 family-scoped 的 Provider 清单（7 个）
  - 代码审查检查点
  - 常见问题解答
  - 参考实现链接

### 3. 路由级别的 Provider 注入 ✅ 已完成
- **实现位置**：`lib/app/router/app_router.dart`（chat 路由的 `onExit` 钩子）
- **清理时机**：路由退出时
- **清理方式**：使用 `ProviderScope.containerOf(context).invalidate()` 清理 7 个 Provider
- **错误处理**：使用 `Future.microtask` 延迟执行，包含 try-catch 防止 container 已销毁异常

### 4. 内存优化 ✅ 已完成
- **实现位置**：`lib/features/im/chat/presentation/pages/chat_page.dart`（dispose 方法）
- **清理时机**：页面 dispose 时
- **清理方式**：使用 `ref.invalidate()` 清理 7 个 family-scoped Provider
- **双重保障**：与路由级别的 onExit 清理形成互补，确保内存及时释放

## 附录：相关代码位置

- ChatPage: `lib/features/im/chat/presentation/pages/chat_page.dart`
- ChatController: `lib/features/im/chat/presentation/controllers/chat_controller.dart`
- ChatProviders: `lib/features/im/chat/presentation/providers/chat_providers.dart`
- ChatRealtimeBinding: `lib/features/im/chat/presentation/providers/chat_realtime_binding.dart`
- ContactProfilePage: `lib/features/contacts/presentation/pages/contact_profile_page.dart`
- RouteConfig: `lib/app/router/app_router.dart` (L397-404)
