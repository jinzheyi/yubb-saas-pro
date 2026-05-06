class StickerPayload {
  const StickerPayload({
    required this.stickerId,
    required this.fileId,
    required this.url,
    this.thumbFileId,
    this.thumbUrl,
    this.md5,
    this.width = 0,
    this.height = 0,
    this.mimeType,
  });

  final String stickerId;
  final String fileId;
  final String url;
  final String? thumbFileId;
  final String? thumbUrl;
  final String? md5;
  final int width;
  final int height;
  final String? mimeType;
}
