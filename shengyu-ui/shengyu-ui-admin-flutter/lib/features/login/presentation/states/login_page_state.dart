import 'package:shengyu_ui_admin_im/core/error/app_error.dart';

enum LoginPageStatus { idle, submitting, failed }

class LoginPageState {
  const LoginPageState({
    this.status = LoginPageStatus.idle,
    this.username = '',
    this.password = '',
    this.error,
  });

  final LoginPageStatus status;
  final String username;
  final String password;
  final AppError? error;

  bool get canSubmit => username.trim().isNotEmpty && password.isNotEmpty;

  LoginPageState copyWith({
    LoginPageStatus? status,
    String? username,
    String? password,
    AppError? error,
  }) {
    return LoginPageState(
      status: status ?? this.status,
      username: username ?? this.username,
      password: password ?? this.password,
      error: error,
    );
  }
}
