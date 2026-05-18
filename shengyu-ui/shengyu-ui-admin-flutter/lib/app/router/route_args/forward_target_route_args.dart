import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';

class ForwardTargetRouteArgs {
  const ForwardTargetRouteArgs({
    this.messageIds = const <String>[],
    this.initialForwardType = 1,
    this.favoriteId,
    this.contactCardPayload,
  });

  final List<String> messageIds;
  final int initialForwardType;
  final String? favoriteId;
  final ContactCardSharePayload? contactCardPayload;

  bool get isFavoriteMode {
    final value = favoriteId?.trim() ?? '';
    return value.isNotEmpty && value != '0';
  }

  bool get isContactCardMode => contactCardPayload != null;
}
