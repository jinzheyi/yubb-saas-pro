// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

/// Web 平台：使用 XMLHttpRequest 探测网络延迟
///
/// 探测目标地址统一收口到 AppConfig.networkProbeUrl，
/// 开发环境默认使用 HTTP 地址（避免 DNS 解析失败），
/// 生产环境可配置为外部 CDN 或健康检查端点。
Future<int> probeNetworkLatency() async {
  final sw = Stopwatch()..start();
  final completer = Completer<int>();

  try {
    final xhr = web.XMLHttpRequest();
    xhr
      ..open('HEAD', AppConfig.networkProbeUrl, true)
      ..responseType = ''
      ..timeout = 3000
      ..onload = (web.Event e) {
        sw.stop();
        completer.complete(sw.elapsedMilliseconds);
      }.toJS
      ..onerror = (web.ProgressEvent e) {
        completer.complete(9999);
      }.toJS
      ..ontimeout = (web.ProgressEvent e) {
        completer.complete(9999);
      }.toJS
      ..send();

    return await completer.future.timeout(const Duration(seconds: 4));
  } catch (e) {
    return 9999;
  }
}
