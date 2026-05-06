import 'package:shengyu_ui_admin_im/core/websocket/socket_header.dart';

class SocketEnvelope {
  const SocketEnvelope({
    required this.header,
    this.body = const <String, Object?>{},
  });

  final SocketHeader header;
  final Map<String, Object?> body;

  factory SocketEnvelope.fromJson(Map<String, dynamic> json) {
    return SocketEnvelope(
      header: SocketHeader.fromJson(
        json['header'] as Map<String, dynamic>? ?? const {},
      ),
      body: Map<String, Object?>.from(
        json['body'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
