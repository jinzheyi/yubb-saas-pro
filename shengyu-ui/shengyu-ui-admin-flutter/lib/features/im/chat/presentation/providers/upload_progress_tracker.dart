import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 单个文件的上传进度信息
class UploadProgressInfo {
  const UploadProgressInfo({
    required this.taskId,
    required this.progress,
    required this.status,
    this.errorMessage,
  });

  final String taskId;
  final int progress; // 0~100
  final UploadProgressStatus status;
  final String? errorMessage;

  UploadProgressInfo copyWith({
    int? progress,
    UploadProgressStatus? status,
    String? errorMessage,
  }) {
    return UploadProgressInfo(
      taskId: taskId,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// 上传进度状态枚举
enum UploadProgressStatus {
  queued,
  preparing,
  uploading,
  uploaded,
  sending,
  sent,
  failed,
  cancelled,
}

/// 上传进度追踪器
///
/// 用于在 UI 层观察文件上传进度。key 为 taskId，
/// 与 ChatUploadCoordinator 中的 UploadTask.taskId 一一对应。
class UploadProgressTracker extends StateNotifier<Map<String, UploadProgressInfo>> {
  UploadProgressTracker() : super(const <String, UploadProgressInfo>{});

  /// 更新上传进度
  void updateProgress({
    required String taskId,
    required int progress,
    required UploadProgressStatus status,
    String? errorMessage,
  }) {
    final existing = state[taskId];
    if (existing != null) {
      state = {
        ...state,
        taskId: existing.copyWith(
          progress: progress,
          status: status,
          errorMessage: errorMessage,
        ),
      };
    } else {
      state = {
        ...state,
        taskId: UploadProgressInfo(
          taskId: taskId,
          progress: progress,
          status: status,
          errorMessage: errorMessage,
        ),
      };
    }
  }

  /// 标记上传完成，移除记录
  void remove(String taskId) {
    final newState = Map<String, UploadProgressInfo>.from(state);
    newState.remove(taskId);
    state = newState;
  }

  /// 清理已完成的任务
  void cleanupFinished() {
    state = Map.fromEntries(
      state.entries.where((e) => e.value.status == UploadProgressStatus.uploading),
    );
  }
}

/// 上传进度追踪器 Provider
final uploadProgressTrackerProvider =
    StateNotifierProvider<UploadProgressTracker, Map<String, UploadProgressInfo>>(
  (ref) => UploadProgressTracker(),
);

/// 根据 taskId 获取上传进度的 Provider
final uploadProgressProvider = Provider.family<UploadProgressInfo?, String>(
  (ref, taskId) => ref.watch(uploadProgressTrackerProvider)[taskId],
);
