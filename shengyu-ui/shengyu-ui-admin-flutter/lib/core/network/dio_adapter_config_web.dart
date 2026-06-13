import 'package:dio/dio.dart';

/// Web 平台：使用默认的 BrowserHttpClientAdapter，无需额外配置
void configureDioAdapter(Dio dio) {
  // Web 平台使用浏览器的 XMLHttpRequest/Fetch API，不需要连接池配置
}
