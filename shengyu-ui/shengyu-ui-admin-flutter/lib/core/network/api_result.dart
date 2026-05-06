import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';

class ApiResult<T> {
  const ApiResult({
    required this.code,
    required this.message,
    required this.data,
  });

  final int code;
  final String message;
  final T data;

  bool get isSuccess => code == 0 || code == 200;

  static ApiResult<R> fromJson<R>(
    Map<String, dynamic> json, {
    required R Function(Object? raw) dataParser,
  }) {
    return ApiResult<R>(
      code: (json['code'] as num?)?.toInt() ?? -1,
      message: json['msg']?.toString() ?? json['message']?.toString() ?? '',
      data: dataParser(json['data']),
    );
  }

  T requireData() {
    if (!isSuccess) {
      throw ApiException(
        code: code,
        message: message.isEmpty ? 'API request failed' : message,
        details: data,
      );
    }
    return data;
  }
}
