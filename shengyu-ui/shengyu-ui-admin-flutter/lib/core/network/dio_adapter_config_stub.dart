import 'package:dio/dio.dart';

/// Dio 适配器配置（平台无关接口）
///
/// Web 平台使用默认 BrowserHttpClientAdapter
/// 非 Web 平台使用 IOHttpClientAdapter 并配置连接池
void configureDioAdapter(Dio dio) => throw UnsupportedError('No implementation');
