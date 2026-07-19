import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';

void main() {
  group('DeviceInfoService Tests', () {
    test('T1/T2: 设备类型枚举与后端一致', () {
      // 验证设备类型定义与后端一致
      expect(DeviceType.web.value, 1);
      expect(DeviceType.ios.value, 2);
      expect(DeviceType.android.value, 3);
      expect(DeviceType.miniProgram.value, 4);
    });

    test('T1/T2: 设备类型标签正确', () {
      expect(DeviceType.web.label, 'Web');
      expect(DeviceType.ios.label, 'iOS');
      expect(DeviceType.android.label, 'Android');
      expect(DeviceType.miniProgram.label, '小程序');
    });

    test('T1/T2: 根据平台动态获取设备类型', () {
      // 模拟不同平台
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(DeviceType.current, DeviceType.ios);
      expect(DeviceType.current.value, 2);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(DeviceType.current, DeviceType.android);
      expect(DeviceType.current.value, 3);

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(DeviceType.current, DeviceType.web);
      expect(DeviceType.current.value, 1);

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(DeviceType.current, DeviceType.web);
      expect(DeviceType.current.value, 1);

      // 恢复默认
      debugDefaultTargetPlatformOverride = null;
    });

    test('T5: DeviceInfo 包含完整字段', () {
      final info = DeviceInfo(
        deviceType: 3,
        deviceId: 'test-device-123',
        deviceName: 'Test Android',
        clientVersion: '1.0.0',
      );

      expect(info.deviceType, 3);
      expect(info.deviceId, 'test-device-123');
      expect(info.deviceName, 'Test Android');
      expect(info.clientVersion, '1.0.0');
    });

    test('T5: DeviceInfo 支持可选参数', () {
      final info = DeviceInfo(
        deviceType: 2,
        deviceId: 'ios-device-456',
        deviceName: 'iPhone 15',
        clientVersion: '1.0.0',
      );

      expect(info.deviceType, 2);
      expect(info.deviceId, 'ios-device-456');
      expect(info.deviceName, 'iPhone 15');
      expect(info.clientVersion, '1.0.0');
    });

    test('T1/T2: 设备类型枚举支持 fromValue', () {
      expect(DeviceType.fromValue(1), DeviceType.web);
      expect(DeviceType.fromValue(2), DeviceType.ios);
      expect(DeviceType.fromValue(3), DeviceType.android);
      expect(DeviceType.fromValue(4), DeviceType.miniProgram);
      expect(DeviceType.fromValue(99), DeviceType.web); // 未知类型默认为 web
    });
  });
}
