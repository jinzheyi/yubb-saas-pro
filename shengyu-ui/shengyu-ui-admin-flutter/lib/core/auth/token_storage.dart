import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';

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
      deviceId: prefs.getString(StorageKeyRegistry.deviceId) ?? '',
      deviceType: prefs.getInt(StorageKeyRegistry.deviceType) ?? 1,
      deviceName:
          prefs.getString(StorageKeyRegistry.deviceName) ?? 'Flutter Client',
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
    await prefs.remove(StorageKeyRegistry.locale);
  }
}
