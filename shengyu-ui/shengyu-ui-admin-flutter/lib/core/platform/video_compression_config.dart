/// 视频压缩质量等级
enum VideoCompressionQuality {
  /// 低质量（文件最小，画质较差）
  low,
  
  /// 中等质量（平衡画质和文件大小）
  medium,
  
  /// 高质量（文件较大，画质较好）
  high,
  
  /// 原始质量（不压缩）
  original,
}

/// 视频分辨率配置
enum VideoResolution {
  /// 480p (854x480)
  sd480,
  
  /// 720p (1280x720) - 推荐
  hd720,
  
  /// 1080p (1920x1080)
  hd1080,
  
  /// 原始分辨率
  original,
}

/// 视频压缩配置
class VideoCompressionConfig {
  const VideoCompressionConfig({
    required this.quality,
    required this.resolution,
    required this.frameRate,
    required this.bitrate,
    required this.compressionThreshold,
  });

  /// 压缩质量等级
  final VideoCompressionQuality quality;

  /// 目标分辨率
  final VideoResolution resolution;

  /// 帧率（fps）
  final int frameRate;

  /// 比特率（bps）
  final int bitrate;

  /// 压缩阈值（字节）- 超过此大小的视频才进行压缩
  final int compressionThreshold;

  /// 获取 video_compress 库的质量值
  int get compressQualityValue {
    switch (quality) {
      case VideoCompressionQuality.low:
        return 20;
      case VideoCompressionQuality.medium:
        return 50;
      case VideoCompressionQuality.high:
        return 80;
      case VideoCompressionQuality.original:
        return 100;
    }
  }

  /// 获取目标宽度（像素）
  int? get targetWidth {
    switch (resolution) {
      case VideoResolution.sd480:
        return 854;
      case VideoResolution.hd720:
        return 1280;
      case VideoResolution.hd1080:
        return 1920;
      case VideoResolution.original:
        return null; // 保持原始分辨率
    }
  }
}
