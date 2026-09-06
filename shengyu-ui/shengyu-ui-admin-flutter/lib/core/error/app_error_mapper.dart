import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';

import 'app_error.dart';

/// App 错误映射器
///
/// 企业级兜底策略：将底层异常（Dio、Socket 等）转换为用户友好的提示文案，
/// 在任何页面都不会出现不友好的代码错误信息。
/// 对标微信/飞书的网络异常体验：服务恢复后自动恢复正常。
abstract final class AppErrorMapper {
  static AppError map(Object error, [StackTrace? stackTrace]) {
    // 1. 已经是我们自己的 AppError，直接返回
    if (error is AppError) {
      return error;
    }

    // 2. 服务端业务异常：优先展示后端返回的 msg/message
    if (error is ApiException) {
      return AppError(
        message: error.message.isEmpty ? '请求失败，请稍后重试' : error.message,
        code: error.code.toString(),
        cause: error,
      );
    }

    // 3. Dio 异常：转换为用户友好的网络提示
    if (error is DioException) {
      return _mapDioException(error);
    }

    // 4. 其他异常：返回通用友好提示
    return AppError(message: '请求失败，请稍后重试', cause: error);
  }

  /// 将 Dio 异常映射为友好错误信息
  static AppError _mapDioException(DioException e) {
    final serverMessage = _extractServerMessage(e.response?.data);
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout => '服务器连接超时，请检查网络后重试',
      DioExceptionType.sendTimeout => '请求发送超时，请稍后重试',
      DioExceptionType.receiveTimeout => '服务器响应超时，请稍后重试',
      DioExceptionType.transformTimeout => '数据转换超时，请稍后重试',
      DioExceptionType.badCertificate => '安全证书验证失败',
      DioExceptionType.badResponse =>
        serverMessage ?? _mapBadResponse(e.response?.statusCode),
      DioExceptionType.cancel => '请求已取消',
      DioExceptionType.connectionError => _mapConnectionError(e.message),
      DioExceptionType.unknown => _mapUnknownError(e.message),
    };
    return AppError(message: message, code: e.message, cause: e);
  }

  static String? _extractServerMessage(Object? data) {
    if (data is Map) {
      final message = data['msg'] ?? data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }
    return null;
  }

  /// HTTP 状态码映射
  static String _mapBadResponse(int? statusCode) {
    return switch (statusCode) {
      400 => '请求参数有误',
      401 => '登录已过期，请重新登录',
      403 => '暂无操作权限',
      404 => '请求的资源不存在',
      429 => '请求过于频繁，请稍后再试',
      500 => '服务器内部错误，请稍后重试',
      502 => '网关异常，请稍后重试',
      503 => '服务器暂时不可用，请稍后重试',
      504 => '网关超时，请稍后重试',
      _ => '服务器异常，请稍后重试',
    };
  }

  /// 连接错误映射（区分网络断开和服务器不可达）
  static String _mapConnectionError(String? message) {
    if (message == null || message.isEmpty) {
      return '网络连接异常，请稍后重试';
    }
    final lower = message.toLowerCase();
    if (lower.contains('socket') || lower.contains('connection refused')) {
      return '无法连接到服务器，请稍后重试';
    }
    if (lower.contains('network') || lower.contains('unreachable')) {
      return '网络连接异常，请检查网络设置';
    }
    return '网络连接异常，请稍后重试';
  }

  /// 未知错误映射
  static String _mapUnknownError(String? message) {
    if (message == null || message.isEmpty) {
      return '请求失败，请稍后重试';
    }
    // 如果消息包含 DioException 原始信息，说明是 WeakNetworkInterceptor 已经处理过的
    if (message.contains('DioException') || message.contains('connection timeout')) {
      return '请求失败，请稍后重试';
    }
    return '请求失败，请稍后重试';
  }
}
