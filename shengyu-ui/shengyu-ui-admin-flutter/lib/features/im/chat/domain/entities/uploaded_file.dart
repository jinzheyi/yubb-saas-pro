class UploadedFile {
  const UploadedFile({
    required this.fileId,
    required this.url,
    required this.name,
    required this.size,
    required this.mimeType,
    this.md5,
    this.thumbFileId,
  });

  final String fileId;
  final String url;
  final String name;
  final int size;
  final String mimeType;
  final String? md5;
  final String? thumbFileId;
}
