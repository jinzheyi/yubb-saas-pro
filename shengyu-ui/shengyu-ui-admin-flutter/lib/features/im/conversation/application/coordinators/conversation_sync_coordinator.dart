import 'package:shengyu_ui_admin_im/features/im/conversation/application/results/conversation_sync_result.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/load_conversation_list_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/sync_conversations_incrementally_use_case.dart';

class ConversationSyncCoordinator {
  const ConversationSyncCoordinator(
    this._loadConversationListUseCase,
    this._syncConversationsIncrementallyUseCase,
  );

  final LoadConversationListUseCase _loadConversationListUseCase;
  final SyncConversationsIncrementallyUseCase
  _syncConversationsIncrementallyUseCase;

  Future<ConversationSyncResult> bootstrap({
    required String cursorVersion,
  }) async {
    final items = await _loadConversationListUseCase();
    if (items.isNotEmpty) {
      return ConversationSyncResult(
        cursorVersion: cursorVersion,
        items: items,
        hasMore: false,
      );
    }
    return _syncConversationsIncrementallyUseCase(cursorVersion: cursorVersion);
  }
}
