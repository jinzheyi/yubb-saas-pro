import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_envelope.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_event_types.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_header.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_inbound_mapper.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_type.dart';

void main() {
  const mapper = SocketInboundMapper();

  test('maps renew suggest to token renew suggested event', () {
    final events = mapper.map(
      const SocketEnvelope(
        header: SocketHeader(
          messageId: 'sys-1',
          messageType: SocketMessageType.systemNotify,
        ),
        body: <String, Object?>{'action': 'RENEW_SUGGEST'},
      ),
    );

    expect(events, hasLength(1));
    expect(events.single.type, SocketEventTypes.tokenRenewSuggested);
  });

  test('maps business message to message and conversation events', () {
    final events = mapper.map(
      const SocketEnvelope(
        header: SocketHeader(
          messageId: 'm-1',
          messageType: SocketMessageType.text,
          chatId: 'chat-1',
          senderId: 'user-2',
          timestamp: '2026-04-30T10:00:00Z',
          sequence: '100',
          extra: '{"clientMessageId":"c-1","rev":"2"}',
        ),
        body: <String, Object?>{'content': 'hello'},
      ),
    );

    expect(events, hasLength(2));
    expect(events.first.type, SocketEventTypes.messageReceived);
    expect(events.first.payload['chatId'], 'chat-1');
    expect(events.first.payload['messageId'], 'm-1');
    expect(events.first.payload['clientMessageId'], 'c-1');
    expect(events.first.payload['rev'], '2');
    expect(events.first.payload['type'], 'text');
    expect(events.last.type, SocketEventTypes.conversationHint);
    expect(events.last.chatId, 'chat-1');
  });

  test('maps call invite from system notify header extra', () {
    final events = mapper.map(
      const SocketEnvelope(
        header: SocketHeader(
          messageId: 'call-event-1',
          messageType: SocketMessageType.systemNotify,
          extra:
              '{"type":"call.invite","callId":"call-1",'
              '"callSessionId":"call-1","callType":"audio",'
              '"callerId":"user-a","chatId":"chat-1",'
              '"callerProfile":{"displayName":"Alice"},'
              '"eventVersion":1}',
        ),
        body: <String, Object?>{'content': ''},
      ),
    );

    expect(events, hasLength(1));
    expect(events.single.type, SocketEventTypes.systemNotify);
    expect(events.single.payload['type'], 'call.invite');
    expect(events.single.payload['callSessionId'], 'call-1');
    expect(events.single.payload['chatId'], 'chat-1');
    expect(events.single.payload['eventVersion'], 1);
    expect(
      (events.single.payload['callerProfile'] as Map)['displayName'],
      'Alice',
    );
  });
}
