import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';

/// 通话悬浮窗管理器
///
/// 通过根 Overlay 管理通话最小化时的全局悬浮窗。
/// 悬浮窗在通话进行中显示，通话结束后自动移除。
/// 点击悬浮窗可恢复到通话界面。
class CallFloatingWindowManager extends ChangeNotifier {
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;
  
  /// 存储当前通话的路由参数，用于恢复导航
  CallLaunchArgs? _callArgs;
  String? _routeName;

  /// 存储媒体状态，用于页面恢复时保留摄像头/麦克风等状态
  CallMediaState? _savedMediaState;

  /// 恢复回调函数（在原始页面 context 中创建，可正确访问 GoRouter）
  VoidCallback? _restoreCallback;

  bool get isVisible => _isVisible;
  CallLaunchArgs? get callArgs => _callArgs;
  String? get routeName => _routeName;
  CallMediaState? get savedMediaState => _savedMediaState;
  VoidCallback? get restoreCallback => _restoreCallback;

  /// 保存当前媒体状态（在最小化前调用）
  void saveMediaState(CallMediaState state) {
    _savedMediaState = state;
  }

  /// 获取并清除已保存的媒体状态（在恢复时调用）
  CallMediaState? takeSavedMediaState() {
    final state = _savedMediaState;
    _savedMediaState = null;
    return state;
  }

  /// 显示悬浮窗（使用根 Overlay，不受页面导航影响）
  void show({
    required OverlayState rootOverlay,
    required WidgetBuilder builder,
    CallLaunchArgs? callArgs,
    String? routeName,
    VoidCallback? onRestore,
  }) {
    if (_isVisible) {
      // 已经显示，先隐藏旧的
      _removeOverlayEntry();
    }

    _callArgs = callArgs;
    _routeName = routeName;
    _restoreCallback = onRestore;

    try {
      _overlayEntry = OverlayEntry(
        builder: builder,
      );

      rootOverlay.insert(_overlayEntry!);
      _isVisible = true;
      notifyListeners();
    } catch (e) {
      // 插入失败，清理状态
      _overlayEntry = null;
      _isVisible = false;
      _callArgs = null;
      _routeName = null;
      _restoreCallback = null;
      debugPrint('[CallFloatingWindowManager] 显示悬浮窗失败: $e');
    }
  }

  /// 移除 overlay entry（内部方法）
  void _removeOverlayEntry() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        // 移除失败，可能是 overlay 已经被销毁
        debugPrint('[CallFloatingWindowManager] 移除悬浮窗失败: $e');
      }
      _overlayEntry = null;
    }
  }

  /// 隐藏悬浮窗
  ///
  /// 注意：不清理 _savedMediaState，因为 CallController.initialize() 在恢复时需要读取它。
  /// _savedMediaState 会在 CallController.initialize() 中通过 takeSavedMediaState() 读取并清除。
  void hide() {
    if (!_isVisible && _overlayEntry == null) {
      // 已经隐藏，无需操作
      return;
    }

    _removeOverlayEntry();
    
    final wasVisible = _isVisible;
    _isVisible = false;
    _callArgs = null;
    _routeName = null;
    _restoreCallback = null;
    
    // 不清理 _savedMediaState，由 CallController.initialize() 负责清理
    
    // 只有在状态确实改变时才通知监听器
    if (wasVisible) {
      notifyListeners();
    }
  }

  /// 强制清理所有状态（仅在通话结束时调用）
  ///
  /// 用于通话结束后彻底清理所有状态，防止内存泄漏
  void forceCleanup() {
    final hadOverlay = _overlayEntry != null || _isVisible;
    final hadMediaState = _savedMediaState != null;
    
    _removeOverlayEntry();
    
    _isVisible = false;
    _callArgs = null;
    _routeName = null;
    _restoreCallback = null;
    _savedMediaState = null;
    
    // 只有在状态确实改变时才通知监听器
    if (hadOverlay || hadMediaState) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    forceCleanup();
    super.dispose();
  }
}

/// Provider：悬浮窗管理器（全局单例）
final callFloatingWindowManagerProvider =
    ChangeNotifierProvider<CallFloatingWindowManager>((ref) {
  final manager = CallFloatingWindowManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider：悬浮窗是否可见
final isCallFloatingWindowVisibleProvider = Provider<bool>((ref) {
  return ref.watch(callFloatingWindowManagerProvider).isVisible;
});
