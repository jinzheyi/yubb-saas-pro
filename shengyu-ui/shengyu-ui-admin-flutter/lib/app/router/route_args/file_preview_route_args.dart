class FilePreviewRouteArgs {
  const FilePreviewRouteArgs({
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.fileUrl,
    this.messageId,
    this.chatId,
    this.sourceType,
  });

  final String fileId;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? fileUrl;
  final String? messageId;
  final String? chatId;
  final String? sourceType;
}
