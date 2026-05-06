import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/auth/refresh_token_coordinator.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/request_id_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/auth_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/locale_interceptor.dart';
import 'package:shengyu_ui_admin_im/core/network/interceptors/tenant_interceptor.dart';

final refreshTokenCoordinatorProvider = Provider<RefreshTokenCoordinator>((
  ref,
) {
  return RefreshTokenCoordinator();
});

final dioProvider = Provider<Dio>((ref) {
  return DioClientFactory.create(ref);
});

abstract final class DioClientFactory {
  static Dio create(Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(ref, ref.read(refreshTokenCoordinatorProvider)),
      TenantInterceptor(ref),
      LocaleInterceptor(ref),
      RequestIdInterceptor(),
    ]);
    return dio;
  }
}
