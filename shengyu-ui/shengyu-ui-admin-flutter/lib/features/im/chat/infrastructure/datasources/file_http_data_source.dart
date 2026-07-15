import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/platform/local_file_size_loader.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/presigned_url_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/upload_and_create_file_response_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/upload_request_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/infrastructure/dtos/file_open_strategy_response_dto.dart';

class FileHttpDataSource {
  FileHttpDataSource({required this.dio, Dio? uploadDio})
    // 上传专用 Dio，未传入时降级使用普通 dio
    : _uploadDio = uploadDio ?? dio;

  /// 普通请求 Dio（文件预览、获取签名 URL 等非上传操作）
  final Dio dio;

  /// 上传专用 Dio，避免大文件上传阻塞聊天消息请求
  final Dio _uploadDio;

  /// 上传文件并创建记录。
  ///
  /// [onProgress] 上传进度回调，参数为已发送字节数和总字节数（0~100 百分比）。
  /// 注意：当请求 [bytes] 上传时，Dio 无法准确获取 sent 进度，
  /// 此时会通过 [onProgress] 回调 0 和 100 两个端点值。
  Future<UploadAndCreateFileResponseDto> uploadAndCreateFile({
    required UploadRequestDto request,
    void Function(int sent, int total)? onProgress,
  }) async {
    await _validateMaxSize(request);
    final isBytesUpload = request.bytes != null;
    final multipart = isBytesUpload
        ? MultipartFile.fromBytes(request.bytes!, filename: request.fileName)
        : await MultipartFile.fromFile(
            request.localUri,
            filename: request.fileName,
          );
    final formData = FormData.fromMap({
      'directory': request.directory,
      request.fieldName: multipart,
    });

    // 字节数组上传时无法获取分片进度，手动模拟端点回调
    if (isBytesUpload && onProgress != null) {
      onProgress(0, 100);
    }

    final response = await _uploadDio.post<Map<String, dynamic>>(
      AppConfig.fileUploadAndReturnIdPath,
      data: formData,
      onSendProgress: isBytesUpload
          ? null
          : onProgress,
    );

    if (isBytesUpload && onProgress != null) {
      onProgress(100, 100);
    }

    final result = ApiResult.fromJson<UploadAndCreateFileResponseDto>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) {
        return UploadAndCreateFileResponseDto.fromJson(
          raw as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
      },
    );
    return result.requireData();
  }

  Future<void> _validateMaxSize(UploadRequestDto request) async {
    final maxSize = request.maxSize;
    if (maxSize == null || maxSize <= 0) {
      return;
    }
    final bytes = request.bytes;
    if (bytes != null) {
      if (bytes.lengthInBytes > maxSize) {
        throw StateError('file_too_large:$maxSize:${bytes.lengthInBytes}');
      }
      return;
    }
    final size = await loadLocalFileSize(request.localUri);
    if (size != null && size > maxSize) {
      throw StateError('file_too_large:$maxSize:$size');
    }
  }

  Future<FileOpenStrategyResponseDto> getFileOpenStrategy({
    required String fileId,
    int expirationSeconds = AppConfig.filePreviewExpirationSeconds,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      AppConfig.fileOpenStrategyPath,
      queryParameters: {
        'fileId': fileId,
        'expirationSeconds': expirationSeconds,
      },
    );
    final result = ApiResult.fromJson<FileOpenStrategyResponseDto>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) {
        return FileOpenStrategyResponseDto.fromJson(
          raw as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
      },
    );
    return result.requireData();
  }

  Future<Uri> getPresignedGetUrl({
    required String fileId,
    int expirationSeconds = AppConfig.filePreviewExpirationSeconds,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      AppConfig.filePresignedGetUrlPath,
      queryParameters: {
        'fileId': fileId,
        'expirationSeconds': expirationSeconds,
      },
    );
    final result = ApiResult.fromJson<Map<String, dynamic>>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) =>
          raw as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    final data = result.requireData();
    final resolvedUrl =
        data['url']?.toString() ??
        data['downloadUrl']?.toString() ??
        data['presignedUrl']?.toString() ??
        '';
    return Uri.parse(resolvedUrl);
  }

  /// 获取预签名上传 URL
  ///
  /// [name] 文件名，[directory] 存储目录。
  Future<PresignedUrlResponseDto> getPresignedUploadUrl({
    required String name,
    String? directory,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      AppConfig.filePresignedUploadUrlPath,
      queryParameters: {
        'name': name,
        if (directory != null && directory.isNotEmpty) 'directory': directory,
      },
    );
    final result = ApiResult.fromJson<PresignedUrlResponseDto>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) {
        return PresignedUrlResponseDto.fromJson(
          raw as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
      },
    );
    return result.requireData();
  }

  /// 直传文件到预签名 URL
  ///
  /// [file] 本地文件，[uploadUrl] 预签名上传 URL，
  /// [contentType] MIME 类型，[onProgress] 上传进度回调。
  Future<void> uploadToPresignedUrl({
    required File file,
    required String uploadUrl,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final fileSize = await file.length();
    await _uploadDio.put(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileSize,
        },
      ),
      onSendProgress: onProgress,
    );
  }

  /// 创建文件记录（配合预签名 URL 直传使用）
  ///
  /// 直传完成后调用此方法，在后端创建文件记录并返回 fileId。
  Future<int> createFileRecord({
    required FileCreateRequestDto request,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      AppConfig.fileCreatePath,
      data: request.toJson(),
    );
    final result = ApiResult.fromJson<int>(
      response.data ?? const <String, dynamic>{},
      dataParser: (raw) {
        if (raw is int) return raw;
        if (raw is Map<String, dynamic>) {
          return (raw['data'] as num?)?.toInt() ?? 0;
        }
        return 0;
      },
    );
    return result.requireData();
  }
}
