import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
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
    final formData = FormData.fromMap({
      'directory': request.directory,
      request.fieldName: await MultipartFile.fromFile(
        request.localUri,
        filename: request.fileName,
      ),
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
