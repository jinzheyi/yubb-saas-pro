import 'package:flutter/foundation.dart';

/// 根据当前平台获取设备类型（与 DeviceType.current 保持一致）
int _currentDeviceTypeValue() {
  if (kIsWeb) return 1;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 2;
    case TargetPlatform.android:
      return 3;
    default:
      return 1;
  }
}

/// 根据当前平台获取设备名称
String _currentDeviceName() {
  if (kIsWeb) return 'Web 浏览器';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'iOS 设备';
    case TargetPlatform.android:
      return 'Android 设备';
    default:
      return 'Web 浏览器';
  }
}

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    this.tenantName,
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.clientVersion,
    required this.locale,
  });

  factory AuthSession.anonymous() => AuthSession(
    userId: '',
    accessToken: '',
    refreshToken: '',
    tenantId: '',
    tenantName: null,
    deviceId: 'flutter-debug-device',
    deviceType: _currentDeviceTypeValue(),
    deviceName: _currentDeviceName(),
    clientVersion: '1.0.0',
    locale: 'zh-CN',
  );

  final String userId;
  final String accessToken;
  final String refreshToken;
  final String tenantId;
  final String? tenantName;
  final String deviceId;
  final int deviceType;
  final String deviceName;
  final String clientVersion;
  final String locale;

  bool get isAuthenticated => accessToken.isNotEmpty;

  AuthSession copyWith({
    String? userId,
    String? accessToken,
    String? refreshToken,
    String? tenantId,
    String? tenantName,
    String? deviceId,
    int? deviceType,
    String? deviceName,
    String? clientVersion,
    String? locale,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      clientVersion: clientVersion ?? this.clientVersion,
      locale: locale ?? this.locale,
    );
  }
}
