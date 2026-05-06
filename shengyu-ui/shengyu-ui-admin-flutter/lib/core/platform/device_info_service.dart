import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

class DeviceInfo {
  const DeviceInfo({
    required this.deviceType,
    required this.deviceId,
    required this.deviceName,
    required this.clientVersion,
  });

  final int deviceType;
  final String deviceId;
  final String deviceName;
  final String clientVersion;
}

class DeviceInfoService {
  Future<DeviceInfo> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existingDeviceId = prefs.getString(StorageKeyRegistry.deviceId);
    final existingDeviceType = prefs.getInt(StorageKeyRegistry.deviceType);
    final existingDeviceName = prefs.getString(StorageKeyRegistry.deviceName);
    final existingClientVersion = prefs.getString(
      StorageKeyRegistry.clientVersion,
    );

    if (existingDeviceId != null &&
        existingDeviceType != null &&
        existingDeviceName != null &&
        existingClientVersion != null) {
      return DeviceInfo(
        deviceType: existingDeviceType,
        deviceId: existingDeviceId,
        deviceName: existingDeviceName,
        clientVersion: existingClientVersion,
      );
    }

    final info = DeviceInfo(
      deviceType: 1,
      deviceId: _generateDeviceId(),
      deviceName: 'Flutter Client',
      clientVersion: '1.0.0',
    );
    await prefs.setString(StorageKeyRegistry.deviceId, info.deviceId);
    await prefs.setInt(StorageKeyRegistry.deviceType, info.deviceType);
    await prefs.setString(StorageKeyRegistry.deviceName, info.deviceName);
    await prefs.setString(StorageKeyRegistry.clientVersion, info.clientVersion);
    return info;
  }

  String _generateDeviceId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    final high = random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    final low = random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    return '$now-$high$low';
  }
}
