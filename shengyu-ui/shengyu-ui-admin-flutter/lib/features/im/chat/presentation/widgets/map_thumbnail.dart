import 'package:flutter/material.dart';

import 'map_thumbnail_stub.dart'
    if (dart.library.html) 'map_thumbnail_web.dart'
    if (dart.library.io) 'map_thumbnail_mobile.dart';

/// 地图缩略图组件 - 多端适配
/// 
/// Web 平台使用 HtmlElementView (iframe) 渲染静态地图
/// 移动端使用 CachedNetworkImage 加载腾讯静态地图 API
class MapThumbnail extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isOutgoing;
  final double height;

  const MapThumbnail({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isOutgoing,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return createMapThumbnail(
      latitude: latitude,
      longitude: longitude,
      isOutgoing: isOutgoing,
      height: height,
    );
  }
}
