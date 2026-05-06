import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

enum ChatEntryMode { latest, anchor, restore }

class ChatEntryArgs {
  const ChatEntryArgs({
    required this.chatId,
    required this.conversationType,
    this.targetId,
    this.title,
    this.isReadOnly = false,
    this.serviceState,
    this.entryMode = ChatEntryMode.latest,
    this.anchorSequence,
    this.anchorMessageId,
    this.highlightedMessageId,
    this.restoreKey,
  });

  const ChatEntryArgs.empty()
    : chatId = '',
      conversationType = ConversationType.direct,
      targetId = null,
      title = null,
      isReadOnly = false,
      serviceState = null,
      entryMode = ChatEntryMode.latest,
      anchorSequence = null,
      anchorMessageId = null,
      highlightedMessageId = null,
      restoreKey = null;

  final String chatId;
  final ConversationType conversationType;
  final String? targetId;
  final String? title;
  final bool isReadOnly;
  final String? serviceState;
  final ChatEntryMode entryMode;
  final String? anchorSequence;
  final String? anchorMessageId;
  final String? highlightedMessageId;
  final String? restoreKey;

  bool get isAnchorOpen =>
      (anchorMessageId != null && anchorMessageId!.isNotEmpty) ||
      (anchorSequence != null && anchorSequence!.isNotEmpty);

  factory ChatEntryArgs.latest({
    required String chatId,
    required ConversationType conversationType,
    String? targetId,
    String? title,
    bool isReadOnly = false,
    String? serviceState,
  }) {
    return ChatEntryArgs(
      chatId: chatId,
      conversationType: conversationType,
      targetId: targetId,
      title: title,
      isReadOnly: isReadOnly,
      serviceState: serviceState,
    );
  }
}
