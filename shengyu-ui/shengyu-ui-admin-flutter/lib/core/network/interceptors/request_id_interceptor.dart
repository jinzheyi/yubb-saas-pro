import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:uuid/uuid.dart';

class RequestIdInterceptor extends Interceptor {
  RequestIdInterceptor() : _uuid = const Uuid();

  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[AppConfig.requestIdHeader] = _uuid.v4();
    handler.next(options);
  }
}
