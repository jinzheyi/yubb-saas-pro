import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/usecases/sync_conversations_incrementally_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/repositories/conversation_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/dtos/conversation_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/mappers/conversation_dto_mapper.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/application/coordinators/conversation_sync_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/states/conversation_list_state.dart';

class ConversationListController extends StateNotifier<ConversationListState> {
  ConversationListController(
    this._conversationSyncCoordinator,
    this._syncConversationsIncrementallyUseCase,
    this._conversationRepository,
  ) : super(const ConversationListState());

  final ConversationSyncCoordinator _conversationSyncCoordinator;
  final SyncConversationsIncrementallyUseCase
  _syncConversationsIncrementallyUseCase;
  final ConversationRepository _conversationRepository;

  Future<AppError?> load() async {
    state = state.copyWith(status: ConversationListStatus.loading, error: null);

    try {
      final result = await _conversationSyncCoordinator.bootstrap(
        cursorVersion: state.cursorVersion,
      );
      state = state.copyWith(
        status: ConversationListStatus.ready,
        conversations: result.items,
        cursorVersion: result.cursorVersion,
      );
      return null;
    } catch (error, stackTrace) {
      final appError = AppErrorMapper.map(error, stackTrace);
      state = state.copyWith(
        status: ConversationListStatus.failed,
        error: appError,
      );
      return appError;
    }
  }

  Future<AppError?> syncIncrementally() async {
    try {
      final result = await _syncConversationsIncrementallyUseCase(
        cursorVersion: state.cursorVersion,
      );
      state = state.copyWith(
        status: ConversationListStatus.ready,
        conversations: result.items,
        cursorVersion: result.cursorVersion,
      );
      return null;
    } catch (error, stackTrace) {
      final appError = AppErrorMapper.map(error, stackTrace);
      state = state.copyWith(
        status: ConversationListStatus.failed,
        error: appError,
      );
      return appError;
    }
  }

  void upsertLocalMessage({
    required String chatId,
    required String title,
    required ConversationType conversationType,
    String? targetId,
    required String messageId,
    String? messageSequence,
    required String preview,
    required MessageType messageType,
    required MessageStatus messageStatus,
    required DateTime updatedAt,
    bool resetUnread = false,
    bool incrementUnread = false,
  }) {
    final items = [...state.conversations];
    final index = items.indexWhere((item) => item.chatId == chatId);
    final unreadCount = index >= 0
        ? (resetUnread
              ? 0
              : incrementUnread
              ? items[index].unreadCount + 1
              : items[index].unreadCount)
        : (resetUnread
              ? 0
              : incrementUnread
              ? 1
              : 0);

    final next = index >= 0
        ? items[index].copyWith(
            title: title.isEmpty ? items[index].title : title,
            conversationType: conversationType,
            targetId: targetId ?? items[index].targetId,
            lastMessageId: messageId,
            lastMessageSequence:
                messageSequence?.trim().isNotEmpty == true
                    ? messageSequence!.trim()
                    : items[index].lastMessageSequence,
            lastMessagePreview: preview,
            lastMessageType: messageType,
            lastMessageStatus: messageStatus,
            updatedAt: updatedAt,
            unreadCount: unreadCount,
          )
        : Conversation(
            chatId: chatId,
            title: title.isEmpty ? chatId : title,
            conversationType: conversationType,
            conversationVersion: null,
            targetId: targetId,
            targetAvatar: null,
            lastMessageId: messageId,
            lastMessageSequence:
                messageSequence?.trim().isNotEmpty == true
                    ? messageSequence!.trim()
                    : null,
            lastReadSequence: null,
            lastMessagePreview: preview,
            lastMessageType: messageType,
            lastMessageStatus: messageStatus,
            lastMessageHasAtMe: false,
            groupMemberCount: 0,
            updatedAt: updatedAt,
            unreadCount: unreadCount,
            isPinned: false,
            isMuted: false,
            online: false,
            onlineDeviceTypes: const <int>[],
            lastActiveTime: null,
          );

    if (index >= 0) {
      items[index] = next;
    } else {
      items.add(next);
    }
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: _sortConversations(items),
    );
  }

  void upsertFromSnapshot({
    required Map<String, dynamic> snapshot,
    required String lastMessage,
    required DateTime updatedAt,
    String? messageSequence,
    bool incrementUnread = false,
  }) {
    final incoming = ConversationDtoMapper.toEntity(
      ConversationDto.fromJson(snapshot),
    );
    if (incoming.chatId.trim().isEmpty || incoming.chatId.trim() == '0') {
      return;
    }
    final items = [...state.conversations];
    final index = items.indexWhere((item) => item.chatId == incoming.chatId);
    final preview = incoming.lastMessagePreview.trim().isNotEmpty
        ? incoming.lastMessagePreview
        : lastMessage;
    final incomingSequence = messageSequence?.trim().isNotEmpty == true
        ? messageSequence!.trim()
        : incoming.lastMessageSequence;
    final appliedIncoming = incoming.copyWith(
      lastMessagePreview: preview,
      updatedAt: updatedAt,
      lastMessageSequence: incomingSequence,
    );
    if (index < 0) {
      final unreadCount = incrementUnread
          ? math.max(appliedIncoming.unreadCount, 1)
          : appliedIncoming.unreadCount;
      items.add(appliedIncoming.copyWith(unreadCount: unreadCount));
      state = state.copyWith(
        status: ConversationListStatus.ready,
        conversations: _sortConversations(items),
      );
      return;
    }
    final existing = items[index];
    if (!_shouldApplySnapshot(existing, appliedIncoming)) {
      return;
    }
    items[index] = existing.copyWith(
      title: appliedIncoming.title.isEmpty ? existing.title : appliedIncoming.title,
      conversationType: appliedIncoming.conversationType,
      conversationVersion:
          appliedIncoming.conversationVersion ?? existing.conversationVersion,
      targetId: appliedIncoming.targetId ?? existing.targetId,
      targetAvatar: appliedIncoming.targetAvatar ?? existing.targetAvatar,
      lastMessageId: appliedIncoming.lastMessageId ?? existing.lastMessageId,
      lastMessageSequence:
          appliedIncoming.lastMessageSequence ?? existing.lastMessageSequence,
      lastReadSequence:
          _maxSeq(appliedIncoming.lastReadSequence, existing.lastReadSequence),
      lastMessagePreview: preview,
      lastMessageType: appliedIncoming.lastMessageType,
      lastMessageStatus: appliedIncoming.lastMessageStatus,
      lastMessageHasAtMe: appliedIncoming.lastMessageHasAtMe,
      groupMemberCount: appliedIncoming.groupMemberCount,
      updatedAt: updatedAt,
      unreadCount:
          incrementUnread
              ? math.max(appliedIncoming.unreadCount, existing.unreadCount + 1)
              : appliedIncoming.unreadCount,
      isPinned: appliedIncoming.isPinned,
      isMuted: appliedIncoming.isMuted,
      online: appliedIncoming.online,
      onlineDeviceTypes: appliedIncoming.onlineDeviceTypes,
      lastActiveTime: appliedIncoming.lastActiveTime ?? existing.lastActiveTime,
    );
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: _sortConversations(items),
    );
  }

  void patchLastMessageStatus({
    required String chatId,
    required String? messageId,
    required MessageStatus status,
  }) {
    final items = [...state.conversations];
    final index = items.indexWhere((item) => item.chatId == chatId);
    if (index < 0) {
      return;
    }
    final conversation = items[index];
    if (messageId != null &&
        messageId.isNotEmpty &&
        conversation.lastMessageId != null &&
        conversation.lastMessageId != messageId) {
      return;
    }
    if (conversation.lastMessageStatus == MessageStatus.recalled &&
        status != MessageStatus.recalled) {
      return;
    }
    items[index] = conversation.copyWith(lastMessageStatus: status);
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: items,
    );
  }

  void markConversationRead(String chatId) {
    final items = [...state.conversations];
    final index = items.indexWhere((item) => item.chatId == chatId);
    if (index < 0) {
      return;
    }
    items[index] = items[index].copyWith(unreadCount: 0);
    final lastSequence = items[index].lastMessageSequence?.trim() ?? '';
    if (lastSequence.isNotEmpty) {
      items[index] = items[index].copyWith(lastReadSequence: lastSequence);
    }
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: items,
    );
  }

  Future<void> markConversationReadRemotely(String chatId) async {
    final conversation = state.conversations
        .where((item) => item.chatId == chatId)
        .firstOrNull;
    if (conversation == null) {
      return;
    }
    final readSequence =
        conversation.lastMessageSequence ??
        conversation.lastReadSequence ??
        '0';
    await _conversationRepository.markConversationRead(
      chatId: chatId,
      readSequence: readSequence,
    );
    markConversationRead(chatId);
  }

  void markConversationUnreadLocally(String chatId) {
    final items = [...state.conversations];
    final index = items.indexWhere((item) => item.chatId == chatId);
    if (index < 0) {
      return;
    }
    items[index] = items[index].copyWith(
      unreadCount: math.max(items[index].unreadCount, 1),
    );
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: items,
    );
  }

  void patchPresence({
    required String chatId,
    required bool online,
    required List<int> onlineDeviceTypes,
    int? lastActiveTime,
  }) {
    final items = [...state.conversations];
    final index = items.indexWhere((item) => item.chatId == chatId);
    if (index < 0) {
      return;
    }
    items[index] = items[index].copyWith(
      online: online,
      onlineDeviceTypes: onlineDeviceTypes,
      lastActiveTime: lastActiveTime,
    );
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: items,
    );
  }

  Future<void> deleteConversation(String chatId) async {
    await _conversationRepository.deleteConversation(chatId: chatId);
    final items = [...state.conversations]
      ..removeWhere((item) => item.chatId == chatId);
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: items,
    );
  }

  void clearConversationPreview({required String chatId, DateTime? updatedAt}) {
    final items = [...state.conversations];
    final index = items.indexWhere((item) => item.chatId == chatId);
    if (index < 0) {
      return;
    }
    items[index] = items[index].copyWith(
      lastMessageId: null,
      lastMessagePreview: '',
      unreadCount: 0,
      updatedAt: updatedAt ?? items[index].updatedAt,
    );
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: _sortConversations(items),
    );
  }

  void patchConversationSettings({
    required String chatId,
    bool? isPinned,
    bool? isMuted,
  }) {
    final items = [...state.conversations];
    final index = items.indexWhere((item) => item.chatId == chatId);
    if (index < 0) {
      return;
    }
    items[index] = items[index].copyWith(
      isPinned: isPinned ?? items[index].isPinned,
      isMuted: isMuted ?? items[index].isMuted,
    );
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: _sortConversations(items),
    );
  }

  List<Conversation> _sortConversations(List<Conversation> items) {
    items.sort((left, right) {
      if (left.isPinned != right.isPinned) {
        return left.isPinned ? -1 : 1;
      }
      return right.updatedAt.compareTo(left.updatedAt);
    });
    return items;
  }

  bool _shouldApplySnapshot(Conversation existing, Conversation incoming) {
    final incomingVersion = incoming.conversationVersion?.trim() ?? '';
    final currentVersion = existing.conversationVersion?.trim() ?? '';
    if (incomingVersion.isEmpty || currentVersion.isEmpty) {
      return true;
    }
    return _compareCursor(incomingVersion, currentVersion) > 0;
  }

  String? _maxSeq(String? left, String? right) {
    final a = left?.trim() ?? '';
    final b = right?.trim() ?? '';
    if (a.isEmpty) {
      return b.isEmpty ? null : b;
    }
    if (b.isEmpty) {
      return a;
    }
    return _compareCursor(a, b) >= 0 ? a : b;
  }

  int _compareCursor(String left, String right) {
    final leftInt = BigInt.tryParse(left);
    final rightInt = BigInt.tryParse(right);
    if (leftInt != null && rightInt != null) {
      return leftInt.compareTo(rightInt);
    }
    if (left.length != right.length) {
      return left.length.compareTo(right.length);
    }
    return left.compareTo(right);
  }
}
