import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/session_cleanup_service.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/presentation/providers/global_im_notification_binding.dart';
import 'package:shengyu_ui_admin_im/features/login/application/usecases/login_use_case.dart';
import 'package:shengyu_ui_admin_im/features/login/presentation/states/login_page_state.dart';

const _hardcodedPassword = '123456';

class LoginController extends StateNotifier<LoginPageState> {
  LoginController(this._loginUseCase, this._authSessionController, this._ref)
    : super(const LoginPageState());

  final LoginUseCase _loginUseCase;
  final AuthSessionController _authSessionController;
  final Ref _ref;

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
      final currentSession = _ref.read(authSessionProvider);
      final wasAuthenticated = currentSession.isAuthenticated;

      if (wasAuthenticated) {
        unawaited(_ref.read(imSocketClientProvider).disconnect());
        _ref.read(sessionCleanupServiceProvider).forceClearAllUserScopes();
      }

      final session = await _loginUseCase(
        username: state.username.trim(),
        password: _hardcodedPassword,
        locale: locale,
      );
      await _authSessionController.saveSession(session);
      debugPrint('[Fcm] login completed; scheduling device registration');
      unawaited(
        _ref
            .read(pushDeviceRegistrationServiceProvider)
            .registerCurrentDevice(),
      );
      // Ask only after a successful, user-initiated login; a denial must not
      // affect authentication or conversation recovery.
      unawaited(
        _ref
            .read(imLocalNotificationServiceProvider)
            .requestPermissionIfNeeded(),
      );
      // 登录成功后先恢复该用户的本地会话快照，再路由到会话页。这样后续登录
      // 直接呈现上次看到的会话，网络同步和 Socket 建连在后台完成。
      await _ref.read(conversationListControllerProvider.notifier).warmStart();
      state = state.copyWith(status: LoginPageStatus.idle, error: null);
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: LoginPageStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }
}
