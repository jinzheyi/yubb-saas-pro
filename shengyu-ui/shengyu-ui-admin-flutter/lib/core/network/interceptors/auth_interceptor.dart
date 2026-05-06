import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_refresh_service.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/refresh_token_coordinator.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref, this._refreshTokenCoordinator);

  final Ref _ref;
  final RefreshTokenCoordinator _refreshTokenCoordinator;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = _ref.read(authSessionProvider);
    if (AppConfig.shouldAttachAuthorizationHeader(options.path) &&
        session.accessToken.isNotEmpty &&
        !AppConfig.containsHeader(
          options.headers,
          AppConfig.authorizationHeader,
        )) {
      AppConfig.putHeader(
        options.headers,
        AppConfig.authorizationHeader,
        AppConfig.formatAuthorization(session.accessToken),
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestOptions = response.requestOptions;
    final data = response.data;
    final code = data is Map<String, dynamic>
        ? (data['code'] as num?)?.toInt()
        : null;
    if (code != 401 ||
        !AppConfig.shouldAttachAuthorizationHeader(requestOptions.path) ||
        requestOptions.path.contains('/system/auth/refresh-token') ||
        requestOptions.extra['retried'] == true) {
      handler.next(response);
      return;
    }

    _retryWithRefreshedSession(
      requestOptions,
    ).then(handler.resolve).catchError((Object _) => handler.next(response));
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    final requestOptions = err.requestOptions;
    if (requestOptions.path.contains('/system/auth/refresh-token') ||
        requestOptions.extra['retried'] == true) {
      handler.next(err);
      return;
    }

    _retryWithRefreshedSession(requestOptions).then(handler.resolve).catchError(
      (Object _) {
        handler.next(err);
      },
    );
  }

  Future<Response<dynamic>> _retryWithRefreshedSession(
    RequestOptions requestOptions,
  ) async {
    final session = await _refreshTokenCoordinator.refresh(() {
      return _ref.read(authRefreshServiceProvider).refreshCurrentSession();
    });
    AppConfig.putHeader(
      requestOptions.headers,
      AppConfig.authorizationHeader,
      AppConfig.formatAuthorization(session.accessToken),
    );
    if (session.tenantId.isNotEmpty &&
        AppConfig.shouldAttachTenantHeader(requestOptions.path)) {
      AppConfig.putHeader(
        requestOptions.headers,
        AppConfig.tenantIdHeader,
        session.tenantId,
      );
    }
    requestOptions.extra['retried'] = true;
    return _ref.read(dioProvider).fetch(requestOptions);
  }
}
