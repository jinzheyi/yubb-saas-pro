import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';

void main() {
  test('getOrCreate creates device info without range error', () async {
    SharedPreferences.setMockInitialValues({});
    final service = DeviceInfoService();

    final info = await service.getOrCreate();

    expect(info.deviceId, isNotEmpty);
    expect(info.deviceType, 1);
    expect(info.deviceName, isNotEmpty);
    expect(info.clientVersion, isNotEmpty);
  });
}
