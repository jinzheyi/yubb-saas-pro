import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

/// 消息预览格式化器工厂函数类型
///
/// 用于控制器层，在不持有 BuildContext 的情况下基于 locale 字符串
/// 获取消息预览文本。
///
/// 使用方式（控制器中）：
///   final locale = ref.read(appLocaleProvider);
///   final preview = formatConversationPreviewByLocale(
///     locale: locale,
///     type: message.type,
///     content: message.content,
///     // ...
///   );
typedef ConversationPreviewFormatter = String Function({
  required MessageType type,
  required String content,
  String? customType,
  required ConversationType conversationType,
  required bool isSelf,
  String? senderName,
  String? fileName,
  String? systemEventKey,
  Map<String, String>? systemEventParams,
});

/// 消息预览格式化器工厂函数类型（简化版，仅 format 方法）
typedef MessagePreviewFormatter = String Function({
  required MessageType type,
  required String content,
  String? customType,
  String? fileName,
  String? systemEventKey,
  Map<String, String>? systemEventParams,
});

/// 基于 locale 的消息预览格式化器工厂（控制器层使用）
///
/// 此工厂根据 locale 字符串返回对应的预览文本，
/// 不依赖 BuildContext，适用于控制器/UseCase 层。
///
/// 注意：控制器层仅返回消息摘要（如 "[图片]"、消息内容本身），
/// 不添加 "我:" 发送者前缀。前缀由 UI 层统一通过
/// AppLocalizations 处理，以确保完整的国际化支持。
ConversationPreviewFormatter createConversationPreviewFormatter(
  String locale,
) {
  return ({
    required MessageType type,
    required String content,
    String? customType,
    required ConversationType conversationType,
    required bool isSelf,
    String? senderName,
    String? fileName,
    String? systemEventKey,
    Map<String, String>? systemEventParams,
  }) {
    return _formatMessagePreview(
      locale: locale,
      type: type,
      content: content,
      customType: customType,
      fileName: fileName,
      systemEventKey: systemEventKey,
      systemEventParams: systemEventParams,
    );
  };
}

/// 基于 locale 的消息预览格式化器（简化版，仅 format 方法）
MessagePreviewFormatter createMessagePreviewFormatter(String locale) {
  return ({
    required MessageType type,
    required String content,
    String? customType,
    String? fileName,
    String? systemEventKey,
    Map<String, String>? systemEventParams,
  }) {
    return _formatMessagePreview(
      locale: locale,
      type: type,
      content: content,
      customType: customType,
      fileName: fileName,
      systemEventKey: systemEventKey,
      systemEventParams: systemEventParams,
    );
  };
}

/// 内部方法：基于 locale 格式化单条消息预览
String _formatMessagePreview({
  required String locale,
  required MessageType type,
  required String content,
  String? customType,
  String? fileName,
  String? systemEventKey,
  Map<String, String>? systemEventParams,
}) {
  switch (type) {
    case MessageType.image:
      return _t(locale, '[Image]', '[图片]');
    case MessageType.voice:
      return _t(locale, '[Voice]', '[语音]');
    case MessageType.video:
      return _t(locale, '[Video]', '[视频]');
    case MessageType.file:
      final resolvedName = (fileName ?? '').trim();
      if (resolvedName.isNotEmpty) {
        return '${_t(locale, '[File]', '[文件]')} $resolvedName';
      }
      return _t(locale, '[File]', '[文件]');
    case MessageType.location:
      return _t(locale, '[Location]', '[位置]');
    case MessageType.emoji:
      return _t(locale, '[Emoji]', '[表情]');
    case MessageType.sticker:
      return _t(locale, '[Sticker]', '[动画表情]');
    case MessageType.custom:
      final normalizedCustomType = (customType ?? '').trim().toUpperCase();
      if (normalizedCustomType == 'CONTACT_CARD') {
        return _t(locale, '[Contact Card]', '[名片]');
      }
      return _t(locale, '[Chat History]', '[聊天记录]');
    case MessageType.contactCard:
      return _t(locale, '[Contact Card]', '[名片]');
    case MessageType.system:
      // 优先使用 systemEventKey 本地化渲染，忽略服务端硬编码 content
      // 新链路：content 即为 eventKey（如 im.system.group_member_added_one）
      final resolvedEventKey = (content.trim().startsWith('im.system.'))
          ? content.trim()
          : (systemEventKey?.isNotEmpty == true ? systemEventKey : null);
      if (resolvedEventKey != null && resolvedEventKey.isNotEmpty) {
        return _systemEventPreview(locale, resolvedEventKey, systemEventParams);
      }
      return content;
    case MessageType.text:
      return content;
  }
}

/// 内部方法：系统事件预览文本
String _systemEventPreview(
  String locale,
  String? systemEventKey,
  Map<String, String>? params,
) {
  switch (systemEventKey) {
    case 'im.system.group_notice_updated':
      return _t(locale, 'The group notice has been updated', '群公告有更新');
    case 'im.system.group_mute_all_enabled':
      return _t(locale, 'This group has muted all members', '当前群已开启全员禁言');
    case 'im.system.group_mute_all_disabled':
      return _t(locale, 'This group has turned off mute-all', '当前群已关闭全员禁言');
    case 'im.system.group_member_added_one':
    case 'im.system.group_member_added_two':
    case 'im.system.group_member_added_many':
      final firstName = params?['firstName'] ?? '';
      if (firstName.isNotEmpty) {
        return _t(
          locale,
          '$firstName joined the group',
          '$firstName 加入了群聊',
        );
      }
      return _t(locale, 'A new member joined the group', '有新成员加入群聊');
    case 'im.system.group_member_removed':
      final memberName = params?['memberName'] ?? params?['firstName'] ?? '';
      if (memberName.isNotEmpty) {
        return _t(
          locale,
          '$memberName was removed from the group',
          '$memberName 被移出群聊',
        );
      }
      return _t(locale, 'A member was removed from the group', '有成员被移出群聊');
    case 'im.system.group_owner_transferred':
      final newOwnerName = params?['newOwnerName'] ?? params?['firstName'] ?? '';
      if (newOwnerName.isNotEmpty) {
        return _t(
          locale,
          'Group ownership has been transferred to $newOwnerName',
          '群主已转让给 $newOwnerName',
        );
      }
      return _t(locale, 'Group ownership has been transferred', '群主已完成转让');
    case 'im.system.group_member_role_set_admin':
      final adminTargetName = params?['targetName'] ?? params?['firstName'] ?? '';
      if (adminTargetName.isNotEmpty) {
        return _t(
          locale,
          '$adminTargetName was set as admin',
          '$adminTargetName 已被设为管理员',
        );
      }
      return _t(locale, 'A group member was set as admin', '群成员已被设为管理员');
    case 'im.system.group_member_role_set_member':
      final memberTargetName = params?['targetName'] ?? params?['firstName'] ?? '';
      if (memberTargetName.isNotEmpty) {
        return _t(
          locale,
          '$memberTargetName was set as member',
          '$memberTargetName 已被设置为普通成员',
        );
      }
      return _t(
        locale,
        'A group member was set as member',
        '群成员已被设置为普通成员',
      );
    case 'im.system.group_member_muted':
    case 'im.system.group_member_muted_until':
      final mutedMemberName = params?['memberName'] ?? params?['firstName'] ?? '';
      if (mutedMemberName.isNotEmpty) {
        return _t(
          locale,
          '$mutedMemberName has been muted',
          '$mutedMemberName 已被禁言',
        );
      }
      return _t(locale, 'A group member has been muted', '群成员已被禁言');
    case 'im.system.group_member_unmuted':
      final unmutedMemberName = params?['memberName'] ?? params?['firstName'] ?? '';
      if (unmutedMemberName.isNotEmpty) {
        return _t(
          locale,
          '$unmutedMemberName has been unmuted',
          '$unmutedMemberName 已被解除禁言',
        );
      }
      return _t(locale, 'A group member has been unmuted', '群成员已被解除禁言');
    default:
      return _t(locale, '[System]', '[系统消息]');
  }
}

/// 简易翻译辅助：优先返回国际化文本（如果有 BuildContext），fallback 到硬编码
///
/// 注意：此方法中的 fallback 硬编码文本与 ARB 文件中的翻译保持一致，
/// 确保控制器层在未连接 BuildContext 时仍能正确显示对应语言的文本。
String _t(String locale, String enText, String zhText) {
  final normalizedLocale = locale.toLowerCase();
  if (normalizedLocale.startsWith('zh')) {
    return zhText;
  }
  return enText;
}

/// UI 层使用的消息预览格式化器（通过 AppLocalizations 获取翻译）
///
/// 适用于有 BuildContext 的场景，如 conversation_tile.dart 中的 UI 组件。
/// 所有文本通过 AppLocalizations 获取，支持完整的 ICU MessageFormat 和运行时语言切换。
class MessagePreviewFormatterWithContext {
  MessagePreviewFormatterWithContext(this._l10n);

  final AppLocalizations _l10n;

  String format({
    required MessageType type,
    required String content,
    String? customType,
    String? fileName,
    String? systemEventKey,
    Map<String, String>? systemEventParams,
  }) {
    switch (type) {
      case MessageType.image:
        return _l10n.messagePreviewImage;
      case MessageType.voice:
        return _l10n.messagePreviewVoice;
      case MessageType.video:
        return _l10n.messagePreviewVideo;
      case MessageType.file:
        final resolvedName = (fileName ?? '').trim();
        if (resolvedName.isNotEmpty) {
          return _l10n.messagePreviewFileWithName(resolvedName);
        }
        return _l10n.messagePreviewFile;
      case MessageType.location:
        return _l10n.messagePreviewLocation;
      case MessageType.emoji:
        return _l10n.messagePreviewEmoji;
      case MessageType.sticker:
        return _l10n.messagePreviewSticker;
      case MessageType.custom:
        final normalizedCustomType = (customType ?? '').trim().toUpperCase();
        if (normalizedCustomType == 'CONTACT_CARD') {
          return _l10n.messagePreviewContactCard;
        }
        return _l10n.messagePreviewForward;
      case MessageType.contactCard:
        return _l10n.messagePreviewContactCard;
      case MessageType.system:
        // 优先使用 systemEventKey 本地化渲染，忽略服务端硬编码 content
        // 新链路：content 即为 eventKey（如 im.system.group_member_added_one）
        final resolvedEventKey = (content.trim().startsWith('im.system.'))
            ? content.trim()
            : (systemEventKey?.isNotEmpty == true ? systemEventKey : null);
        if (resolvedEventKey != null && resolvedEventKey.isNotEmpty) {
          return _systemEventPreviewWithContext(resolvedEventKey, systemEventParams);
        }
        return content;
      case MessageType.text:
        return content;
    }
  }

  String formatConversationPreview({
    required MessageType type,
    required String content,
    String? customType,
    required ConversationType conversationType,
    required bool isSelf,
    String? senderName,
    String? fileName,
    String? systemEventKey,
    Map<String, String>? systemEventParams,
  }) {
    final summary = format(
      type: type,
      content: content,
      customType: customType,
      fileName: fileName,
      systemEventKey: systemEventKey,
      systemEventParams: systemEventParams,
    );
    if (type == MessageType.system) {
      return summary;
    }
    if (conversationType != ConversationType.group) {
      if (isSelf) {
        return summary.isEmpty
            ? _l10n.messagePreviewMePrefix
            : _l10n.messagePreviewMePrefixColon(summary);
      }
      return summary;
    }
    final prefix = isSelf
        ? _l10n.messagePreviewMePrefix
        : ((senderName ?? '').trim().isNotEmpty
              ? (senderName ?? '').trim()
              : _l10n.messagePreviewUnknownSender);
    return _l10n.messagePreviewSenderColon(prefix, summary);
  }

  String _systemEventPreviewWithContext(
    String? systemEventKey,
    Map<String, String>? params,
  ) {
    switch (systemEventKey) {
      case 'im.system.group_notice_updated':
        return _l10n.systemEventGroupNoticeUpdated;
      case 'im.system.group_mute_all_enabled':
        return _l10n.systemEventGroupMuteAllEnabled;
      case 'im.system.group_mute_all_disabled':
        return _l10n.systemEventGroupMuteAllDisabled;
      case 'im.system.group_member_added_one':
      case 'im.system.group_member_added_two':
      case 'im.system.group_member_added_many':
        final firstName = params?['firstName'] ?? '';
        return firstName.isNotEmpty
            ? _l10n.systemEventGroupMemberAddedWithName(firstName)
            : _l10n.systemEventGroupMemberAdded;
      case 'im.system.group_member_removed':
        final memberName = params?['memberName'] ?? '';
        return memberName.isNotEmpty
            ? _l10n.systemEventGroupMemberRemovedWithName(memberName)
            : _l10n.systemEventGroupMemberRemoved;
      case 'im.system.group_owner_transferred':
        final newOwnerName = params?['newOwnerName'] ?? '';
        return newOwnerName.isNotEmpty
            ? _l10n.systemEventGroupOwnerTransferredTo(newOwnerName)
            : _l10n.systemEventGroupOwnerTransferred;
      case 'im.system.group_member_role_set_admin':
        final targetName = params?['targetName'] ?? '';
        return targetName.isNotEmpty
            ? _l10n.systemEventGroupMemberRoleSetAdminWithName(targetName)
            : _l10n.systemEventGroupMemberRoleSetAdmin;
      case 'im.system.group_member_role_set_member':
        final memberTargetName = params?['targetName'] ?? '';
        return memberTargetName.isNotEmpty
            ? _l10n.systemEventGroupMemberRoleSetMemberWithName(memberTargetName)
            : _l10n.systemEventGroupMemberRoleSetMember;
      case 'im.system.group_member_muted':
      case 'im.system.group_member_muted_until':
        final mutedMemberName = params?['memberName'] ?? '';
        return mutedMemberName.isNotEmpty
            ? _l10n.systemEventGroupMemberMutedWithName(mutedMemberName)
            : _l10n.systemEventGroupMemberMuted;
      case 'im.system.group_member_unmuted':
        final unmutedMemberName = params?['memberName'] ?? '';
        return unmutedMemberName.isNotEmpty
            ? _l10n.systemEventGroupMemberUnmutedWithName(unmutedMemberName)
            : _l10n.systemEventGroupMemberUnmuted;
      default:
        return _l10n.messagePreviewSystem;
    }
  }
}
