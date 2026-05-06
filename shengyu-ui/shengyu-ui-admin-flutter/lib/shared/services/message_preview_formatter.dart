import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

final messagePreviewFormatterProvider = Provider<MessagePreviewFormatter>((
  ref,
) {
  return MessagePreviewFormatter(ref.watch(appLocaleProvider));
});

class MessagePreviewFormatter {
  const MessagePreviewFormatter(this.locale);

  final String locale;

  bool get _isZh => locale.toLowerCase().startsWith('zh');

  String format({
    required MessageType type,
    required String content,
    String? customType,
    String? fileName,
    String? systemEventKey,
  }) {
    switch (type) {
      case MessageType.image:
        return _isZh ? '[图片]' : '[Image]';
      case MessageType.voice:
        return _isZh ? '[语音]' : '[Voice]';
      case MessageType.video:
        return _isZh ? '[视频]' : '[Video]';
      case MessageType.file:
        final resolvedName = (fileName ?? '').trim();
        if (resolvedName.isNotEmpty) {
          return _isZh ? '[文件] $resolvedName' : '[File] $resolvedName';
        }
        return _isZh ? '[文件]' : '[File]';
      case MessageType.location:
        return _isZh ? '[位置]' : '[Location]';
      case MessageType.emoji:
        return _isZh ? '[表情]' : '[Emoji]';
      case MessageType.sticker:
        return _isZh ? '[动画表情]' : '[Sticker]';
      case MessageType.custom:
        final normalizedCustomType = (customType ?? '').trim().toUpperCase();
        if (normalizedCustomType == 'CONTACT_CARD') {
          return _isZh ? '[名片]' : '[Contact Card]';
        }
        if (normalizedCustomType == 'FORWARD_COMBINE') {
          return _isZh ? '[聊天记录]' : '[Chat History]';
        }
        return _isZh ? '[聊天记录]' : '[Chat History]';
      case MessageType.contactCard:
        return _isZh ? '[名片]' : '[Contact Card]';
      case MessageType.system:
        if (content.isNotEmpty) {
          return content;
        }
        return _systemEventPreview(systemEventKey);
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
  }) {
    final summary = format(
      type: type,
      content: content,
      customType: customType,
      fileName: fileName,
      systemEventKey: systemEventKey,
    );
    if (conversationType != ConversationType.group ||
        type == MessageType.system) {
      return summary;
    }
    final prefix = isSelf
        ? (_isZh ? '我' : 'Me')
        : ((senderName ?? '').trim().isNotEmpty
              ? (senderName ?? '').trim()
              : (_isZh ? '未知' : 'Unknown'));
    return '$prefix: $summary';
  }

  String _systemEventPreview(String? systemEventKey) {
    switch (systemEventKey) {
      case 'im.system.group_notice_updated':
        return _isZh ? '群公告有更新' : 'The group notice has been updated';
      case 'im.system.group_mute_all_enabled':
        return _isZh ? '当前群已开启全员禁言' : 'This group has muted all members';
      case 'im.system.group_mute_all_disabled':
        return _isZh ? '当前群已关闭全员禁言' : 'This group has turned off mute-all';
      case 'im.system.group_member_added_one':
      case 'im.system.group_member_added_two':
      case 'im.system.group_member_added_many':
        return _isZh ? '有新成员加入群聊' : 'A new member joined the group';
      case 'im.system.group_member_removed':
        return _isZh ? '有成员被移出群聊' : 'A member was removed from the group';
      case 'im.system.group_owner_transferred':
        return _isZh ? '群主已完成转让' : 'Group ownership has been transferred';
      case 'im.system.group_member_role_set_admin':
        return _isZh ? '群成员已被设为管理员' : 'A group member was set as admin';
      case 'im.system.group_member_role_set_member':
        return _isZh ? '群成员已被设置为普通成员' : 'A group member was set as member';
      case 'im.system.group_member_muted':
      case 'im.system.group_member_muted_until':
        return _isZh ? '群成员已被禁言' : 'A group member has been muted';
      case 'im.system.group_member_unmuted':
        return _isZh ? '群成员已被解除禁言' : 'A group member has been unmuted';
      default:
        return _isZh ? '[系统消息]' : '[System]';
    }
  }
}
