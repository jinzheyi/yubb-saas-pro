class GroupFileItemDto {
  const GroupFileItemDto({
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

  factory GroupFileItemDto.fromJson(Map<String, dynamic> json) {
    return GroupFileItemDto(
      id: '${json['id'] ?? json['fileRecordId'] ?? json['fileId'] ?? ''}',
      fileId: '${json['fileId'] ?? json['id'] ?? ''}',
      messageId: '${json['messageId'] ?? json['msgId'] ?? ''}',
      fileName: '${json['fileName'] ?? json['name'] ?? ''}',
      fileSize: _parseInt(json['fileSize'] ?? json['size']) ?? 0,
      fileUrl: '${json['fileUrl'] ?? json['url'] ?? json['downloadUrl'] ?? ''}',
      mediaType:
          '${json['mediaType'] ?? json['type'] ?? json['fileCategory'] ?? ''}',
      uploadedAt: _parseDateTime(
        json['uploadTime'] ?? json['createdAt'] ?? json['createTime'],
      ),
      uploaderName:
          '${json['uploaderName'] ?? json['createByName'] ?? json['createByNickname'] ?? ''}',
      mimeType:
          '${json['fileType'] ?? json['mimeType'] ?? json['contentType'] ?? ''}',
    );
  }

  static int? _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  static DateTime? _parseDateTime(Object? raw) {
    final value = _parseInt(raw);
    if (value != null && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final normalized = text.contains(' ') ? text.replaceFirst(' ', 'T') : text;
    return DateTime.tryParse(normalized);
  }
}
