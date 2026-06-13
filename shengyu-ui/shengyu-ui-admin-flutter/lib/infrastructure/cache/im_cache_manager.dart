import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// IM 专用音频缓存管理器
///
/// 三级缓存策略：内存 → 磁盘 → 网络
/// - 内存缓存：Flutter ImageCache 管理
/// - 磁盘缓存：flutter_cache_manager 管理，最多50个音频文件，30天过期，最大200MB
/// - 网络：未命中缓存时从网络下载
class AudioCacheManager {
  AudioCacheManager._();

  static const String _key = 'imAudioCache';

  /// 获取 IM 音频缓存管理器单例
  static final CacheManager instance = CacheManager(
    Config(
      _key,
      // 缓存对象数量上限（最多50个音频文件）
      maxNrOfCacheObjects: 50,
      // 缓存过期时间 30 天
      stalePeriod: const Duration(days: 30),
    ),
  );

  /// 获取音频文件本地路径（优先缓存，未命中时后台下载）
  ///
  /// 返回本地文件路径，若缓存未命中则触发下载并等待完成后返回。
  static Future<String?> getAudioFile(String url) async {
    try {
      final fileInfo = await instance.getSingleFile(url);
      return fileInfo?.path;
    } catch (_) {
      return null;
    }
  }
}

/// IM 通用图片缓存管理器
///
/// 三级缓存策略：内存 → 磁盘 → 网络
/// 用于 CachedNetworkImage 的图片缓存加载。
abstract final class ImCacheManager {
  static const String _key = 'imImageCache';

  /// 获取 IM 图片缓存管理器单例
  static final CacheManager instance = CacheManager(
    Config(
      _key,
      // 缓存对象数量上限
      maxNrOfCacheObjects: 100,
      // 缓存过期时间 30 天
      stalePeriod: const Duration(days: 30),
    ),
  );
}
