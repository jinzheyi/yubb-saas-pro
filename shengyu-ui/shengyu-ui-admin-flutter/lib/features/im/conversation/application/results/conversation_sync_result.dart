import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';

class ConversationSyncResult {
  const ConversationSyncResult({
    required this.cursorVersion,
    required this.items,
    required this.hasMore,
  });

  final String cursorVersion;
  final List<Conversation> items;
  final bool hasMore;
}
