import 'dart:io';

import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

/// 非 Web 平台：使用 Socket 连接探测网络延迟
///
/// 探测目标地址统一收口到 AppConfig.networkProbeHost，
/// 开发环境默认使用 API 服务器地址（避免 DNS 解析失败），
/// 生产环境可配置为外部 CDN 或健康检查端点。
Future<int> probeNetworkLatency() async {
  final sw = Stopwatch()..start();
  final socket = await Socket.connect(
    AppConfig.networkProbeHost,
    AppConfig.networkProbePort,
    timeout: const Duration(seconds: 3),
  ).timeout(const Duration(seconds: 3));
  sw.stop();
  await socket.close();
  return sw.elapsedMilliseconds;
}
