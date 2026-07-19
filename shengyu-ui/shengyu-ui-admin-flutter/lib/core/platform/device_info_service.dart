import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

/// 设备类型枚举（与后端保持一致）
/// 1-Web 2-iOS 3-Android 4-小程序
enum DeviceType {
  web(1, 'Web'),
  ios(2, 'iOS'),
  android(3, 'Android'),
  miniProgram(4, '小程序');

  final int value;
  final String label;

  const DeviceType(this.value, this.label);

  /// 根据当前平台获取设备类型
  static DeviceType get current {
    if (kIsWeb) return DeviceType.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return DeviceType.ios;
      case TargetPlatform.android:
        return DeviceType.android;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return DeviceType.web;
      case TargetPlatform.fuchsia:
        return DeviceType.web;
    }
  }
}

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
    final existingClientVersion = prefs.getString(
      StorageKeyRegistry.clientVersion,
    );

    // deviceType 和 deviceName 必须始终根据当前平台动态检测
    final currentDeviceType = DeviceType.current;
    final currentDeviceName = await _getDeviceName(currentDeviceType);

    // deviceId 和 clientVersion 可以复用缓存（它们是稳定值）
    final deviceId = existingDeviceId ?? _generateDeviceId();
    final clientVersion = existingClientVersion ?? '1.0.0';

    final info = DeviceInfo(
      deviceType: currentDeviceType.value,
      deviceId: deviceId,
      deviceName: currentDeviceName,
      clientVersion: clientVersion,
    );

    // 持久化所有字段（deviceType/deviceName 每次都会更新为当前平台值）
    await prefs.setString(StorageKeyRegistry.deviceId, info.deviceId);
    await prefs.setInt(StorageKeyRegistry.deviceType, info.deviceType);
    await prefs.setString(StorageKeyRegistry.deviceName, info.deviceName);
    await prefs.setString(StorageKeyRegistry.clientVersion, info.clientVersion);
    return info;
  }

  /// 获取精确的设备名称（品牌 + 型号）
  Future<String> _getDeviceName(DeviceType deviceType) async {
    final plugin = DeviceInfoPlugin();
    switch (deviceType) {
      case DeviceType.web:
        return _getWebDeviceName(plugin);
      case DeviceType.ios:
        return _getIosDeviceName(plugin);
      case DeviceType.android:
        return _getAndroidDeviceName(plugin);
      case DeviceType.miniProgram:
        return '小程序';
    }
  }

  /// Web 端：浏览器名称
  Future<String> _getWebDeviceName(DeviceInfoPlugin plugin) async {
    try {
      final info = await plugin.webBrowserInfo;
      return info.browserName.name;
    } catch (_) {
      return 'Web 浏览器';
    }
  }

  /// iOS 端：设备型号名称（如 "iPhone 15 Pro"）
  Future<String> _getIosDeviceName(DeviceInfoPlugin plugin) async {
    try {
      final info = await plugin.iosInfo;
      final name = info.name; // 用户自定义的设备名，如 "张三的 iPhone"
      final model = info.model; // 设备型号，如 "iPhone16,2"
      final systemName = info.systemName; // "iOS"
      final systemVersion = info.systemVersion; // "17.0"

      // 优先使用用户自定义的设备名，回退到型号
      if (name.isNotEmpty) {
        return '$name ($systemName $systemVersion)';
      }
      if (model.isNotEmpty) {
        return '$model ($systemName $systemVersion)';
      }
      return 'iOS 设备';
    } catch (_) {
      return 'iOS 设备';
    }
  }

  /// Android 端：品牌 + 型号（如 "Xiaomi 13"）
  Future<String> _getAndroidDeviceName(DeviceInfoPlugin plugin) async {
    try {
      final info = await plugin.androidInfo;
      final brand = info.brand; // 品牌，如 "Xiaomi"
      final model = info.model; // 型号，如 "2211133C"
      final release = info.version.release; // Android 版本，如 "14"

      if (brand.isNotEmpty && model.isNotEmpty) {
        return '$brand $model (Android $release)';
      }
      if (model.isNotEmpty) {
        return '$model (Android $release)';
      }
      return 'Android 设备';
    } catch (_) {
      return 'Android 设备';
    }
  }

  String _generateDeviceId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    final high = random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    final low = random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    return '$now-$high$low';
  }
}
