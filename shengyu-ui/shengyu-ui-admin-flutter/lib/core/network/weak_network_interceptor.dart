import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/network_monitor_service.dart';

/// 弱网友好的 Dio 拦截器
class WeakNetworkInterceptor extends Interceptor {
  final NetworkMonitorService networkMonitor;
  final Dio dio;

  WeakNetworkInterceptor(this.networkMonitor, {required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {

      if (!networkMonitor.isNetworkAvailable) {
        // 无网络：返回友好的本地错误
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          type: DioExceptionType.unknown,
          error: '网络连接已断开，请检查网络设置',
        ));
      } else if (networkMonitor.isWeakNetwork) {
        // 弱网：增加重试
        final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
        if (retryCount < 2) {
          err.requestOptions.extra['retryCount'] = retryCount + 1;
          // 延迟后重试
          Future.delayed(const Duration(milliseconds: 500)).then((_) {
            dio.fetch(err.requestOptions).then(
              (response) => handler.resolve(response),
              onError: (e) => handler.reject(err),
            );
          });
        } else {
          handler.reject(DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.unknown,
            error: '当前网络不稳定，请稍后重试',
          ));
        }
      } else {
        // 网络正常但请求失败：原始错误
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
