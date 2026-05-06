import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_token_dto.dart';
import 'package:shengyu_ui_admin_im/core/auth/permission_info_dto.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.read(dioProvider));
});

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthTokenDto> login({
    required String username,
    required String password,
    required int deviceType,
    required String deviceId,
    required String clientVersion,
  }) async {
    final response = await _dio.post(
      '/system/auth/login',
      data: {
        'username': username,
        'password': password,
        'deviceType': deviceType,
        'deviceId': deviceId,
        'clientVersion': clientVersion,
      },
    );
    final result = ApiResult.fromJson<AuthTokenDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return AuthTokenDto.fromJson(raw as Map<String, dynamic>? ?? const {});
      },
    );
    return result.requireData();
  }

  Future<AuthTokenDto> refreshToken({required String refreshToken}) async {
    final response = await _dio.post(
      '/system/auth/refresh-token?refreshToken=$refreshToken',
    );
    final result = ApiResult.fromJson<AuthTokenDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return AuthTokenDto.fromJson(raw as Map<String, dynamic>? ?? const {});
      },
    );
    return result.requireData();
  }

  Future<PermissionInfoDto> getPermissionInfo() async {
    return getPermissionInfoWithSession();
  }

  Future<PermissionInfoDto> getPermissionInfoWithSession({
    String? accessToken,
    String? tenantId,
  }) async {
    final response = await _dio.get(
      '/system/auth/get-permission-info',
      options: Options(
        headers: _buildPermissionHeaders(
          path: '/system/auth/get-permission-info',
          accessToken: accessToken,
          tenantId: tenantId,
        ),
      ),
    );
    final result = ApiResult.fromJson<PermissionInfoDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return PermissionInfoDto.fromJson(
          raw as Map<String, dynamic>? ?? const {},
        );
      },
    );
    return result.requireData();
  }

  Map<String, dynamic> _buildPermissionHeaders({
    required String path,
    String? accessToken,
    String? tenantId,
  }) {
    final headers = <String, dynamic>{};
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        AppConfig.shouldAttachAuthorizationHeader(path)) {
      AppConfig.putHeader(
        headers,
        AppConfig.authorizationHeader,
        AppConfig.formatAuthorization(accessToken),
      );
    }
    if (tenantId != null &&
        tenantId.isNotEmpty &&
        AppConfig.shouldAttachTenantHeader(path)) {
      AppConfig.putHeader(headers, AppConfig.tenantIdHeader, tenantId);
    }
    return headers;
  }
}
