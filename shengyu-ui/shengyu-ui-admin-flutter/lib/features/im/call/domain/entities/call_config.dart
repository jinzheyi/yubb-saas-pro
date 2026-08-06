/// 通话配置实体
///
/// 定义通话系统的各项可配置参数，包括：
/// - 群通话最大参与人数
/// - 通话邀请超时时间
/// - 铃声播放时长
/// - 功能开关（录制、屏幕共享、转接等）
class CallConfig {
  const CallConfig({
    this.maxGroupCallParticipants = 9,
    this.callInviteTimeout = const Duration(seconds: 30),
    this.ringtoneDuration = const Duration(seconds: 30),
    this.enableCallRecording = true,
    this.enableScreenShare = true,
    this.enableCallTransfer = true,
  });

  /// 群通话最大参与人数（包含发起人）
  /// 默认 9 人，可根据业务需求调整
  final int maxGroupCallParticipants;

  /// 通话邀请超时时间
  /// 超过此时间未接听则自动取消，默认 30 秒
  final Duration callInviteTimeout;

  /// 铃声播放时长
  /// 超过此时间自动停止铃声，默认 30 秒
  final Duration ringtoneDuration;

  /// 是否启用通话录制功能
  final bool enableCallRecording;

  /// 是否启用屏幕共享功能
  final bool enableScreenShare;

  /// 是否启用通话转接功能
  final bool enableCallTransfer;

  /// 创建默认配置
  factory CallConfig.defaultConfig() => const CallConfig();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallConfig &&
          runtimeType == other.runtimeType &&
          maxGroupCallParticipants == other.maxGroupCallParticipants &&
          callInviteTimeout == other.callInviteTimeout &&
          ringtoneDuration == other.ringtoneDuration &&
          enableCallRecording == other.enableCallRecording &&
          enableScreenShare == other.enableScreenShare &&
          enableCallTransfer == other.enableCallTransfer;

  @override
  int get hashCode =>
      maxGroupCallParticipants.hashCode ^
      callInviteTimeout.hashCode ^
      ringtoneDuration.hashCode ^
      enableCallRecording.hashCode ^
      enableScreenShare.hashCode ^
      enableCallTransfer.hashCode;

  @override
  String toString() {
    return 'CallConfig('
        'maxGroupCallParticipants: $maxGroupCallParticipants, '
        'callInviteTimeout: $callInviteTimeout, '
        'ringtoneDuration: $ringtoneDuration, '
        'enableCallRecording: $enableCallRecording, '
        'enableScreenShare: $enableScreenShare, '
        'enableCallTransfer: $enableCallTransfer)';
  }
}
