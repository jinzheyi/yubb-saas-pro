import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';

class ReeditHint {
  const ReeditHint({required this.content, required this.deadlineTs});

  final String content;
  final int? deadlineTs;
}

class ReeditHintLocalStore {
  const ReeditHintLocalStore(this.prefix);

  final String prefix;

  String _key({
    required String tenantId,
    required String userId,
    required String chatId,
    required String messageId,
  }) {
    return '$prefix.$tenantId.$userId.$chatId.$messageId';
  }

  Future<void> persist({
    required String tenantId,
    required String userId,
    required String chatId,
    required String messageId,
    required String content,
    int? deadlineTs,
  }) async {
    final safeChatId = chatId.trim();
    final safeMessageId = messageId.trim();
    final safeContent = content.trim();
    if (safeChatId.isEmpty || safeMessageId.isEmpty || safeContent.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, Object?>{'c': safeContent, 'd': deadlineTs};
    await prefs.setString(
      _key(
        tenantId: tenantId,
        userId: userId,
        chatId: safeChatId,
        messageId: safeMessageId,
      ),
      jsonEncode(payload),
    );
  }

  Future<ReeditHint?> get({
    required String tenantId,
    required String userId,
    required String chatId,
    required String messageId,
  }) async {
    final safeChatId = chatId.trim();
    final safeMessageId = messageId.trim();
    if (safeChatId.isEmpty || safeMessageId.isEmpty) {
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      _key(
        tenantId: tenantId,
        userId: userId,
        chatId: safeChatId,
        messageId: safeMessageId,
      ),
    );
    return _parse(raw);
  }

  Future<ReeditHint?> getByCandidates({
    required String tenantId,
    required String userId,
    required String chatId,
    required List<String> messageIds,
  }) async {
    final seen = <String>{};
    for (final rawId in messageIds) {
      final id = rawId.trim();
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      final hint = await get(
        tenantId: tenantId,
        userId: userId,
        chatId: chatId,
        messageId: id,
      );
      if (hint != null && hint.content.trim().isNotEmpty) {
        return hint;
      }
    }
    return null;
  }

  Future<List<Message>> rehydrateMessages({
    required String tenantId,
    required String userId,
    required String chatId,
    required List<Message> messages,
  }) async {
    final hydrated = <Message>[];
    for (final message in messages) {
      if (!message.isOutgoing ||
          message.extra.reeditContent?.trim().isNotEmpty == true) {
        hydrated.add(message);
        continue;
      }
      final hint = await getByCandidates(
        tenantId: tenantId,
        userId: userId,
        chatId: chatId,
        messageIds: <String>[
          message.messageId,
          if (message.clientMessageId != null) message.clientMessageId!,
        ],
      );
      if (hint == null || hint.content.trim().isEmpty) {
        hydrated.add(message);
        continue;
      }
      hydrated.add(
        message.copyWith(
          extra: message.extra.copyWith(
            reeditContent: hint.content,
            reeditDeadlineTs: hint.deadlineTs ?? message.extra.reeditDeadlineTs,
          ),
        ),
      );
    }
    return hydrated;
  }

  ReeditHint? _parse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        return null;
      }
      final content = json['c']?.toString().trim() ?? '';
      if (content.isEmpty) {
        return null;
      }
      final deadline = int.tryParse(json['d']?.toString() ?? '');
      return ReeditHint(content: content, deadlineTs: deadline);
    } catch (_) {
      return null;
    }
  }
}
