/// The only notification routing fields accepted from a transport payload.
/// Display strings deliberately do not cross this boundary.
sealed class ImNotificationEvent {
  const ImNotificationEvent({
    required this.eventId,
    required this.tenantId,
    required this.sentAt,
  });

  final String eventId;
  final String tenantId;
  final int sentAt;

  static ImNotificationEvent? fromPayload(Map<String, Object?> payload) {
    final kind = payload['kind']?.toString();
    final version = payload['v']?.toString();
    // A missing version is not a v1 payload. Accepting it would make a later
    // server protocol change silently routable by old clients.
    if (version != '1') {
      return null;
    }
    final eventId =
        payload['eventId']?.toString() ?? payload['messageId']?.toString();
    final tenantId = payload['tenantId']?.toString();
    final sentAt =
        int.tryParse(payload['sentAt']?.toString() ?? '') ??
        DateTime.now().millisecondsSinceEpoch;
    if (eventId == null ||
        eventId.isEmpty ||
        tenantId == null ||
        tenantId.isEmpty) {
      return null;
    }
    if (kind == 'call_invite') {
      final callId = payload['callId']?.toString();
      final eventVersion = payload['eventVersion']?.toString();
      if (callId == null || callId.isEmpty || eventVersion == null || eventVersion.isEmpty) {
        return null;
      }
      return ImCallNotificationEvent(
        eventId: eventId,
        tenantId: tenantId,
        sentAt: sentAt,
        callId: callId,
        eventVersion: eventVersion,
      );
    }
    final chatId = payload['chatId']?.toString();
    if (chatId == null || chatId.isEmpty) return null;
    return ImMessageNotificationEvent(
      eventId: eventId,
      tenantId: tenantId,
      sentAt: sentAt,
      chatId: chatId,
      messageId: payload['messageId']?.toString() ?? eventId,
      recipientUserId: payload['recipientUserId']?.toString(),
      isMention:
          payload['isMention'] == true ||
          payload['isMention']?.toString() == 'true',
    );
  }
}

final class ImMessageNotificationEvent extends ImNotificationEvent {
  const ImMessageNotificationEvent({
    required super.eventId,
    required super.tenantId,
    required super.sentAt,
    required this.chatId,
    required this.messageId,
    this.recipientUserId,
    this.isMention = false,
  });
  final String chatId;
  final String messageId;
  final String? recipientUserId;
  final bool isMention;
}

final class ImCallNotificationEvent extends ImNotificationEvent {
  const ImCallNotificationEvent({
    required super.eventId,
    required super.tenantId,
    required super.sentAt,
    required this.callId,
    required this.eventVersion,
  });
  final String callId;
  final String eventVersion;
}
