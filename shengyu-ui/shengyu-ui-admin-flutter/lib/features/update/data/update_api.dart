import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/update/domain/app_update_info.dart';

final updateApiProvider = Provider<UpdateApi>((ref) {
  return UpdateApi(ref.read(dioProvider));
});

class UpdateApi {
  const UpdateApi(this._dio);

  final Dio _dio;

  Future<AppUpdateInfo> checkUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final response = await _dio.get<Map<String, dynamic>>(
      '/system/app-release/check',
      queryParameters: {
        'appKey': 'yuxin',
        'platform': _platformCode(),
        'versionName': packageInfo.version,
        'versionCode': int.tryParse(packageInfo.buildNumber) ?? 1,
        'channel': 'prod',
      },
    );
    final result = ApiResult.fromJson<AppUpdateInfo>(
      response.data ?? const {},
      dataParser: (raw) {
        if (raw is Map<String, dynamic>) {
          return AppUpdateInfo.fromJson(raw);
        }
        if (raw is Map) {
          return AppUpdateInfo.fromJson(Map<String, dynamic>.from(raw));
        }
        return AppUpdateInfo.none();
      },
    );
    return result.requireData();
  }

  String _platformCode() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
