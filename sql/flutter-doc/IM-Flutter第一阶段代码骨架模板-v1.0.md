# IM Flutter 第一阶段代码骨架模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：第一阶段关键 Dart 文件的建议代码骨架模板  

---

## 1. 目标

本文件不是最终代码，而是第一阶段建议的最小代码骨架形状，便于后续快速落工程。

---

## 2. `main.dart` 模板

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/app_bootstrap.dart';

void main() {
  runApp(const ProviderScope(child: ShengyuImApp()));
}

class ShengyuImApp extends ConsumerWidget {
  const ShengyuImApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppBootstrap();
  }
}
```

---

## 3. `app_bootstrap.dart` 模板

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../theme/app_theme.dart';

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
```

---

## 4. `app_router.dart` 模板

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // TODO: register routes
    ],
  );
});
```

---

## 5. `conversation_repository.dart` 模板

```dart
import '../entities/conversation.dart';

abstract class ConversationRepository {
  Future<List<Conversation>> getConversationList();

  Future<ConversationSyncResult> syncConversationsIncrementally({
    required String cursorVersion,
  });

  Future<void> pinConversation({
    required String chatId,
    required bool pinned,
  });

  Future<void> toggleNoDisturb({
    required String chatId,
    required bool noDisturb,
  });
}
```

---

## 6. `load_conversation_list_use_case.dart` 模板

```dart
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';

class LoadConversationListUseCase {
  const LoadConversationListUseCase(this._repository);

  final ConversationRepository _repository;

  Future<List<Conversation>> call() {
    return _repository.getConversationList();
  }
}
```

---

## 7. `conversation_list_state.dart` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_list_state.freezed.dart';

@freezed
class ConversationListState with _$ConversationListState {
  const factory ConversationListState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default([]) List<ConversationUiModel> conversations,
    @Default('0') String cursorVersion,
    AppError? error,
  }) = _ConversationListState;
}
```

---

## 8. `conversation_list_controller.dart` 模板

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationListController extends StateNotifier<ConversationListState> {
  ConversationListController(
    this._loadConversationListUseCase,
  ) : super(const ConversationListState());

  final LoadConversationListUseCase _loadConversationListUseCase;

  Future<void> load() async {
    state = state.copyWith(status: LoadStatus.loading, error: null);
    try {
      final conversations = await _loadConversationListUseCase();
      state = state.copyWith(
        status: LoadStatus.ready,
        conversations: conversations.map(ConversationUiModel.fromEntity).toList(),
      );
    } catch (e, st) {
      state = state.copyWith(
        status: LoadStatus.failed,
        error: AppErrorMapper.map(e, st),
      );
    }
  }
}
```

---

## 9. `message_repository.dart` 模板

```dart
import '../entities/message.dart';

abstract class MessageRepository {
  Future<ChatWindowResult> getMessageWindow(LoadChatWindowCommand command);

  Future<ChatWindowResult> getOlderMessages({
    required String chatId,
    required String beforeSequence,
  });

  Future<SendMessageResult> sendMessage(SendMessageCommand command);
}
```

---

## 10. `open_chat_use_case.dart` 模板

```dart
class OpenChatUseCase {
  const OpenChatUseCase(
    this._messageRepository,
    this._conversationRepository,
  );

  final MessageRepository _messageRepository;
  final ConversationRepository _conversationRepository;

  Future<OpenChatResult> call(OpenChatCommand command) async {
    // TODO: orchestrate latest / anchor / restore
    throw UnimplementedError();
  }
}
```

---

## 11. `chat_page_state.dart` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_page_state.freezed.dart';

@freezed
class ChatPageState with _$ChatPageState {
  const factory ChatPageState({
    required ChatEntryArgs entryArgs,
    @Default(ChatPageStatus.initial) ChatPageStatus pageStatus,
    ChatHeaderUiModel? chatHeader,
    @Default(false) bool isReadOnly,
    @Default(false) bool isMultiSelectMode,
    String? highlightedMessageId,
    @Default(ChatPendingAction.none) ChatPendingAction pendingAction,
    AppError? error,
  }) = _ChatPageState;
}
```

---

## 12. `chat_controller.dart` 模板

```dart
class ChatController extends StateNotifier<ChatPageState> {
  ChatController(
    this._openChatUseCase,
    this._timelineController,
    this._receiptController,
  ) : super(ChatPageState(entryArgs: ChatEntryArgs.empty()));

  final OpenChatUseCase _openChatUseCase;
  final ChatTimelineController _timelineController;
  final ChatReceiptController _receiptController;

  Future<void> initialize(ChatEntryArgs args) async {
    state = state.copyWith(
      entryArgs: args,
      pageStatus: ChatPageStatus.initializing,
      error: null,
    );

    try {
      final result = await _openChatUseCase(OpenChatCommand.fromArgs(args));
      state = state.copyWith(
        pageStatus: ChatPageStatus.ready,
        chatHeader: result.chatHeader,
      );
    } catch (e, st) {
      state = state.copyWith(
        pageStatus: ChatPageStatus.failed,
        error: AppErrorMapper.map(e, st),
      );
    }
  }
}
```

---

## 13. `chat_page.dart` 模板

```dart
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key,
    required this.args,
  });

  final ChatEntryArgs args;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatControllerProvider.notifier).initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);

    return Scaffold(
      body: switch (state.pageStatus) {
        ChatPageStatus.initial || ChatPageStatus.initializing => const AppLoadingView(),
        ChatPageStatus.failed => AppErrorView(error: state.error),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
```

---

## 14. `message_bubble_factory.dart` 模板

```dart
class MessageBubbleFactory {
  const MessageBubbleFactory._();

  static Widget build(MessageUiModel message) {
    switch (message.renderType) {
      case MessageRenderType.text:
        return TextMessageBubble(message: message);
      case MessageRenderType.image:
        return ImageMessageBubble(message: message);
      default:
        return const SizedBox.shrink();
    }
  }
}
```

---

## 15. 使用原则

1. 先跑通骨架，再填业务实现。
2. 不要一开始就把最终复杂逻辑全部塞进模板文件。
3. 所有模板都要遵守前面文档里的命名、分层和状态机约束。

