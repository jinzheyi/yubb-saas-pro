class UploadAndCreateFileResponseDto {
  const UploadAndCreateFileResponseDto({
    required this.fileId,
    required this.url,
    required this.name,
    required this.size,
    required this.mimeType,
    this.md5,
    this.thumbFileId,
    this.thumbUrl,
  });

  final String fileId;
  final String url;
  final String name;
  final int size;
  final String mimeType;
  final String? md5;
  final String? thumbFileId;
  final String? thumbUrl;

  factory UploadAndCreateFileResponseDto.fromJson(Map<String, dynamic> json) {
    return UploadAndCreateFileResponseDto(
      fileId:
          json['fileId']?.toString() ??
          json['id']?.toString() ??
          json['fileBizId']?.toString() ??
          '',
      url:
          json['url']?.toString() ??
          json['fileUrl']?.toString() ??
          json['downloadUrl']?.toString() ??
          '',
      name:
          json['name']?.toString() ??
          json['fileName']?.toString() ??
          json['originName']?.toString() ??
          '',
      size: _toInt(json['size']) != 0
          ? _toInt(json['size'])
          : _toInt(json['fileSize']),
      mimeType:
          json['mimeType']?.toString() ??
          json['contentType']?.toString() ??
          json['fileType']?.toString() ??
          '',
      md5: json['md5']?.toString(),
      thumbFileId:
          json['thumbFileId']?.toString() ??
          json['thumbnailFileId']?.toString() ??
          json['coverFileId']?.toString(),
      thumbUrl:
          json['thumbUrl']?.toString() ??
          json['thumbnailUrl']?.toString() ??
          json['coverUrl']?.toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
