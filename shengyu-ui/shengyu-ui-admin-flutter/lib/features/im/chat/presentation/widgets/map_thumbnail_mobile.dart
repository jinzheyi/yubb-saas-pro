import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

/// 移动端地图缩略图 - 使用 WebView 渲染腾讯地图
/// 
/// 与主地图使用相同的 JavaScript API GL，确保 Key 授权一致
Widget createMapThumbnail({
  required double latitude,
  required double longitude,
  required bool isOutgoing,
  double height = 100,
}) {
  return _MobileMapThumbnail(
    latitude: latitude,
    longitude: longitude,
    isOutgoing: isOutgoing,
    height: height,
  );
}

class _MobileMapThumbnail extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool isOutgoing;
  final double height;

  const _MobileMapThumbnail({
    required this.latitude,
    required this.longitude,
    required this.isOutgoing,
    required this.height,
  });

  @override
  State<_MobileMapThumbnail> createState() => _MobileMapThumbnailState();
}

class _MobileMapThumbnailState extends State<_MobileMapThumbnail> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    final lat = widget.latitude;
    final lng = widget.longitude;
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body, #map { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="map"></div>
  <script src="${AppConfig.tencentJsApiUrl}"></script>
  <script>
    if (typeof TMap !== 'undefined') {
      new TMap.Map("map", {
        center: new TMap.LatLng($lat, $lng),
        zoom: 15,
        viewMode: '2D',
        draggable: false,
        zoomControl: false,
        scaleControl: false
      });
    }
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(widget.isOutgoing ? 10 : 5),
        bottomRight: Radius.circular(widget.isOutgoing ? 5 : 10),
      ),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
