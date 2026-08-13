import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_config.dart';

/// 通话配置 Provider
///
/// 提供全局通话配置，可在应用启动时自定义配置
final callConfigProvider = Provider<CallConfig>((ref) {
  // 默认配置，可通过 override 自定义
  return CallConfig.defaultConfig();
});

/// 群通话最大参与人数 Provider
final maxGroupCallParticipantsProvider = Provider<int>((ref) {
  return ref.watch(callConfigProvider).maxGroupCallParticipants;
});

/// 通话邀请超时时间 Provider
final callInviteTimeoutProvider = Provider<Duration>((ref) {
  return ref.watch(callConfigProvider).callInviteTimeout;
});

/// 是否启用屏幕共享 Provider
final enableScreenShareConfigProvider = Provider<bool>((ref) {
  return ref.watch(callConfigProvider).enableScreenShare;
});


