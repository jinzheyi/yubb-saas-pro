import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/features/im/notification/infrastructure/fcm_notification_gateway.dart';

class PushDeviceRegistrationService {
  PushDeviceRegistrationService(this._dio, this._gateway, this._session);
  final Dio _dio;
  final FcmNotificationGateway _gateway;
  final AuthSession Function() _session;
  StreamSubscription<String>? _refreshSubscription;

  Future<void> registerCurrentDevice() async {
    try {
      final session = _session();
      if (!session.isAuthenticated) return;
      await _gateway.initialize();
      final token = await _gateway.currentToken();
      if (token == null || token.isEmpty) return;
      final permissionState = await _gateway.permissionState();
      await _dio.post(
        '/system/im/push/device-token',
        data: {
          'provider': 'fcm',
          'token': token,
          'deviceId': session.deviceId,
          'platform': kIsWeb
              ? 'web'
              : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          'appVersion': session.clientVersion,
          'permissionState': permissionState,
        },
      );
      debugPrint('[Fcm] device registration succeeded');
      _refreshSubscription ??= _gateway.tokenRefreshes.listen(
        (_) => unawaited(registerCurrentDevice()),
      );
    } catch (error) {
      // A FCM token is a credential. Do not log it or a request body.
      debugPrint('[Fcm] device registration failed: ${error.runtimeType}');
    }
  }

  Future<void> unregisterCurrentDevice() async {
    return unregisterSessionDevice(_session());
  }

  Future<void> unregisterSessionDevice(AuthSession session) async {
    if (!session.isAuthenticated) return;
    await _dio.delete(
      '/system/im/push/device-token',
      queryParameters: {'provider': 'fcm', 'deviceId': session.deviceId},
    );
  }
}
