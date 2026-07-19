import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/token_storage.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.read(flutterSecureStorageProvider));
});

final authSessionProvider =
    StateNotifierProvider<AuthSessionController, AuthSession>((ref) {
      return AuthSessionController(
        ref.read(tokenStorageProvider),
        ref.read(deviceInfoServiceProvider),
      );
    });

class AuthSessionController extends StateNotifier<AuthSession> {
  AuthSessionController(this._tokenStorage, this._deviceInfoService)
    : super(AuthSession.anonymous());

  final TokenStorage _tokenStorage;
  final DeviceInfoService _deviceInfoService;

  Future<void> restore() async {
    final persisted = await _tokenStorage.readSession();
    final deviceInfo = await _deviceInfoService.getOrCreate();
    state = (persisted ?? AuthSession.anonymous()).copyWith(
      deviceId: deviceInfo.deviceId,
      deviceType: deviceInfo.deviceType,
      deviceName: deviceInfo.deviceName,
      clientVersion: deviceInfo.clientVersion,
    );
  }

  Future<void> saveSession(AuthSession session) async {
    final deviceInfo = await _deviceInfoService.getOrCreate();
    final next = session.copyWith(
      deviceId: deviceInfo.deviceId,
      deviceType: deviceInfo.deviceType,
      deviceName: deviceInfo.deviceName,
      clientVersion: deviceInfo.clientVersion,
    );
    await _tokenStorage.saveSession(next);
    state = next;
  }

  Future<void> clearSession() async {
    await _tokenStorage.clear();
    final deviceInfo = await _deviceInfoService.getOrCreate();
    state = AuthSession.anonymous().copyWith(
      deviceId: deviceInfo.deviceId,
      deviceType: deviceInfo.deviceType,
      deviceName: deviceInfo.deviceName,
      clientVersion: deviceInfo.clientVersion,
    );
  }

  Future<void> updateLocale(String locale) async {
    final next = state.copyWith(locale: locale);
    await _tokenStorage.saveSession(next);
    state = next;
  }
}
