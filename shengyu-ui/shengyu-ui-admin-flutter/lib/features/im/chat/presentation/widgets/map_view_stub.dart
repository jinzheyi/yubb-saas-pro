import 'package:flutter/material.dart';

/// 平台地图视图创建函数 - 存根实现
/// 
/// 这个文件是条件导入的默认实现，当无法确定平台时使用
Widget createPlatformMapView({
  required double latitude,
  required double longitude,
  int zoom = 15,
  bool enableDrag = false,
  bool showMarker = true,
  String? markerTitle,
  String? markerAddress,
  Function(double lat, double lng)? onDragEnd,
  Function()? onMapLoaded,
}) {
  return Container(
    color: Colors.grey[200],
    child: const Center(
      child: Text('地图组件未支持当前平台'),
    ),
  );
}
