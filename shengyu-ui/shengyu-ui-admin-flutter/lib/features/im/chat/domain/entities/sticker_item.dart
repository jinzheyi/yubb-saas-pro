class StickerItem {
  const StickerItem({
    required this.stickerId,
    required this.url,
    this.thumbUrl,
    this.fileId,
    this.thumbFileId,
    this.name,
    this.md5,
    this.width,
    this.height,
    this.mimeType,
    this.sortNo,
    this.duplicated = false,
  });

  final String stickerId;
  final String url;
  final String? thumbUrl;
  final String? fileId;
  final String? thumbFileId;
  final String? name;
  final String? md5;
  final int? width;
  final int? height;
  final String? mimeType;
  final int? sortNo;
  final bool duplicated;
}
