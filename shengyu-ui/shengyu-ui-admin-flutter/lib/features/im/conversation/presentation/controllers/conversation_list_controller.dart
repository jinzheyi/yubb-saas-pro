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
        conversations: _replaceSyncedConversations(result.items),
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
        conversations: _mergeSyncedConversations(
          current: state.conversations,
          incoming: result.items,
        ),
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
    String? senderName,
    bool isSelf = false,
    String? customType,
    String? fileName,
    String? systemEventKey,
    required MessageStatus messageStatus,
    required DateTime updatedAt,
    bool resetUnread = false,
    bool incrementUnread = false,
  }) {
    final items = [...state.conversations];
    final index = _findConversationIndex(
      items,
      chatId: chatId,
      targetId: targetId,
      conversationType: conversationType,
    );
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
            lastMessageSequence: messageSequence?.trim().isNotEmpty == true
                ? messageSequence!.trim()
                : items[index].lastMessageSequence,
            lastMessagePreview: preview,
            lastMessageType: messageType,
            lastMessageSenderName:
                senderName ?? items[index].lastMessageSenderName,
            lastMessageIsSelf: isSelf,
            lastMessageCustomType:
                customType ?? items[index].lastMessageCustomType,
            lastMessageFileName: fileName ?? items[index].lastMessageFileName,
            lastMessageSystemEventKey:
                systemEventKey ?? items[index].lastMessageSystemEventKey,
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
            avatarText: null,
            avatarBg: null,
            lastMessageId: messageId,
            lastMessageSequence: messageSequence?.trim().isNotEmpty == true
                ? messageSequence!.trim()
                : null,
            lastReadSequence: null,
            lastMessagePreview: preview,
            lastMessageType: messageType,
            lastMessageSenderName: senderName,
            lastMessageIsSelf: isSelf,
            lastMessageCustomType: customType,
            lastMessageFileName: fileName,
            lastMessageSystemEventKey: systemEventKey,
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
      conversations: _sortConversations(_dedupeConversations(items)),
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
        conversations: _sortConversations(_dedupeConversations(items)),
      );
      return;
    }
    final existing = items[index];
    if (!_shouldApplySnapshot(existing, appliedIncoming)) {
      return;
    }
    items[index] = existing.copyWith(
      title: appliedIncoming.title.isEmpty
          ? existing.title
          : appliedIncoming.title,
      conversationType: appliedIncoming.conversationType,
      conversationVersion:
          appliedIncoming.conversationVersion ?? existing.conversationVersion,
      targetId: appliedIncoming.targetId ?? existing.targetId,
      targetAvatar: appliedIncoming.targetAvatar ?? existing.targetAvatar,
      avatarText: appliedIncoming.avatarText ?? existing.avatarText,
      avatarBg: appliedIncoming.avatarBg ?? existing.avatarBg,
      lastMessageId: appliedIncoming.lastMessageId ?? existing.lastMessageId,
      lastMessageSequence:
          appliedIncoming.lastMessageSequence ?? existing.lastMessageSequence,
      lastReadSequence: _maxSeq(
        appliedIncoming.lastReadSequence,
        existing.lastReadSequence,
      ),
      lastMessagePreview: _preferConversationPreview(
        existing,
        appliedIncoming,
        preview,
      ),
      lastMessageType: appliedIncoming.lastMessageType,
      lastMessageSenderName:
          appliedIncoming.lastMessageSenderName ??
          existing.lastMessageSenderName,
      lastMessageIsSelf: appliedIncoming.lastMessageIsSelf,
      lastMessageCustomType:
          appliedIncoming.lastMessageCustomType ??
          existing.lastMessageCustomType,
      lastMessageFileName:
          appliedIncoming.lastMessageFileName ?? existing.lastMessageFileName,
      lastMessageSystemEventKey:
          appliedIncoming.lastMessageSystemEventKey ??
          existing.lastMessageSystemEventKey,
      lastMessageStatus: appliedIncoming.lastMessageStatus,
      lastMessageHasAtMe: appliedIncoming.lastMessageHasAtMe,
      groupMemberCount: appliedIncoming.groupMemberCount,
      updatedAt: updatedAt,
      unreadCount: incrementUnread
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
      conversations: _sortConversations(_dedupeConversations(items)),
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

  void applyBadgeSnapshot(Map<String, int> conversationBadges) {
    if (conversationBadges.isEmpty || state.conversations.isEmpty) {
      return;
    }
    var changed = false;
    final items = [...state.conversations];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final serverUnread = conversationBadges[item.chatId] ?? 0;
      if (serverUnread > 0) {
        if (item.unreadCount != serverUnread) {
          items[index] = item.copyWith(unreadCount: serverUnread);
          changed = true;
        }
        continue;
      }
      final lastSequence = item.lastMessageSequence?.trim() ?? '';
      final nextReadSequence = lastSequence.isNotEmpty
          ? lastSequence
          : item.lastReadSequence;
      if (item.unreadCount != 0 || nextReadSequence != item.lastReadSequence) {
        items[index] = item.copyWith(
          unreadCount: 0,
          lastReadSequence: nextReadSequence,
        );
        changed = true;
      }
    }
    if (!changed) {
      return;
    }
    state = state.copyWith(
      status: ConversationListStatus.ready,
      conversations: items,
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

  List<Conversation> _replaceSyncedConversations(List<Conversation> incoming) {
    final items = incoming
        .where((item) => !item.deletedByUser)
        .toList(growable: true);
    return _sortConversations(_dedupeConversations(items));
  }

  List<Conversation> _mergeSyncedConversations({
    required List<Conversation> current,
    required List<Conversation> incoming,
  }) {
    if (incoming.isEmpty) {
      return current;
    }
    final items = [...current];
    for (final conversation in incoming) {
      final index = items.indexWhere(
        (item) => item.chatId == conversation.chatId,
      );
      if (conversation.deletedByUser) {
        if (index >= 0) {
          items.removeAt(index);
        }
        continue;
      }
      if (index < 0) {
        items.add(conversation);
        continue;
      }
      final existing = items[index];
      if (!_shouldApplySnapshot(existing, conversation)) {
        continue;
      }
      items[index] = existing.copyWith(
        title: conversation.title.isEmpty ? existing.title : conversation.title,
        conversationType: conversation.conversationType,
        conversationVersion:
            conversation.conversationVersion ?? existing.conversationVersion,
        targetId: conversation.targetId ?? existing.targetId,
        targetAvatar: conversation.targetAvatar ?? existing.targetAvatar,
        avatarText: conversation.avatarText ?? existing.avatarText,
        avatarBg: conversation.avatarBg ?? existing.avatarBg,
        lastMessageId: conversation.lastMessageId ?? existing.lastMessageId,
        lastMessageSequence:
            conversation.lastMessageSequence ?? existing.lastMessageSequence,
        lastReadSequence: _maxSeq(
          conversation.lastReadSequence,
          existing.lastReadSequence,
        ),
        lastMessagePreview: _preferConversationPreview(
          existing,
          conversation,
          conversation.lastMessagePreview,
        ),
        lastMessageType: conversation.lastMessageType,
        lastMessageSenderName:
            conversation.lastMessageSenderName ??
            existing.lastMessageSenderName,
        lastMessageIsSelf: conversation.lastMessageIsSelf,
        lastMessageCustomType:
            conversation.lastMessageCustomType ??
            existing.lastMessageCustomType,
        lastMessageFileName:
            conversation.lastMessageFileName ?? existing.lastMessageFileName,
        lastMessageSystemEventKey:
            conversation.lastMessageSystemEventKey ??
            existing.lastMessageSystemEventKey,
        lastMessageStatus: conversation.lastMessageStatus,
        lastMessageHasAtMe: conversation.lastMessageHasAtMe,
        groupMemberCount: conversation.groupMemberCount,
        updatedAt: conversation.updatedAt,
        unreadCount: conversation.unreadCount,
        isPinned: conversation.isPinned,
        isMuted: conversation.isMuted,
        deletedByUser: false,
        online: conversation.online,
        onlineDeviceTypes: conversation.onlineDeviceTypes,
        lastActiveTime: conversation.lastActiveTime ?? existing.lastActiveTime,
      );
    }
    return _sortConversations(_dedupeConversations(items));
  }

  int _findConversationIndex(
    List<Conversation> items, {
    required String chatId,
    String? targetId,
    ConversationType? conversationType,
  }) {
    final normalizedChatId = chatId.trim();
    if (normalizedChatId.isNotEmpty) {
      final byChatId = items.indexWhere(
        (item) => item.chatId == normalizedChatId,
      );
      if (byChatId >= 0) {
        return byChatId;
      }
    }
    final normalizedTargetId = targetId?.trim() ?? '';
    if (normalizedTargetId.isNotEmpty && conversationType != null) {
      return items.indexWhere(
        (item) =>
            (item.targetId?.trim() ?? '') == normalizedTargetId &&
            item.conversationType == conversationType,
      );
    }
    return -1;
  }

  List<Conversation> _dedupeConversations(List<Conversation> items) {
    if (items.length < 2) {
      return items;
    }
    final ordered = [...items];
    final byIdentity = <String, Conversation>{};
    for (final item in ordered) {
      final key = _conversationIdentityKey(item);
      final existing = byIdentity[key];
      if (existing == null) {
        byIdentity[key] = item;
        continue;
      }
      byIdentity[key] = _mergeDuplicateConversation(existing, item);
    }
    return byIdentity.values.toList(growable: true);
  }

  String _conversationIdentityKey(Conversation item) {
    final targetId = item.targetId?.trim() ?? '';
    if (targetId.isNotEmpty && targetId != '0') {
      return '${item.conversationType.name}:$targetId';
    }
    return 'chat:${item.chatId.trim()}';
  }

  Conversation _mergeDuplicateConversation(
    Conversation left,
    Conversation right,
  ) {
    final preferred = right.updatedAt.isAfter(left.updatedAt) ? right : left;
    final fallback = identical(preferred, right) ? left : right;
    final mergedPreview = _preferConversationPreview(
      preferred,
      fallback,
      preferred.lastMessagePreview,
    );
    return preferred.copyWith(
      chatId: preferred.chatId.trim().isNotEmpty
          ? preferred.chatId
          : fallback.chatId,
      title: preferred.title.trim().isNotEmpty
          ? preferred.title
          : fallback.title,
      conversationVersion:
          preferred.conversationVersion?.trim().isNotEmpty == true
          ? preferred.conversationVersion
          : fallback.conversationVersion,
      targetId: preferred.targetId?.trim().isNotEmpty == true
          ? preferred.targetId
          : fallback.targetId,
      targetAvatar: preferred.targetAvatar?.trim().isNotEmpty == true
          ? preferred.targetAvatar
          : fallback.targetAvatar,
      avatarText: preferred.avatarText?.trim().isNotEmpty == true
          ? preferred.avatarText
          : fallback.avatarText,
      avatarBg: preferred.avatarBg?.trim().isNotEmpty == true
          ? preferred.avatarBg
          : fallback.avatarBg,
      lastMessageId: preferred.lastMessageId ?? fallback.lastMessageId,
      lastMessageSequence: _maxSeq(
        preferred.lastMessageSequence,
        fallback.lastMessageSequence,
      ),
      lastReadSequence: _maxSeq(
        preferred.lastReadSequence,
        fallback.lastReadSequence,
      ),
      lastMessagePreview: mergedPreview,
      lastMessageType: preferred.lastMessageType,
      lastMessageSenderName:
          preferred.lastMessageSenderName ?? fallback.lastMessageSenderName,
      lastMessageIsSelf: preferred.lastMessageIsSelf,
      lastMessageCustomType:
          preferred.lastMessageCustomType ?? fallback.lastMessageCustomType,
      lastMessageFileName:
          preferred.lastMessageFileName ?? fallback.lastMessageFileName,
      lastMessageSystemEventKey:
          preferred.lastMessageSystemEventKey ??
          fallback.lastMessageSystemEventKey,
      lastMessageStatus: preferred.lastMessageStatus,
      lastMessageHasAtMe:
          preferred.lastMessageHasAtMe || fallback.lastMessageHasAtMe,
      groupMemberCount: math.max(
        preferred.groupMemberCount,
        fallback.groupMemberCount,
      ),
      updatedAt: preferred.updatedAt.isAfter(fallback.updatedAt)
          ? preferred.updatedAt
          : fallback.updatedAt,
      unreadCount: math.max(preferred.unreadCount, fallback.unreadCount),
      isPinned: preferred.isPinned || fallback.isPinned,
      isMuted: preferred.isMuted || fallback.isMuted,
      online: preferred.online || fallback.online,
      onlineDeviceTypes: preferred.onlineDeviceTypes.isNotEmpty
          ? preferred.onlineDeviceTypes
          : fallback.onlineDeviceTypes,
      lastActiveTime:
          math.max(
                preferred.lastActiveTime ?? 0,
                fallback.lastActiveTime ?? 0,
              ) >
              0
          ? math.max(
              preferred.lastActiveTime ?? 0,
              fallback.lastActiveTime ?? 0,
            )
          : null,
    );
  }

  String _preferConversationPreview(
    Conversation existing,
    Conversation incoming,
    String candidate,
  ) {
    if (candidate.trim().isEmpty) {
      return existing.lastMessagePreview;
    }
    final sameMessage =
        (existing.lastMessageId?.trim().isNotEmpty == true &&
            existing.lastMessageId == incoming.lastMessageId) ||
        ((existing.lastMessageSequence?.trim().isNotEmpty ?? false) &&
            existing.lastMessageSequence == incoming.lastMessageSequence);
    if (!sameMessage || incoming.conversationType != ConversationType.group) {
      return candidate;
    }
    final existingPreview = existing.lastMessagePreview.trim();
    final incomingPreview = candidate.trim();
    if (_looksAttributedGroupPreview(existingPreview) &&
        !_looksAttributedGroupPreview(incomingPreview)) {
      return existingPreview;
    }
    return candidate;
  }

  bool _looksAttributedGroupPreview(String preview) {
    if (preview.isEmpty) {
      return false;
    }
    return preview.contains(': ') || preview.contains('：');
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
