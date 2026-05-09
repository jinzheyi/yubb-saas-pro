import 'dart:typed_data';

import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';

class ChatUploadInput {
  const ChatUploadInput({
    required this.purpose,
    required this.scope,
    required this.localUri,
    required this.displayName,
    required this.mimeType,
    required this.fileSize,
    this.bytes,
  });

  final UploadPurpose purpose;
  final UploadScope scope;
  final String localUri;
  final String displayName;
  final String mimeType;
  final int fileSize;
  final Uint8List? bytes;
}
