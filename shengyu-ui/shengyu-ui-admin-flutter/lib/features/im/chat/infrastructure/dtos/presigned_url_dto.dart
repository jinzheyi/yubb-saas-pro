/// 预签名 URL 响应 DTO
///
/// 对应后端 FilePresignedUrlRespVO
class PresignedUrlResponseDto {
  const PresignedUrlResponseDto({
    required this.configId,
    required this.uploadUrl,
    required this.url,
    required this.path,
  });

  final int configId;
  final String uploadUrl;
  final String url;
  final String path;

  factory PresignedUrlResponseDto.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponseDto(
      configId: (json['configId'] as num?)?.toInt() ?? 0,
      uploadUrl: json['uploadUrl']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
    );
  }
}

/// 文件创建请求 DTO
///
/// 对应后端 FileCreateReqVO
class FileCreateRequestDto {
  const FileCreateRequestDto({
    required this.configId,
    required this.path,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
  });

  final int configId;
  final String path;
  final String name;
  final String url;
  final String type;
  final int size;

  Map<String, dynamic> toJson() {
    return {
      'configId': configId,
      'path': path,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
    };
  }
}
