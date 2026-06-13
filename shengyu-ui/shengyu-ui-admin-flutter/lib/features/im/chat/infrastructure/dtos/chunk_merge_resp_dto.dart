/// 分片合并响应 DTO
class ChunkMergeRespDto {
  const ChunkMergeRespDto({
    required this.uploadId,
    required this.url,
    required this.fileId,
  });

  final String uploadId;
  final String url;
  final int fileId;

  factory ChunkMergeRespDto.fromJson(Map<String, dynamic> json) {
    return ChunkMergeRespDto(
      uploadId: json['uploadId']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      fileId: _toInt(json['fileId']),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
