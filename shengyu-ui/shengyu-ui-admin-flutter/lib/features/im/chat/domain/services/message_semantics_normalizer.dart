import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

abstract final class MessageSemanticsNormalizer {
  static Message normalize(Message message) {
    if (message.type == MessageType.contactCard &&
        message.extra.contactUserId?.trim().isNotEmpty == true &&
        message.extra.contactDisplayName?.trim().isNotEmpty == true) {
      return message;
    }

    final payload = _extractStructuredPayload(message.content);
    if (payload == null) {
      return message;
    }

    final structuredType = payload['type']?.toString().trim().toUpperCase() ?? '';
    if (structuredType != 'CONTACT_CARD') {
      return message;
    }

    return message.copyWith(
      type: MessageType.contactCard,
      extra: message.extra.copyWith(
        customType: 'CONTACT_CARD',
        contactUserId: _pickString(
          payload,
          const <String>['userId', 'contactUserId'],
          fallback: message.extra.contactUserId,
        ),
        contactDisplayName: _pickString(
          payload,
          const <String>['displayName', 'contactDisplayName'],
          fallback: message.extra.contactDisplayName,
        ),
        contactDepartmentName: _pickString(
          payload,
          const <String>['deptName', 'contactDepartmentName'],
          fallback: message.extra.contactDepartmentName,
        ),
        contactPostName: _pickString(
          payload,
          const <String>['postName', 'contactPostName'],
          fallback: message.extra.contactPostName,
        ),
        contactAvatar: _pickString(
          payload,
          const <String>['avatar', 'contactAvatar'],
          fallback: message.extra.contactAvatar,
        ),
      ),
    );
  }

  static Map<String, dynamic>? _extractStructuredPayload(String raw) {
    final direct = _tryParseObject(raw);
    if (direct != null) {
      final nestedContent = direct['content'];
      if (nestedContent is String) {
        final nested = _tryParseObject(nestedContent);
        if (nested != null) {
          return nested;
        }
      }
      return direct;
    }
    return null;
  }

  static Map<String, dynamic>? _tryParseObject(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (e) {
      debugPrint('[SemanticsNormalizer] normalize failed: $e');
    }
    return null;
  }

  static String? _pickString(
    Map<String, dynamic> payload,
    List<String> keys, {
    String? fallback,
  }) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return fallback;
  }
}
