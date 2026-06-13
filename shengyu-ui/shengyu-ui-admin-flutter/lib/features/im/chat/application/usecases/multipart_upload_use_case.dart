import 'dart:io';

import 'package:shengyu_ui_admin_im/features/im/file/domain/repositories/multipart_upload_repository.dart';

/// 分片上传用例
///
/// 负责处理大文件的分片上传流程：初始化 -> 并发上传分片 -> 合并 -> 返回 URL。
class MultipartUploadUseCase {
  MultipartUploadUseCase(this._repository);

  final MultipartUploadRepository _repository;

  /// 默认分片大小：5MB
  static const int _defaultChunkSize = 5 * 1024 * 1024;

  /// 最大并发数
  static const int _maxConcurrency = 3;

  /// 执行分片上传
  ///
  /// [file] 待上传的文件，[directory] 存储目录（可选），
  /// [onProgress] 整体上传进度回调（0.0 ~ 1.0）。
  ///
  /// 返回上传完成后的文件 URL。
  Future<String> execute({
    required File file,
    String? directory,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();
    final mimeType = _guessMimeType(fileName);

    // 1. 初始化分片上传
    final initResult = await _repository.initMultipartUpload(
      name: fileName,
      size: fileSize,
      type: mimeType,
      directory: directory,
    );

    final uploadId = initResult.uploadId;
    final chunkSize = initResult.chunkSize > 0 ? initResult.chunkSize : _defaultChunkSize;
    final totalChunks = initResult.totalChunks > 0 ? initResult.totalChunks : _calcChunks(fileSize, chunkSize);

    try {
      // 2. 按分片大小读取文件，并发上传多个分片
      await _uploadAllChunks(
        file: file,
        uploadId: uploadId,
        totalChunks: totalChunks,
        chunkSize: chunkSize,
        fileSize: fileSize,
        onProgress: onProgress,
      );

      // 3. 调用合并接口
      final mergeResult = await _repository.completeMultipartUpload(uploadId: uploadId);

      onProgress?.call(1.0);
      return mergeResult.url;
    } catch (e) {
      // 上传异常时，尝试取消分片上传
      await _repository.abortMultipartUpload(uploadId: uploadId);
      rethrow;
    }
  }

  /// 计算总分片数
  int _calcChunks(int fileSize, int chunkSize) {
    return (fileSize + chunkSize - 1) ~/ chunkSize;
  }

  /// 上传所有分片（并发控制）
  Future<void> _uploadAllChunks({
    required File file,
    required String uploadId,
    required int totalChunks,
    required int chunkSize,
    required int fileSize,
    void Function(double progress)? onProgress,
  }) async {
    final raf = await file.open();
    try {
      // 使用分批并发的方式上传分片
      int uploadedCount = 0;

      for (int startChunk = 1; startChunk <= totalChunks; startChunk += _maxConcurrency) {
        final endChunk = (startChunk + _maxConcurrency - 1).clamp(1, totalChunks);

        final futures = <Future<void>>[];
        for (int chunkNumber = startChunk; chunkNumber <= endChunk; chunkNumber++) {
          futures.add(_uploadSingleChunk(
            raf: raf,
            uploadId: uploadId,
            chunkNumber: chunkNumber,
            chunkSize: chunkSize,
            fileSize: fileSize,
            onChunkComplete: () {
              uploadedCount++;
              onProgress?.call(uploadedCount / totalChunks);
            },
          ));
        }

        await Future.wait(futures);
      }
    } finally {
      await raf.close();
    }
  }

  /// 上传单个分片
  Future<void> _uploadSingleChunk({
    required RandomAccessFile raf,
    required String uploadId,
    required int chunkNumber,
    required int chunkSize,
    required int fileSize,
    required void Function() onChunkComplete,
  }) async {
    final offset = (chunkNumber - 1) * chunkSize;
    final length = (chunkNumber * chunkSize > fileSize)
        ? fileSize - offset
        : chunkSize;

    await raf.setPosition(offset);
    final chunkData = await raf.read(length);

    await _repository.uploadChunk(
      uploadId: uploadId,
      chunkNumber: chunkNumber,
      chunkData: chunkData,
      onProgress: (sent, total) {
        // 分片级进度，暂不上报，由整体进度控制
      },
    );

    onChunkComplete();
  }

  /// 根据文件名猜测 MIME 类型
  String _guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
