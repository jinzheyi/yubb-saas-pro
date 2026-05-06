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
