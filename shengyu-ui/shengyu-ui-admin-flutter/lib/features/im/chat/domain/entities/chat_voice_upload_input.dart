import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';

class ChatVoiceUploadInput {
  const ChatVoiceUploadInput({
    required this.scope,
    required this.localUri,
    required this.displayName,
    required this.mimeType,
    required this.fileSize,
    required this.duration,
    required this.durationMs,
    this.md5,
  });

  final UploadScope scope;
  final String localUri;
  final String displayName;
  final String mimeType;
  final int fileSize;
  final int duration;
  final int durationMs;
  final String? md5;
}
