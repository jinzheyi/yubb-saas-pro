import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_view_stub.dart'
    if (dart.library.html) 'map_view_web.dart'
    if (dart.library.io) 'map_view_mobile.dart';

/// 地图视图组件 - 多端适配
/// 
/// Web 平台使用 HtmlElementView (iframe)
/// 移动端使用 WebView
class MapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final int zoom;
  final bool enableDrag;
  final bool showMarker;
  final String? markerTitle;
  final String? markerAddress;
  final Function(double lat, double lng)? onDragEnd;
  final Function()? onMapLoaded;

  const MapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 15,
    this.enableDrag = false,
    this.showMarker = true,
    this.markerTitle,
    this.markerAddress,
    this.onDragEnd,
    this.onMapLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return createPlatformMapView(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
      enableDrag: enableDrag,
      showMarker: showMarker,
      markerTitle: markerTitle,
      markerAddress: markerAddress,
      onDragEnd: onDragEnd,
      onMapLoaded: onMapLoaded,
    );
  }
}
