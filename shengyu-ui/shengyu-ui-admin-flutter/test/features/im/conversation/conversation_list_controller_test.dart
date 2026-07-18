import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/coordinators/conversation_sync_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/results/conversation_sync_result.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/load_conversation_list_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/sync_conversations_incrementally_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/controllers/conversation_list_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/active_conversation_service.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/unified_cache_manager.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/cursor_version_store.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

void main() {
  late ConversationListController controller;
  late _FakeConversationRepository repository;
  late ActiveConversationService activeConversationService;
  late UnifiedCacheManager unifiedCacheManager;
  late CursorVersionStore cursorVersionStore;

  setUp(() {
    repository = _FakeConversationRepository();
    activeConversationService = ActiveConversationService();
    final memoryCache = MemoryCacheManager();
    final diskCache = DiskCacheManager();
    cursorVersionStore = CursorVersionStore();
    unifiedCacheManager = UnifiedCacheManager(
      memoryCache: memoryCache,
      diskCache: diskCache,
      cursorVersionStore: cursorVersionStore,
    );
    controller = ConversationListController(
      ConversationSyncCoordinator(
        _FakeLoadConversationListUseCase(repository),
        _FakeSyncConversationsIncrementallyUseCase(repository),
      ),
      _FakeSyncConversationsIncrementallyUseCase(repository),
      repository,
      activeConversationService,
      unifiedCacheManager,
      cursorVersionStore,
      'test-user-id',
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

  test('load falls back to list when initial sync is empty', () async {
    repository.syncResult = const ConversationSyncResult(
      items: <Conversation>[],
      cursorVersion: '0',
      hasMore: false,
    );
    repository.listResult = <Conversation>[
      _buildConversation(chatId: 'chat-1'),
    ];

    await controller.load();

    expect(controller.state.conversations, hasLength(1));
    expect(controller.state.conversations.single.chatId, 'chat-1');
    expect(repository.listCallCount, 1);
    expect(repository.syncCallCount, 0);
  });

  test('coordinator uses incremental sync after cursor is established', () async {
    repository.syncResult = ConversationSyncResult(
      items: <Conversation>[_buildConversation(chatId: 'chat-2')],
      cursorVersion: '42',
      hasMore: false,
    );
    final coordinator = ConversationSyncCoordinator(
      _FakeLoadConversationListUseCase(repository),
      _FakeSyncConversationsIncrementallyUseCase(repository),
    );

    final result = await coordinator.bootstrap(cursorVersion: '41');

    expect(result.items.single.chatId, 'chat-2');
    expect(repository.syncCallCount, 1);
    expect(repository.listCallCount, 0);
  });

  test(
    'incremental sync keeps current conversations when response is empty',
    () async {
      repository.listResult = <Conversation>[_buildConversation(chatId: 'chat-1')];
      await controller.load();

      repository.syncResult = const ConversationSyncResult(
        items: <Conversation>[],
        cursorVersion: '40',
        hasMore: false,
      );
      await controller.syncIncrementally();

      expect(controller.state.conversations, hasLength(1));
      expect(controller.state.conversations.single.chatId, 'chat-1');
    },
  );

  test(
    'incremental sync preserves avatar fields when delta omits them',
    () async {
      repository.listResult = <Conversation>[
        _buildConversation(
          chatId: 'chat-1',
          avatarText: '张三',
          avatarBg: '#abcdef',
        ),
      ];
      await controller.load();

      repository.syncResult = ConversationSyncResult(
        items: <Conversation>[
          _buildConversation(
            chatId: 'chat-1',
            avatarText: null,
            avatarBg: null,
          ),
        ],
        cursorVersion: '41',
        hasMore: false,
      );
      await controller.syncIncrementally();

      expect(controller.state.conversations.single.avatarText, '张三');
      expect(controller.state.conversations.single.avatarBg, '#abcdef');
    },
  );
}

class _FakeLoadConversationListUseCase extends LoadConversationListUseCase {
  _FakeLoadConversationListUseCase(super.repository);
}

class _FakeSyncConversationsIncrementallyUseCase
    extends SyncConversationsIncrementallyUseCase {
  _FakeSyncConversationsIncrementallyUseCase(super.repository);
}

class _FakeConversationRepository implements ConversationRepository {
  List<Conversation> listResult = const <Conversation>[];
  ConversationSyncResult syncResult = const ConversationSyncResult(
    items: <Conversation>[],
    cursorVersion: '0',
    hasMore: false,
  );
  int listCallCount = 0;
  int syncCallCount = 0;

  @override
  Future<List<Conversation>> getConversationList() async {
    listCallCount += 1;
    return listResult;
  }

  Future<ConversationSyncResult> _syncIncrementally({
    required String cursorVersion,
  }) async {
    syncCallCount += 1;
    return syncResult;
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

Conversation _buildConversation({
  required String chatId,
  String? avatarText,
  String? avatarBg,
}) {
  return Conversation(
    chatId: chatId,
    title: 'Test',
    conversationType: ConversationType.direct,
    avatarText: avatarText,
    avatarBg: avatarBg,
    lastMessageId: 'm-1',
    lastMessagePreview: 'hello',
    lastMessageType: MessageType.text,
    lastMessageStatus: MessageStatus.sent,
    updatedAt: DateTime.parse('2026-04-30T10:00:00Z'),
    unreadCount: 0,
    isPinned: false,
    isMuted: false,
  );
}
