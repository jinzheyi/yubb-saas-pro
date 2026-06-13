import 'dart:typed_data';

import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/multipart_upload_dto.dart';

/// 分片上传仓库接口
abstract class MultipartUploadRepository {
  /// 初始化分片上传
  Future<MultipartUploadInitResult> initMultipartUpload({
    required String name,
    required int size,
    String? type,
    String? directory,
    int? chunkSize,
  });

  /// 上传单个分片
  Future<MultipartChunkResult> uploadChunk({
    required String uploadId,
    required int chunkNumber,
    required Uint8List chunkData,
    void Function(int, int)? onProgress,
  });

  /// 完成分片合并
  Future<MergeResult> completeMultipartUpload({required String uploadId});

  /// 取消分片上传
  Future<void> abortMultipartUpload({required String uploadId});

  /// 查询上传状态
  Future<UploadStatusResult> getUploadStatus({required String uploadId});
}
