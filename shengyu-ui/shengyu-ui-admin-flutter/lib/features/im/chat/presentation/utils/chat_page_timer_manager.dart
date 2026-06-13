import 'dart:async';

/// ChatPage Timer 统一管理器
///
/// 职责：
/// 1. 集中管理所有 Timer 实例，避免分散声明
/// 2. dispose 时一键取消所有 Timer，防止资源泄漏
/// 3. 提供命名化访问，便于追踪和调试
class ChatPageTimerManager {
  final Map<String, Timer?> _timers = <String, Timer?>{};

  /// 获取指定名称的 Timer
  Timer? get(String name) => _timers[name];

  /// 设置单次 Timer
  void setOnce(String name, Timer timer) {
    cancel(name);
    _timers[name] = timer;
  }

  /// 设置周期性 Timer
  void setPeriodic(String name, Timer timer) {
    cancel(name);
    _timers[name] = timer;
  }

  /// 取消指定 Timer
  void cancel(String name) {
    final timer = _timers[name];
    if (timer != null && timer.isActive) {
      timer.cancel();
      _timers[name] = null;
    }
  }

  /// 取消所有 Timer，释放资源
  void cancelAll() {
    for (final entry in _timers.entries) {
      final timer = entry.value;
      if (timer != null && timer.isActive) {
        timer.cancel();
      }
    }
    _timers.clear();
  }

  /// 检查指定 Timer 是否存活
  bool isActive(String name) {
    final timer = _timers[name];
    return timer != null && timer.isActive;
  }
}
