import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_token_dto.dart';
import 'package:shengyu_ui_admin_im/core/auth/permission_info_dto.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';
import 'package:shengyu_ui_admin_im/features/login/application/usecases/login_use_case.dart';

void main() {
  test(
    'passes fresh token and tenant to permission request after login',
    () async {
      final remote = _FakeAuthRemoteDataSource();
      const deviceInfo = DeviceInfo(
        deviceType: 9,
        deviceId: 'device-1',
        deviceName: 'unit-test-device',
        clientVersion: '9.9.9',
      );
      final useCase = LoginUseCase(remote, _FakeDeviceInfoService(deviceInfo));

      final session = await useCase(
        username: 'tester',
        password: 'secret',
        locale: 'zh-CN',
      );

      expect(remote.lastPermissionAccessToken, 'access-token-1');
      expect(remote.lastPermissionTenantId, 'tenant-100');
      expect(session.userId, 'user-1');
      expect(session.accessToken, 'access-token-1');
      expect(session.tenantId, 'tenant-100');
      expect(session.deviceId, deviceInfo.deviceId);
    },
  );
}

class _FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  _FakeAuthRemoteDataSource() : super(Dio());

  String? lastPermissionAccessToken;
  String? lastPermissionTenantId;

  @override
  Future<AuthTokenDto> login({
    required String username,
    required String password,
    required int deviceType,
    required String deviceId,
    required String clientVersion,
  }) async {
    return const AuthTokenDto(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      tenantId: 'tenant-100',
    );
  }

  @override
  Future<PermissionInfoDto> getPermissionInfoWithSession({
    String? accessToken,
    String? tenantId,
  }) async {
    lastPermissionAccessToken = accessToken;
    lastPermissionTenantId = tenantId;
    return const PermissionInfoDto(userId: 'user-1', nickname: 'tester');
  }
}

class _FakeDeviceInfoService extends DeviceInfoService {
  _FakeDeviceInfoService(this._deviceInfo);

  final DeviceInfo _deviceInfo;

  @override
  Future<DeviceInfo> getOrCreate() async => _deviceInfo;
}
