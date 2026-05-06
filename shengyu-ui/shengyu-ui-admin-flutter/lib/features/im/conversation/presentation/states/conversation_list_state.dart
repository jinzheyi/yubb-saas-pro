import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';

enum ConversationListStatus { initial, loading, ready, failed }

class ConversationListState {
  const ConversationListState({
    this.status = ConversationListStatus.initial,
    this.conversations = const <Conversation>[],
    this.cursorVersion = '0',
    this.error,
  });

  final ConversationListStatus status;
  final List<Conversation> conversations;
  final String cursorVersion;
  final AppError? error;

  ConversationListState copyWith({
    ConversationListStatus? status,
    List<Conversation>? conversations,
    String? cursorVersion,
    AppError? error,
  }) {
    return ConversationListState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      cursorVersion: cursorVersion ?? this.cursorVersion,
      error: error,
    );
  }
}
