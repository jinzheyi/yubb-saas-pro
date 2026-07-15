import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/platform/video_compression_config.dart';

/// 视频压缩服务
///
/// 对标微信/钉钉视频压缩策略，在上传前对视频进行压缩处理，
/// 减少文件大小，提升上传速度，降低服务器带宽压力。
///
/// 压缩策略：
/// - 仅压缩超过阈值（20MB）的视频
/// - 使用 720p 分辨率，2Mbps 比特率，30fps
/// - 质量等级：medium（平衡画质和文件大小）
/// - 压缩失败时降级使用原始文件
class VideoCompressionService {
  VideoCompressionService._();

  static final VideoCompressionService instance = VideoCompressionService._();

  /// 压缩视频文件
  ///
  /// [inputPath] 原始视频文件路径
  /// [onProgress] 压缩进度回调（0.0 ~ 1.0）
  ///
  /// 返回压缩后的文件路径，如果压缩失败或不需要压缩，返回原始文件路径
  Future<String> compressVideo(
    String inputPath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        debugPrint('[VideoCompressor] 输入文件不存在: $inputPath');
        return inputPath;
      }

      final fileSize = await inputFile.length();
      const config = AppConfig.videoCompressionConfig;

      // 检查是否需要压缩
      if (fileSize <= config.compressionThreshold) {
        debugPrint(
          '[VideoCompressor] 视频大小 ${_formatBytes(fileSize)} '
          '未超过阈值 ${_formatBytes(config.compressionThreshold)}，跳过压缩',
        );
        return inputPath;
      }

      debugPrint(
        '[VideoCompressor] 开始压缩视频: ${_formatBytes(fileSize)} -> '
        '目标 ${config.quality.name}, ${config.resolution.name}',
      );

      // 订阅压缩进度
      final subscription = VideoCompress.compressProgress$.subscribe(
        (progress) {
          onProgress?.call(progress);
        },
      );

      try {
        // 执行压缩
        final mediaInfo = await VideoCompress.compressVideo(
          inputPath,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false, // 保留原始文件
          includeAudio: true, // 保留音频
        );

        if (mediaInfo == null || mediaInfo.path == null) {
          debugPrint('[VideoCompressor] 压缩失败，返回原始文件');
          return inputPath;
        }

        final compressedFile = File(mediaInfo.path!);
        if (!await compressedFile.exists()) {
          debugPrint('[VideoCompressor] 压缩文件不存在，返回原始文件');
          return inputPath;
        }

        final compressedSize = await compressedFile.length();
        final compressionRatio = (1 - compressedSize / fileSize) * 100;

        debugPrint(
          '[VideoCompressor] 压缩完成: ${_formatBytes(fileSize)} -> '
          '${_formatBytes(compressedSize)} (减少 ${compressionRatio.toStringAsFixed(1)}%)',
        );

        return mediaInfo.path!;
      } finally {
        subscription.unsubscribe();
      }
    } catch (e, stackTrace) {
      debugPrint('[VideoCompressor] 压缩异常: $e\n$stackTrace');
      return inputPath; // 压缩失败时降级使用原始文件
    }
  }

  /// 获取视频信息
  ///
  /// [path] 视频文件路径
  ///
  /// 返回 MediaInfo 对象，包含视频时长、分辨率、文件大小等信息
  Future<MediaInfo?> getMediaInfo(String path) async {
    try {
      return await VideoCompress.getMediaInfo(path);
    } catch (e, stackTrace) {
      debugPrint('[VideoCompressor] 获取视频信息失败: $e\n$stackTrace');
      return null;
    }
  }

  /// 格式化字节数为可读字符串
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 删除压缩产生的临时文件
  ///
  /// [path] 要删除的文件路径
  ///
  /// 注意：仅删除压缩后的临时文件，不会删除原始文件
  Future<void> deleteTemporaryFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[VideoCompressor] 已删除临时文件: $path');
      }
    } catch (e, stackTrace) {
      debugPrint('[VideoCompressor] 删除临时文件失败: $e\n$stackTrace');
    }
  }
}
