import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class OpenChatCommand {
  const OpenChatCommand({
    required this.chatId,
    required this.conversationType,
    required this.entryMode,
    this.title,
    this.anchorSequence,
    this.anchorMessageId,
  });

  final String chatId;
  final ConversationType conversationType;
  final ChatEntryMode entryMode;
  final String? title;
  final String? anchorSequence;
  final String? anchorMessageId;

  String? get windowMode {
    return switch (entryMode) {
      ChatEntryMode.latest => 'latest',
      ChatEntryMode.anchor || ChatEntryMode.restore => null,
    };
  }

  int? get windowLimit {
    return switch (entryMode) {
      ChatEntryMode.latest => 30,
      ChatEntryMode.anchor || ChatEntryMode.restore => null,
    };
  }

  int? get beforeLimit {
    return switch (entryMode) {
      ChatEntryMode.latest => null,
      ChatEntryMode.anchor || ChatEntryMode.restore => 15,
    };
  }

  int? get afterLimit {
    return switch (entryMode) {
      ChatEntryMode.latest => null,
      ChatEntryMode.anchor || ChatEntryMode.restore => 10,
    };
  }

  factory OpenChatCommand.fromArgs(ChatEntryArgs args) {
    return OpenChatCommand(
      chatId: args.chatId,
      conversationType: args.conversationType,
      entryMode: args.entryMode,
      title: args.title,
      anchorSequence: args.anchorSequence,
      anchorMessageId: args.anchorMessageId,
    );
  }
}
