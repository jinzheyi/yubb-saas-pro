import 'package:shengyu_ui_admin_im/features/im/conversation/application/results/conversation_sync_result.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';

class SyncConversationsIncrementallyUseCase {
  const SyncConversationsIncrementallyUseCase(this._repository);

  final ConversationRepository _repository;

  Future<ConversationSyncResult> call({required String cursorVersion}) {
    return _repository.syncConversationsIncrementally(
      cursorVersion: cursorVersion,
    );
  }
}
