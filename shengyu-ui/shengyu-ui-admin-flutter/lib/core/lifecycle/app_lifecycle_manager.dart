import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/websocket/socket_session_coordinator.dart';

/// App 生命周期状态
enum ShengyuAppLifecycleState {
  resumed, // 前台活跃
  inactive, // 非活跃（如来电、分屏）
  paused, // 后台
  hidden, // 完全隐藏
  detached, // 从引擎分离
}

/// App 生命周期管理器（单例）
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  final StreamController<ShengyuAppLifecycleState> _stateController =
      StreamController<ShengyuAppLifecycleState>.broadcast();

  ShengyuAppLifecycleState _currentState = ShengyuAppLifecycleState.resumed;

  /// 当前生命周期状态
  ShengyuAppLifecycleState get currentState => _currentState;

  /// 状态流
  Stream<ShengyuAppLifecycleState> get stateStream => _stateController.stream;

  /// 是否在前台
  bool get isResumed => _currentState == ShengyuAppLifecycleState.resumed;

  /// 是否在后台
  bool get isInBackground =>
      _currentState == ShengyuAppLifecycleState.paused ||
      _currentState == ShengyuAppLifecycleState.hidden;

  DateTime? _enterBackgroundTime;
  SocketSessionCoordinator? _socketCoordinator;

  /// 设置 WebSocket 协调器引用（在初始化时注入）
  void setSocketCoordinator(SocketSessionCoordinator coordinator) {
    _socketCoordinator = coordinator;
  }

  /// 初始化生命周期监控
  void init() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[AppLifecycleManager] initialized');
  }

  /// 销毁
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final oldState = _currentState;
    _currentState = _mapFlutterState(state);

    debugPrint(
      '[AppLifecycleManager] lifecycle changed: ${oldState.name} -> ${_currentState.name}',
    );

    if (oldState == _currentState) {
      return;
    }

    _stateController.add(_currentState);

    // 处理状态变化
    _handleLifecycleChange(oldState, _currentState);
  }

  /// 映射 Flutter 原生状态到应用状态
  ShengyuAppLifecycleState _mapFlutterState(AppLifecycleState flutterState) {
    switch (flutterState) {
      case AppLifecycleState.resumed:
        return ShengyuAppLifecycleState.resumed;
      case AppLifecycleState.inactive:
        return ShengyuAppLifecycleState.inactive;
      case AppLifecycleState.paused:
        return ShengyuAppLifecycleState.paused;
      case AppLifecycleState.hidden:
        return ShengyuAppLifecycleState.hidden;
      case AppLifecycleState.detached:
        return ShengyuAppLifecycleState.detached;
    }
  }

  /// 处理生命周期变化
  void _handleLifecycleChange(
    ShengyuAppLifecycleState oldState,
    ShengyuAppLifecycleState newState,
  ) {
    final wasInBackground = _isBackgroundState(oldState);
    final isInBackground = _isBackgroundState(newState);

    // Flutter 通常会先进入 inactive，再进入 hidden/paused。
    // 以是否跨越后台状态集合为准，不能依赖 resumed -> paused 的直接跳转。
    if (!wasInBackground && isInBackground) {
      _onEnterBackground();
    }

    if (newState == ShengyuAppLifecycleState.resumed &&
        (wasInBackground || _enterBackgroundTime != null)) {
      _onResumeFromBackground();
    }
  }

  bool _isBackgroundState(ShengyuAppLifecycleState state) =>
      state == ShengyuAppLifecycleState.paused ||
      state == ShengyuAppLifecycleState.hidden ||
      state == ShengyuAppLifecycleState.detached;

  /// 进入后台处理
  void _onEnterBackground() {
    _enterBackgroundTime = DateTime.now();

    // 主动标记连接为 stale，避免后台连接被系统静默关闭
    debugPrint(
      '[AppLifecycleManager] entering background, marking connection as stale',
    );

    // 如果 socket coordinator 可用，通知连接状态变化
    _socketCoordinator?.notifyAppBackgrounded();
  }

  /// 回到前台处理
  void _onResumeFromBackground() {
    final backgroundDuration = _enterBackgroundTime != null
        ? DateTime.now().difference(_enterBackgroundTime!)
        : Duration.zero;

    _enterBackgroundTime = null;

    debugPrint(
      '[AppLifecycleManager] resumed from background, was away for ${backgroundDuration.inSeconds}s',
    );

    // 如果离开超过 30 秒，强制重连（因为 TCP 连接可能已被系统或服务器关闭）
    if (backgroundDuration.inSeconds > 30) {
      debugPrint(
        '[AppLifecycleManager] background duration > 30s, forcing reconnect',
      );
      _socketCoordinator?.forceReconnect();
    } else {
      // 短暂离开，仅检查连接状态
      _socketCoordinator?.checkAndReconnectIfStale();
    }
  }
}

/// Riverpod Provider
final appLifecycleManagerProvider = Provider<AppLifecycleManager>((ref) {
  final manager = AppLifecycleManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// 当前 App 生命周期状态 Provider
final appLifecycleStateProvider = StateProvider<ShengyuAppLifecycleState>((
  ref,
) {
  return ShengyuAppLifecycleState.resumed;
});
