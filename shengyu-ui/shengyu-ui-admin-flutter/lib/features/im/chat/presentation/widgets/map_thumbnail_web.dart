import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

/// Web 端地图缩略图 - 使用 HtmlElementView + iframe 渲染静态地图
/// 绕过浏览器 CORS 限制
Widget createMapThumbnail({
  required double latitude,
  required double longitude,
  required bool isOutgoing,
  double height = 100,
}) {
  return _WebMapThumbnail(
    latitude: latitude,
    longitude: longitude,
    isOutgoing: isOutgoing,
    height: height,
  );
}

class _WebMapThumbnail extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool isOutgoing;
  final double height;

  const _WebMapThumbnail({
    required this.latitude,
    required this.longitude,
    required this.isOutgoing,
    required this.height,
  });

  @override
  State<_WebMapThumbnail> createState() => _WebMapThumbnailState();
}

class _WebMapThumbnailState extends State<_WebMapThumbnail> {
  static int _nextViewId = 0;
  late final String _viewId;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'map_thumb_${_nextViewId++}_${widget.latitude}_${widget.longitude}';
    _registerView();
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'none'
          ..srcdoc = _buildStaticMapHtml();
        return iframe;
      },
    );
  }

  String _buildStaticMapHtml() {
    final lat = widget.latitude;
    final lng = widget.longitude;
    return '''
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; }
  html, body { width: 100%; height: 100%; overflow: hidden; }
  #map { width: 100%; height: 100%; }
</style>
</head>
<body>
  <div id="map"></div>
  <script src="${AppConfig.tencentJsApiUrl}"></script>
  <script>
    var map = new TMap.Map("map", {
      center: new TMap.LatLng($lat, $lng),
      zoom: 15,
      viewMode: '2D',
      draggable: false,
      zoomControl: false,
      scaleControl: false
    });
    new TMap.MultiMarker({
      map: map,
      styles: {
        "default": new TMap.MarkerStyle({
          "width": 20,
          "height": 30,
          "anchor": { x: 10, y: 30 },
          "src": "https://mapapi.qq.com/web/lbs/javascriptGL/demo/img/markerDefault.png"
        })
      },
      geometries: [{
        "id": "marker",
        "styleId": "default",
        "position": new TMap.LatLng($lat, $lng)
      }]
    });
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewId),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
