/// 聊天文件上传大小超限异常。
///
/// 当用户选择的文件超过客户端允许的最大上传大小时抛出，
/// 用于在上传发起前拦截并展示友好提示，避免发送到后端后才报错。
class ChatFileTooLargeException implements Exception {
  const ChatFileTooLargeException({
    required this.fileName,
    required this.fileSize,
    required this.maxSize,
  });

  final String fileName;
  final int fileSize;
  final int maxSize;

  @override
  String toString() =>
      'ChatFileTooLargeException: $fileName ($fileSize bytes) exceeds limit ($maxSize bytes)';
}
