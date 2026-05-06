import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';

class TenantInterceptor extends Interceptor {
  TenantInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = _ref.read(authSessionProvider);
    final tenantId = session.tenantId;
    if (tenantId.isNotEmpty &&
        AppConfig.shouldAttachTenantHeader(options.path) &&
        !AppConfig.containsHeader(options.headers, AppConfig.tenantIdHeader)) {
      AppConfig.putHeader(options.headers, AppConfig.tenantIdHeader, tenantId);
    }
    AppConfig.putHeader(
      options.headers,
      AppConfig.deviceIdHeader,
      session.deviceId,
    );
    handler.next(options);
  }
}
