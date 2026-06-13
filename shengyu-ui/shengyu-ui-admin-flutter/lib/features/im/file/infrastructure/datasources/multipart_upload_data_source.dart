import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/chunk_upload_init_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/multipart_upload_dto.dart';

/// 分片上传数据源
///
/// 负责与后端分片上传接口交互，包括初始化、上传分片、合并、取消、查询进度。
class MultipartUploadDataSource {
  MultipartUploadDataSource({required Dio uploadDio}) : _uploadDio = uploadDio;

  /// 上传专用 Dio，避免大文件上传阻塞聊天消息请求
  final Dio _uploadDio;

  /// 初始化分片上传
  ///
  /// [name] 文件名，[size] 文件大小（字节），[type] MIME 类型，
  /// [directory] 存储目录，[chunkSize] 分片大小（字节，可选）。
  Future<MultipartUploadInitResult> initMultipartUpload({
    required String name,
    required int size,
    String? type,
    String? directory,
    int? chunkSize,
  }) async {
    final response = await _uploadDio.post<Map<String, dynamic>>(
      AppConfig.fileMultipartUploadInitPath,
      data: MultipartUploadInitDto(
        name: name,
        size: size,
        type: type,
        directory: directory,
        chunkSize: chunkSize,
      ).toJson(),
    );

    final result = ApiResult.fromJson<ChunkUploadInitDto>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) {
        return ChunkUploadInitDto.fromJson(
          raw as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
      },
    );
    return result.requireData();
  }

  /// 上传单个分片
  ///
  /// [uploadId] 上传任务 ID，[chunkNumber] 分片序号（从 1 开始），
  /// [chunkData] 分片数据，[onProgress] 上传进度回调（已发送字节数, 总字节数）。
  Future<MultipartChunkResult> uploadChunk({
    required String uploadId,
    required int chunkNumber,
    required Uint8List chunkData,
    void Function(int, int)? onProgress,
  }) async {
    // 字节数组上传时无法获取分片进度，手动模拟端点回调
    if (onProgress != null) {
      onProgress(0, 100);
    }

    final formData = FormData.fromMap({
      'uploadId': uploadId,
      'chunkNumber': chunkNumber,
      'chunk': MultipartFile.fromBytes(
        chunkData,
        filename: 'chunk_$chunkNumber',
      ),
    });

    final response = await _uploadDio.post<Map<String, dynamic>>(
      AppConfig.fileMultipartUploadChunkPath,
      data: formData,
      onSendProgress: onProgress,
    );

    // 手动模拟端点回调
    if (onProgress != null) {
      onProgress(100, 100);
    }

    final result = ApiResult.fromJson<MultipartChunkResult>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) {
        return MultipartChunkResult.fromJson(
          raw as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
      },
    );
    return result.requireData();
  }

  /// 完成分片合并
  ///
  /// [uploadId] 上传任务 ID。
  Future<MergeResult> completeMultipartUpload({
    required String uploadId,
  }) async {
    final response = await _uploadDio.post<Map<String, dynamic>>(
      AppConfig.fileMultipartUploadMergePath,
      data: MultipartUploadCompleteDto(uploadId: uploadId).toJson(),
    );

    final result = ApiResult.fromJson<MergeResult>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) {
        return MergeResult.fromJson(
          raw as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
      },
    );
    return result.requireData();
  }

  /// 取消分片上传
  ///
  /// [uploadId] 上传任务 ID。
  Future<void> abortMultipartUpload({required String uploadId}) async {
    final response = await _uploadDio.post<Map<String, dynamic>>(
      AppConfig.fileMultipartUploadAbortPath,
      queryParameters: {'uploadId': uploadId},
    );

    final result = ApiResult.fromJson<bool>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) => raw == true,
    );
    result.requireData();
  }

  /// 查询上传进度
  ///
  /// [uploadId] 上传任务 ID。
  Future<UploadStatusResult> getUploadStatus({required String uploadId}) async {
    final response = await _uploadDio.get<Map<String, dynamic>>(
      AppConfig.fileMultipartUploadStatusPath,
      queryParameters: {'uploadId': uploadId},
    );

    final result = ApiResult.fromJson<UploadStatusResult>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) {
        return UploadStatusResult.fromJson(
          raw as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
      },
    );
    return result.requireData();
  }
}
