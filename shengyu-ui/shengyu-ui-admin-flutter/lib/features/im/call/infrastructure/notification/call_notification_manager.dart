import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 通话通知管理器
/// 
/// 管理通话过程中的本地通知：
/// - 后台通话通知（应用进入后台时显示）
/// - 来电通知（应用未在前台时显示）
/// - 通话结束清理通知
/// 
/// 企业级特性：
/// - 平台自适应（iOS/Android 不同通知策略）
/// - 通知渠道管理（Android O+ 必需）
/// - 通知点击跳转（点击通知返回通话界面）
/// - 自动清理（通话结束时自动移除通知）
class CallNotificationManager {
  CallNotificationManager._();
  static final CallNotificationManager instance = CallNotificationManager._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  /// 后台通知固定 ID（使用固定值避免 ID 溢出）
  static const int _backgroundNotificationId = 9001;

  /// 来电通知基础 ID（用于计算 hashCode 偏移，避免碰撞）
  static const int _incomingCallNotificationBaseId = 10000;

  /// 正在进行的初始化 Future（防止并发初始化）
  Future<void>? _initializingFuture;

  /// 检查是否已初始化
  bool get isInitialized => _initialized;

  /// 初始化通知管理器
  /// 
  /// 必须在应用启动时调用，配置通知权限和渠道
  /// 支持并发安全：多次调用只执行一次初始化
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    // 防止并发初始化
    _initializingFuture ??= _doInitialize();
    try {
      await _initializingFuture;
    } finally {
      _initializingFuture = null;
    }
  }

  Future<void> _doInitialize() async {
    try {
      // Android 通知渠道配置
      const androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 通知配置
      const DarwinInitializationSettings iOSInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iOSInitializationSettings,
      );

      await _notifications.initialize(initializationSettings);

      // 创建 Android 通知渠道（通话通知）
      if (Platform.isAndroid) {
        const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
          'call_channel',
          '通话通知',
          description: '通话过程中的通知',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        // 创建全屏意图渠道（来电通知需要）
        const AndroidNotificationChannel incomingCallChannel = AndroidNotificationChannel(
          'incoming_call_channel',
          '来电通知',
          description: '来电时的全屏通知',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(callChannel);
          await androidImplementation.createNotificationChannel(incomingCallChannel);
        }
      }

      _initialized = true;
      debugPrint('[CallNotificationManager] 初始化成功');
    } catch (e) {
      debugPrint('[CallNotificationManager] 初始化失败: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// 显示后台通话通知
  /// 
  /// 当应用进入后台且通话进行中时调用
  /// 使用固定 ID，多次调用会更新同一条通知
  Future<void> showBackgroundCallNotification({
    required String callType,
    required String duration,
    String? callerName,
  }) async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (_) {
        return; // 初始化失败则不显示通知
      }
    }

    try {
      // Android 通知配置
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'call_channel',
        '通话通知',
        channelDescription: '通话过程中的通知',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        enableVibration: false,
        playSound: false,
      );

      // iOS 通知配置
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      final String title = '通话中';
      final String body = '$callType通话 - $duration';

      await _notifications.show(
        _backgroundNotificationId,
        title,
        body,
        notificationDetails,
        payload: 'call_background',
      );

      debugPrint('[CallNotificationManager] 后台通知已显示: $body');
    } catch (e) {
      debugPrint('[CallNotificationManager] 显示后台通知失败: $e');
    }
  }

  /// 显示来电通知
  /// 
  /// 当应用未在前台且收到来电时调用
  /// 使用 callSessionId 的绝对值 hashCode 作为通知 ID，确保同一来电不会重复显示
  Future<void> showIncomingCallNotification({
    required String callType,
    required String callerName,
    required String callSessionId,
  }) async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (_) {
        return; // 初始化失败则不显示通知
      }
    }

    try {
      // 使用全屏意图渠道（Android）
      final String channelId = Platform.isAndroid
          ? 'incoming_call_channel'
          : 'call_channel';

      // Android 通知配置（全屏意图）
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        Platform.isAndroid ? '来电通知' : '通话通知',
        channelDescription: Platform.isAndroid
            ? '来电时的全屏通知'
            : '通话过程中的通知',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: true,
        autoCancel: false,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.call,
      );

      // iOS 通知配置
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      final String title = '$callerName 邀请您参加$callType通话';
      const String body = '点击接听';

      // 使用绝对值避免负数 ID 导致崩溃
      final int notificationId =
          _incomingCallNotificationBaseId + callSessionId.hashCode.abs() % 9000;

      await _notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: callSessionId,
      );

      debugPrint('[CallNotificationManager] 来电通知已显示: $title (id=$notificationId)');
    } catch (e) {
      debugPrint('[CallNotificationManager] 显示来电通知失败: $e');
    }
  }

  /// 取消特定来电通知
  /// 
  /// 当来电被接听/拒绝/取消时调用
  Future<void> cancelIncomingCallNotification(String callSessionId) async {
    try {
      final int notificationId =
          _incomingCallNotificationBaseId + callSessionId.hashCode.abs() % 9000;
      await _notifications.cancel(notificationId);
      debugPrint('[CallNotificationManager] 来电通知已取消: id=$notificationId');
    } catch (e) {
      debugPrint('[CallNotificationManager] 取消来电通知失败: $e');
    }
  }

  /// 取消后台通话通知
  /// 
  /// 当应用恢复前台或通话结束时调用
  Future<void> cancelBackgroundNotification() async {
    try {
      await _notifications.cancel(_backgroundNotificationId);
      debugPrint('[CallNotificationManager] 后台通知已取消');
    } catch (e) {
      debugPrint('[CallNotificationManager] 取消后台通知失败: $e');
    }
  }

  /// 取消所有通知
  /// 
  /// 通话结束时调用，清理所有通话相关通知
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('[CallNotificationManager] 所有通知已取消');
    } catch (e) {
      debugPrint('[CallNotificationManager] 取消所有通知失败: $e');
    }
  }
}
