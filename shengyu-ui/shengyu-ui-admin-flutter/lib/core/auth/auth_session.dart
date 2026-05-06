class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.clientVersion,
    required this.locale,
  });

  const AuthSession.anonymous()
    : userId = '',
      accessToken = '',
      refreshToken = '',
      tenantId = '',
      deviceId = 'flutter-debug-device',
      deviceType = 1,
      deviceName = 'Flutter Client',
      clientVersion = '1.0.0',
      locale = 'zh-CN';

  final String userId;
  final String accessToken;
  final String refreshToken;
  final String tenantId;
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
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      clientVersion: clientVersion ?? this.clientVersion,
      locale: locale ?? this.locale,
    );
  }
}
