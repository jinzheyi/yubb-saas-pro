import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// 非 Web 平台：配置 IOHttpClientAdapter 连接池
void configureDioAdapter(Dio dio) {
  const maxConnectionsPerHost = 10;
  const idleTimeout = Duration(seconds: 30);

  final adapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.maxConnectionsPerHost = maxConnectionsPerHost;
      client.idleTimeout = idleTimeout;
      return client;
    },
  );
  dio.httpClientAdapter = adapter;
}
