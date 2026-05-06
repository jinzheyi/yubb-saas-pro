import 'app_error.dart';

abstract final class AppErrorMapper {
  static AppError map(Object error, [StackTrace? stackTrace]) {
    return AppError(message: error.toString(), cause: error);
  }
}
