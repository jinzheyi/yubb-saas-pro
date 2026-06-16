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

  /// 通过 WebSocket 发送文本消息并等待服务端确认（ACK）。
  /// 失败时抛出异常，调用方应捕获后降级为 HTTP 发送。
  Future<String> sendTextMessage({
    required String chatId,
    required String content,
    required String clientMessageId,
    String? receiverId,
    String? groupId,
    int? messageType,
    Map<String, dynamic>? extra,
  }) async {
    final envelope = <String, Object?>{
      'header': {
        'messageId': _uuid.v4(),
        'messageType': SocketMessageType.text,
        'chatId': chatId,
        'clientMessageId': clientMessageId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        if (receiverId != null) 'receiverId': receiverId,
        if (groupId != null) 'groupId': groupId,
        if (messageType != null) 'messageType': messageType,
      },
      'body': {
        'chatId': chatId,
        'clientMessageId': clientMessageId,
        'content': content,
        'type': 'text',
        if (extra != null) 'extra': extra,
      },
    };

    final ack = await _socketClient.sendEnvelopeWithAck(
      envelope,
      clientMessageId: clientMessageId,
      requireAuthenticated: true,
    );

    // 检查 ACK 是否表示发送成功
    final header = ack['header'] as Map<String, dynamic>?;
    final success = header?['success'] == true || header?['code'] == 0;
    if (!success) {
      final errorMsg = header?['message']?.toString() ?? '发送失败';
      throw StateError('[WebSocket] send message ack error: $errorMsg');
    }

    return clientMessageId;
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
