import 'package:shengyu_ui_admin_im/features/im/conversation/application/results/conversation_sync_result.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/datasources/conversation_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/mappers/conversation_dto_mapper.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._remoteDataSource);

  final ConversationRemoteDataSource _remoteDataSource;

  @override
  Future<List<Conversation>> getConversationList() async {
    final items = await _remoteDataSource.fetchConversationList();
    return items.map(ConversationDtoMapper.toEntity).toList();
  }

  @override
  Future<void> pinConversation({
    required String chatId,
    required bool pinned,
  }) async {
    await _remoteDataSource.updateConversationSettings(
      chatId: chatId,
      isPinned: pinned,
    );
  }

  @override
  Future<void> deleteConversation({required String chatId}) async {
    await _remoteDataSource.deleteConversation(chatId: chatId);
  }

  @override
  Future<void> markConversationRead({
    required String chatId,
    required String readSequence,
  }) async {
    await _remoteDataSource.markConversationRead(
      chatId: chatId,
      readSequence: readSequence,
    );
  }

  @override
  Future<ConversationSyncResult> syncConversationsIncrementally({
    required String cursorVersion,
  }) async {
    var nextCursor = cursorVersion.trim().isEmpty ? '0' : cursorVersion.trim();
    var hasMore = true;
    final items = <Conversation>[];
    while (hasMore) {
      final response = await _remoteDataSource.syncConversationList(
        cursorVersion: nextCursor,
        limit: 200,
      );
      items.addAll(response.items.map(ConversationDtoMapper.toEntity));
      nextCursor = response.cursorVersion;
      hasMore = response.hasMore;
      if (response.cursorVersion.trim().isEmpty) {
        hasMore = false;
      }
    }
    return ConversationSyncResult(
      cursorVersion: nextCursor,
      items: items,
      hasMore: false,
    );
  }

  @override
  Future<void> toggleNoDisturb({
    required String chatId,
    required bool noDisturb,
  }) async {
    await _remoteDataSource.updateConversationSettings(
      chatId: chatId,
      noDisturb: noDisturb,
    );
  }
}
