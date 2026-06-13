import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_preview_entry.dart';

enum ChatTimelineStatus { initial, loading, ready, failed }

class ChatTimelineState {
  const ChatTimelineState({
    this.status = ChatTimelineStatus.initial,
    this.messages = const <Message>[],
    this.viewportState,
    this.error,
    this.quotePreviewCache = const <String, List<QuotePreviewEntry>>{},
  });

  final ChatTimelineStatus status;
  final List<Message> messages;
  final ChatViewportState? viewportState;
  final AppError? error;
  /// 引用链预计算缓存，key 为 messageId，value 为预计算的引用链列表
  /// 消息合并时自动触发预计算，渲染时直接读取缓存，无需在 build 中遍历引用链
  final Map<String, List<QuotePreviewEntry>> quotePreviewCache;

  ChatTimelineState copyWith({
    ChatTimelineStatus? status,
    List<Message>? messages,
    ChatViewportState? viewportState,
    AppError? error,
    Map<String, List<QuotePreviewEntry>>? quotePreviewCache,
  }) {
    return ChatTimelineState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      viewportState: viewportState ?? this.viewportState,
      error: error,
      quotePreviewCache: quotePreviewCache ?? this.quotePreviewCache,
    );
  }
}
