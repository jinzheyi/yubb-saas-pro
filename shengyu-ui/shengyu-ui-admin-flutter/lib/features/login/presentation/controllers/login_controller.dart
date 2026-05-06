import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/login/application/usecases/login_use_case.dart';
import 'package:shengyu_ui_admin_im/features/login/presentation/states/login_page_state.dart';

const _hardcodedPassword = '123456';

class LoginController extends StateNotifier<LoginPageState> {
  LoginController(this._loginUseCase, this._authSessionController)
    : super(const LoginPageState());

  final LoginUseCase _loginUseCase;
  final AuthSessionController _authSessionController;

  void updateUsername(String value) {
    state = state.copyWith(username: value, error: null);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, error: null);
  }

  Future<void> submit({required String locale}) async {
    if (!state.canSubmit) {
      return;
    }

    state = state.copyWith(status: LoginPageStatus.submitting, error: null);
    try {
      final session = await _loginUseCase(
        username: state.username.trim(),
        password: _hardcodedPassword,
        locale: locale,
      );
      await _authSessionController.saveSession(session);
      state = state.copyWith(status: LoginPageStatus.idle, error: null);
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: LoginPageStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }
}
