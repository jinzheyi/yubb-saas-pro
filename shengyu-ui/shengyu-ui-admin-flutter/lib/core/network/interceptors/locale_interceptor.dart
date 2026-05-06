import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';

class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[AppConfig.localeHeader] = _ref
        .read(authSessionProvider)
        .locale;
    handler.next(options);
  }
}
