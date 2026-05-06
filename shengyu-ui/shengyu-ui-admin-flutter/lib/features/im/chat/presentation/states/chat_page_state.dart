import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';

enum ChatPageStatus { initial, initializing, ready, failed }

enum ChatPendingAction { none, sendingMessage }

class ChatPageState {
  const ChatPageState({
    required this.entryArgs,
    this.pageStatus = ChatPageStatus.initial,
    this.chatTitle,
    this.isReadOnly = false,
    this.isMultiSelectMode = false,
    this.highlightedMessageId,
    this.pendingAction = ChatPendingAction.none,
    this.error,
  });

  final ChatEntryArgs entryArgs;
  final ChatPageStatus pageStatus;
  final String? chatTitle;
  final bool isReadOnly;
  final bool isMultiSelectMode;
  final String? highlightedMessageId;
  final ChatPendingAction pendingAction;
  final AppError? error;

  ChatPageState copyWith({
    ChatEntryArgs? entryArgs,
    ChatPageStatus? pageStatus,
    String? chatTitle,
    bool? isReadOnly,
    bool? isMultiSelectMode,
    String? highlightedMessageId,
    ChatPendingAction? pendingAction,
    AppError? error,
  }) {
    return ChatPageState(
      entryArgs: entryArgs ?? this.entryArgs,
      pageStatus: pageStatus ?? this.pageStatus,
      chatTitle: chatTitle ?? this.chatTitle,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
      highlightedMessageId: highlightedMessageId ?? this.highlightedMessageId,
      pendingAction: pendingAction ?? this.pendingAction,
      error: error,
    );
  }
}
