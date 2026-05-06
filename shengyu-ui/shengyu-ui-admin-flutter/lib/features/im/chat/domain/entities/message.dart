import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class Message {
  const Message({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.status,
    required this.content,
    required this.sentAt,
    required this.isOutgoing,
    this.clientMessageId,
    this.sequence,
    this.quoteInfo,
    this.extra = const MessageExtra(),
  });

  final String messageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final MessageStatus status;
  final String content;
  final DateTime sentAt;
  final bool isOutgoing;
  final String? clientMessageId;
  final String? sequence;
  final QuoteInfo? quoteInfo;
  final MessageExtra extra;

  Message copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    MessageStatus? status,
    String? content,
    DateTime? sentAt,
    bool? isOutgoing,
    String? clientMessageId,
    String? sequence,
    QuoteInfo? quoteInfo,
    MessageExtra? extra,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      status: status ?? this.status,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      sequence: sequence ?? this.sequence,
      quoteInfo: quoteInfo ?? this.quoteInfo,
      extra: extra ?? this.extra,
    );
  }
}
