/// 分片上传响应 DTO
class ChunkUploadRespDto {
  const ChunkUploadRespDto({
    required this.uploadId,
    required this.chunkNumber,
    required this.etag,
    required this.uploadedChunks,
    required this.totalChunks,
    required this.completed,
  });

  final String uploadId;
  final int chunkNumber;
  final String etag;
  final int uploadedChunks;
  final int totalChunks;
  final bool completed;

  factory ChunkUploadRespDto.fromJson(Map<String, dynamic> json) {
    return ChunkUploadRespDto(
      uploadId: json['uploadId']?.toString() ?? '',
      chunkNumber: _toInt(json['chunkNumber']),
      etag: json['etag']?.toString() ?? '',
      uploadedChunks: _toInt(json['uploadedChunks']),
      totalChunks: _toInt(json['totalChunks']),
      completed: json['completed'] == true,
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
