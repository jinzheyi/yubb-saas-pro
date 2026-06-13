import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/chunk_upload_init_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/chunk_upload_resp_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/chunk_merge_resp_dto.dart';

/// 分片上传初始化请求 DTO
class MultipartUploadInitDto {
  const MultipartUploadInitDto({
    required this.name,
    required this.size,
    this.type,
    this.directory,
    this.chunkSize,
  });

  final String name;
  final int size;
  final String? type;
  final String? directory;
  final int? chunkSize;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'size': size,
      if (type != null) 'type': type,
      if (directory != null) 'directory': directory,
      if (chunkSize != null) 'chunkSize': chunkSize,
    };
  }

  factory MultipartUploadInitDto.fromJson(Map<String, dynamic> json) {
    return MultipartUploadInitDto(
      name: json['name']?.toString() ?? '',
      size: _toInt(json['size']),
      type: json['type']?.toString(),
      directory: json['directory']?.toString(),
      chunkSize: _toIntOrNull(json['chunkSize']),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  static int? _toIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}');
  }
}

/// 分片上传完成请求 DTO
class MultipartUploadCompleteDto {
  const MultipartUploadCompleteDto({
    required this.uploadId,
  });

  final String uploadId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uploadId': uploadId,
    };
  }
}

/// 分片上传初始化结果（直接透传 ChunkUploadInitDto）
typedef MultipartUploadInitResult = ChunkUploadInitDto;

/// 分片上传结果（直接透传 ChunkUploadRespDto）
typedef MultipartChunkResult = ChunkUploadRespDto;

/// 分片合并结果（直接透传 ChunkMergeRespDto）
typedef MergeResult = ChunkMergeRespDto;

/// 分片上传状态结果
class UploadStatusResult {
  const UploadStatusResult({
    required this.uploadId,
    required this.totalChunks,
    required this.uploadedChunks,
    required this.completed,
  });

  final String uploadId;
  final int totalChunks;
  final int uploadedChunks;
  final bool completed;

  factory UploadStatusResult.fromJson(Map<String, dynamic> json) {
    return UploadStatusResult(
      uploadId: json['uploadId']?.toString() ?? '',
      totalChunks: _toInt(json['totalChunks']),
      uploadedChunks: _toInt(json['uploadedChunks']),
      completed: json['completed'] == true,
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
