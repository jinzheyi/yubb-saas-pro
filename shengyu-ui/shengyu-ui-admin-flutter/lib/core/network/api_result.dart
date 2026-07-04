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
    // 兼容 code 字段可能是 String 或 num 类型
    final rawCode = json['code'];
    int parsedCode = -1;
    if (rawCode is num) {
      parsedCode = rawCode.toInt();
    } else if (rawCode is String) {
      parsedCode = int.tryParse(rawCode) ?? -1;
    }
    
    return ApiResult<R>(
      code: parsedCode,
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
