import 'package:shengyu_ui_admin_im/features/im/conversation/application/results/conversation_sync_result.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';

abstract class ConversationRepository {
  Future<List<Conversation>> getConversationList();

  Future<ConversationSyncResult> syncConversationsIncrementally({
    required String cursorVersion,
  });

  Future<void> pinConversation({required String chatId, required bool pinned});

  Future<void> deleteConversation({required String chatId});

  Future<void> markConversationRead({
    required String chatId,
    required String readSequence,
  });

  Future<void> toggleNoDisturb({
    required String chatId,
    required bool noDisturb,
  });
}
