import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';
import 'package:shengyu_ui_admin_im/features/login/application/usecases/login_use_case.dart';
import 'package:shengyu_ui_admin_im/features/login/presentation/controllers/login_controller.dart';
import 'package:shengyu_ui_admin_im/features/login/presentation/states/login_page_state.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(
    ref.read(authRemoteDataSourceProvider),
    ref.read(deviceInfoServiceProvider),
  );
});

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginPageState>((ref) {
      return LoginController(
        ref.read(loginUseCaseProvider),
        ref.read(authSessionProvider.notifier),
        ref,
      );
    });
