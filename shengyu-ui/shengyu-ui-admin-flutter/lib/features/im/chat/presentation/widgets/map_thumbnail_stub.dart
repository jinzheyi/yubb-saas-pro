import 'package:flutter/material.dart';

/// 地图缩略图 - 平台适配入口
/// 
/// Web 使用 HtmlElementView + iframe 渲染静态地图（绕过 CORS）
/// 移动端使用 CachedNetworkImage 加载腾讯静态地图 API
Widget createMapThumbnail({
  required double latitude,
  required double longitude,
  required bool isOutgoing,
  double height = 100,
}) {
  // Stub: 移动端默认使用 CachedNetworkImage，由 map_thumbnail_mobile.dart 覆盖
  return const SizedBox.shrink();
}
