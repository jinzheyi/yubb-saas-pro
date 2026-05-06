import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';

class LoginUseCase {
  const LoginUseCase(this._remoteDataSource, this._deviceInfoService);

  final AuthRemoteDataSource _remoteDataSource;
  final DeviceInfoService _deviceInfoService;

  Future<AuthSession> call({
    required String username,
    required String password,
    required String locale,
  }) async {
    final deviceInfo = await _deviceInfoService.getOrCreate();
    final token = await _remoteDataSource.login(
      username: username,
      password: password,
      deviceType: deviceInfo.deviceType,
      deviceId: deviceInfo.deviceId,
      clientVersion: deviceInfo.clientVersion,
    );
    final permissionInfo = await _remoteDataSource.getPermissionInfoWithSession(
      accessToken: token.accessToken,
      tenantId: token.tenantId,
    );
    return AuthSession(
      userId: permissionInfo.userId,
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      tenantId: token.tenantId,
      deviceId: deviceInfo.deviceId,
      deviceType: deviceInfo.deviceType,
      deviceName: deviceInfo.deviceName,
      clientVersion: deviceInfo.clientVersion,
      locale: locale,
    );
  }
}
