/// 分片上传初始化响应 DTO
class ChunkUploadInitDto {
  const ChunkUploadInitDto({
    required this.uploadId,
    required this.chunkSize,
    required this.totalChunks,
  });

  final String uploadId;
  final int chunkSize;
  final int totalChunks;

  factory ChunkUploadInitDto.fromJson(Map<String, dynamic> json) {
    return ChunkUploadInitDto(
      uploadId: json['uploadId']?.toString() ?? '',
      chunkSize: _toInt(json['chunkSize']),
      totalChunks: _toInt(json['totalChunks']),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
