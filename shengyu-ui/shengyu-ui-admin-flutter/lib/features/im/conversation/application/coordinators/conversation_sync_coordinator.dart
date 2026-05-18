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
    final normalizedCursor = cursorVersion.trim().isEmpty
        ? '0'
        : cursorVersion.trim();
    if (normalizedCursor == '0') {
      final items = await _loadConversationListUseCase();
      return ConversationSyncResult(
        cursorVersion: normalizedCursor,
        items: items,
        hasMore: false,
      );
    }

    try {
      final result = await _syncConversationsIncrementallyUseCase(
        cursorVersion: normalizedCursor,
      );
      return result;
    } catch (_) {
      final items = await _loadConversationListUseCase();
      return ConversationSyncResult(
        cursorVersion: normalizedCursor,
        items: items,
        hasMore: false,
      );
    }
  }
}
