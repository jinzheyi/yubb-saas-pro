import 'package:shengyu_ui_admin_im/features/im/chat/application/results/send_message_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';

class SendUploadedMessageUseCase {
  const SendUploadedMessageUseCase(this._messageRepository);

  final MessageRepository _messageRepository;

  Future<SendMessageResult> sendImage({
    required UploadResult upload,
    required String clientMessageId,
    required int width,
    required int height,
  }) {
    return _messageRepository.sendImageMessage(
      chatId: upload.scope.requireChatId(),
      fileId: upload.file.fileId,
      url: upload.file.url,
      thumbnailUrl: upload.file.url,
      width: width,
      height: height,
      size: upload.file.size,
      clientMessageId: clientMessageId,
      receiverId: upload.scope.kind == UploadScopeKind.directChat
          ? upload.scope.requireTargetUserId()
          : null,
      groupId: upload.scope.kind == UploadScopeKind.groupChat
          ? upload.scope.groupId
          : null,
    );
  }

  Future<SendMessageResult> sendVideo({
    required UploadResult upload,
    required String clientMessageId,
    required int duration,
    required int width,
    required int height,
  }) {
    return _messageRepository.sendVideoMessage(
      chatId: upload.scope.requireChatId(),
      fileId: upload.file.fileId,
      url: upload.file.url,
      thumbFileId: upload.file.thumbFileId,
      thumbnailUrl: upload.file.thumbUrl ?? '',
      duration: duration,
      width: width,
      height: height,
      size: upload.file.size,
      clientMessageId: clientMessageId,
      receiverId: upload.scope.kind == UploadScopeKind.directChat
          ? upload.scope.requireTargetUserId()
          : null,
      groupId: upload.scope.kind == UploadScopeKind.groupChat
          ? upload.scope.groupId
          : null,
    );
  }

  Future<SendMessageResult> sendFile({
    required UploadResult upload,
    required String clientMessageId,
  }) {
    return _messageRepository.sendFileMessage(
      chatId: upload.scope.requireChatId(),
      fileId: upload.file.fileId,
      url: upload.file.url,
      fileName: upload.file.name,
      size: upload.file.size,
      fileType: upload.file.mimeType,
      clientMessageId: clientMessageId,
      receiverId: upload.scope.kind == UploadScopeKind.directChat
          ? upload.scope.requireTargetUserId()
          : null,
      groupId: upload.scope.kind == UploadScopeKind.groupChat
          ? upload.scope.groupId
          : null,
    );
  }
}
