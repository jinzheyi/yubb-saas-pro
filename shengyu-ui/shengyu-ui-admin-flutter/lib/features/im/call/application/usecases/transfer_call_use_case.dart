import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';

class TransferCallUseCase {
  const TransferCallUseCase(this._repository);

  final CallRepository _repository;

  /// 发起通话转接
  Future<void> initiate({
    required String callId,
    required String targetUserId,
    String? targetUserName,
  }) {
    return _repository.initiateTransfer(
      callId: callId,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
    );
  }

  /// 接受通话转接
  Future<void> accept({required String callId}) {
    return _repository.acceptTransfer(callId: callId);
  }

  /// 拒绝通话转接
  Future<void> reject({required String callId}) {
    return _repository.rejectTransfer(callId: callId);
  }

  /// 取消通话转接
  Future<void> cancel({required String callId}) {
    return _repository.cancelTransfer(callId: callId);
  }
}
