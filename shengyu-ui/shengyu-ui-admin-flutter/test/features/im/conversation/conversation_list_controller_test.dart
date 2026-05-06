import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/coordinators/conversation_sync_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/results/conversation_sync_result.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/load_conversation_list_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/sync_conversations_incrementally_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/controllers/conversation_list_controller.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

void main() {
  late ConversationListController controller;
  late _FakeConversationRepository repository;

  setUp(() {
    repository = _FakeConversationRepository();
    controller = ConversationListController(
      ConversationSyncCoordinator(
        _FakeLoadConversationListUseCase(repository),
        _FakeSyncConversationsIncrementallyUseCase(repository),
      ),
      _FakeSyncConversationsIncrementallyUseCase(repository),
      repository,
    );
  });

  test('upsertLocalMessage inserts and sorts latest conversation first', () {
    controller.upsertLocalMessage(
      chatId: 'chat-older',
      title: 'Older',
      conversationType: ConversationType.direct,
      messageId: 'm-1',
      preview: 'older',
      messageType: MessageType.text,
      messageStatus: MessageStatus.sent,
      updatedAt: DateTime.parse('2026-04-30T09:00:00Z'),
    );
    controller.upsertLocalMessage(
      chatId: 'chat-newer',
      title: 'Newer',
      conversationType: ConversationType.group,
      messageId: 'm-2',
      preview: 'newer',
      messageType: MessageType.text,
      messageStatus: MessageStatus.sending,
      updatedAt: DateTime.parse('2026-04-30T10:00:00Z'),
    );

    expect(controller.state.conversations, hasLength(2));
    expect(controller.state.conversations.first.chatId, 'chat-newer');
    expect(
      controller.state.conversations.first.lastMessageStatus,
      MessageStatus.sending,
    );
  });

  test('patchLastMessageStatus only updates matching last message', () {
    controller.upsertLocalMessage(
      chatId: 'chat-1',
      title: 'Chat',
      conversationType: ConversationType.direct,
      messageId: 'm-1',
      preview: 'hello',
      messageType: MessageType.text,
      messageStatus: MessageStatus.sending,
      updatedAt: DateTime.parse('2026-04-30T10:00:00Z'),
    );

    controller.patchLastMessageStatus(
      chatId: 'chat-1',
      messageId: 'm-1',
      status: MessageStatus.failed,
    );

    expect(
      controller.state.conversations.single.lastMessageStatus,
      MessageStatus.failed,
    );
  });

  test('markConversationRead clears unread count', () {
    controller.upsertLocalMessage(
      chatId: 'chat-1',
      title: 'Chat',
      conversationType: ConversationType.direct,
      messageId: 'm-1',
      preview: 'hello',
      messageType: MessageType.text,
      messageStatus: MessageStatus.sent,
      updatedAt: DateTime.parse('2026-04-30T10:00:00Z'),
      incrementUnread: true,
    );

    controller.markConversationRead('chat-1');

    expect(controller.state.conversations.single.unreadCount, 0);
  });
}

class _FakeLoadConversationListUseCase extends LoadConversationListUseCase {
  _FakeLoadConversationListUseCase(super.repository);
}

class _FakeSyncConversationsIncrementallyUseCase
    extends SyncConversationsIncrementallyUseCase {
  _FakeSyncConversationsIncrementallyUseCase(super.repository);
}

class _FakeConversationRepository implements ConversationRepository {
  @override
  Future<List<Conversation>> getConversationList() async =>
      const <Conversation>[];

  Future<ConversationSyncResult> _syncIncrementally({
    required String cursorVersion,
  }) async {
    return const ConversationSyncResult(
      items: <Conversation>[],
      cursorVersion: '0',
      hasMore: false,
    );
  }

  @override
  Future<void> pinConversation({
    required String chatId,
    required bool pinned,
  }) async {}

  @override
  Future<ConversationSyncResult> syncConversationsIncrementally({
    required String cursorVersion,
  }) {
    return _syncIncrementally(cursorVersion: cursorVersion);
  }

  @override
  Future<void> toggleNoDisturb({
    required String chatId,
    required bool noDisturb,
  }) async {}

  @override
  Future<void> markConversationRead({
    required String chatId,
    required String readSequence,
  }) async {}

  @override
  Future<void> deleteConversation({required String chatId}) async {}
}
