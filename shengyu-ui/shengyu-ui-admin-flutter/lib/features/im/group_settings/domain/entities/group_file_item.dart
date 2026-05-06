class GroupFileItem {
  const GroupFileItem({
    required this.id,
    required this.fileId,
    required this.messageId,
    required this.fileName,
    required this.fileSize,
    required this.fileUrl,
    required this.mediaType,
    required this.uploadedAt,
    required this.uploaderName,
    required this.mimeType,
  });

  final String id;
  final String fileId;
  final String messageId;
  final String fileName;
  final int fileSize;
  final String fileUrl;
  final String mediaType;
  final DateTime? uploadedAt;
  final String uploaderName;
  final String mimeType;
}
