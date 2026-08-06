import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';

class RecordCallUseCase {
  const RecordCallUseCase(this._repository);

  final CallRepository _repository;

  /// 开始通话录制
  Future<void> start({required String callId}) {
    return _repository.startRecording(callId: callId);
  }

  /// 停止通话录制
  Future<void> stop({
    required String callId,
    String? recordingFilePath,
  }) {
    return _repository.stopRecording(
      callId: callId,
      recordingFilePath: recordingFilePath,
    );
  }
}
