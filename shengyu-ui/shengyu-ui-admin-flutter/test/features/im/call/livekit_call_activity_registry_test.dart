import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/livekit_call_providers.dart';

void main() {
  group('LiveKitCallActivityRegistry', () {
    test('tracks a single call lease', () {
      final registry = LiveKitCallActivityRegistry();

      expect(registry.isActive, isFalse);

      final lease = registry.acquire();
      expect(registry.isActive, isTrue);

      registry.release(lease);
      expect(registry.isActive, isFalse);
    });

    test('tracks and updates the active call id', () {
      final registry = LiveKitCallActivityRegistry();
      final lease = registry.acquire();

      expect(registry.activeCallId, isNull);
      registry.update(lease, 'call-1');
      expect(registry.activeCallId, 'call-1');

      registry.release(lease);
      expect(registry.activeCallId, isNull);
    });

    test('stays active until every overlapping lease is released', () {
      final registry = LiveKitCallActivityRegistry();
      final firstLease = registry.acquire();
      final secondLease = registry.acquire();

      registry.release(firstLease);
      expect(registry.isActive, isTrue);

      registry.release(secondLease);
      expect(registry.isActive, isFalse);
    });

    test('release is idempotent and clear resets all leases', () {
      final registry = LiveKitCallActivityRegistry();
      final lease = registry.acquire();
      registry.acquire();

      registry.release(lease);
      registry.release(lease);
      expect(registry.isActive, isTrue);

      registry.clear();
      expect(registry.isActive, isFalse);
    });
  });
}
