import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/domain/im_notification_event.dart';

/// Resolves a notification routing id against the authenticated local/remote
/// conversation state before navigation.  Payload display fields are never
/// used as route arguments.
class ImNotificationRouter {
  const ImNotificationRouter({
    required this.resolveChat,
    required this.openChat,
  });

  final Future<ChatEntryArgs?> Function(String chatId) resolveChat;
  final void Function(ChatEntryArgs args) openChat;

  Future<bool> routeMessage(ImMessageNotificationEvent event) async {
    final args = await resolveChat(event.chatId);
    if (args == null) return false;
    openChat(args);
    return true;
  }
}
