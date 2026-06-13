import 'dart:typed_data';

import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/multipart_upload_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/file/domain/repositories/multipart_upload_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/file/infrastructure/datasources/multipart_upload_data_source.dart';

/// 分片上传仓库实现
class MultipartUploadRepositoryImpl implements MultipartUploadRepository {
  MultipartUploadRepositoryImpl(this._dataSource);

  final MultipartUploadDataSource _dataSource;

  @override
  Future<MultipartUploadInitResult> initMultipartUpload({
    required String name,
    required int size,
    String? type,
    String? directory,
    int? chunkSize,
  }) {
    return _dataSource.initMultipartUpload(
      name: name,
      size: size,
      type: type,
      directory: directory,
      chunkSize: chunkSize,
    );
  }

  @override
  Future<MultipartChunkResult> uploadChunk({
    required String uploadId,
    required int chunkNumber,
    required Uint8List chunkData,
    void Function(int, int)? onProgress,
  }) {
    return _dataSource.uploadChunk(
      uploadId: uploadId,
      chunkNumber: chunkNumber,
      chunkData: chunkData,
      onProgress: onProgress,
    );
  }

  @override
  Future<MergeResult> completeMultipartUpload({required String uploadId}) {
    return _dataSource.completeMultipartUpload(uploadId: uploadId);
  }

  @override
  Future<void> abortMultipartUpload({required String uploadId}) {
    return _dataSource.abortMultipartUpload(uploadId: uploadId);
  }

  @override
  Future<UploadStatusResult> getUploadStatus({required String uploadId}) {
    return _dataSource.getUploadStatus(uploadId: uploadId);
  }
}
