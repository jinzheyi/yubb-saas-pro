String groupCallRecordText({
  required String callerName,
  required bool isVideo,
  required int status,
  required int durationSeconds,
}) {
  final type = isVideo ? '视频' : '语音';
  return switch (status) {
    1 => '群$type通话已结束 ${_formatDuration(durationSeconds)}',
    2 || 3 => '$callerName发起了群$type通话',
    4 => '所选成员正在通话中',
    5 => '群$type通话已取消',
    _ => '群$type通话',
  };
}

String _formatDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final remaining = safe % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remaining.toString().padLeft(2, '0')}';
}
