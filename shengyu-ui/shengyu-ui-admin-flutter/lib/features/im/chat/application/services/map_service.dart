import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

/// 地图服务
class MapService {
  /// 生成静态地图 URL（腾讯地图）
  ///
  /// 注意：Web 平台由于 CORS 限制，无法直接访问腾讯地图静态图 API，
  /// 返回空字符串，调用方需处理降级显示。
  ///
  /// 坐标格式：纬度在前，经度在后（lat,lng），与腾讯 API 文档一致
  static String generateStaticMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 15,
    int width = 400,
    int height = 200,
    int markerSize = 12,
  }) {
    // Web 平台 CORS 限制，无法直接访问腾讯地图静态图 API
    if (kIsWeb) {
      debugPrint('[MapService] Web 平台不支持静态地图 API（CORS 限制）');
      return '';
    }

    // 腾讯地图静态图 API V2
    // 文档：https://lbs.qq.com/service/staticV2/staticGuide/staticDoc
    // 坐标格式：纬度在前，经度在后
    final markers =
        'size:$markerSize|color:0xFF0000|label:A|position:$latitude,$longitude';
    final url = '${AppConfig.tencentStaticMapBaseUrl}'
        '?center=$latitude,$longitude'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=$markers'
        '&key=${AppConfig.tencentLbsKey}';

    return url;
  }

  /// 生成缩略图 URL（用于消息气泡）
  static String generateThumbnailUrl({
    required double latitude,
    required double longitude,
  }) {
    return generateStaticMapUrl(
      latitude: latitude,
      longitude: longitude,
      zoom: 15,
      width: 300,
      height: 150,
      markerSize: 10,
    );
  }

  /// 生成详情页地图 URL
  static String generateDetailMapUrl({
    required double latitude,
    required double longitude,
  }) {
    return generateStaticMapUrl(
      latitude: latitude,
      longitude: longitude,
      zoom: 16,
      width: 600,
      height: 400,
      markerSize: 16,
    );
  }
}
