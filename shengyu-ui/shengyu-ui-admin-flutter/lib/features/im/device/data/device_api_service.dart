import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/device/domain/device_info.dart';

class DeviceRemoteDataSource {
  const DeviceRemoteDataSource({required this.dio});

  final Dio dio;

  Future<List<DeviceInfo>> getDeviceList() async {
    final response = await dio.get('/system/im/device/list');
    final result = ApiResult.fromJson<List<DeviceInfo>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        if (raw is List) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map((json) => DeviceInfo.fromJson(json))
              .toList(growable: false);
        }
        return <DeviceInfo>[];
      },
    );
    return result.requireData();
  }

  Future<void> kickDevice(int deviceType, {String? deviceId}) async {
    final queryParameters = <String, dynamic>{'deviceType': deviceType};
    if (deviceId != null) {
      queryParameters['deviceId'] = deviceId;
    }
    await dio.post(
      '/system/im/device/kick',
      queryParameters: queryParameters,
    );
  }

  Future<bool> getOnlineStatus() async {
    final response = await dio.get('/system/im/device/online-status');
    final result = ApiResult.fromJson<bool>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        if (raw is bool) return raw;
        if (raw is num) return raw != 0;
        if (raw is String) return raw.toLowerCase() == 'true' || raw == '1';
        return false;
      },
    );
    return result.requireData();
  }
}
