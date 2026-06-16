enum DeviceType {
  web(1, 'Web'),
  windows(2, 'Windows'),
  mac(3, 'macOS'),
  android(4, 'Android'),
  ios(5, 'iOS'),
  miniProgram(6, '小程序');

  const DeviceType(this.value, this.label);

  final int value;
  final String label;

  static DeviceType fromValue(int? value) {
    return DeviceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeviceType.web,
    );
  }
}

class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.loginTime,
    required this.lastActiveTime,
    required this.isCurrentDevice,
    this.ipAddress = '',
    this.location = '',
  });

  final String deviceId;
  final DeviceType deviceType;
  final String deviceName;
  final DateTime loginTime;
  final DateTime lastActiveTime;
  final bool isCurrentDevice;
  final String ipAddress;
  final String location;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    final loginTimeRaw = json['loginTime']?.toString() ?? '';
    final lastActiveRaw = json['lastActiveTime']?.toString() ?? '';

    return DeviceInfo(
      deviceId: json['deviceId']?.toString() ?? '',
      deviceType: DeviceType.fromValue(
        json['deviceType'] is num
            ? (json['deviceType'] as num).toInt()
            : int.tryParse(json['deviceType']?.toString() ?? '') ?? 0,
      ),
      deviceName: json['deviceName']?.toString() ?? '',
      loginTime: _parseDateTime(loginTimeRaw),
      lastActiveTime: _parseDateTime(lastActiveRaw),
      isCurrentDevice: _parseBool(json['isCurrentDevice']),
      ipAddress: json['ipAddress']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }

  static DateTime _parseDateTime(String value) {
    if (value.isEmpty) return DateTime.now();
    // Try ISO 8601 first
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    // Try parsing as timestamp (milliseconds)
    final ms = int.tryParse(value);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.now();
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  DeviceInfo copyWith({
    bool? isCurrentDevice,
  }) {
    return DeviceInfo(
      deviceId: deviceId,
      deviceType: deviceType,
      deviceName: deviceName,
      loginTime: loginTime,
      lastActiveTime: lastActiveTime,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
      ipAddress: ipAddress,
      location: location,
    );
  }
}
