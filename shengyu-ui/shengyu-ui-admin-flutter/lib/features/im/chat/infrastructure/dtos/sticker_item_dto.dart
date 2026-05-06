import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_item.dart';

class StickerItemDto {
  const StickerItemDto({
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

  factory StickerItemDto.fromJson(Map<String, dynamic> json) {
    return StickerItemDto(
      stickerId: json['stickerId']?.toString() ?? '',
      url: json['url']?.toString() ?? json['thumbUrl']?.toString() ?? '',
      thumbUrl: json['thumbUrl']?.toString(),
      fileId: json['fileId']?.toString(),
      thumbFileId: json['thumbFileId']?.toString(),
      name: json['name']?.toString(),
      md5: json['md5']?.toString(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      mimeType: json['mimeType']?.toString(),
      sortNo: (json['sortNo'] as num?)?.toInt(),
      duplicated: json['duplicated'] == true,
    );
  }

  StickerItem toEntity() {
    return StickerItem(
      stickerId: stickerId,
      url: url,
      thumbUrl: thumbUrl,
      fileId: fileId,
      thumbFileId: thumbFileId,
      name: name,
      md5: md5,
      width: width,
      height: height,
      mimeType: mimeType,
      sortNo: sortNo,
      duplicated: duplicated,
    );
  }
}
