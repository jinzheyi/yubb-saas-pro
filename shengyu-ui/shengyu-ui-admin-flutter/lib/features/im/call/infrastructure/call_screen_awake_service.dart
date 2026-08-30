import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the physical display awake only while a call surface is visible.
///
/// A lease is deliberately used instead of a boolean: a foreground Flutter
/// call page may overlap briefly with the native incoming-call surface during
/// handoff. Releasing either one must not let the screen sleep prematurely.
class CallScreenAwakeService {
  static const MethodChannel _channel = MethodChannel(
    'com.shengyu.im/call_screen_awake',
  );

  final Set<Object> _leases = <Object>{};

  bool get isHeld => _leases.isNotEmpty;

  Object acquire() {
    final lease = Object();
    final wasHeld = isHeld;
    _leases.add(lease);
    if (!wasHeld) _setKeepScreenOn(true);
    return lease;
  }

  void release(Object lease) {
    if (!_leases.remove(lease) || isHeld) return;
    _setKeepScreenOn(false);
  }

  void clear() {
    if (!isHeld) return;
    _leases.clear();
    _setKeepScreenOn(false);
  }

  void _setKeepScreenOn(bool enabled) {
    if (kIsWeb) return;
    // Native call UI is not available on every desktop target. A missing
    // platform channel must never affect the call state machine.
    _channel.invokeMethod<void>('setKeepScreenOn', enabled).catchError((_) {});
  }
}
