import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

/// 移动端地图视图实现
/// 
/// 使用 webview_flutter 加载腾讯地图
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
  return _MobileMapView(
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

class _MobileMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int zoom;
  final bool enableDrag;
  final bool showMarker;
  final String? markerTitle;
  final String? markerAddress;
  final Function(double lat, double lng)? onDragEnd;
  final Function()? onMapLoaded;

  const _MobileMapView({
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
  State<_MobileMapView> createState() => _MobileMapViewState();
}

class _MobileMapViewState extends State<_MobileMapView> {
  late final WebViewController _webViewController;
  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          debugPrint('[MobileMapView] 页面加载完成');
        },
        onWebResourceError: (error) {
          debugPrint('[MobileMapView] 资源加载错误: ${error.description}');
          debugPrint('[MobileMapView] 错误码: ${error.errorCode}');
        },
      ))
      ..addJavaScriptChannel(
        'MapBridge',
        onMessageReceived: _handleJavaScriptMessage,
      )
      ..loadHtmlString(_buildMapHtml());
  }

  void _handleJavaScriptMessage(JavaScriptMessage message) {
    try {
      final msg = message.message;
      if (msg == 'mapLoaded') {
        setState(() {
          _mapLoaded = true;
        });
        widget.onMapLoaded?.call();
      } else if (msg.startsWith('dragEnd,')) {
        final parts = msg.split(',');
        if (parts.length == 3) {
          final lat = double.parse(parts[1].trim());
          final lng = double.parse(parts[2].trim());
          widget.onDragEnd?.call(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('[MobileMapView] 解析 JS 消息失败: $e');
    }
  }

  String _buildMapHtml() {
    final lat = widget.latitude;
    final lng = widget.longitude;
    final zoom = widget.zoom;
    final enableDrag = widget.enableDrag;
    final showMarker = widget.showMarker;
    final title = widget.markerTitle ?? '';
    final address = widget.markerAddress ?? '';

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
  <script src="${AppConfig.tencentJsApiUrl}"></script>
  <script>
    window.mapLoadedSent = false;
    function notifyLoaded() {
      if (!window.mapLoadedSent) {
        window.mapLoadedSent = true;
        try { MapBridge.postMessage('mapLoaded'); } catch(e) {}
      }
    }
    try {
      if (typeof TMap !== 'undefined') {
        var map = new TMap.Map("map", {
          center: new TMap.LatLng($lat, $lng),
          zoom: $zoom,
          viewMode: '2D',
          draggable: $enableDrag
        });
        ${enableDrag ? '''
        map.on('dragend', function() {
          var center = map.getCenter();
          try { MapBridge.postMessage('dragEnd,' + center.lat + ',' + center.lng); } catch(e) {}
        });
        ''' : ''}
        map.on('complete', function() {
          notifyLoaded();
        });
      } else {
        console.error('TMap SDK not loaded');
        notifyLoaded();
      }
    } catch(e) {
      console.error('Map init error: ' + e.message);
      notifyLoaded();
    }
    // 兜底：3秒后强制通知
    setTimeout(notifyLoaded, 3000);
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

  @override
  void dispose() {
    // WebViewController 不需要手动 dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
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
