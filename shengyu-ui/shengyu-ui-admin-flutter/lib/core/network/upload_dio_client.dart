import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_adapter_config_stub.dart'
    if (dart.library.html) 'package:shengyu_ui_admin_im/core/network/dio_adapter_config_web.dart'
    if (dart.library.io) 'package:shengyu_ui_admin_im/core/network/dio_adapter_config_io.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart' show refreshTokenCoordinatorProvider;
import 'package:shengyu_ui_admin_im/core/network/interceptors/auth_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/locale_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/request_id_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/tenant_interceptor.dart';

/// 文件上传专用 Dio Provider
///
/// 与聊天消息共用同一个 HttpClient 实例池，但独立的 Dio 实例，
/// 避免上传大文件时占用连接导致聊天消息请求被阻塞。
final uploadDioProvider = Provider<Dio>((ref) {
  return UploadDioClientFactory.create(ref);
});

/// 上传专用 Dio 工厂
///
/// 配置说明：
/// - 与聊天 Dio 共享连接池参数，但独立实例确保请求互不干扰
/// - 上传超时时间更长，适应大文件上传场景
abstract final class UploadDioClientFactory {
  /// 上传请求超时时间（较长，适配大文件）
  static const Duration _uploadTimeout = Duration(minutes: 5);

  static Dio create(Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        // 上传使用更长的超时时间
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: _uploadTimeout,
      ),
    );

    // 平台相关：Web 使用默认 BrowserHttpClientAdapter
    // 非 Web 使用 IOHttpClientAdapter + 连接池优化
    configureDioAdapter(dio);

    dio.interceptors.addAll([
      AuthInterceptor(ref, ref.read(refreshTokenCoordinatorProvider)),
      TenantInterceptor(ref),
      LocaleInterceptor(ref),
      RequestIdInterceptor(),
    ]);
    return dio;
  }
}
