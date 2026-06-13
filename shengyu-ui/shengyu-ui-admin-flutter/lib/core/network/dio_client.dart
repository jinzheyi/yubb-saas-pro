import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/auth/refresh_token_coordinator.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_adapter_config_stub.dart'
    if (dart.library.html) 'package:shengyu_ui_admin_im/core/network/dio_adapter_config_web.dart'
    if (dart.library.io) 'package:shengyu_ui_admin_im/core/network/dio_adapter_config_io.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/auth_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/locale_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/request_id_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/tenant_interceptor.dart';

final refreshTokenCoordinatorProvider = Provider<RefreshTokenCoordinator>((
  ref,
) {
  return RefreshTokenCoordinator();
});

final dioProvider = Provider<Dio>((ref) {
  return DioClientFactory.create(ref);
});

/// 聊天消息专用 Dio 实例（默认）
/// 配置连接池优化，避免连接数过多导致资源浪费
abstract final class DioClientFactory {
  static Dio create(Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
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
