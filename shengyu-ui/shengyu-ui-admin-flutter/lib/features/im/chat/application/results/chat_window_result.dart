import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';

class ChatWindowResult {
  const ChatWindowResult({required this.messages, required this.viewportState});

  final List<Message> messages;
  final ChatViewportState viewportState;
}
