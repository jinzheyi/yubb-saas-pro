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

  /// 序列化为 JSON（用于 Isolate 跨线程通信）
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      'type': type.name,
      'status': status.name,
      'content': content,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'isOutgoing': isOutgoing,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
      if (sequence != null) 'sequence': sequence,
      if (quoteInfo != null) 'quoteInfo': quoteInfo!.toJson(),
      'extra': extra.toJson(),
    };
  }

  /// 从 JSON 反序列化（用于 Isolate 返回结果解析）
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderAvatar: json['senderAvatar']?.toString(),
      type: _parseMessageType(json['type']?.toString() ?? 'text'),
      status: _parseMessageStatus(json['status']?.toString() ?? 'sent'),
      content: json['content']?.toString() ?? '',
      sentAt: _parseSentAt(json['sentAt']),
      isOutgoing: json['isOutgoing'] == true,
      clientMessageId: json['clientMessageId']?.toString(),
      sequence: json['sequence']?.toString(),
      quoteInfo: json['quoteInfo'] != null
          ? QuoteInfo.fromJson(json['quoteInfo'] as Map<String, dynamic>)
          : null,
      extra: json['extra'] != null
          ? MessageExtra.fromJson(json['extra'] as Map<String, dynamic>)
          : const MessageExtra(),
    );
  }

  static MessageType _parseMessageType(String? raw) {
    return MessageType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MessageType.text,
    );
  }

  static MessageStatus _parseMessageStatus(String? raw) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MessageStatus.sent,
    );
  }

  static DateTime _parseSentAt(dynamic raw) {
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    if (raw is String) {
      final ms = int.tryParse(raw);
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    return DateTime.now();
  }
}
