import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Web 平台地图视图实现
/// 
/// 使用 HtmlElementView (iframe) 嵌入腾讯地图
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
  return _WebMapView(
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

class _WebMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int zoom;
  final bool enableDrag;
  final bool showMarker;
  final String? markerTitle;
  final String? markerAddress;
  final Function(double lat, double lng)? onDragEnd;
  final Function()? onMapLoaded;

  const _WebMapView({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.enableDrag,
    required this.showMarker,
    this.markerTitle,
    this.markerAddress,
    this.onDragEnd,
    this.onMapLoaded,
  });

  @override
  State<_WebMapView> createState() => _WebMapViewState();
}

class _WebMapViewState extends State<_WebMapView> {
  static int _viewIdCounter = 0;
  late final String _viewType;
  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'tencent-map-${_viewIdCounter++}';
    _registerWebViewFactory();
  }

  void _registerWebViewFactory() {
    // 注册 WebView 工厂
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'geolocation'
          ..srcdoc = _buildMapHtml();

        // 监听 iframe 消息
        html.window.addEventListener('message', _handleMessage);

        return iframe;
      },
    );
  }

  String _buildMapHtml() {
    final lat = widget.latitude;
    final lng = widget.longitude;
    final zoom = widget.zoom;
    final enableDrag = widget.enableDrag;
    final showMarker = widget.showMarker;
    final title = widget.markerTitle ?? '';
    final address = widget.markerAddress ?? '';

    // 构建 HTML 内容 - 使用腾讯地图 JavaScript API GL 版本
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body, #map { width: 100%; height: 100%; }
    .marker { 
      position: absolute; 
      top: 50%; 
      left: 50%; 
      transform: translate(-50%, -100%);
      width: 30px;
      height: 40px;
      pointer-events: none;
      z-index: 1000;
    }
    .marker::before {
      content: '';
      position: absolute;
      width: 30px;
      height: 30px;
      background: #FF4444;
      border-radius: 50% 50% 50% 0;
      transform: rotate(-45deg);
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    }
    .marker::after {
      content: '';
      position: absolute;
      top: 8px;
      left: 8px;
      width: 14px;
      height: 14px;
      background: white;
      border-radius: 50%;
    }
    .info-window {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -100%);
      background: white;
      padding: 12px 16px;
      border-radius: 8px;
      box-shadow: 0 2px 12px rgba(0,0,0,0.15);
      max-width: 200px;
      z-index: 1000;
      pointer-events: none;
    }
    .info-window h3 {
      font-size: 14px;
      font-weight: 600;
      color: #202531;
      margin-bottom: 4px;
    }
    .info-window p {
      font-size: 12px;
      color: #8F96A3;
      line-height: 1.4;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  ${showMarker && !enableDrag ? '<div class="marker"></div>' : ''}
  ${showMarker && enableDrag && title.isNotEmpty ? '''
  <div class="info-window">
    <h3>${_escapeHtml(title)}</h3>
    <p>${_escapeHtml(address)}</p>
  </div>
  ''' : ''}
  <script charset="utf-8" src="https://map.qq.com/api/gljs?v=1.exp&key=AU3BZ-QTLHT-GGJXH-VT5Q3-WLGEZ-JRBTA"></script>
  <script charset="utf-8">
    var map;
    var marker;
    
    // 等待 SDK 加载完成
    function initMap() {
      if (typeof TMap === 'undefined') {
        setTimeout(initMap, 100);
        return;
      }
      
      map = new TMap.Map("map", {
        center: new TMap.LatLng($lat, $lng),
        zoom: $zoom,
        viewMode: '2D',
        draggable: $enableDrag
      });

      // 添加标记点
      if ($showMarker) {
        marker = new TMap.MultiMarker({
          map: map,
          geometries: [{
            id: 'marker',
            position: new TMap.LatLng($lat, $lng)
          }]
        });
      }

      ${enableDrag ? '''
      // 地图拖动结束事件
      map.on('dragend', function() {
        var center = map.getCenter();
        window.parent.postMessage({
          type: 'dragEnd',
          lat: center.lat,
          lng: center.lng
        }, '*');
      });
      ''' : ''}

      // 等待地图渲染完成后通知
      map.on('complete', function() {
        window.parent.postMessage({ type: 'mapLoaded' }, '*');
      });
      
      // 备用方案：如果 complete 事件未触发，500ms 后发送
      setTimeout(function() {
        if (!window.mapLoadedSent) {
          window.mapLoadedSent = true;
          window.parent.postMessage({ type: 'mapLoaded' }, '*');
        }
      }, 500);
    }
    
    // 开始初始化
    initMap();
  </script>
</body>
</html>
    ''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  void _handleMessage(html.Event event) {
    if (!mounted) return;
    if (event is html.MessageEvent) {
      final data = event.data;
      if (data is Map) {
        final type = data['type'];
        if (type == 'mapLoaded') {
          setState(() {
            _mapLoaded = true;
          });
          widget.onMapLoaded?.call();
        } else if (type == 'dragEnd' && widget.onDragEnd != null) {
          final lat = (data['lat'] as num).toDouble();
          final lng = (data['lng'] as num).toDouble();
          widget.onDragEnd!(lat, lng);
        }
      }
    }
  }

  @override
  void dispose() {
    html.window.removeEventListener('message', _handleMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(viewType: _viewType),
        if (!_mapLoaded)
          Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
