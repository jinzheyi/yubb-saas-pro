import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

/// 系统消息本地渲染器
///
/// 当收到 WebSocket 推送的系统消息时，根据 systemEventKey
/// 使用当前语言本地渲染，而非直接使用服务端返回的 content。
/// 这样用户在切换语言后，历史系统消息会自动按新语言重渲染。
///
/// 使用方式：
/// ```dart
/// final text = SystemMessageRenderer.render(context, systemEventKey, params: params);
/// ```
final class SystemMessageRenderer {
  SystemMessageRenderer._();

  /// 渲染系统消息
  ///
  /// [context] 用于获取当前语言环境
  /// [systemEventKey] 系统消息事件标识（如 im.system.group_member_added_one）
  /// [params] 事件参数，用于填充占位符
  /// [fallbackContent] 回退内容，当事件标识未知时使用
  static String render(
    BuildContext context,
    String? systemEventKey, {
    Map<String, String>? params,
    String? fallbackContent,
  }) {
    if (systemEventKey == null || systemEventKey.isEmpty) {
      return fallbackContent ?? '';
    }

    final l10n = AppLocalizations.of(context);
    final p = params ?? const <String, String>{};

    switch (systemEventKey) {
      case 'im.system.group_owner_transferred':
        final name = p['newOwnerName'] ?? p['name'] ?? '';
        if (name.isNotEmpty) {
          return l10n.chatGroupOwnerTransferredTo(name);
        }
        return l10n.chatGroupOwnerTransferred;

      case 'im.system.group_member_added_one':
        final firstName = p['firstName'] ?? p['name'] ?? '';
        if (firstName.isNotEmpty) {
          return l10n.chatGroupMemberAddedOne(firstName);
        }
        return l10n.chatGroupMemberAdded;

      case 'im.system.group_member_added_two':
        final firstName = p['firstName'] ?? '';
        final secondName = p['secondName'] ?? '';
        if (firstName.isNotEmpty || secondName.isNotEmpty) {
          return l10n.chatGroupMemberAddedTwo(firstName, secondName);
        }
        return l10n.chatGroupMemberAdded;

      case 'im.system.group_member_added_many':
        final firstName = p['firstName'] ?? '';
        final secondName = p['secondName'] ?? '';
        final otherCount = int.tryParse(p['otherCount'] ?? '0') ?? 0;
        if (firstName.isNotEmpty || secondName.isNotEmpty) {
          return l10n.chatGroupMemberAddedMany(firstName, secondName, otherCount);
        }
        return l10n.chatGroupMemberAdded;

      case 'im.system.group_member_removed':
        final name = p['memberName'] ?? p['name'] ?? '';
        if (name.isNotEmpty) {
          return l10n.chatGroupMemberRemovedNamed(name);
        }
        return l10n.chatGroupMemberRemoved;

      case 'im.system.group_member_muted':
        final name = p['memberName'] ?? p['name'] ?? '';
        if (name.isNotEmpty) {
          return l10n.chatGroupMemberMutedNamed(name);
        }
        return l10n.chatGroupMemberMutedGeneric;

      case 'im.system.group_member_muted_until':
        final name = p['memberName'] ?? p['name'] ?? '';
        final time = p['time'] ?? '';
        if (name.isNotEmpty && time.isNotEmpty) {
          return l10n.chatGroupMemberMutedUntil(name, time);
        }
        return l10n.chatGroupMemberMutedGeneric;

      case 'im.system.group_member_unmuted':
        final name = p['memberName'] ?? p['name'] ?? '';
        if (name.isNotEmpty) {
          return l10n.chatGroupMemberUnmutedNamed(name);
        }
        return l10n.chatGroupMemberUnmutedGeneric;

      case 'im.system.group_member_role_set_admin':
        final operatorName = p['operatorName'] ?? '';
        final targetName = p['targetName'] ?? '';
        if (operatorName.isNotEmpty && targetName.isNotEmpty) {
          return l10n.chatGroupMemberRoleSetAdminNamed(operatorName, targetName);
        }
        return l10n.chatGroupMemberRoleSetAdmin;

      case 'im.system.group_member_role_set_member':
        final operatorName = p['operatorName'] ?? '';
        final targetName = p['targetName'] ?? '';
        if (operatorName.isNotEmpty && targetName.isNotEmpty) {
          return l10n.chatGroupMemberRoleSetMemberNamed(operatorName, targetName);
        }
        return l10n.chatGroupMemberRoleSetMember;

      case 'im.system.group_notice_updated':
        return l10n.chatGroupNoticeUpdated;

      case 'im.system.group_mute_all_enabled':
        return l10n.chatGroupMuteAllEnabled;

      case 'im.system.group_mute_all_disabled':
        return l10n.chatGroupMuteAllDisabled;

      case 'im.recall.self':
        return l10n.chatRecallSelfTip;

      case 'im.recall.other':
        final operatorName = p['operatorName'] ?? '';
        if (operatorName.isNotEmpty) {
          return l10n.chatRecallOtherTip(operatorName);
        }
        return l10n.chatRecallSelfTip;

      case 'im.system.group_you_are_new_owner':
        return l10n.chatGroupYouAreNewOwner;

      case 'im.system.group_you_transferred_owner':
        return l10n.chatGroupYouTransferredOwner;

      default:
        return fallbackContent ?? '';
    }
  }
}
