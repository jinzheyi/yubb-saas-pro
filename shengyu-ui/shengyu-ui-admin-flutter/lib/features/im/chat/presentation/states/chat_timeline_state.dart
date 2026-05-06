import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';

enum ChatTimelineStatus { initial, loading, ready, failed }

class ChatTimelineState {
  const ChatTimelineState({
    this.status = ChatTimelineStatus.initial,
    this.messages = const <Message>[],
    this.viewportState,
    this.error,
  });

  final ChatTimelineStatus status;
  final List<Message> messages;
  final ChatViewportState? viewportState;
  final AppError? error;

  ChatTimelineState copyWith({
    ChatTimelineStatus? status,
    List<Message>? messages,
    ChatViewportState? viewportState,
    AppError? error,
  }) {
    return ChatTimelineState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      viewportState: viewportState ?? this.viewportState,
      error: error,
    );
  }
}
