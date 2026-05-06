import 'dart:convert';

import 'package:shengyu_ui_admin_im/core/websocket/socket_envelope.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_type.dart';

class SocketInboundMapper {
  const SocketInboundMapper();

  List<ImSocketEvent> map(SocketEnvelope envelope) {
    final header = envelope.header;
    final body = envelope.body;

    switch (header.messageType) {
      case SocketMessageType.authResp:
        return _mapAuthResponse(body);
      case SocketMessageType.close:
        return _mapClose(envelope);
      case SocketMessageType.probeResp:
        return const <ImSocketEvent>[];
      case SocketMessageType.heartbeatResp:
        return const <ImSocketEvent>[];
      case SocketMessageType.systemNotify:
        return _mapSystemNotify(envelope);
      case SocketMessageType.readReceipt:
        return _mapReadReceipt(envelope);
      case SocketMessageType.typing:
        return _mapTyping(envelope);
      case SocketMessageType.recall:
        return _mapRecall(envelope);
      case SocketMessageType.badgeUpdate:
        return <ImSocketEvent>[
          ImSocketEvent(type: SocketEventTypes.badgeUpdated, payload: body),
        ];
      default:
        if (header.messageType >= 100 && header.messageType < 200) {
          return _mapBusinessMessage(envelope);
        }
        return const <ImSocketEvent>[];
    }
  }

  List<ImSocketEvent> _mapAuthResponse(Map<String, Object?> body) {
    final success = body['success'] == true;
    if (success) {
      return const <ImSocketEvent>[
        ImSocketEvent(type: SocketEventTypes.authSucceeded),
      ];
    }
    return <ImSocketEvent>[
      ImSocketEvent(type: SocketEventTypes.authFailed, payload: body),
    ];
  }

  List<ImSocketEvent> _mapClose(SocketEnvelope envelope) {
    final extra = _decodeExtra(envelope.header.extra);
    final merged = <String, Object?>{...extra, ...envelope.body};
    final action = merged['action']?.toString() ?? '';
    final message = merged['message']?.toString() ?? '';

    final events = <ImSocketEvent>[
      ImSocketEvent(
        type: SocketEventTypes.closeByServer,
        payload: {'action': action, 'message': message, ...merged},
      ),
    ];
    switch (action) {
      case 'REAUTH_REQUIRED':
        events.add(
          ImSocketEvent(
            type: SocketEventTypes.sessionReauthRequired,
            payload: {'message': message, ...merged},
          ),
        );
        break;
      case 'KICKED':
        events.add(
          ImSocketEvent(
            type: SocketEventTypes.sessionKicked,
            payload: {'message': message, ...merged},
          ),
        );
        break;
      case 'LOGOUT':
        events.add(
          ImSocketEvent(
            type: SocketEventTypes.sessionLoggedOut,
            payload: {'message': message, ...merged},
          ),
        );
        break;
      case 'REVOKED':
        events.add(
          ImSocketEvent(
            type: SocketEventTypes.sessionRevoked,
            payload: {'message': message, ...merged},
          ),
        );
        break;
      default:
        break;
    }
    return events;
  }

  List<ImSocketEvent> _mapSystemNotify(SocketEnvelope envelope) {
    final body = envelope.body;
    final extra = _decodeExtra(envelope.header.extra);
    final merged = <String, Object?>{...extra, ...body};
    final action = merged['action']?.toString() ?? '';
    if (action == 'RENEW_SUGGEST') {
      return <ImSocketEvent>[
        ImSocketEvent(
          type: SocketEventTypes.tokenRenewSuggested,
          payload: merged,
        ),
      ];
    }
    return <ImSocketEvent>[
      ImSocketEvent(
        type: SocketEventTypes.systemNotify,
        chatId: merged['chatId']?.toString() ?? envelope.header.chatId,
        messageId: merged['messageId']?.toString() ?? envelope.header.messageId,
        payload: merged,
      ),
    ];
  }

  List<ImSocketEvent> _mapReadReceipt(SocketEnvelope envelope) {
    return <ImSocketEvent>[
      ImSocketEvent(
        type: SocketEventTypes.readReceiptChanged,
        chatId: envelope.header.chatId,
        messageId:
            envelope.body['messageId']?.toString() ?? envelope.header.messageId,
        payload: {
          ...envelope.body,
          'chatId': envelope.header.chatId ?? '',
          'sequence': envelope.header.sequence ?? '',
        },
      ),
    ];
  }

  List<ImSocketEvent> _mapBusinessMessage(SocketEnvelope envelope) {
    final header = envelope.header;
    final extra = _decodeExtra(header.extra);
    final merged = <String, Object?>{
      ...extra,
      ...envelope.body,
      'messageId': envelope.body['messageId']?.toString() ?? header.messageId,
      'clientMessageId':
          envelope.body['clientMessageId']?.toString() ??
          extra['clientMessageId']?.toString() ??
          extra['reqMessageId']?.toString() ??
          '',
      'chatId': envelope.body['chatId']?.toString() ?? (header.chatId ?? ''),
      'senderId':
          envelope.body['senderId']?.toString() ?? (header.senderId ?? ''),
      'sequence':
          envelope.body['sequence']?.toString() ?? (header.sequence ?? ''),
      'rev':
          envelope.body['rev']?.toString() ?? extra['rev']?.toString() ?? '1',
      'type': _messageTypeToString(header.messageType),
      'isOutgoing': false,
      'isSelf': false,
      'status': 'delivered',
      'createdAt':
          envelope.body['createdAt']?.toString() ?? (header.timestamp ?? ''),
      'sentAt': envelope.body['sentAt']?.toString() ?? (header.timestamp ?? ''),
    };
    return <ImSocketEvent>[
      ImSocketEvent(
        type: SocketEventTypes.messageReceived,
        chatId: header.chatId,
        messageId: header.messageId,
        payload: merged,
      ),
      if (header.chatId != null && header.chatId!.isNotEmpty)
        ImSocketEvent(
          type: SocketEventTypes.conversationHint,
          chatId: header.chatId,
          payload: {'messageId': header.messageId},
        ),
    ];
  }

  List<ImSocketEvent> _mapTyping(SocketEnvelope envelope) {
    final header = envelope.header;
    return <ImSocketEvent>[
      ImSocketEvent(
        type: SocketEventTypes.typingReceived,
        chatId: header.chatId,
        messageId: header.messageId,
        payload: {
          ...envelope.body,
          'chatId': header.chatId ?? '',
          'senderId': header.senderId ?? '',
          'receiverId': header.receiverId ?? '',
          'groupId': header.groupId ?? '',
          'tenantId': header.tenantId ?? '',
        },
      ),
    ];
  }

  List<ImSocketEvent> _mapRecall(SocketEnvelope envelope) {
    final header = envelope.header;
    final extra = _decodeExtra(header.extra);
    final merged = <String, Object?>{
      ...extra,
      ...envelope.body,
      'messageId': envelope.body['messageId']?.toString() ?? header.messageId,
      'chatId': envelope.body['chatId']?.toString() ?? (header.chatId ?? ''),
      'senderId':
          envelope.body['senderId']?.toString() ?? (header.senderId ?? ''),
      'sequence':
          envelope.body['sequence']?.toString() ?? (header.sequence ?? ''),
      'rev':
          envelope.body['rev']?.toString() ?? extra['rev']?.toString() ?? '1',
      'type': 'text',
      'status':
          envelope.body['status']?.toString() ??
          extra['status']?.toString() ??
          'recalled',
      'createdAt':
          envelope.body['createdAt']?.toString() ?? (header.timestamp ?? ''),
      'sentAt': envelope.body['sentAt']?.toString() ?? (header.timestamp ?? ''),
    };
    return <ImSocketEvent>[
      ImSocketEvent(
        type: SocketEventTypes.messageRecalled,
        chatId: header.chatId,
        messageId: merged['messageId']?.toString(),
        payload: merged,
      ),
      if (header.chatId != null && header.chatId!.isNotEmpty)
        ImSocketEvent(
          type: SocketEventTypes.conversationHint,
          chatId: header.chatId,
          payload: {'messageId': merged['messageId']},
        ),
    ];
  }

  Map<String, Object?> _decodeExtra(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <String, Object?>{};
    }
    try {
      return Map<String, Object?>.from(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  String _messageTypeToString(int type) {
    switch (type) {
      case SocketMessageType.text:
        return 'text';
      case SocketMessageType.image:
        return 'image';
      case SocketMessageType.voice:
        return 'voice';
      case SocketMessageType.video:
        return 'video';
      case SocketMessageType.file:
        return 'file';
      case SocketMessageType.location:
        return 'location';
      case SocketMessageType.quoteReply:
        return 'quoteReply';
      default:
        return 'text';
    }
  }
}
