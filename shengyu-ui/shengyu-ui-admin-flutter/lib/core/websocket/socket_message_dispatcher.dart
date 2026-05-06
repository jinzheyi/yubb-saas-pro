import 'dart:async';

import 'package:shengyu_ui_admin_im/core/websocket/socket_event.dart';

class SocketMessageDispatcher {
  final StreamController<ImSocketEvent> _controller =
      StreamController<ImSocketEvent>.broadcast();

  Stream<ImSocketEvent> get stream => _controller.stream;

  void dispatch(ImSocketEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
