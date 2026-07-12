# Provider 设计规范

## 概述

本规范旨在确保 Riverpod Provider 的正确使用，避免多实例共享导致的状态错乱问题。

## 核心原则

### 1. Provider 作用域必须与 UI 实例一一对应

**规则**：每个页面实例需要独立的状态空间时，必须使用 `family` 参数。

**示例**：
```dart
// ✅ 正确：使用 family-scoped
final chatControllerProvider = StateNotifierProvider.autoDispose.family<
    ChatController, ChatPageState, String>((ref, chatId) {
  return ChatController(chatId: chatId);
});

// ❌ 错误：多实例共享
final chatControllerProvider = StateNotifierProvider.autoDispose<
    ChatController, ChatPageState>((ref) {
  return ChatController();
});
```

### 2. autoDispose 不等于实例隔离

**规则**：`autoDispose` 只控制生命周期，不控制实例数量。多个监听器同时存在时，共享同一个 Provider 实例。

**说明**：
- 路由栈中的多个页面会同时持有 Provider 引用
- push 新页面时，旧页面仍在栈中，不会 dispose
- 必须使用 family-scoped 确保状态隔离

### 3. 路由级别的 Provider 清理

**规则**：使用 GoRouter 的 `onExit` 钩子在路由退出时主动清理 Provider。

**示例**：
```dart
GoRoute(
  path: '/chat/:chatId',
  pageBuilder: (context, state) => ChatPage(chatId: state.pathParameters['chatId']!),
  onExit: (context, state) {
    final chatId = state.pathParameters['chatId']!;
    // 延迟清理，避免路由切换过程中的问题
    Future.microtask(() {
      final container = ProviderScope.containerOf(context);
      container.invalidate(chatControllerProvider(chatId));
    });
    return true;
  },
),
```

### 4. 页面 dispose 时主动清理

**规则**：在页面 `dispose` 方法中主动 invalidate 对应的 Provider 实例。

**示例**：
```dart
@override
void dispose() {
  final chatId = widget.args.chatId;
  
  // 延迟清理，避免 widget 树构建过程中的问题
  Future.microtask(() {
    ref.invalidate(chatControllerProvider(chatId));
    ref.invalidate(chatTimelineControllerProvider(chatId));
    // ... 其他相关 Provider
  });
  
  super.dispose();
}
```

## 需要 family-scoped 的 Provider 清单

以下 Provider 必须使用 `family` 参数进行作用域隔离：

| Provider 名称 | family 参数 | 说明 |
|--------------|------------|------|
| `chatControllerProvider` | `chatId` | 聊天页面主控制器 |
| `chatTimelineControllerProvider` | `chatId` | 消息时间线控制器 |
| `chatMediaControllerProvider` | `chatId` | 媒体控制器 |
| `chatMessageActionControllerProvider` | `chatId` | 消息操作控制器 |
| `chatRuntimeNoticeProvider` | `chatId` | 运行时通知 |
| `chatRealtimeSignalProvider` | `chatId` | 实时信号 |
| `chatReceiptLastVisibleChatIdProvider` | `chatId` | 已读回执可见聊天 ID |

## 调试工具

### ProviderScopeChecker

在 debug 模式下，`ProviderScopeChecker` 会监控上述 Provider 的创建和销毁，输出日志帮助排查问题。

**启用方式**：
```dart
runApp(ProviderScope(
  observers: [
    if (kDebugMode) ProviderScopeChecker(),
  ],
  child: const MyApp(),
));
```

**日志示例**：
```
[ProviderScopeChecker] ✅ Provider 创建: chatControllerProvider
[ProviderScopeChecker] 🗑️ Provider 销毁: chatControllerProvider (生命周期: 45s, 访问次数: 128)
```

## 代码审查检查点

在代码审查时，重点关注以下场景：

1. **新增 Provider**：检查是否需要 family-scoped
2. **多实例页面**：确保每个页面实例有独立的 Provider
3. **路由跳转**：检查是否有 Provider 清理逻辑
4. **dispose 方法**：检查是否主动 invalidate Provider

## 常见问题

### Q: 什么时候不需要 family-scoped？

A: 当 Provider 是全局单例，或者状态不需要按实例隔离时，不需要 family-scoped。例如：
- `authSessionProvider`：全局认证状态
- `conversationListControllerProvider`：会话列表（全局唯一）

### Q: family-scoped 会导致内存泄漏吗？

A: 不会，前提是正确清理。使用 `autoDispose.family` 配合 `onExit` 和 `dispose` 清理，可以确保内存及时释放。

### Q: 如何调试 Provider 共享问题？

A: 使用 `ProviderScopeChecker` 监控 Provider 的创建和销毁，检查日志中是否有异常。

## 参考实现

- [chat_providers.dart](../shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/providers/chat_providers.dart)
- [app_router.dart](../shengyu-ui/shengyu-ui-admin-flutter/lib/app/router/app_router.dart)
- [chat_page.dart](../shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/pages/chat_page.dart)
