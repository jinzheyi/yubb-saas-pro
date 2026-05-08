import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/platform/local_file_size_loader.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/upload_and_create_file_response_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/upload_request_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/infrastructure/dtos/file_open_strategy_response_dto.dart';

class FileHttpDataSource {
  FileHttpDataSource({required this.dio});

  final Dio dio;

  Future<UploadAndCreateFileResponseDto> uploadAndCreateFile({
    required UploadRequestDto request,
  }) async {
    await _validateMaxSize(request);
    final multipart = request.bytes != null
        ? MultipartFile.fromBytes(request.bytes!, filename: request.fileName)
        : await MultipartFile.fromFile(
            request.localUri,
            filename: request.fileName,
          );
    final formData = FormData.fromMap({
      'directory': request.directory,
      request.fieldName: multipart,
    });

    final response = await dio.post<Map<String, dynamic>>(
      AppConfig.fileUploadAndReturnIdPath,
      data: formData,
    );

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
}
