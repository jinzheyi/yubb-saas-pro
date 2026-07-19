import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';

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

class TokenStorage {
  TokenStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(
      key: StorageKeyRegistry.accessToken,
      value: session.accessToken,
    );
    await _secureStorage.write(
      key: StorageKeyRegistry.refreshToken,
      value: session.refreshToken,
    );
    await prefs.setString(StorageKeyRegistry.userId, session.userId);
    await prefs.setString(StorageKeyRegistry.tenantId, session.tenantId);
    if (session.tenantName != null) {
      await prefs.setString(StorageKeyRegistry.tenantName, session.tenantName!);
    } else {
      await prefs.remove(StorageKeyRegistry.tenantName);
    }
    await prefs.setString(StorageKeyRegistry.locale, session.locale);
    await prefs.setString(StorageKeyRegistry.deviceId, session.deviceId);
    await prefs.setInt(StorageKeyRegistry.deviceType, session.deviceType);
    await prefs.setString(StorageKeyRegistry.deviceName, session.deviceName);
    await prefs.setString(
      StorageKeyRegistry.clientVersion,
      session.clientVersion,
    );
  }

  Future<AuthSession?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = await _secureStorage.read(
      key: StorageKeyRegistry.accessToken,
    );
    final refreshToken = await _secureStorage.read(
      key: StorageKeyRegistry.refreshToken,
    );
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    return AuthSession(
      userId: prefs.getString(StorageKeyRegistry.userId) ?? '',
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      tenantId: prefs.getString(StorageKeyRegistry.tenantId) ?? '',
      tenantName: prefs.getString(StorageKeyRegistry.tenantName),
      deviceId: prefs.getString(StorageKeyRegistry.deviceId) ?? '',
      // 【关键修复】deviceType 和 deviceName 必须始终根据当前平台动态检测，
      // 不能从缓存读取或使用硬编码默认值，否则会导致跨平台互踢错误。
      deviceType: prefs.getInt(StorageKeyRegistry.deviceType) ?? _currentDeviceTypeValue(),
      deviceName: prefs.getString(StorageKeyRegistry.deviceName) ?? _currentDeviceName(),
      clientVersion:
          prefs.getString(StorageKeyRegistry.clientVersion) ?? '1.0.0',
      locale: prefs.getString(StorageKeyRegistry.locale) ?? 'zh-CN',
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: StorageKeyRegistry.accessToken);
    await _secureStorage.delete(key: StorageKeyRegistry.refreshToken);
    await prefs.remove(StorageKeyRegistry.userId);
    await prefs.remove(StorageKeyRegistry.tenantId);
    await prefs.remove(StorageKeyRegistry.tenantName);
    await prefs.remove(StorageKeyRegistry.locale);
    await prefs.remove(StorageKeyRegistry.deviceId);
    await prefs.remove(StorageKeyRegistry.deviceType);
    await prefs.remove(StorageKeyRegistry.deviceName);
    await prefs.remove(StorageKeyRegistry.clientVersion);
    await prefs.remove(StorageKeyRegistry.imBadgeSnapshot);
    await prefs.remove(StorageKeyRegistry.conversationCursorVersion);
    await prefs.remove(StorageKeyRegistry.groupRemovalNotice);
    await _clearPrefsWithPrefix(StorageKeyRegistry.voicePlayedPrefix);
    await _clearPrefsWithPrefix(StorageKeyRegistry.reeditHintPrefix);
  }

  Future<void> _clearPrefsWithPrefix(String prefix) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
