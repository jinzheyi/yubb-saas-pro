import 'dart:io';

import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/datasources/file_http_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/presigned_url_dto.dart';

/// 预签名 URL 直传结果
class PresignedUploadResult {
  const PresignedUploadResult({
    required this.fileId,
    required this.url,
    required this.configId,
    required this.path,
  });

  final int fileId;
  final String url;
  final int configId;
  final String path;
}

/// 预签名 URL 不支持异常
///
/// 当后端存储不支持预签名 URL 时抛出，前端应降级到普通上传方式
class PresignedUrlNotSupportedException implements Exception {
  const PresignedUrlNotSupportedException(this.message);
  final String message;

  @override
  String toString() => 'PresignedUrlNotSupportedException: $message';
}

/// 预签名 URL 直传用例
///
/// 实现流程：
/// 1. 请求预签名上传 URL
/// 2. 直传文件到 S3/MinIO
/// 3. 创建文件记录，获取 fileId
class PresignedUrlUploadUseCase {
  PresignedUrlUploadUseCase(this._fileHttpDataSource);

  final FileHttpDataSource _fileHttpDataSource;

  /// 执行预签名 URL 直传
  ///
  /// [file] 待上传的文件，[directory] 存储目录，
  /// [fileName] 文件名，[mimeType] MIME 类型，
  /// [onProgress] 整体上传进度回调（0.0 ~ 1.0）。
  ///
  /// 返回上传结果，包含 fileId、url 等信息。
  /// 如果后端不支持预签名 URL（返回空 uploadUrl），则抛出 [PresignedUrlNotSupportedException]。
  Future<PresignedUploadResult> execute({
    required File file,
    required String directory,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    // 1. 请求预签名上传 URL
    final presignedInfo = await _fileHttpDataSource.getPresignedUploadUrl(
      name: fileName,
      directory: directory,
    );

    // 检查后端是否支持预签名 URL
    if (presignedInfo.uploadUrl.isEmpty) {
      throw PresignedUrlNotSupportedException(
        '后端不支持预签名 URL 上传，请降级到普通上传',
      );
    }

    // 2. 直传文件到 S3/MinIO
    await _fileHttpDataSource.uploadToPresignedUrl(
      file: file,
      uploadUrl: presignedInfo.uploadUrl,
      contentType: mimeType,
      onProgress: (sent, total) {
        if (total > 0) {
          onProgress?.call(sent / total);
        }
      },
    );

    // 3. 创建文件记录，获取 fileId
    final fileSize = await file.length();
    final fileId = await _fileHttpDataSource.createFileRecord(
      request: FileCreateRequestDto(
        configId: presignedInfo.configId,
        path: presignedInfo.path,
        name: fileName,
        url: presignedInfo.url,
        type: mimeType,
        size: fileSize,
      ),
    );

    onProgress?.call(1.0);

    return PresignedUploadResult(
      fileId: fileId,
      url: presignedInfo.url,
      configId: presignedInfo.configId,
      path: presignedInfo.path,
    );
  }
}
