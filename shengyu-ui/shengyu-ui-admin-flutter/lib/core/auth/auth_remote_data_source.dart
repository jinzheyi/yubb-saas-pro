import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_token_dto.dart';
import 'package:shengyu_ui_admin_im/core/auth/permission_info_dto.dart';
import 'package:shengyu_ui_admin_im/core/auth/tenant_list_item_dto.dart';
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

  Future<void> sendRegisterEmailCode({required String email}) async {
    final response = await _dio.post(
      '/system/register/send-email-code',
      data: {'email': email},
    );
    final result = ApiResult.fromJson<bool>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => raw == true,
    );
    result.requireData();
  }

  Future<Map<String, dynamic>> registerTenant({
    required String username,
    required String emailCode,
    required String nickname,
    required String tenantName,
    String? mobile,
    required int deviceType,
    required String deviceId,
    required String clientVersion,
  }) async {
    final response = await _dio.post(
      '/system/register/tenant',
      data: {
        'username': username,
        'emailCode': emailCode,
        'nickname': nickname,
        'tenantName': tenantName,
        if (mobile != null && mobile.trim().isNotEmpty) 'mobile': mobile,
        'deviceType': deviceType,
        'deviceId': deviceId,
        'clientVersion': clientVersion,
      },
    );
    final result = ApiResult.fromJson<Map<String, dynamic>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => Map<String, dynamic>.from(raw as Map? ?? const {}),
    );
    return result.requireData();
  }

  Future<Map<String, dynamic>> joinTenantByInvite({
    required String email,
    required String emailCode,
    required String inviteCode,
    String? nickname,
  }) async {
    final response = await _dio.post(
      '/system/register/join-by-invite',
      data: {
        'email': email,
        'emailCode': emailCode,
        'inviteCode': inviteCode,
        if (nickname != null && nickname.trim().isNotEmpty)
          'nickname': nickname.trim(),
      },
    );
    final result = ApiResult.fromJson<Map<String, dynamic>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => Map<String, dynamic>.from(raw as Map? ?? const {}),
    );
    return result.requireData();
  }

  Future<AuthTokenDto> refreshToken({
    required String refreshToken,
    String? tenantId,
  }) async {
    final response = await _dio.post(
      '/system/auth/refresh-token?refreshToken=$refreshToken',
      options: Options(
        headers: _buildPermissionHeaders(
          path: '/system/auth/refresh-token',
          tenantId: tenantId,
        ),
      ),
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

  /// 获取租户列表
  Future<List<TenantListItemDto>> getMyTenantList() async {
    final response = await _dio.get('/system/user/get-my-tenant-list');
    final result = ApiResult.fromJson<List<TenantListItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        if (raw is! List) return [];
        return raw
            .whereType<Map>()
            .map(
              (e) => TenantListItemDto.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
    return result.requireData();
  }

  /// 切换租户
  Future<AuthTokenDto> toTenant({required String tenantId}) async {
    final response = await _dio.post(
      '/system/auth/to-tenant',
      data: {'id': tenantId},
    );
    final result = ApiResult.fromJson<AuthTokenDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return AuthTokenDto.fromJson(raw as Map<String, dynamic>? ?? const {});
      },
    );
    return result.requireData();
  }

  Future<Map<String, dynamic>> joinByInviteCode(String inviteCode) async {
    final response = await _dio.post(
      '/system/tenant-join/by-invite',
      data: {'inviteCode': inviteCode},
    );
    final result = ApiResult.fromJson<Map<String, dynamic>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => Map<String, dynamic>.from(raw as Map? ?? const {}),
    );
    return result.requireData();
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _dio.put(
      '/system/user/profile/update-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    final result = ApiResult.fromJson<bool>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => raw == true,
    );
    result.requireData();
  }
}
