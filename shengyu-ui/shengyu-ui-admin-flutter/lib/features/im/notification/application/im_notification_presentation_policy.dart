import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';

/// Converts a trusted, minimal notification event into presentation data.
///
/// Transport payloads intentionally carry no message text or user profile
/// fields.  Until a conversation has been synchronised and a separate privacy
/// preference is introduced, notifications therefore use fixed private copy.
class ImNotificationPresentationPolicy {
  const ImNotificationPresentationPolicy();

  ImNotificationPresentation forMessage(ImMessageNotificationEvent event) {
    if (event.isMention) {
      return const ImNotificationPresentation(
        title: '圣钰科技 IM',
        body: '你有一条重要群消息',
        androidChannelId: 'im_mentions',
        androidChannelName: 'IM 提醒',
        groupKey: 'im_mentions',
        isMention: true,
      );
    }
    return const ImNotificationPresentation(
      title: '圣钰科技 IM',
      body: '你收到一条新消息',
      androidChannelId: 'im_messages',
      androidChannelName: 'IM 消息',
      groupKey: 'im_messages',
      isMention: false,
    );
  }
}

class ImNotificationPresentation {
  const ImNotificationPresentation({
    required this.title,
    required this.body,
    required this.androidChannelId,
    required this.androidChannelName,
    required this.groupKey,
    required this.isMention,
  });

  final String title;
  final String body;
  final String androidChannelId;
  final String androidChannelName;
  final String groupKey;
  final bool isMention;
}
