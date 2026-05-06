import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_message_type.dart';
import 'package:uuid/uuid.dart';

class SocketAuthPayloadBuilder {
  SocketAuthPayloadBuilder() : _uuid = const Uuid();

  final Uuid _uuid;

  Map<String, Object?> buildProbeEnvelope(AuthSession session) {
    return {
      'header': {
        'messageId': _uuid.v4(),
        'messageType': SocketMessageType.probe,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      'body': {
        'version': 1,
        'codec': 'json',
        'features': {'ack': true},
        'client': {
          'deviceType': session.deviceType,
          'deviceId': session.deviceId,
          'deviceName': session.deviceName,
          'clientVersion': session.clientVersion,
        },
      },
    };
  }

  Map<String, Object?> buildAuthEnvelope(AuthSession session) {
    return {
      'header': {
        'messageId': _uuid.v4(),
        'messageType': SocketMessageType.authReq,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      'body': {
        'accessToken': session.accessToken,
        'deviceType': session.deviceType,
        'deviceId': session.deviceId,
        'deviceName': session.deviceName,
        'clientVersion': session.clientVersion,
        'locale': session.locale,
      },
    };
  }

  Map<String, Object?> buildHeartbeatEnvelope() {
    return {
      'header': {
        'messageId': _uuid.v4(),
        'messageType': SocketMessageType.heartbeatReq,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      'body': const <String, Object?>{},
    };
  }
}
