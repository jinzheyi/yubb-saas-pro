import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/call_screen_awake_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.shengyu.im/call_screen_awake');

  test(
    'keeps the screen awake until every call surface releases its lease',
    () async {
      final calls = <bool>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'setKeepScreenOn');
            calls.add(call.arguments as bool);
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final service = CallScreenAwakeService();
      final nativeIncoming = service.acquire();
      final callPage = service.acquire();
      await Future<void>.delayed(Duration.zero);

      expect(service.isHeld, isTrue);
      expect(calls, <bool>[true]);

      service.release(nativeIncoming);
      await Future<void>.delayed(Duration.zero);
      expect(service.isHeld, isTrue);
      expect(calls, <bool>[true]);

      service.release(callPage);
      await Future<void>.delayed(Duration.zero);
      expect(service.isHeld, isFalse);
      expect(calls, <bool>[true, false]);
    },
  );
}
