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
    this.groupMemberStatus,
    this.leftAt,
    this.error,
  });

  final ChatEntryArgs entryArgs;
  final ChatPageStatus pageStatus;
  final String? chatTitle;
  final bool isReadOnly;
  final bool isMultiSelectMode;
  final String? highlightedMessageId;
  final ChatPendingAction pendingAction;
  final int? groupMemberStatus;
  final DateTime? leftAt;
  final AppError? error;

  bool get isGroupKicked => groupMemberStatus == 2;
  bool get isGroupLeft => groupMemberStatus == 1;
  bool get isGroupDisbanded => groupMemberStatus == 3;
  bool get hasLeftGroup => isGroupKicked || isGroupLeft || isGroupDisbanded;

  ChatPageState copyWith({
    ChatEntryArgs? entryArgs,
    ChatPageStatus? pageStatus,
    String? chatTitle,
    bool? isReadOnly,
    bool? isMultiSelectMode,
    String? highlightedMessageId,
    ChatPendingAction? pendingAction,
    int? groupMemberStatus,
    DateTime? leftAt,
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
      groupMemberStatus: groupMemberStatus ?? this.groupMemberStatus,
      leftAt: leftAt ?? this.leftAt,
      error: error,
    );
  }
}
