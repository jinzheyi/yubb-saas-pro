import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

int _hashToInt(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0xffffffff;
  }
  return hash;
}

String _toHex2(int value) => value.toRadixString(16).padLeft(2, '0');

Color _hashToPastelColor(String value, int salt) {
  final hash = (_hashToInt(value) ^ salt) & 0xffffffff;
  var red = (hash >> 16) & 0xff;
  var green = (hash >> 8) & 0xff;
  var blue = hash & 0xff;
  red = ((red + 255) / 2).floor();
  green = ((green + 255) / 2).floor();
  blue = ((blue + 255) / 2).floor();
  return Color(
    int.parse('0xff${_toHex2(red)}${_toHex2(green)}${_toHex2(blue)}'),
  );
}

Color getUserAvatarColor(String userId) => _hashToPastelColor(userId, 0);

Color getGroupAvatarColor(String groupId) =>
    _hashToPastelColor(groupId, 100000);

Color getConversationAvatarColor(
  ConversationType conversationType,
  String targetId,
) {
  if (conversationType == ConversationType.group) {
    return getGroupAvatarColor(targetId);
  }
  return getUserAvatarColor(targetId);
}

String getAvatarText(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  if (trimmed.length <= 2) {
    return trimmed;
  }
  if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(trimmed)) {
    return trimmed.substring(0, 2);
  }
  final words = trimmed
      .split(' ')
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
  if (words.length >= 2) {
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }
  return trimmed.substring(0, 1).toUpperCase();
}

String resolveConversationAvatarText({
  required String? avatarText,
  required String title,
  required String? targetId,
}) {
  final serviceText = avatarText?.trim() ?? '';
  if (serviceText.isNotEmpty) {
    return serviceText;
  }
  final normalizedTitle = title.trim();
  if (normalizedTitle.isNotEmpty) {
    return getAvatarText(normalizedTitle);
  }
  final normalizedTargetId = targetId?.trim() ?? '';
  if (normalizedTargetId.isNotEmpty && normalizedTargetId != '0') {
    return getAvatarText(normalizedTargetId);
  }
  return '?';
}

Color resolveConversationAvatarBg({
  required String? avatarBg,
  required ConversationType conversationType,
  required String? targetId,
  required String chatId,
}) {
  final serviceBg = avatarBg?.trim() ?? '';
  if (serviceBg.isNotEmpty) {
    final hex = serviceBg.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('0xff$hex'));
    }
    if (hex.length == 8) {
      return Color(int.parse('0x$hex'));
    }
  }
  final seed = (targetId?.trim().isNotEmpty ?? false)
      ? targetId!.trim()
      : chatId;
  return getConversationAvatarColor(conversationType, seed);
}
