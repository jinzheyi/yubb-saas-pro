import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';

class LoadConversationListUseCase {
  const LoadConversationListUseCase(this._repository);

  final ConversationRepository _repository;

  Future<List<Conversation>> call() {
    return _repository.getConversationList();
  }
}
