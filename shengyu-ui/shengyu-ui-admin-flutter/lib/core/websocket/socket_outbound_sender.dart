import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_type.dart';
import 'package:uuid/uuid.dart';

final socketOutboundSenderProvider = Provider<SocketOutboundSender>((ref) {
  return SocketOutboundSender(ref.read(imSocketClientProvider), const Uuid());
});

class SocketOutboundSender {
  SocketOutboundSender(this._socketClient, this._uuid);

  final ImSocketClient _socketClient;
  final Uuid _uuid;

  bool get canSendBusinessMessage => _socketClient.canSendBusinessMessage;

  Future<bool> sendTextIfConnected({
    required String chatId,
    required String clientMessageId,
    required String content,
  }) {
    return _socketClient.sendEnvelope({
      'header': {
        'messageId': _uuid.v4(),
        'messageType': SocketMessageType.text,
        'chatId': chatId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      'body': {
        'chatId': chatId,
        'clientMessageId': clientMessageId,
        'type': 'text',
        'content': content,
      },
    }, requireAuthenticated: true);
  }

  Future<bool> sendReadReceiptIfConnected({
    required String senderId,
    required String receiverId,
    required String tenantId,
    required List<String> messageIds,
  }) {
    final normalizedIds = messageIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != '0')
        .toList(growable: false);
    if (senderId.trim().isEmpty ||
        receiverId.trim().isEmpty ||
        tenantId.trim().isEmpty ||
        normalizedIds.isEmpty) {
      return Future.value(false);
    }
    return _socketClient.sendEnvelope({
      'header': {
        'messageId': _uuid.v4(),
        'messageType': SocketMessageType.readReceipt,
        'senderId': senderId,
        'receiverId': receiverId,
        'groupId': '0',
        'tenantId': tenantId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      'body': {
        'messageIds': normalizedIds,
      },
    }, requireAuthenticated: true);
  }

  Future<bool> sendTypingIfConnected({
    required String senderId,
    required String receiverId,
    required String groupId,
    required String tenantId,
    required String senderName,
  }) {
    if (senderId.trim().isEmpty || tenantId.trim().isEmpty) {
      return Future.value(false);
    }
    return _socketClient.sendEnvelope({
      'header': {
        'messageId': _uuid.v4(),
        'messageType': SocketMessageType.typing,
        'senderId': senderId,
        'receiverId': receiverId,
        'groupId': groupId,
        'tenantId': tenantId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      'body': {
        'senderName': senderName,
      },
    }, requireAuthenticated: true);
  }
}
